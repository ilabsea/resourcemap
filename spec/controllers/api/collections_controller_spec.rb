require 'spec_helper'

describe Api::CollectionsController, type: :controller do
  include Devise::TestHelpers
  render_views

  let!(:user) { User.make time_zone: 'UTC' }
  let!(:collection) { user.create_collection(Collection.make) }
  let!(:layer) { collection.layers.make }

  let!(:text) { layer.text_fields.make :code => 'text'}
  let!(:numeric) { layer.numeric_fields.make :code => 'numeric' }
  let!(:yes_no) { layer.yes_no_fields.make :code => 'yes_no'}
  let!(:select_one) { layer.select_one_fields.make :code => 'select_one', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  let!(:select_many) { layer.select_many_fields.make :code => 'select_many', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  config_hierarchy = [{ id: 'dad', name: 'Dad', sub: [{id: 'son', name: 'Son'}, {id: 'bro', name: 'Bro'}]}]
  let!(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy',  config: { hierarchy: config_hierarchy }.with_indifferent_access }
  let!(:site_ref) { layer.site_fields.make :code => 'site' }
  let!(:date) { layer.date_fields.make :code => 'date' }
  let!(:director) { layer.user_fields.make :code => 'user'}

  let!(:site2) {collection.sites.make :name => "Site A", properties: { hierarchy.es_code => 'bro' } }

  let!(:site) { collection.sites.make  :name => "Site B", :properties => {
    text.es_code => 'foo',
    numeric.es_code => 1,
    yes_no.es_code => true,
    select_one.es_code => 1,
    select_many.es_code => [1, 2],
    hierarchy.es_code => 'dad',
    site_ref.es_code => site2.id,
    date.es_code => "2012-10-24T00:00:00Z",
    director.es_code => user.email }
  }

  before(:each) { sign_in user }

  describe "GET collection" do
    before(:each) do
      get :show, id: collection.id, format: 'json'
    end

    it 'should assign time_zone from login user' do
      expect(controller.collection.time_zone).to eq user.time_zone
    end
  end

  describe "GET JSON collection" do
    before(:each) do
      get :show, id: collection.id, format: 'json'
    end

    it { expect(response).to be_success }

    it "should return JSON", skip: true do
      json = JSON.parse response.body
      expect(json["name"]).to eq(collection.name)
      json['sites'].sort_by! { |site| site["name"] }
      expect(json["sites"].length).to eq(2)

      expect(json["sites"][0]["id"]).to eq(site2.id)
      expect(json["sites"][0]["name"]).to eq(site2.name)
      expect(json["sites"][0]["lat"]).to eq(site2.lat)
      expect(json["sites"][0]["long"]).to eq(site2.lng)

      expect(json["sites"][0]["properties"].length).to eq(1)

      expect(json["sites"][0]["properties"][hierarchy.code]).to eq("Bro")

      expect(json["sites"][1]["id"]).to eq(site.id)
      expect(json["sites"][1]["name"]).to eq(site.name)
      expect(json["sites"][1]["lat"]).to eq(site.lat)
      expect(json["sites"][1]["long"]).to eq(site.lng)

      expect(json["sites"][1]["properties"].length).to eq(9)

      expect(json["sites"][1]["properties"][text.code]).to eq(site.properties[text.es_code])
      expect(json["sites"][1]["properties"][yes_no.code]).to be_truthy
      expect(json["sites"][1]["properties"][numeric.code]).to eq(site.properties[numeric.es_code])
      expect(json["sites"][1]["properties"][select_one.code]).to eq('one')
      expect(json["sites"][1]["properties"][select_many.code]).to eq(['one', 'two'])
      expect(json["sites"][1]["properties"][hierarchy.code]).to eq("Dad")
      expect(json["sites"][1]["properties"][site_ref.code]).to eq(site2.id)
      expect(json["sites"][1]["properties"][date.code]).to eq('10/24/2012')
      expect(json["sites"][1]["properties"][director.code]).to eq(user.email)

    end
  end

  describe "GET JSON collection with query fieldeters" do

    it "should retrieve sites under certain item in a hierarchy field", skip: true do
      get :show, id: collection.id, format: 'json', hierarchy.code => { under: 'Dad' }
      expect(response).to be_success
      json = JSON.parse response.body
      expect(json["sites"].length).to eq(2)
      expect(json["sites"][0]["id"]).to eq(site2.id)
      expect(json["sites"][1]["id"]).to eq(site.id)
    end
  end

  describe "GET RSS collection" do
    before(:each) do
      get :show, id: collection.id, format: 'rss'
    end

    it { expect(response).to be_success }

    it "should return RSS" do
      rss =  Hash.from_xml response.body

      expect(rss["rss"]["channel"]["title"]).to eq(collection.name)
      rss["rss"]["channel"]["item"].sort_by! { |item| item["name"] }

      expect(rss["rss"]["channel"]["item"][0]["title"]).to eq(site2.name)
      expect(rss["rss"]["channel"]["item"][0]["lat"]).to eq(site2.lat.to_s)
      expect(rss["rss"]["channel"]["item"][0]["long"]).to eq(site2.lng.to_s)
      expect(rss["rss"]["channel"]["item"][0]["guid"]).to eq(api_site_url site2, format: 'rss')

      #TODO: This is returning "properties"=>"\n      "
      expect(rss["rss"]["channel"]["item"][0]["properties"].length).to eq(1)

      expect(rss["rss"]["channel"]["item"][0]["properties"][hierarchy.code]).to eq('Bro')

      expect(rss["rss"]["channel"]["item"][1]["title"]).to eq(site.name)
      expect(rss["rss"]["channel"]["item"][1]["lat"]).to eq(site.lat.to_s)
      expect(rss["rss"]["channel"]["item"][1]["long"]).to eq(site.lng.to_s)
      expect(rss["rss"]["channel"]["item"][1]["guid"]).to eq(api_site_url site, format: 'rss')


      expect(rss["rss"]["channel"]["item"][1]["properties"].length).to eq(9)

      expect(rss["rss"]["channel"]["item"][1]["properties"][text.code]).to eq(site.properties[text.es_code])
      expect(rss["rss"]["channel"]["item"][1]["properties"][numeric.code]).to eq(site.properties[numeric.es_code].to_s)
      expect(rss["rss"]["channel"]["item"][1]["properties"][yes_no.code]).to eq('true')
      expect(rss["rss"]["channel"]["item"][1]["properties"][select_one.code]).to eq('one')
      expect(rss["rss"]["channel"]["item"][1]["properties"][select_many.code].length).to eq(1)
      expect(rss["rss"]["channel"]["item"][1]["properties"][select_many.code]['option'].length).to eq(2)
      expect(rss["rss"]["channel"]["item"][1]["properties"][select_many.code]['option'][0]['code']).to eq('one')
      expect(rss["rss"]["channel"]["item"][1]["properties"][select_many.code]['option'][1]['code']).to eq('two')
      expect(rss["rss"]["channel"]["item"][1]["properties"][hierarchy.code]).to eq('Dad')
      expect(rss["rss"]["channel"]["item"][1]["properties"][site_ref.code]).to eq(site2.id.to_s)
      expect(rss["rss"]["channel"]["item"][1]["properties"][date.code]).to eq('10/24/2012')
      expect(rss["rss"]["channel"]["item"][1]["properties"][director.code]).to eq(user.email)


    end

  end

  describe "GET CSV collection" do
    before(:each) do
      get :show, id: collection.id, format: 'csv'
    end

    it { expect(response).to be_success }

    it "should return CSV" do
      csv =  CSV.parse response.body
      expect(csv.length).to eq(3)
      expect(csv[0]).to eq(['resmap-id', 'name', 'lat', 'long', text.code, numeric.code, yes_no.code, select_one.code, 'select_many', 'hierarchy', site_ref.code, date.code, director.code, 'last updated'])
      
      expect(csv.include?([site2.id.to_s, site2.name, site2.lat.to_s, site2.lng.to_s, "", "", "no", "", "", "Bro", "", "", "", site2.updated_at.strftime("%a, %d %B %Y %T %z")])).to eq(true)

      expect(csv.include?([site.id.to_s, site.name, site.lat.to_s, site.lng.to_s, site.properties[text.es_code], site.properties[numeric.es_code].to_s, "yes", "one", "one, two", "Dad", site2.id.to_s, "10/24/2012", user.email, site.updated_at.strftime("%a, %d %B %Y %T %z")])).to eq(true)
    end
  end

  describe "GET SHP collection" do
    before(:each) do
      get :show, id: collection.id, format: 'shp'
    end

    it { expect(response).to be_success }
  end

  describe "GET some sites from collection" do
    before(:each) do
      get :show, id: collection.id, format: 'shp'
    end

    it "should return some sites based on provided ids params", skip: true do
      get :get_some_sites ,sites: [site.id, site2.id].join(","), format: 'json', collection_id: collection.id
      expect(response).to be_success
      json = JSON.parse response.body
      expect(json.length).to eq(2)
    end
  end

  describe "validate query fields" do

    it "should validate numeric fields in equal queries", skip: true do
      get :show, id: collection.id, format: 'csv', numeric.code => "invalid"
      expect(response.response_code).to be(400)
      expect(response.body).to include("Invalid numeric value in field numeric")
      get :show, id: collection.id, format: 'csv', numeric.code => "2"
      expect(response.response_code).to be(200)
    end

    it "should validate numeric fields in other operations", skip: true do
      get :show, id: collection.id, format: 'csv', numeric.code => "<=invalid"
      expect(response.response_code).to be(400)
      expect(response.body).to include("Invalid numeric value in field numeric")
      get :show, id: collection.id, format: 'csv', numeric.code => "<=2"
      expect(response.response_code).to be(200)
    end

    it "should validate date fields format" do
      get :show, id: collection.id, format: 'csv', date.code => "invalid1234"
      expect(response.response_code).to be(400)
      expect(response.body).to include("Invalid date value in field date")
    end

    it "should validate date fields format values" do
      get :show, id: collection.id, format: 'csv', date.code => "32/4,invalid"
      expect(response.response_code).to be(400)
      expect(response.body).to include("Invalid date value in field date")
      get :show, id: collection.id, format: 'csv', date.code => "12/25/2012,12/31/2012"
      expect(response.response_code).to be(200)
    end

    it "should validate hierarchy existing option" do
      get :show, id: collection.id, format: 'csv', hierarchy.code => ["invalid"]
      expect(response.response_code).to be(400)
      expect(response.body).to include("Invalid hierarchy option in field hierarchy")
      get :show, id: collection.id, format: 'csv', hierarchy.code => ["Dad"]
      expect(response.response_code).to be(200)
    end

    it "should validate select_one existing option" do
      get :show, id: collection.id, format: 'csv', select_one.code => "invalid"
      expect(response.response_code).to be(400)
      expect(response.body).to include("Invalid option in field select_one")
      get :show, id: collection.id, format: 'csv', select_one.code => "one"
      expect(response.response_code).to be(200)
    end

    it "should validate select_many existing option" do
      get :show, id: collection.id, format: 'csv', select_many.code => "invalid"
      expect(response.response_code).to be(400)
      expect(response.body).to include("Invalid option in field select_many")
      get :show, id: collection.id, format: 'csv', select_many.code => "one"
      expect(response.response_code).to be(200)
    end
  end
end
