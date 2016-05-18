require 'spec_helper'

describe Snapshot do
  describe "validations" do
    let!(:snapshot) { Snapshot.make }

    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:collection_id) }
  end

  let!(:collection) { Collection.make }

  before(:each) do
    stub_time '2011-01-01 10:00:00 -0500'

    layer = collection.layers.make
    @field = layer.numeric_fields.make code: 'beds'

    @site1 = collection.sites.make name: 'site1 last year'
    @site2 = collection.sites.make name: 'site2 last year'

    stub_time '2012-06-05 12:17:58 -0500'
    @field2 = layer.numeric_fields.make code: 'beds2'

    @site3 = collection.sites.make name: 'site3 today'
    @site4 = collection.sites.make name: 'site4 today'
  end

  it "should create index with sites", skip: true do
    date = '2011-01-01 10:00:00 -0500'.to_time
    snapshot = collection.snapshots.create! date: date, name: 'last_year'

    index_name = Collection.index_name collection.id, snapshot_id: snapshot.id
    search = Tire::Search::Search.new index_name

    expect(search.perform.results.map { |x| x['_source']['id'] }.sort).to eq([@site1.id, @site2.id])

    # Also check mapping
    expect(snapshot.index.mapping['site']['properties']['properties']['properties']).to eq({@field.es_code => {'type' => 'long'}})
  end

  it "should destroy index on destroy", skip: true do
    date = '2011-01-01 10:00:00 -0500'.to_time

    snapshot = collection.snapshots.create! date: date, name: 'last_year'
    snapshot.destroy

    index_name = Collection.index_name collection.id, snapshot_id: snapshot.id
    expect(Tire::Index.new(index_name).exists?).to be_falsey
  end

  it "collection should have histories", skip: true do
    date = Time.now

    site_histories = collection.site_histories.at_date(date)
    expect(site_histories.count).to eq(4)

    layer_histories = collection.layer_histories.at_date(date)
    expect(layer_histories.count).to eq(1)

    field_histories = collection.field_histories.at_date(date)
    expect(field_histories.count).to eq(2)
  end

  it "should delete history when collection is destroyed" do
    collection.destroy

    expect(collection.site_histories.count).to eq(0)
    expect(collection.layer_histories.count).to eq(0)
    expect(collection.field_histories.count).to eq(0)
  end

  it "should delete snapshots when collection is destroyed", skip: true do
    collection.snapshots.create! date: Time.now, name: 'last_year'
    expect(collection.snapshots.count).to eq(1)

    collection.destroy

    expect(collection.snapshots.count).to eq(0)
  end

  it "should delete userSnapshot if collection is destroyed", skip: true do
    snapshot = collection.snapshots.create! date: Time.now, name: 'last_year'
    user = User.make
    snapshot.user_snapshots.create! user: user
    expect(snapshot.user_snapshots.count).to eq(1)

    collection.destroy

    expect(UserSnapshot.where(user_id: user.id, snapshot_id: snapshot.id).count).to eq(0)
  end

end
