require 'spec_helper'

describe Epsg do
  let(:content) { 'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]' }

  describe 'esri projection' do
    it 'should get wgs84' do
      expect(Epsg.wgs84).to eq(content)
    end

    it 'should get epsg:4326' do
      expect(Epsg['4326']).to eq(content)
    end

    it 'should get other code' do
      expect(Epsg['5726']).not_to be_nil
    end

    context 'non-existed code' do
      it 'should return nil' do
        expect(Epsg['non-existed']).to be_nil
      end
    end
  end
end