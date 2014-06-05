require 'nokogiri'
module Collection::KmlConcern
  extend ActiveSupport::Concern

  def to_kml results
    fields = {}
    field_options = {}
    field_kinds = {}
    self.fields.each do |f|
      fields["#{f["code"]}"] = f["name"]
      if ['select_one','select_many'].include? f.kind
        field_options["#{f["code"]}"] = {} 
        f["config"]["options"].each do |option|
          field_options["#{f["code"]}"]["#{option['id'].to_s}"] = option['label']
        end
      end
      field_kinds["#{f["code"]}"] = f["kind"]
    end
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.kml(:xmlns => "http://earth.google.com/kml/2.1"){
        xml.Document {
          xml.name self.name
          xml.open "1"

          xml.Style(:id => "defaultstyle") do

            xml.IconStyle {
              xml.Icon {
                xml.href "http://maps.google.com/mapfiles/kml/pushpin/red-pushpin.png"
              }
              xml.scale '1.4'
            }

            xml.LabelStyle{
              xml.color 'a1ff00ff'
              xml.scale '1.4'
            }

          end

          results.each do |r|
            row = r["_source"]
            xml.Placemark {
              xml.name row["name"]
              xml.styleUrl "#defaultstyle"
              xml.LookAt {
                xml.longitude row["location"]["lon"]
                xml.latitude  row["location"]["lat"]
                xml.altitude  0
                xml.range 32185
                xml.tilt 0
                xml.heading 0
              }

              xml.ExtendedData {
                row["properties"].each do |key, value|
                  xml.Data(:name => "#{fields[key]} (#{key})") {
                    case(field_kinds[key])
                    when "select_one"
                      xml.value field_options["#{key}"]["#{value}"]
                    when "select_many"
                      val_text = []
                      value.each do |v|
                        val_text.push field_options["#{key}"]["#{v}"]
                      end
                      xml.value val_text.join(", ")     
                    when 'yes_no'
                      xml.value value == true ? 'Yes': 'No'
                    when 'photo'
                      xml.value "<image src='http://#{Settings.host}/photo_field/#{value}' style='width:200px;' alt='#{value}' />"
                    else
                      xml.value value
                    end
                  }
                end
                xml.Data(:name => "Location") {
                  xml.value row["location"]
                }
              }

              xml.Point {
                xml.coordinates "#{row["location"]["lon"]},#{row["location"]["lat"]},0"
              }
            }
          end
        }
      }
    end
    builder.to_xml
  end

end