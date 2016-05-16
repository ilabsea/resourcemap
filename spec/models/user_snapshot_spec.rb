require 'spec_helper'

describe UserSnapshot do
  let!(:collection) { Collection.make }
  let!(:user) { User.make }
  let!(:snapshot1) { collection.snapshots.create! date: Date.yesterday, name: 'snp1' }
  let!(:user_snapshot) { snapshot1.user_snapshots.create! user: user, collection: collection }

  it "should delete previous snapshot per user and collection when creating a new one" do
    snapshot_for_user = UserSnapshot.where user_id: user.id, collection_id: collection.id
    snapshot_for_user.count.should eq(1)
    snapshot_for_user.first.snapshot.name.should eq("snp1")

    snapshot2 = collection.snapshots.create! date: Time.now , name: 'snp2'
    snapshot2.user_snapshots.create! user: user, collection: collection
    snapshot_for_user_new = UserSnapshot.where user_id: user.id, collection_id: collection
    snapshot_for_user_new.count.should eq(1)
    snapshot_for_user_new.first.snapshot.name.should eq("snp2")
  end

  describe "for" do
    it "returns the corresponding UserSnapshot" do
      s = UserSnapshot.for user, collection

      s.snapshot.name.should == 'snp1'
    end

    it "returns a valid unsaved UserSnapshot instance when there is not a previously saved one" do
      user2 = User.make

      s = UserSnapshot.for user2, collection

      s.should_not == nil
      s.new_record?.should == true
      s.collection.should == collection
      s.user.should == user2
    end
  end

  describe "at_present?" do
    it "is false if there's a snapshot loaded" do
      user_snapshot.at_present?.should == false
    end

    it "is true if there isn't any snapshot loaded" do
      s = UserSnapshot.new user: User.make, collection: collection
      s.at_present?.should == true
    end
  end

  describe "go_back_to_present" do
    it "does not persist the UserSnapshot if it wasn't persisted before" do
      s = UserSnapshot.new user: User.make, collection: collection
      s.go_back_to_present!
      s.new_record?.should == true
    end

    it "persists changes immediately" do
      user_snapshot.go_back_to_present!
      user_snapshot.reload
      user_snapshot.at_present?.should == true
    end

    it "goes back to present if a snapshot was loaded" do
      user_snapshot.go_back_to_present!
      user_snapshot.at_present?.should == true
    end

    it "stays at present if a snapshot wasn't loaded" do
      s = UserSnapshot.new user: User.make, collection: collection

      s.go_back_to_present!

      s.at_present?.should == true
    end
  end

  describe "go_to" do
    it "returns false and does nothing if there is not any snapshot with the given name" do
      snapshot_before = user_snapshot.snapshot

      user_snapshot.go_to!('a_snapshot_that_doesnt_exist').should == false

      user_snapshot.snapshot.should == snapshot_before
    end

    it "loads a snapshot with the given name", skip: true do
      my_snapshot = collection.snapshots.create! date: Time.now , name: 'my snapshot'

      user_snapshot.go_to!('my snapshot').should == true

      user_snapshot.snapshot.should == user_snapshot.snapshot
      user_snapshot.snapshot.name.should == 'my snapshot'
    end
  end

  describe 'telemetry' do
    let!(:collection) { Collection.make }
    let!(:snapshot) { Snapshot.make collection: collection }
    let!(:user) { User.make }

    it 'should touch collection lifespan on create' do
      user_snapshot = UserSnapshot.make_unsaved snapshot: snapshot, user: user, collection: collection

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection).at_least(:once)

      user_snapshot.save
    end

    it 'should touch collection lifespan on update' do
      user_snapshot = UserSnapshot.make snapshot: snapshot, user: user, collection: collection
      user_snapshot.touch

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      user_snapshot.save
    end

    it 'should touch collection lifespan on destroy' do
      user_snapshot = UserSnapshot.make snapshot: snapshot, user: user, collection: collection

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      user_snapshot.destroy
    end

    it 'should touch user lifespan on create' do
      user_snapshot = UserSnapshot.make_unsaved snapshot: snapshot, user: user, collection: collection

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      user_snapshot.save
    end

    it 'should touch user lifespan on update' do
      user_snapshot = UserSnapshot.make snapshot: snapshot, user: user, collection: collection
      user_snapshot.touch

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user)

      user_snapshot.save
    end

    it 'should touch user lifespan on destroy' do
      user_snapshot = UserSnapshot.make snapshot: snapshot, user: user, collection: collection

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user)

      user_snapshot.destroy
    end
  end
end
