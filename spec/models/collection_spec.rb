require 'spec_helper'

describe Collection do
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to have_many :memberships }
  it { is_expected.to have_many :users }
  it { is_expected.to have_many :layers }
  it { is_expected.to have_many :fields }
  it { is_expected.to have_many :thresholds }

  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:layer) { collection.layers.make user: user, fields_attributes: [{kind: 'numeric', code: 'foo', name: 'Foo', ord: 1}] }
  let!(:field) { layer.fields.first }

  context "max value" do
    it "gets max value for property that exists", skip: true do
      collection.sites.make :properties => {field.es_code => 10}
      collection.sites.make :properties => {field.es_code => 20}, :lat => nil, :lng => nil
      collection.sites.make :properties => {field.es_code => 5}

      expect(collection.max_value_of_property(field.es_code)).to eq(20)
    end
  end

  describe "thresholds test", skip: true do
    let!(:site) { collection.sites.make properties: {field.es_code => 9}}
    it "should return false when there is no threshold", skip: true do
      expect(collection.thresholds_test(site)).to be_falsey
    end

    it "should return false when no threshold is hit", skip: true do
      collection.thresholds.make is_all_site: true, conditions: [ field: 1, op: :gt, value: 10 ]
      expect(collection.thresholds_test(site)).to be_falsey
    end

    it "should return true when threshold 1 is hit" do
      collection.thresholds.make is_all_site: false, sites: [{"id" => site.id}], conditions: [ field: field.es_code, op: :lt, value: 10 ]
      expect(collection.thresholds_test(site)).to be_truthy
    end

    it "should return true when threshold 2 is hit" do
      collection.thresholds.make sites: [{"id" => site.id}], conditions: [ field: field.es_code, op: :gt, value: 10 ]
      collection.thresholds.make sites: [{"id" => site.id}], conditions: [ field: field.es_code, op: :eq, value: 9 ]
      expect(collection.thresholds_test(site)).to be_truthy
    end

    describe "multiple thresholds test" do
      let!(:site_2) { collection.sites.make properties: {field.es_code => 25}}

      it "should evaluate second threshold" do
        collection.thresholds.make is_all_site: false, conditions: [ {field: field.es_code, op: :gt, value: 10} ], sites: [{ "id" => site.id }]
        collection.thresholds.make is_all_site: false, conditions: [ {field: field.es_code, op: :gt, value: 20} ], sites: [{ "id" => site_2.id }]
        expect(collection.thresholds_test(site_2)).to be_truthy
      end
    end
  end

  describe "SMS query" do
    describe "Operator parser" do
      it "should return operator for search class" do
        expect(collection.operator_parser(">")).to eq("gt")
        expect(collection.operator_parser("<")).to eq("lt")
        expect(collection.operator_parser("=>")).to eq("gte")
        expect(collection.operator_parser("=<")).to eq("lte")
        expect(collection.operator_parser(">=")).to eq("gte")
        expect(collection.operator_parser("<=")).to eq("lte")
      end
    end
  end

  describe "History" do
    it "shold have user_snapshots througt snapshots" do
      snp_1 = collection.snapshots.create! date: Time.now, name: 'snp1'
      snp_2 = collection.snapshots.create! date: Time.now, name: 'snp2'

      snp_1.user_snapshots.create! user: User.make
      snp_2.user_snapshots.create! user: User.make

      expect(collection.user_snapshots.count).to eq(2)
      expect(collection.user_snapshots.first.snapshot.name).to eq('snp1')
      expect(collection.user_snapshots.last.snapshot.name).to eq('snp2')
    end

    it "should obtain snapshot for user if user_snapshot exists" do
      user = User.make
      snp_1 = collection.snapshots.create! date: Time.now, name: 'snp1'
      snp_1.user_snapshots.create! user: user

      snp_2 = collection.snapshots.create! date: Time.now, name: 'snp2'
      snp_2.user_snapshots.create! user: User.make

      snapshot = collection.snapshot_for(user)
      expect(snapshot.name).to eq('snp1')
    end

    it "should obtain nil snapshot_name for user if user_snapshot does not exists" do
      snp_1 = collection.snapshots.create! date: Time.now, name: 'snp1'
      snp_1.user_snapshots.create! user: User.make

      user = User.make
      snapshot = collection.snapshot_for(user)
      expect(snapshot).to be_nil
    end


  end

  describe "plugins" do
    # will fixe as soon as possible
    pending do
      it "should set plugins by names" do
        collection.selected_plugins = ['plugin_1', 'plugin_2']
        expect(collection.plugins).to eq({'plugin_1' => {}, 'plugin_2' => {}})
      end

      it "should skip blank plugin name when setting plugins" do
        collection.selected_plugins = ["", 'plugin_1', ""]
        expect(collection.plugins).to eq({'plugin_1' => {}})
      end
    end
  end

  describe 'gateway' do
    let(:admin_user) { User.make }
    let(:collection_1) { admin_user.create_collection Collection.make name: 'test'}
    let!(:gateway) { admin_user.channels.make name: 'default', basic_setup: true, ticket_code: '2222'  }

    it 'should return user_owner of collection' do
      expect(collection_1.get_user_owner).to eq admin_user
    end

    it 'should return gateway under user_owner', skip: true do
      expect(collection_1.get_gateway_under_user_owner).to eq gateway
    end
  end

  describe 'es_codes_by_field_code' do
    let!(:collection_a) { user.create_collection Collection.make_unsaved }
    let!(:layer_a) { collection_a.layers.make user: user }

    let!(:field_a) { layer_a.text_fields.make code: 'A', name: 'A', ord: 1 }
    let!(:field_b) { layer_a.text_fields.make code: 'B', name: 'B', ord: 2 }
    let!(:field_c) { layer_a.text_fields.make code: 'C', name: 'C', ord: 3 }
    let!(:field_d) { layer_a.text_fields.make code: 'D', name: 'D', ord: 4 }

    it 'returns a dict of es_codes by field_code' do
      dict = collection_a.es_codes_by_field_code

      expect(dict['A']).to eq(field_a.es_code)
      expect(dict['B']).to eq(field_b.es_code)
      expect(dict['C']).to eq(field_c.es_code)
      expect(dict['D']).to eq(field_d.es_code)
    end
  end

  describe 'site_ids_permission' do
    let(:collection) { user.create_collection Collection.make_unsaved }
    let(:user_2) { User.make }

    context 'when no memberships' do
      it "should have empty site ids permission" do
        expect(collection.site_ids_permission(user_2)).to be_empty
      end
    end
  end

  describe 'visible_layers_for' do
    let(:collection) { user.create_collection Collection.make_unsaved }

    context 'when user is not a collection member' do
      let(:user_2) { User.make }

      it "should have no layer" do
        expect(collection.visible_layers_for(user_2)).to be_empty
      end
    end
  end

  describe "#is site exist?", skip: true do
    before(:each) do
      site1 = collection.sites.make device_id: 'dv1', external_id: '1',properties: {}
      site2 = collection.sites.make device_id: 'dv1', external_id: '2',properties: {}
    end
    it "should return true when the site is not exist yet" do
      site3 = Site.new name: "Site3", collection_id: collection.id, device_id: 'dv1', external_id: '3', properties: {}
      expect(collection.is_site_exist?(site3.device_id, site3.external_id)).to be_falsey
    end 

    it "should return false when the site is already exist" do
      site4 = Site.new name: "Site4", collection_id: collection.id, device_id: 'dv1', external_id: '1', properties: {}
      expect(collection.is_site_exist?(site4.device_id, site4.external_id)).to be_truthy
    end
    it "should return false when the device_id is not exist yet" do
      site5 = Site.new name: "Site5", collection_id: collection.id, device_id: 'dv2', external_id: '1', properties: {}
      expect(collection.is_site_exist?(site5.device_id, site5.external_id)).to be_falsey
    end

    it "should return false without device_id" do
      site6 = Site.new name: "Site6", collection_id: collection.id, properties: {}
      expect(collection.is_site_exist?(site6.device_id, site6.external_id)).to be_falsey
    end
  end

  describe 'telemetry' do
    it 'should touch lifespan on create' do
      collection = Collection.make_unsaved

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      collection.save
    end

    it 'should touch lifespan on update' do
      collection = Collection.make
      collection.touch

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      collection.save
    end

    it 'should touch lifespan on destroy' do
      collection = Collection.make

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      collection.destroy
    end
  end

end
