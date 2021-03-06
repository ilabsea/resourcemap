require 'spec_helper'

describe ThresholdsController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:site) { Site.make } 
  before(:each) { sign_in user }

  describe 'Create threshold' do
    let(:condition_attributes) { {"field"=>"392", "op"=>"eq", "value"=>"20", "type"=>"value"} }
    let(:sites) { {"id" => site.id, "name" => "SR Health Center"} }
    it 'should fix conditions' do
      post :create, "threshold"=>{"color"=>"red", "ord" => 1, "sites" => {"0" => sites}, "conditions"=>{"0"=>condition_attributes}}, "collection_id" => collection.id
      
      threshold = collection.thresholds.last
      threshold.conditions.size.should == 1
      threshold.conditions[0].should eq condition_attributes
    end
  end

  describe 'Update threshold' do
    let(:condition_attributes) { {"field"=>"392", "op"=>"eq", "value"=>"20", "type"=>"value"} }
    let(:threshold) { collection.thresholds.make }
    let(:sites) {{"id" => "1", "name" => "SR Health Center"}}
    
    it 'should fix conditions' do
      put :update, "threshold"=>{ "conditions"=>{"0"=>condition_attributes}, "sites" => {"0" => sites}}, "collection_id" => collection.id, "id" => threshold.id

      threshold.reload
      threshold.conditions[0].should eq condition_attributes
    end
  end

end
