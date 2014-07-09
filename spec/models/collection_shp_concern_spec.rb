require 'spec_helper'

describe Collection::ShpConcern do
  let(:user) { User.make time_zone: 'UTC' }
  let(:collection) { user.collections.make }

  describe "generate dbf record" do
    let(:date_string) { '20140620T080000.000+0700' }
    let(:data_source) { 
      { 'created_at' => date_string, 'updated_at' => date_string }
    }

    describe "apply timezone" do
      let(:record) { collection.dbf_record_for data_source }

      before(:each) do
        collection.time_zone = 'UTC'
      end

      it 'should format created_at' do
        record.data['created_at'].should eq 'Fri, 20 Jun 2014 01:00:00 +0000'
      end

      it 'should format updated_at' do
        record.data['updated_at'].should eq 'Fri, 20 Jun 2014 01:00:00 +0000'
      end
    end
  end
end