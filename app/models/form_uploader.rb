include ActiveModel::Validations


class FormUploader
  extend CarrierWave::Mount
  include LoadData
  include PG
  include ActiveModel::Model


  attr_accessor :id
  attr_reader :shp_name
  attr_accessor :datum
  attr_accessor :temporality
  # mount_uploaders :xlsxs, XlsxUploader
  mount_uploader :shp, ShpUploader
  mount_uploader :dbf, DbfUploader
  mount_uploader :shx, ShxUploader

  validate :validate_temporality,
           :validate_datum


  def shp_name
    if (shp != nil && shp.filename != nil)
      File.basename(shp.filename, File.extname(shp.filename))
    end
  end

  def shx_name
    if (shx != nil && shx.filename != nil)
      File.basename(shx.filename, File.extname(shx.filename))
    end
  end

  def dbf_name
    if (dbf != nil && dbf.filename != nil)
      File.basename(dbf.filename, File.extname(dbf.filename))
    end
  end

  def validate_shp_name
    validates_presence_of :shp_name
    if (shp != nil && shp.filename != nil)
      empiezaAux = shp_name.starts_with?("aux")
      mayorDe100 = shp_name.length > 100

      if empiezaAux
        errors.add(:shp_name, "El nombre no puede empezar con aux")
      end
      if mayorDe100
        errors.add(:shp_name, "El nombre no puede superar los 100 caracteres")
      end
    end


  end

  def validate_datum
    validates_presence_of :datum
    validates_numericality_of :datum
    out_of_range = datum.to_i.between?(2000, 32766)
    if out_of_range == false
      errors.add(:datum, "El srid debe estar entre 2000 y 32766")
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
    connection_hash = {dbname: database, host: host, user: username, password: password}
    conn = PG::Connection.new(connection_hash)

    get_exists = %Q(SELECT TABLE_NAME FROM INFORMATION_SCHEMA.tables WHERE TABLE_NAME LIKE '#{tablename}')
    fetching = conn.exec(get_exists)
    if (fetching.ntuples() != 0)
      n = true
    end
  end

  def validate_xlsxs

  end

  def validate_dbf
    if (exist_table?(dbf_name))
      errors.add(:dbf, "DANGER: Ya existe ese archivo en la BD, utilice otro nombre (Renombrar)")
    end
  end

  def validate_shp
    if (exist_table?(shp_name))
      errors.add(:shp, "DANGER: Ya existe ese archivo en la BD, utilice otro nombre (Renombrar)")
    end
  end

  def validate_shx
    if (exist_table?(shx_name))
      errors.add(:shx, "DANGER: Ya existe ese shapefile, utilice otro nombre (Renombrar)")
    end
  end

  def validate_files

    validate :validate_dbf
    validate :validate_shp
    validate :validate_shx


    if !((dbf_name == shp_name) and (dbf_name == shx_name))
      errors.add([:dbf, :shp, :shx], "DANGER: El nombre de los archivos no es el mismo, reviselo")
    end
  end

  def save

    self.store_shp!
    self.store_shx!
    self.store_dbf!

    validate validate_shp_name

    puts("#{Rails.public_path}/uploads/form_uploader/#{shp_name}")
    listPath=recorreCarpeta("#{Rails.public_path}/uploads/form_uploader/#{shp_name}", "*.shp")
    shp2script(listPath, 25830, 25830)
    listScripts=recorreCarpeta("#{Rails.public_path}/scripts", "#{shp_name}.sql")
    script2pg(listScripts)

    if exist_table?(shp_name)
      return true
    else
      return false
    end
  end

  def clean_form_uploder_directory
    FileUtils.rm_rf(Dir.glob("#{Rails.public_path}/uploads/form_uploader/#{shp_name}"))
  end

end