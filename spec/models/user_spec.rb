require 'spec_helper'

describe User do
  it { is_expected.to have_many :memberships }
  it { is_expected.to have_many :collections }

  it "should be confirmed" do
    user = User.make confirmed_at: nil
    expect(user.confirmed?).to be_falsey
    user.confirm!
    expect(user.confirmed?).to be_truthy
  end

  it "creates a collection" do
    user = User.make
    collection = Collection.make_unsaved
    expect(user.create_collection(collection)).to eq(collection)
    expect(user.collections).to eq([collection])
    expect(user.memberships.first).to be_admin
  end

  it "creates a collection with owner true" do
    user = User.make
    collection = Collection.make_unsaved
    expect(user.create_collection(collection)).to eq(collection)
    expect(user.collections).to eq([collection])
    expect(user.memberships.first).to be_admin
    expect(user.memberships.first).to be_owner
  end

  it "fails to create a collection if invalid" do
    user = User.make
    collection = Collection.make_unsaved
    collection.name = nil
    expect(user.create_collection(collection)).to be_falsey
    expect(user.collections).to be_empty
  end

  context "duplicate phone numbers" do
    let!(:user) { User.make :phone_number => '85592811844' }

    it "should not allow to add a new user with duplicate phone" do
      user2 = User.make
      expect(User.create(:email => 'test@instedd.org', :password => 'AbCd456', :phone_number => '85592811844')).not_to be_valid
    end

  end

  context "admins?" do
    let!(:user) { User.make }
    let!(:collection) { user.create_collection Collection.make_unsaved }

    it "admins a collection" do
      expect(user.admins?(collection)).to be_truthy
    end

    it "doesn't admin a collection if belongs but not admin" do
      user2 = User.make
      user2.memberships.create! :collection_id => collection.id
      expect(user2.admins?(collection)).to be_falsey
    end

    it "doesn't admin a collection if doesn't belong" do
      expect(User.make.admins?(collection)).to be_falsey
    end
  end

  context "activities" do
    let!(:user) { User.make }
    let!(:collection) { user.create_collection Collection.make_unsaved }

    before(:each) do
      Activity.delete_all
    end

    it "returns activities for user membership" do
      Activity.make collection_id: collection.id, user_id: user.id, item_type: 'collection', action: 'created', data: {:name => collection.name}, collection_name: collection.name
      expect(user.activities.length).to eq(1)
    end

    it "doesn't return activities for user membership" do
      user2 = User.make
      Activity.make collection_id: collection.id, user_id: user.id, item_type: 'collection', action: 'created', data: {:name => collection.name}, collection_name: collection.name
      expect(user2.activities.length).to eq(0)
    end
  end

  describe "Permission" do
    before(:each) do
      @user1  = User.make
      @user = User.create(:email => "demo@instedd.org", :password => "AbCd456", :phone_number => "855123456789")
      @collection = Collection.make
      @site  = @collection.sites.make
      @layer = @collection.layers.create(:name => "health center")
      @properties =[{:code=>"AB", :value=>"26"}]
      @field = Field.create(:collection_id => @collection.id, :layer_id => @layer.id, :code => "AB", :ord => 1, :kind => "numeric")
    end

    it "should be able to view and update layer" do
      @collection.memberships.create(:user => @user, :admin => false)
      @collection.layer_memberships.create( :layer_id => @layer.id, :read => true, :user_id => @user.id, :write => true)
      Field::NumericField.create :collection_id => @collection.id, :layer_id => @layer.id, :code => "AB", :ord => 1
      expect(@user.can_view?(@collection, @properties[0][:code])).to be_truthy
      expect(@user.can_update?(@site, @properties)).to be_truthy
    end

    context "can update" do
      it "should return true when user have write permission on layer" do
        @collection.layer_memberships.create( :layer_id => @layer.id, :read => true, :user_id => @user.id, :write => true)
        expect(@user.validate_layer_write_permission(@site, @properties)).to be_truthy
      end

      it "should return false when user don't have write permission on layer" do
        expect(@user.validate_layer_write_permission(@site, @properties)).to be_falsey
      end

      it "should return true when two field have the same code 'AB' but difference collection_id" do
        @collection1 = Collection.make
        @layer1 = @collection1.layers.create(:name => "school")
        @field1 = Field.create(:collection_id => @collection1.id, :layer_id => @layer1.id, :code => "AB", :ord => 1, :kind => "numeric")
        @site1  = @collection1.sites.make
        @collection1.layer_memberships.create( :layer_id => @layer1.id, :read => true, :user_id => @user.id, :write => true)
        expect(@user.validate_layer_write_permission(@site1, @properties)).to be_truthy
      end
    end

    context "can view" do
      it "should return true when user have read permission on layer" do
        @collection.layer_memberships.create( :layer_id => @layer.id, :read => true, :user_id => @user.id, :write => true)
        expect(@user.validate_layer_read_permission(@collection, @properties[0][:code])).to be_truthy
      end

      it "should return false when user don't have write permission on layer" do
        expect(@user.validate_layer_read_permission(@site, @properties[0][:code])).to be_falsey
      end
    end
  end

  it "should encrypt all users password" do
    User.connection.execute "INSERT INTO `users` (`id`, `email`, `encrypted_password`, `created_at`, `updated_at`) VALUES (22, 'foo@example.com', 'BAr12345', CURDATE(), CURDATE())"
    User.encrypt_users_password
    expect(User.first.encrypted_password).not_to eq('BAr12345')
  end

  describe 'gateway' do 
    let(:user_1){ User.make }
    let!(:gateway) { user_1.channels.make name: 'default', ticket_code: '1234', basic_setup: true}

    it 'should return gateway under user' do
      expect(user_1.get_gateway).to eq gateway 
    end
  end

  it "should change datetime based on user timezone" do
    User.connection.execute "INSERT INTO `users` (`id`, `email`, `encrypted_password`, `time_zone`, `created_at`, `updated_at`) VALUES (22, 'foo@example.com', 'BAr12345', 'Bangkok', CURDATE(), CURDATE())"
    Time.zone = User.first.time_zone
    expect(User.first.created_at.in_time_zone(User.first.time_zone).to_s).to eq User.first.created_at.to_s
  end 

  describe 'telemetry' do
    it 'should touch lifespan on create' do
      user = User.make_unsaved

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user)

      user.save
    end

    it 'should touch lifespan on update' do
      user = User.make
      user.touch

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user)

      user.save
    end

    it 'should touch lifespan on destroy' do
      user = User.make

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user)

      user.destroy
    end
  end 
end
