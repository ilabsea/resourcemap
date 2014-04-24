class Backup

  TEMP_DIR = 'tmp/'
  PART_FILE_DIR = File.join(TEMP_DIR, "s3parts")
  BASEDIR = File.join(TEMP_DIR, "backups")

  FULL = :full
  INCREMENTAL = :incremental

  LOG_NAME = :s3_log_dir
  include Loggable

  attr_reader :name, :directory

  def initialize(name)
    @name = name
  end

  def db_config
    @db_config ||= Rails.configuration.database_configuration[Rails.env]
  end

  def current_dir
    @current_dir ||= [BASEDIR, '/', @name].join
  end

  def file_compression
    @file_compression ||= "#{@directory[:current]}.tar.gz"
  end


  def self.sql_with_assets
    if File.exists? Amazon::S3::CONFIG_FILE_PATH
      Log.info :s3_log_dir, "====== full backup: started at #{Time.now.to_s} ======"
      backup = setup Backup::FULL
      backup.copy_files
      backup.mysqldump
      backup.compress
      Amazon::S3.upload backup.file_compression
      backup.remove_files
      Log.info :s3_log_dir, "====== full backup: finished at #{Time.now.to_s} ======"
    end
  end

  def self.setup type
    instance = Backup.new "#{Time.now.strftime '%Y%m%d%H%M%S'}_#{type}"
    instance.prepare!
    instance
  end


  def prepare!
    Log.info(:s3_log_dir, "backup: preparing")
    @directory = {
      current: current_dir
    }

    FileUtils.mkdir TEMP_DIR unless File.exists? TEMP_DIR
    FileUtils.mkdir PART_FILE_DIR unless File.exists? PART_FILE_DIR
    FileUtils.mkdir BASEDIR unless File.exists? BASEDIR
    FileUtils.mkdir current_dir
  end

  def copy_files

    command = "cp -rH #{Rails.root}/public/photo_field #{@directory[:current]}"
    log_message "running command #{command} " 
    system command
  end

  def mysqldump
    log_message "backup: mysqldump database"
    cmd = "mysqldump --single-transaction -u#{db_config['username']} --flush-logs"
    cmd << " -p'#{db_config['password']}'" if db_config['password'].present?
    cmd << " #{db_config['database']} > #{@directory[:current]}/#{db_config['database']}.sql"
    system(cmd)
  end

  def compress
    log_message "backup: compressing"

    system "tar -zcf #{file_compression} #{@directory[:current]}"
    FileUtils.rm_rf @directory[:current]
  end

  def remove_files
    FileUtils.rm_rf file_compression
  end

  private
  def execute_sql sql
    log_message "backup: executing mysql command"

    yield if block_given?
    cmd = %{mysql -u#{db_config['username']} -e "#{sql}"}
    cmd << " -p'#{db_config['password']}'" if db_config['password'].present?
    system(cmd)
  end
end
