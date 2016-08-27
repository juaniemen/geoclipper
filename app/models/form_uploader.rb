include ActiveModel::Validations
include LoadData
include Zip


class FormUploader
  extend CarrierWave::Mount
  include PG
  include ActiveModel::Model


  attr_accessor :id
  attr_reader :shp_name
  attr_accessor :datum
  attr_accessor :temporality
  # mount_uploaders :xlsxs, XlsxUploader
  mount_uploader :zip, ZipUploader

  validate :validate_temporality,
           :validate_datum


  def shp_name
    if (zip != nil && zip.filename != nil)
      File.basename(zip.filename, File.extname(zip.filename))
    end
  end

  def validate_shp_name
    validates_presence_of :shp_name
    if (zip != nil && zip.filename != nil)
      empiezaAux = shp_name.starts_with?("aux")
      mayorDe100 = shp_name.length > 100
      special = "?<>',?[]}{=-)(*&^%$#`~{}"
      regex = /[#{special.gsub(/./){|char| "\\#{char}"}}]/

      if empiezaAux
        errors.add(:shp_name, "El nombre no puede empezar con aux")
      end
      if mayorDe100
        errors.add(:shp_name, "El nombre no puede superar los 100 caracteres")
      end
      if shp_name =~ regex
        errors.add(:shp_name, "El nombre no puede contener caracteres especiales: ?<>',?[]}{=-)(*&^%$#`~{}")
      end
    end


  end

  def existe_epsg?
    result = false
    config = Rails.configuration.database_configuration
    host = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]
    connection_hash = {dbname: database, host: host, user: username, password: password}
    conn = PG::Connection.new(connection_hash)

    get_exists = %Q(SELECT * FROM spatial_ref_sys WHERE srid = '#{datum}')
    fetching = conn.exec(get_exists)
    if (fetching.ntuples() != 0)
      result = true
    end
    result
  end

  def validate_datum
    validates_presence_of :datum
    validates_numericality_of :datum
    out_of_range = datum.to_i.between?(2000, 32766)
    if(!existe_epsg?)
      errors.add(:datum, "El valor #{datum} no es un código EPSG válido")
    end


  end

  def validate_temporality
    validates_presence_of :temporality
    # regex = /^(ENE|FEB|MAR|ABR|MAY|JUN|JUL|AGO|SEP|OCT|NOV|DIC)\d{4}$/
    # if regex.match(temporality) == nil
    #   errors.add(:temporality, "DANGER: La temporalidad debe cumplir el formato (3 letras mes 4 dígitos año) EJ: ENE2014")
    # end


  end

  def exist_table?(tablename)
    n = false
    config = Rails.configuration.database_configuration
    host = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]
    port = 5432
    connection_hash = {dbname: database, host: host, user: username, password: password}
    conn = PG::Connection.new(connection_hash)

    get_exists = %Q(SELECT TABLE_NAME FROM INFORMATION_SCHEMA.tables WHERE TABLE_NAME LIKE '#{tablename}')
    fetching = conn.exec(get_exists)
    if (fetching.ntuples() != 0)
      n = true
    end
  end



  def validate_zip
    if (exist_table?(shp_name))
      errors.add(:zip, "DANGER: Ya existe ese archivo en la BD, utilice otro nombre (Renombrar)")
    end
  end


  def validate_files
    validate :validate_zip
  end

  def descomprime_zip
    Zip::File.open("#{Rails.public_path}/uploads/form_uploader/#{shp_name}.zip") do |zip_file|

      zip_file.each do |entry|
        # Extract to file/directory/symlink

        puts "Extracting #{entry.name}"
        unless File.exist?("#{Rails.public_path}/uploads/form_uploader/#{shp_name}")
          FileUtils::mkdir_p("#{Rails.public_path}/uploads/form_uploader/#{shp_name}")
        end
        zip_file.extract(entry, "#{Rails.public_path}/uploads/form_uploader/#{entry.name}"){true}

        puts "Extracted #{entry.name}"
      end
    end
  end

  def save

    self.store_zip!

    validate validate_shp_name

    self.descomprime_zip
    puts("#{Rails.public_path}/uploads/form_uploader/#{shp_name}")
    config = Rails.configuration.database_configuration
    host = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]
    port = 5432
    connection_hash = {dbname: database, host: host, user: username, password: password, port: port}
    listPath=recorreCarpeta("#{Rails.public_path}/uploads/form_uploader/#{shp_name}", "*.shp")
    listPath.each do |n|
    inserta_datos(shp_name, n, connection_hash, datum)
    end
    # shp2script(listPath, self.datum, 25830)
    # # listScripts=recorreCarpeta("#{Rails.public_path}/scripts", "#{shp_name}.sql")
    # script2pg(listScripts)
    if (existe_epsg?)
    if exist_table?(shp_name)
      return true
    else
      return false
    end
    end
    return false
  end

  def clean_form_uploder_directory
    FileUtils.rm_rf(Dir.glob("#{Rails.public_path}/uploads/form_uploader/#{shp_name}"))
  end

end