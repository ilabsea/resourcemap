require 'spec_helper'

describe ImportWizard do
  let!(:user) { User.make }

  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:user2) { collection.users.make email: 'user2@email.com'}
  let!(:membership) { collection.memberships.create! user_id: user2.id }

  let!(:layer) { collection.layers.make }

  let!(:luhn) { layer.identifier_fields.make code: 'luhn', config: {'format' => 'Luhn'} }

  it "imports into existing field with non-blank values" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Luhn']
      csv << ['Foo', '100000-9']
      csv << ['Bar', '100001-8']
      csv << ['Baz', '100002-7']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Luhn', use_as: 'existing_field', field_id: luhn.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string
    ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    sites = collection.sites.reload
    expect(sites.length).to eq(3)

    expect(sites[0].properties[luhn.es_code]).to eq('100000-9')
    expect(sites[1].properties[luhn.es_code]).to eq('100001-8')
    expect(sites[2].properties[luhn.es_code]).to eq('100002-7')
  end

  it "imports into existing field and deletes the value" do
    site = collection.sites.make properties: {luhn.es_code => '100000-9'}

    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Luhn']
      csv << [site.id, 'Foo', '']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'Luhn', use_as: 'existing_field', field_id: luhn.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string
    ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    sites = collection.sites.reload
    expect(sites.length).to eq(1)
    expect(sites[0].properties[luhn.es_code]).to be_blank
  end

  it "imports into existing field with invalid values" do
    collection.sites.make properties: {luhn.es_code => '100000-9'}

    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Luhn']
      csv << ['Foo', 'Hello']
      csv << ['Bar', '100000-8']
      csv << ['Baz', '100000-9']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Luhn', use_as: 'existing_field', field_id: luhn.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string
    ImportWizard.mark_job_as_pending user, collection
    sites = (ImportWizard.validate_sites_with_columns user, collection, specs)

    sites_errors = sites[:errors]
    data_errors = sites_errors[:data_errors]
    expect(data_errors.length).to eq(3)

    expect(data_errors[0][:description]).to eq("Some of the values in column 2 are not valid for the type luhn identifier: the value must be in this format: nnnnnn-n (where 'n' is a number).")
    expect(data_errors[0][:column]).to eq(1)
    expect(data_errors[0][:rows]).to eq([0])

    expect(data_errors[1][:description]).to eq("Some of the values in column 2 are not valid for the type luhn identifier: the value failed the luhn check.")
    expect(data_errors[1][:column]).to eq(1)
    expect(data_errors[1][:rows]).to eq([1])

    expect(data_errors[2][:description]).to eq("Some of the values in column 2 are not valid for the type luhn identifier: the value already exists in the collection.")
    expect(data_errors[2][:column]).to eq(1)
    expect(data_errors[2][:rows]).to eq([2])
  end

end
