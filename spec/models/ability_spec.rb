require 'spec_helper'
require "cancan/matchers"

describe Ability do

	describe "Collection Abilities" do
		let!(:admin) { User.make }
		let!(:guest) { User.make is_guest: true}
		let!(:user) { User.make }
		let!(:member) { User.make }
		let!(:collection) { admin.create_collection Collection.make }
		let!(:membership) { collection.memberships.create! :user_id => member.id, admin: false }

		let!(:admin_ability) { Ability.new(admin)}
		let!(:member_ability) { Ability.new(member)}
		let!(:user_ability) { Ability.new(user)}
		let!(:guest_ability) { Ability.new(guest)}


		describe "Destroy collection" do
			it { expect(admin_ability).to be_able_to(:destroy, collection) }
			it { expect(member_ability).not_to be_able_to(:destroy, collection) }
			it { expect(user_ability).not_to be_able_to(:destroy, collection) }
			it { expect(guest_ability).not_to be_able_to(:destroy, collection) }
		end

		describe "Create snapshot" do
			it { expect(admin_ability).to be_able_to(:create_snapshot, collection) }
			it { expect(member_ability).not_to be_able_to(:create_snapshot, collection) }
			it { expect(user_ability).not_to be_able_to(:create_snapshot, collection) }
			it { expect(guest_ability).not_to be_able_to(:create_snapshot, collection) }
		end

		describe "Update collection" do 
			it { expect(admin_ability).to be_able_to(:update, collection) }
			it { expect(member_ability).not_to be_able_to(:upate, collection) }
			it { expect(user_ability).not_to be_able_to(:update, collection) }
			it { expect(guest_ability).not_to be_able_to(:update, collection) }
		end

		describe "Create collection" do
			it { expect(guest_ability).not_to be_able_to(:create, Collection) }
			it { expect(user_ability).to be_able_to(:create, Collection) }
		end

		describe "Public Collection Abilities" do
			let!(:public_collection) { admin.create_collection Collection.make public: true}

			it { expect(user_ability).not_to be_able_to(:read, collection) }
			it { expect(user_ability).not_to be_able_to(:update, collection) }

		end

		describe "Manage snapshots" do

			it { expect(admin_ability).to be_able_to(:create, (Snapshot.make collection: collection)) }
			it { expect(member_ability).not_to be_able_to(:create, (Snapshot.make collection: collection)) }
			it { expect(user_ability).not_to be_able_to(:create, (Snapshot.make collection: collection)) }
			it { expect(guest_ability).not_to be_able_to(:create, (Snapshot.make collection: collection)) }
		end

		describe "Members" do
			it { expect(admin_ability).to be_able_to(:members, collection) }
			it { expect(member_ability).not_to be_able_to(:members, collection) }
			it { expect(user_ability).not_to be_able_to(:members, collection) }
			it { expect(guest_ability).not_to be_able_to(:members, collection) }
		end
	end

end