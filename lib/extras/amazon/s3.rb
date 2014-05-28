module Amazon
  class S3
    CONFIG_FILE_PATH = "#{Rails.root}/config/aws.yml"
    LOG_NAME = :s3_log_dir
    include Loggable

    def initialize
      @s3 = AWS::S3.new
    end

    class << self
      def upload file
        unless validate?(file)
          log_message "error at #{Time.now.to_s}, file can't be null"
          raise "file can't be null"
        end

        instance = Amazon::S3.new
        instance.upload file
      end

      def validate? file
        file && File.exists?(file) ? true : false
      end
    end

    def bucket
      return nil unless File.exists?(CONFIG_FILE_PATH)
      aws = YAML::load(File.open(CONFIG_FILE_PATH))[Rails.env]
      @bucket ||= @s3.buckets[aws['bucket_name']]
    end

    def object(file)
      if file
        @key = File.basename(file)
        @object ||= bucket.nil? ? nil : bucket.objects[@key]
      end
    end

    def upload original_file
      log_message("test")
      part_file = PartFile.new original_file
      part_file.split!
      total = File.size original_file
      uploaded = 0

      log_message "uploading to amazon s3"
      log_message("total: #{total}")

      object(original_file).multipart_upload do |multipart_upload|
        part_file.get_files.sort!.each do |file|

          length = File.size file
          log_message_with_percentage("Uploading file #{file}", uploaded, total)

          multipart_upload.add_part  file: file, content_length: length
          
          uploaded += length
          log_message_with_percentage("Finishing file #{file}", uploaded, total)
        end

        log_message("part: #{uploaded}")
        multipart_upload.complete(:remote_parts)
        
      end
      log_message "Done"
      part_file.clear!
    end
  end
end
