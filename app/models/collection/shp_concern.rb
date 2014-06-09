module Collection::ShpConcern
  extend ActiveSupport::Concern

  def to_shp(elastic_search_api_results = new_search.unlimited.api_results)
    Dir.mktmpdir { |dir|
      generate_shp File.join(dir, "#{self.id}.shp"), elastic_search_api_results
      compress_files dir
    }
  end

  def generate_shp path, search_results
    shp = ShpFile.create path, ShpType::POINT, self.class.resmap_dbf_fields | dbf_fields.values
    shp.transaction do |tr|
      search_results.each do |result|
        tr.add dbf_record_for result['_source']
      end
    end
    shp.close
  end

  def dbf_fields
    @dbf_fields ||= Hash[
      fields.all.map { |field|
        [field, field.to_dbf_field]
      }
    ]
  end

  def compress_files dir
    path = File.join dir, "#{self.id}.zip"
    Zip::ZipOutputStream.open(path) do |zos|
      %w(shp shx dbf).each do |format|
        filename = "#{self.id}.#{format}"

        zos.put_next_entry filename
        zos.print File.read File.join(dir, filename)
      end
      zos.put_next_entry "#{self.id}.prj"
      zos.print Epsg.wgs84
    end
    IO.read path
  end

  def dbf_record_for source = {}
    point = Point.from_x_y source['location'].try(:[], 'lon'), source['location'].try(:[], 'lat')
    data  = [ 
      ['resmap-id', source['id']],
      ['name', source['name']],
      ['created_at', Site.iso_string_to_rfc822(source['created_at'])],
      ['updated_at', Site.iso_string_to_rfc822(source['updated_at'])] ]

    data |= dbf_fields.map { |field, _| [field.code, source['properties'][field.code]] }

    ShpRecord.new point, Hash[ data ]
  end

  module ClassMethods
    def resmap_dbf_fields
      fields = [
        dbf_field_for('resmap-id', type: 'N', length: 4, decimal: 0),
        dbf_field_for('name', type: 'C', length: 50),
        dbf_field_for('created_at', type: 'C', length: 40),
        dbf_field_for('updated_at', type: 'C', length: 40) ]
    end

    def dbf_field_for name, attrs = {}
      Dbf::Field.new name, attrs[:type], attrs[:length], attrs[:decimal] || 0
    end
  end
end