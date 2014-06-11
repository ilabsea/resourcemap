# epsg.io - Coordinate Systems Worldwide
# http://epsg.io

module Epsg
  extend self

  COORDINATE_SYSTEMS = {
    '4326' => 'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]' }.freeze

  def [] key
    esri = COORDINATE_SYSTEMS[key.to_s]
    unless esri
      res = Net::HTTP.get_response URI "http://epsg.io/#{key}.esriwkt"
      res.body if res.code == '200'
    end || esri
  end

  # Named alias for epsg:4326
  # http://epsg.io/4326
  def wgs84
    self['4326']
  end
end