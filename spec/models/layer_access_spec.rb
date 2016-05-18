require 'spec_helper'

describe "layer access", skip: true do
  let!(:collection) { Collection.make }
  let!(:user) { User.make }
  let!(:membership) { Membership.create! user_id: user.id, collection_id: collection.id }
  let!(:layer1) { collection.layers.make }
  let!(:field1) { layer1.text_fields.make collection_id: collection.id }
  let!(:layer2) { collection.layers.make }
  let!(:field2) { layer2.text_fields.make collection_id: collection.id }

  context "fields for user" do
    it "only returns fields that can be read" do
      membership.set_layer_access :verb => :read, :access => true, :layer_id => layer1.id

      layers = collection.visible_layers_for user
      expect(layers.length).to eq(1)
      expect(layers[0][:name]).to eq(layer1.name)

      fields = layers[0][:fields]
      expect(fields.length).to eq(1)
      expect(fields[0][:id]).to eq(field1.es_code)
      expect(fields[0][:writeable]).to be_falsey
    end

    it "returns all fields if admin" do
      membership.admin = true
      membership.save!

      layers = collection.visible_layers_for user
      expect(layers.length).to eq(2)
      expect(layers[0][:name]).to eq(layer1.name)
      expect(layers[1][:name]).to eq(layer2.name)

      fields = layers[0][:fields]
      expect(fields.length).to eq(1)
      expect(fields[0][:id]).to eq(field1.es_code)
      expect(fields[0][:writeable]).to be_truthy

      fields = layers[1][:fields]
      expect(fields.length).to eq(1)
      expect(fields[0][:id]).to eq(field2.es_code)
      expect(fields[0][:writeable]).to be_truthy
    end
  end

  context "can write field" do
    it "can't write if property doesn't exist" do
      expect(user.can_write_field?(nil, collection, "unexistent")).to be_falsey
    end

    it "can't write if only read access" do
      membership.set_layer_access :verb => :read, :access => true, :layer_id => layer1.id

      expect(user.can_write_field?(field1, collection, field1.es_code)).to be_falsey
    end

    it "can write if write access" do
      membership.set_layer_access :verb => :write, :access => true, :layer_id => layer1.id

      expect(user.can_write_field?(field1, collection, field1.es_code)).to be_truthy
    end

    it "can write if admin" do
      membership.admin = true
      membership.save!

      expect(user.can_write_field?(field1, collection, field1.es_code)).to be_truthy
    end
  end

end
