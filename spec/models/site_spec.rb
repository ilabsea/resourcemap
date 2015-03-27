# == Schema Information
#
# Table name: sites
#
#  id               :integer          not null, primary key
#  collection_id    :integer
#  name             :string(255)
#  lat              :decimal(10, 6)
#  lng              :decimal(10, 6)
#  parent_id        :integer
#  hierarchy        :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  properties       :text
#  location_mode    :string(10)       default("automatic")
#  id_with_prefix   :string(255)
#  uuid             :string(255)
#  device_id        :string(255)
#  external_id      :string(255)
#  start_entry_date :datetime         default(2015-08-14 02:57:03 UTC)
#  end_entry_date   :datetime         default(2015-08-14 02:57:03 UTC)
#  user_id          :integer
#

require 'spec_helper'

describe Site do
  let(:user) { User.make }
  it { should belong_to :collection }

  def history_concern_class
    described_class
  end

  def history_concern_foreign_key
    described_class.name.foreign_key
  end

  def history_concern_histories
    "#{described_class}_histories"
  end

  it_behaves_like "it includes History::Concern"

  let(:collection) { Collection.make }
  let(:layer) { collection.layers.make }
  let(:room) { layer.numeric_fields.make name: 'room'  }
  let(:desk) { layer.text_fields.make name: 'desk'  }
  let(:creation) { layer.date_fields.make name: 'creation'}

  let(:site) { collection.sites.make properties: { room.id.to_s => '50', desk.id.to_s => 'bla bla', creation.id.to_s => '2012-09-22T00:00:00Z' } }

  it "return as a hash of field_name and its value" do
    site.human_properties.should eq({'room' => 50, 'desk' => 'bla bla', 'creation' => '09/22/2012' })
  end

  it "should save yes_no property with value 'false' "  do
    yes_no_field = layer.yes_no_fields.make :code => 'X Ray machine'
    site.properties[yes_no_field.es_code] = false
    site.save!
    site.reload
    site.properties[yes_no_field.es_code].should eq(false)
  end

  describe "create or update from hash" do
    before(:each) do
      @hash = { "collection_id" => layer.collection.id,
        "name" => "site1", "lat" =>  "11.1", "lng" => "12.1",
        "existing_fields" => {"field_#{room.id}" => {"field_id" => room.id, "value" => "10"},
          "field_#{desk.id}" => {"field_id" => desk.id, "value" => "test"}}}
      @hash.merge!("current_user" => user)
      @site_count = Site.count
    end

    it "should create a new site when site id is missing or nil" do
      site1 = Site.create_or_update_from_hash!(@hash)
      site1.should_not be_nil
    end

    it "should update an existing site" do
      @hash["site_id"] = site.id
      site1 = Site.create_or_update_from_hash!(@hash)
      site1.name.should eq(@hash["name"])
    end
  end

  it "should get id and name" do
    Site.get_id_and_name([site.id]).should eq([{'id' => site.id, 'name' => site.name}])
  end

  it "should save without problems after field is deleted" do
    site # This line is needed because let(:site) is lazy

    room.destroy

    site.properties = site.properties
    site.save!
  end

  describe ".is site exist?" do
    before(:each) do
      site1 = collection.sites.make device_id: 'dv1', external_id: '1',properties: { room.id.to_s => '10', desk.id.to_s => 'desk1' }
      site2 = collection.sites.make device_id: 'dv1', external_id: '2',properties: { room.id.to_s => '20', desk.id.to_s => 'desk2' }
    end
    it "should return true when the site is not exist yet" do
      site3 = Site.new name: "Site3", collection_id: collection.id, device_id: 'dv1', external_id: '3', properties: { room.id.to_s => '30', desk.id.to_s => 'desk3' }
      collection.is_site_exist?(site3.device_id, site3.external_id).should be_false
    end 

    it "should return false when the site is already exist" do
      site4 = Site.new name: "Site4", collection_id: collection.id, device_id: 'dv1', external_id: '1', properties: { room.id.to_s => '40', desk.id.to_s => 'desk4' }
      collection.is_site_exist?(site4.device_id, site4.external_id).should be_true
    end
    it "should return false when the device_id is not exist yet" do
      site5 = Site.new name: "Site5", collection_id: collection.id, device_id: 'dv2', external_id: '1', properties: { room.id.to_s => '50', desk.id.to_s => 'desk5' }
      Collection.is_site_exist?(site5.device_id, site5.external_id).should be_false
    end

    it "should return false without device_id" do
      site6 = Site.new name: "Site6", collection_id: collection.id, properties: { room.id.to_s => '60', desk.id.to_s => 'desk6' }
      Collection.is_site_exist?(site6.device_id, site6.external_id).should be_false
    end
  end
end
