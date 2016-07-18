module DataHelper

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
end
