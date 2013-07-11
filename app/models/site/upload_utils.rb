module Site::UploadUtils
  extend self
  require 'RMagick'

  def uploadFile(fileHash)
    if fileHash
      fileHash.each do |key, value|
        img = Magick::Image::from_blob(Base64.decode64(value)).first
        img.resize_to_fit!(800)
        img.write("public/photo_field/" + key)
      end
    end
  end

end
