module Site::UploadUtils
  extend self

  def uploadFile(fileHash)
    if fileHash 
      fileHash.each do |key, value|
        File.open("public/photo_field/" + key, "wb") do |file|
          file.write(Base64.decode64(value))
        end
      end
    end
  end

end
