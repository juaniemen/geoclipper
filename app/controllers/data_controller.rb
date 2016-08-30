require 'fileutils'

class DataController < ApplicationController
  include DataHelper
  include Clipper
  include PG
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
    params.require(:form_uploader).permit(:zip, :temporality, :datum)
  end

  def create
    @tree_view = [create_tree_structure]
    @uploader = FormUploader.new(uploader_params)
    @uploader.id = 36
    if !exists_table? && @uploader.existe_epsg?
      # begin
      @uploader.save
      # rescue
      # end
      if @uploader.errors.blank? && exists_table?
        flash.alert = nil
        @conn.exec(%Q[ALTER TABLE #{@uploader.shp_name} ADD COLUMN temporal_context DATE;
            UPDATE #{@uploader.shp_name} SET temporal_context = to_date('#{@uploader.temporality}', 'mm-yyyy');])
        flash.notice = "SUCCESS: Los datos se han cargado correctamente"
        @uploader.clean_form_uploder_directory
        @tree_view = [create_tree_structure]
      elsif @uploader.errors.blank?
        flash.alert = "DANGER: No se pudo completar la operación"
        @uploader.clean_form_uploder_directory
      end
    elsif exists_table?
      flash.alert = "WARNING: La tabla que desea cargar ya se encuentra en el sistema"
    elsif !@uploader.existe_epsg?
      flash.alert = "DANGER: El código EPSG que ha introducido no es válido"
    end

    render :new
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
    args = %Q(-f GeoJSON #{path} "PG:host=#{host} dbname=#{database} user=#{username} password=#{password}" -sql 'select * from #{shp_name1}' -s_srs EPSG:25830 -t_srs EPSG:3857)
    instruction = "ogr2ogr " + args
    out = `#{instruction}`
    p out
    json = File.open("#{path}", "r")
    jsonAux = json.read
    if !jsonAux.nil?
      jsonFinal = {
          :status => :ok,
          :message => "Success!",
          :data => jsonAux
      }
    else
      jsonFinal = {
          :status => :error,
          :message => ":((((",
          :data => nil
      }
    end
    respond_to do |format|
      format.json { render json: jsonFinal }
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
                                  data: {id: table_name, columns: columns, htmlResponse: (render_to_string partial: '/data/populateForm', locals: {columns: columns, table_name: table_name}, layout: false, formats: :html)},
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
                                  data: {htmlResponse: (render_to_string partial: '/data/list_to_clip', locals: {dataArray: dataArray1, nodeId: nodeId}, layout: false, formats: :html)},
      }
      }
    end
  end

  def clipNow

    dataAux = params['clipData']
    name = params['layerName']
    name.downcase!

    if validate_name_return_message(name) == nil
    existsTableBefore = exists_table_by_name?(name)
    if (!existsTableBefore)
      # Los datos no vienen como array si no como un hash cuyos indices son los números de un array lógico
      data = Array.new()
      dataAux.each do |k, v|
        data.push(v)
      end
      arrayProperties = []
      data.each do |dataArray|
        arrayProperties.push(dataArray['properties'])
      end
      arrayProperties.flatten!
      # arrayToClip -> Contendra table, properties y properties_as por lo tanto borramos nodeId y meteremos properties_as
      arrayToClip = Array.new(data)
      arrayToClip.map { |n| n['properties_as'] = n['properties'].clone } # Modificado a [{table: x, properties: y, properties_as: y }]

      counts = Hash.new(0)
      arrayProperties.map! { |val| counts[val]+=1 }
      arrayRepetidos = counts.reject { |val, count| count==1 }.keys
      if (arrayRepetidos.length != 0)
        arrayToClip.map do |table1|
          table = table1['table']
          properties = table1['properties']
          properties_as = table1['properties_as']
          properties_as.map! do |prop_as|
            if (arrayRepetidos.include?(prop_as))
              prop_as = table + '_' + prop_as
            else
              prop_as = prop_as
            end
          end
        end
      end
      arrayToClip.map! { |n| n.to_unsafe_h }
      listaTablas = []
      arrayToClip.map do |tablas|
        listaTablas.push(tablas['table'])
      end
      # Estas 2 variables las usamos para hacer permutaciones si no salen los clip.
      errorDataB = false
      permutListTablas = listaTablas.permutation.to_a
      (0...permutListTablas.length).each do |index|
        begin
          clipper_now(permutListTablas[index], name, @conn)

          # Si no ha habido error ha llegado hasta aqui
          break
        rescue PG::Error => error
          # Si ha habido error intenta con la siguiente
          errorDataB = true
          borra_intermedias(@conn)
          p error
        end
      end

      load_tables(name, arrayToClip, @conn)
      puts 'Ha salido del load, a ver que tal'

      existsTableAfter = exists_table_by_name?(name)

    end
  end

    if(validate_name_return_message(name) != nil)
      finalResponse = {status: 'badName', message: validate_name_return_message(name)}
    elsif (existsTableBefore)
      finalResponse = {status: 'duplicatedTable', message: 'Ya existe una tabla con ese nombre'}
    elsif ((existsTableBefore && !existsTableAfter) || errorDataB)
      finalResponse = {status: 'databaseError', message: 'Ha habido un error con la base de datos. Contacte con el administrador'}
    elsif (blankTable?(name))
      finalResponse = {status: 'blankTable', message: 'La tabla resultante está vacía'}
    elsif (existsTableAfter)
      finalResponse = {status: 'successClip', message: 'La nueva capa ha sido generada correctamente', data: jsonToMapHelped(name), table: name}
    end

    respond_to do |format|
      format.json { render json: finalResponse }
    end

  end

  def validate_name_return_message(name)
      empiezaAux = name.starts_with?("aux")
      mayorDe100 = name.length > 100
      special = "?<>',?[]}{=-)(*&^%$#`~{}"
      regex = /[#{special.gsub(/./){|char| "\\#{char}"}}]/

      if (name == "" || name == nil)
        message = "El nombre no puede estar vacío"
      elsif empiezaAux
        message =  "El nombre no puede empezar con aux"

      elsif mayorDe100
        message =  "El nombre no puede superar los 100 caracteres"

      elsif name =~ regex
        message =  "El nombre no puede contener caracteres especiales: ?<>',?[]}{=-)(*&^%$#`~{}"
      else
        message = nil
      end
    message
  end

  def downloadShp
    name = params['name']
    config = Rails.configuration.database_configuration
    host = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]


    dirname = "#{Rails.public_path}/shp_to_download/#{name}"
    if !File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    else
      FileUtils.rm_rf("#{dirname}/.", secure: true)
    end

    `pgsql2shp -f #{Rails.public_path}/shp_to_download/#{name}/#{name}.shp -h #{host} -u #{username} -P #{password} #{database} "SELECT * FROM #{name};"`
    createAndSendZip(name)
  end


  def downloadCsv
    name = params['name']
    config = Rails.configuration.database_configuration
    host = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]


    if !File.exist?("/postgres/#{name}.csv")
      File.new("/postgres/#{name}.csv", "w+")
    else
      File.delete("/postgres/#{name}.csv")
      File.new("/postgres/#{name}.csv", "w+")
    end
    File.chmod(0777, "/postgres/#{name}.csv")
    shpToCSV = %Q(COPY #{name}
    TO '/postgres/#{name}.csv'
    DELIMITER ',' ESCAPE '"'
    CSV HEADER;)
    ActiveRecord::Base.connection.execute(shpToCSV)
    # if File.exist?("#{Rails.public_path}/csv_to_download/#{name}.csv")
      send_file "/postgres/#{name}.csv", type: 'text/csv', disposition: 'attachment'
  end

  def remove
    name = params['name']
    drop_if_exists = "drop table if exists #{name}"
    @conn.exec(drop_if_exists)

    redirect_to  "/data/new"
  end
end





