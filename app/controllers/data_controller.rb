class DataController < ApplicationController
  before_action :connection_establishment

  def load
  end

  def new
    flash.alert = nil
    flash.notice = nil
    @tree_view = [create_tree_structure]
    @uploader = FormUploader.new
  end

  def uploader_params
    params.require(:form_uploader).permit(:dbf, :shx, :shp, :temporality, :datum)
  end

  def create
    @tree_view = [create_tree_structure]
    @uploader = FormUploader.new(uploader_params)
    @uploader.id = 36
    if !exists_table?
      @uploader.save
      if @uploader.errors.blank? && exists_table?
        flash.alert = nil
        @conn.exec(%Q(ALTER #{@tree_view.shp_name} ADD COLUMN temporal_context DATE;
            UPDATE #{tree_view.shp_name} SET temporal_context = to_date('#{@tree_view.temporality}', 'mm-yyyy');))
        flash.notice = "SUCCESS: Los datos se han cargado correctamente"
        @uploader.clean_form_uploder_directory
      elsif @uploader.errors.blank?
        flash.alert = "DANGER: No se pudo completar la operación"
        @uploader.clean_form_uploder_directory
      end
      render :new
    end

  end


  def create_tree_structure
    get_exists = %Q(SELECT f_table_name FROM geometry_columns)
    fetching = @conn.exec(get_exists)
    nodes = []
    fetching.each_row { |row|
      nodes.append(row[0])

    }

    result = nodes.each_with_object({}) do |s, memo|
      s.split('_').inject(memo) do |deep, k|
        deep[k.to_s] ||= {}
      end
    end
    resultFinal = {"VER TABLAS": result}
    final_tree(resultFinal)
  end


  def final_tree(result)
    return Tree.new_from_hash(result)
  end

  def connection_establishment
    config = Rails.configuration.database_configuration
    host = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]
    connection_hash = {dbname: database, host: host, user: username, password: password}
    @conn = PG::Connection.new(connection_hash)

  end

  def exists_table?
    get_exists = %Q(SELECT f_table_name FROM geometry_columns WHERE f_table_name LIKE lower('#{@uploader.shp_name}'))
    fetching = @conn.exec(get_exists)
    if fetching.ntuples != 0
      flash.alert = "DANGER: La tabla que desea cargar ya existe"
      result = true
    else
      result = false
    end
    result

  end


  def jsonToMap
    shp_name1 = params['shp_name']
    config = Rails.configuration.database_configuration
    host = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]
    path = "#{Rails.public_path}/geojsons/#{shp_name1}.json"
    if File.exist?("#{path}")
      File.delete("#{path}")
    end
    args = %Q(-f GeoJSON #{path} "PG:host=#{host} dbname=#{database} user=#{username} password=#{password}" -sql 'select * from #{shp_name1}')
    instruction = "ogr2ogr " + args
    out = `#{instruction}`
    p out
    json = File.open("#{path}", "r")
    if !json.nil?
      jsonFinal = {
          :status => :ok,
          :message => "Success!",
          :data => json
      }
    else
      jsonFinal = {
          :status => :error,
          :message => ":((((",
          :data => nil
      }
    end
    respond_to do |format|
      format.json { render json: json }
    end
  end

  def clipper
    @tree_view = [create_tree_structure]
    render 'clip'
  end

  def tables
    table_name = params['id']
    get_column_names = %Q(select column_name from information_schema.columns where table_name='#{table_name}';)
    fetching = @conn.exec(get_column_names)
    columns = []
    fetching.values.each do |column|
      if column[0] != 'geom' && !column[0].starts_with?('gid')
      columns.append(column[0])
      end
    end
    respond_to do |format|
      format.json { render json: {status: :success,
                                  message: ":))))",
                                  data: {id: table_name, columns: columns, htmlResponse: (render_to_string partial: '/data/populateForm', locals: {columns: columns, table_name: table_name}, layout: false, formats: :html )},
                                  }
      }
    end
  end

  def listToClip
    dataArray = params['dataArray']
    nodeId = params['nodeId']
    dataArray1 = [JSON.parse(dataArray)]
    respond_to do |format|
      format.json { render json: {status: :success,
                                  message: ":))))",
                                  data: {htmlResponse: (render_to_string partial: '/data/list_to_clip', locals: {dataArray: dataArray1, nodeId: nodeId}, layout: false, formats: :html )},
      }
      }
    end
  end

end




