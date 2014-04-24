class PartFile
  LOG_NAME = :s3_log_dir
  include Loggable
  PART_FILE_SIZE = "5m"

  def initialize file
    @file = file
  end

  def part_file_prefix
    File.join(Backup::PART_FILE_DIR, "#{File.basename(@file)}_")
  end

  def get_files
    Dir.glob("#{part_file_prefix}*")
  end

  def split!
    command = "split -b #{PART_FILE_SIZE} #{abs_path(@file)} #{abs_path(part_file_prefix)}"
    log_message "running command: #{command}"

    system(command)
  end

  def abs_path file
    "#{Rails.root}/#{file}"
  end

  def clear!
    FileUtils.rm_rf Backup::PART_FILE_DIR
  end
end
