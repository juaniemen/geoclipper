require 'walk'
require 'minitest/assertions'
require 'pg'

# Recorre la carpeta buscando los archivos que cumplen algunos de los patrones establecidos en la lista includes
# ejemplo: ['*.sql','.txt']
# excluyendo los patrones de la lista excludes por ejemplo ['*_paisajes.txt']
# path es el directorio desde el que empieza a buscar de forma recursiva
module LoadData
  include Walk
  include Minitest::Assertions
  include PG

  def recorreCarpeta(path1, extension)
    files_definitivos = []

    Walk.walk(path1) do |path, dirs, files|
      for file in files
        if File.fnmatch?(extension, file)
          files_definitivos.push(File.expand_path(file, path))
        end
      end
    end
    files_definitivos
  end


  # def shp2script(pathList, from_srid, to_srid)
  #   for n in pathList
  #     commandSHP2SCRIPT(from_srid, to_srid, "latin1", n.to_s, File.basename(n, ".shp"))
  #   end
  #
  #   files_definitivos = []
  #
  #
  #   Walk.walk("#{Rails.public_path}/scripts") do |path, dirs, files|
  #     for file in files
  #       if File.fnmatch?("*.sql", file)
  #         files_definitivos.push(File.expand_path(file, path))
  #       end
  #     end
  #   end
  #   files_definitivos
  #
  # end

  # def commandSHP2SCRIPT(from_srid, to_srid, encoding, shapefile_path, data_table)
    # cmd_path = ''
    # args = "-s #{from_srid}:#{to_srid} -n skip -W #{encoding} #{shapefile_path} public.#{data_table} > #{Rails.public_path}/scripts/#{data_table}.sql"
    # instruction = "shp2pgsql " + args
    # out = `#{instruction}`
    # p out
    # return [data_table, "#{Rails.public_path}/scripts/#{data_table}.sql"]


    #SOLUCION VALIDA
    # connection_hash = {dbname: "geoclipper-db/development", host: "localhost", user: "postgres", password: "postgres"}
    #
    # conn = PG::Connection.new(connection_hash)
    # drop_if_exists = "drop table if exists #{data_table}"
    # conn.exec(drop_if_exists)
    # rnm= %Q(ogr2ogr -f "PostgreSQL" PG:"host=localhost port=5432 user=postgres dbname=geoclipper-db/development password=postgres" #{shapefile_path})
    # out = `#{rnm}`
    # p out
  # end


  # def script2pg(listScripts)
  #   connection_hash = {dbname: "geoclipper-db/development", host: "localhost", user: "postgres", password: "postgres"}
  #
  #   conn = PG::Connection.new(connection_hash)
  #
  #
  #   for script_path in listScripts
  #     drop_if_exists = "drop table if exists #{File.basename(script_path, ".sql")}"
  #     conn.exec(drop_if_exists)
  #     begin
  #     conn.exec(File.open(script_path, "r").read())
  #     rescue Exception
  #       true
  #     end
  #   end
  # end

  def inserta_datos(data_table, shapefile_path, conexion_bd, datum_fuente)
    host = conexion_bd[:host]
    port = conexion_bd[:port]
    user = conexion_bd[:user]
    password = conexion_bd[:password]
    dbname = conexion_bd[:dbname]
    conn = PG::Connection.new(conexion_bd)
    drop_if_exists = "drop table if exists #{data_table}"
    conn.exec(drop_if_exists)
    spat_source =  "-s_srs EPSG:25830"
    rnm= %(ogr2ogr  -skipfailures  -s_srs EPSG:#{datum_fuente} -t_srs EPSG:25830 -f 'PostgreSQL' PG:"host='#{host}'
 port=#{port} user='#{user}' password='#{password}' dbname='#{dbname}' options='-c client_encoding=latin1'" #{shapefile_path} -nln #{data_table})
    out = `#{rnm}`
    p out
  end
end

#TODO Preguntar a Sara ¿Meter registros a la mimsa tabla? Meter más datos a la misma capa?
#TODO Refinar para que borre o anyada (a los registros existentes) si existe la tabla, segun quiera el usuario.
#TODO Mirar para hacer "directorios" en pgsql
