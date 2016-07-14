include 'pg'

module Clipper
def clipper(listaTablas, name)
  connection_hash = {dbname: "geoclipper-db/development", host:"localhost", user:"postgres", password: "postgres"}

  conn = PG::Connection.new(connection_hash)

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
  end


  borra_intermedias(conn)
end




def borra_intermedias(conn)
  get_aux = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.tables WHERE TABLE_NAME LIKE 'aux_%'"
  fetching = conn.exec(get_aux)
  fetching.each_row{ |n|
    print n
    if n != nil
      auxTable = %Q["#{n[0]}"]
      borra_aux = "drop table if exists #{auxTable};"
      conn.exec(borra_aux)
    end
  }
end




listaTablas = ["gmpsje_ambgeomorfo", "gmpsje_geofacies", "gmpsje_litologia"]
name = "geomofor_lito_paisaje"

clipper(listaTablas, name)

end





