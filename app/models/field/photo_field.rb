class Field::PhotoField < Field
  def value_type_description
    "photos"
  end

  def value_hint
    "Path to photo."
  end

  # params: value is 2-element array
  #   value[0] - is the filename
  #   value[1] - is the binary string of the image
  def decode_from_ui(value)
    Site::UploadUtils.uploadSingleFile value[0], Base64.decode64(value[1])
    value[0]
  end
end
