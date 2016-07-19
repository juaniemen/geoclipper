module DataHelper
  require 'zip'

  def jsonToMapHelped(name)
    shp_name1 = name
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

    json
  end

  def exists_table_by_name?(name)
    get_exists = %Q(SELECT f_table_name FROM geometry_columns WHERE f_table_name LIKE lower('#{name}'))
    fetching = @conn.exec(get_exists)
    if fetching.ntuples != 0
      result = true
    else
      result = false
    end
    result

  end

  def blankTable?(name)
    get_exists = %Q(SELECT * FROM "#{name}")
    fetching = @conn.exec(get_exists)
    if fetching.ntuples != 0
      result = false
    else
      result = true
    end
    result
  end


  # Este snipet ha sido cogido y adaptado de http://thinkingeek.com/2013/11/15/create-temporary-zip-file-send-response-rails/
  def createAndSendZip(name)

    #Attachment name
    filename = "#{name}.zip"
    temp_file = Tempfile.new(filename)

    begin
      #This is the tricky part
      #Initialize the temp file as a zip file
      Zip::OutputStream.open(temp_file) { |zos|}

      #Add files to the zip file as usual
      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
        #Put files in here

        n1 = "#{Rails.public_path}/shp_to_download/#{name}/#{name}.shp"
        n2 = "#{Rails.public_path}/shp_to_download/#{name}/#{name}.dbf"
        n3 = "#{Rails.public_path}/shp_to_download/#{name}/#{name}.prj"
        n4 = "#{Rails.public_path}/shp_to_download/#{name}/#{name}.shx"

        zipfile.add("#{name}/#{name}.shp", n1)
        zipfile.add("#{name}/#{name}.dbf", n2)
        zipfile.add("#{name}/#{name}.prj", n3)
        zipfile.add("#{name}/#{name}.shx", n4)
      end

      #Read the binary data from the file
      zip_data = File.read(temp_file.path)

      #Send the data to the browser as an attachment
      #We do not send the file directly because it will
      #get deleted before rails actually starts sending it
      send_data(zip_data, :type => 'application/zip', :filename => filename)
    ensure
      #Close and delete the temp file
      temp_file.close
      temp_file.unlink
    end
  end
end