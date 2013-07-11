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
  def purgeUploadedPhotos(site)
    photoFields = Field.where(:collection_id => site.collection_id, :kind => 'photo')
    puts photoFields.length
    photoFields.each { |field|
      path = "public/photo_field/"
      photoFileName = site.properties[field.id.to_s]
      if !photoFileName.nil? and File.exists?(path + photoFileName)
          File.delete(path + photoFileName)
      end
    }

  end

end
