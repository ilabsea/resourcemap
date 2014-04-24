class Log
  CONFIG_FILE = "#{Rails.root}/config/log_file.yml"

  def initialize key
    if Log.config
      Dir.mkdir Log.config['log_dir'] unless File.exists?(Log.config['log_dir'])
      Dir.mkdir Log.config[key.to_s] unless File.exists?(Log.config[key.to_s])
      @file_name = File.join(Log.config[key.to_s], Date.today.to_s)
    end
  end

  class << self
    def info key, content
      instance = Log.new(key)
      instance.info(content)
    end

    def config
      return nil unless File.exists?(CONFIG_FILE)
      @config ||= YAML::load(File.open(CONFIG_FILE))
    end
  end

  def info content
    File.open @file_name, "a" do |f|
      f.puts content
    end if @file_name
  end
end
