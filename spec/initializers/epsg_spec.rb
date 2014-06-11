require 'spec_helper'

describe Epsg do
  let(:content) { 'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]' }

  describe 'esri projection' do
    it 'should get wgs84' do
      Epsg.wgs84.should eq(content)
    end

    it 'should get epsg:4326' do
      Epsg['4326'].should eq(content)
    end

    it 'should get other code' do
      Epsg['5726'].should_not be_nil
    end

    context 'non-existed code' do
      it 'should return nil' do
        Epsg['non-existed'].should be_nil
      end
    end
  end
end