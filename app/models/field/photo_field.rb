class Field::PhotoField < Field
  def value_type_description
    "photos"
  end

  def value_hint
    "Path to photo."
  end

  def decode_from_ui(value)
    filename = "#{id}_#{Time.now.to_i}"
    Site::UploadUtils.uploadSingleFile filename, value
  end
end
