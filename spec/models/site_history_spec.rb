require 'spec_helper'

describe SiteHistory, skip: true do
  it { is_expected.to belong_to :site }

  it "should create ES index" do
    index_name = Collection.index_name 32, snapshot: "last_year"
    index = Tire::Index.new index_name
    index.create

    site_history = SiteHistory.make

    site_history.store_in index

    expect(index.exists?).to be_truthy

    search = Tire::Search::Search.new index_name
    expect(search.perform.results.length).to eq(1)
    expect(search.perform.results.first["_source"]["name"]).to eq(site_history.name)
    expect(search.perform.results.first["_source"]["id"]).to eq(site_history.site_id)
    expect(search.perform.results.first["_source"]["properties"]).to eq(site_history.properties)
    expect(search.perform.results.first["_source"]["location"]["lat"]).to eq(site_history.lat)
    expect(search.perform.results.first["_source"]["location"]["lon"]).to eq(site_history.lng)
  end

end

