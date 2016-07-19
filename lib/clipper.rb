require 'walk'
require 'minitest/assertions'
require 'pg'

module Clipper
  include Walk
  include Minitest::Assertions
  include PG

  def clipper_now(listaTablas, name, conn)
    # connection_hash = {dbname: "geoclipper-db/development", host: "localhost", user: "postgres", password: "postgres"}

    conn = conn

    # CAUTION Nombre de la columna en Postgre es 128 caracteres
    # Operador .. -> Último punto inclusive
    # Operador ... -> Último punto exclusive
    aux = listaTablas[0]
    query = ""
    (0...listaTablas.length - 1).each do |i|
      # Es necesario que quoteemos las string para meterlas en la query
      aux1 = %Q["#{aux}"]
      aux2 = %Q["#{listaTablas[i+1]}"]
      aux3 = %Q["aux_#{name+i.to_s}"]

      gidA = %Q["gid_#{aux}"]
      gidB = %Q["gid_#{listaTablas[i+1]}"]

      if (i == 0)
        if i == (listaTablas.length - 2)
          aux3 = %Q["#{name}"]
        end
        query = "drop table if exists #{aux3};
        create table #{aux3} as
        (select a.gid as #{gidA}, b.gid as #{gidB}, st_intersection(a.geom, b.geom) as geom
        from #{aux1} as a, #{aux2} as b
        where st_intersects(a.geom, b.geom));"
      else
        queryAux = "select column_name from information_schema.columns where
        table_name='#{aux}';"

        namesCol = conn.exec(queryAux)
        n = []
        namesCol.each_row do |x|
          if x[0] != 'gid' and x[0] != 'geom'
            n.push(x[0])
          end
        end


        string1 = ""
        (0...n.length).each do |r|
          if r != n.length-1
            string1 +=("a.#{n[r]}, ")
          else
            string1 += "a.#{n[r]}"
          end
        end


        ## Lo hago para borrar las intermedias, ya que obtendré todas las tablas y borraré las que terminan por aux+numero
        if i == (listaTablas.length - 2)
          aux3 = %Q["#{name}"]
        end


        query = "drop table if exists #{aux3};
            create table #{aux3} as
            (select #{string1}, b.gid as #{gidB}, st_intersection(a.geom, b.geom) as geom
            from #{aux1} as a, #{aux2} as b
            where st_intersects(a.geom, b.geom));"

      end
      conn.exec(query)
      aux = "aux_#{name+i.to_s}"
      if i != (listaTablas.length - 2)
        validate_table(aux, conn)
      end
    end


    borra_intermedias(conn)
    # Anado id a la tabla para que pueda ser buscada e iterada
    conn.exec(%Q[ALTER TABLE "#{name}" ADD COLUMN gid SERIAL PRIMARY KEY;])
  end


  def borra_intermedias(conn)
    get_aux = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.tables WHERE TABLE_NAME LIKE 'aux_%'"
    fetching = conn.exec(get_aux)
    fetching.each_row { |n|
      print n
      if n != nil
        auxTable = %Q["#{n[0]}"]
        borra_aux = "drop table if exists #{auxTable};"
        conn.exec(borra_aux)
      end
    }
  end


  def load_tables(tableClipped, arrayData, conn)
    arrayData.each do |table1|
      table = table1['table']
      properties = table1['properties']
      properties_as = table1['properties_as']

      # Primero debemos anadir las columnas

      # Obtenemos las columnas

      query_datatype = %Q[select column_name, data_type from information_schema.columns where table_name = '#{table}';]
      r = conn.exec(query_datatype)
      column_names = r.field_values('column_name')
      data_types = r.field_values('data_type')

      for r in 0...column_names.length
        for l in 0...properties.length
        if (properties[l] == (column_names[r]))
          query_alter = %Q[ALTER TABLE "#{tableClipped}" ADD COLUMN #{properties_as[l]} #{data_types[r]};]
          conn.exec(query_alter)
          end
        end
      end


      setOfValues = ""
      for n in 0...properties.length
        if (n != properties.length-1)
          setOfValues = setOfValues + %Q[#{properties_as[n]} = s.#{properties[n]}, ]
        end
      end
      setOfValues[setOfValues.length - 2] = " "
      puts setOfValues
      get_aux = %Q[UPDATE "#{tableClipped}" AS v SET #{setOfValues} FROM #{table} AS s WHERE v.gid_#{table} = s.gid;]
      conn.exec(get_aux)
    end
  end

  def validate_table(name1, conn)
    query_srid_unified = %Q[SELECT UpdateGeometrySRID('#{name1}','geom',25830);]
    conn.exec(query_srid_unified)
  end
  # listaTablas = ["gmpsje_ambgeomorfo", "gmpsje_geofacies", "gmpsje_litologia"]
  # name = "geomofor_lito_paisaje"
  #
  # clipper_now(listaTablas, name)
  # load_tables(table, arrayToClip)


end





