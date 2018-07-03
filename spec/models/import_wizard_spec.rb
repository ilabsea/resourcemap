# encoding: UTF-8
require 'spec_helper'

describe ImportWizard do
  let!(:user) { User.make }

  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:user2) { collection.users.make :email => 'user2@email.com'}
  let!(:membership) { collection.memberships.create! :user_id => user2.id }

  let!(:layer) { collection.layers.make }

  let!(:text) { layer.text_fields.make :code => 'text' }
  let!(:numeric) { layer.numeric_fields.make :code => 'numeric'}
  let!(:yes_no) { layer.yes_no_fields.make :code => 'yes_no' }
  let!(:select_one) { layer.select_one_fields.make :code => 'select_one', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  let!(:select_many) { layer.select_many_fields.make :code => 'select_many', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
  let!(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access }
  let!(:site) { layer.site_fields.make :code => 'site'}
  let!(:date) { layer.date_fields.make :code => 'date' }
  let!(:director) { layer.user_fields.make :code => 'user' }

  it "imports with name, lat, lon and one new numeric property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon', 'Beds']
      csv << ['Foo', '1.2', '3.4', '10']
      csv << ['Bar', '5.6', '7.8', '20']
      csv << ['', '', '', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'},
      {header: 'Beds', use_as: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)
    layers[1].name.should eq('Import wizard')

    fields = layers[1].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The beds')
    fields[0].code.should eq('beds')
    fields[0].kind.should eq('numeric')

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({fields[0].es_code => 10})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({fields[0].es_code => 20})
  end

  it "import should calculate collection bounds from sites" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon']
      csv << ['Foo', '30.0', '20.0']
      csv << ['Bar', '40.0', '30.0']
      csv << ['FooBar', '45.0', '40.0']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'}
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    collection.reload
    collection.min_lat.to_f.should eq(30.0)
    collection.max_lat.to_f.should eq(45.0)
    collection.min_lng.to_f.should eq(20.0)
    collection.max_lng.to_f.should eq(40.0)
    collection.lat.to_f.should eq(37.5)
    collection.lng.to_f.should eq(30.0)
  end

  it "imports with name, lat, lon and one new numeric property and existing ID" do
    site1 = collection.sites.make name: 'Foo old', properties: {text.es_code => 'coco'}
    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}

    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Beds']
      csv << ["#{site1.id}", 'Foo', '1.2', '3.4', '10']
      csv << ["#{site2.id}", 'Bar', '5.6', '7.8', '20']
      csv << ['', '', '', '', '']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'},
      {header: 'Beds', use_as: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)
    layers[1].name.should eq('Import wizard')

    fields = layers[1].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The beds')
    fields[0].code.should eq('beds')
    fields[0].kind.should eq('numeric')

    sites = collection.sites.all
    sites.length.should eq(2)

    site1.reload
    site1.name.should eq('Foo')
    site1.properties.should eq({fields[0].es_code => 10, text.es_code => 'coco'})

    site2.reload
    site2.name.should eq('Bar')
    site2.properties.should eq({fields[0].es_code => 20, text.es_code => 'lala'})
  end

  it "imports with name, lat, lon and one new numeric property and existing ID empty" do
    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Beds']
      csv << ["", 'Foo', '1.2', '3.4', '10']
      csv << ['', '', '', '', '']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'},
      {header: 'Beds', use_as: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)
    layers[1].name.should eq('Import wizard')

    fields = layers[1].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The beds')
    fields[0].code.should eq('beds')
    fields[0].kind.should eq('numeric')

    sites = collection.sites.all
    sites.length.should eq(1)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({fields[0].es_code => 10})
  end

  it "imports with new select one mapped to both code and label" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Visibility']
      csv << ['Foo', 'public']
      csv << ['Bar', 'private']
      csv << ['Baz', 'private']
      csv << ['', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Visibility', use_as: 'new_field', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'both'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)
    layers[1].name.should eq('Import wizard')

    fields = layers[1].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The visibility')
    fields[0].code.should eq('visibility')
    fields[0].kind.should eq('select_one')
    fields[0].config.should eq('next_id' => 3, 'options' => [{'id' => 1, 'code' => 'public', 'label' => 'public'}, {'id' => 2, 'code' => 'private', 'label' => 'private'}])

    sites = collection.sites.all
    sites.length.should eq(3)

    sites[0].properties.should eq({fields[0].es_code => 1})
    sites[1].properties.should eq({fields[0].es_code => 2})
    sites[2].properties.should eq({fields[0].es_code => 2})
  end

  it "imports with two new select ones mapped to code and label" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Visibility', 'Visibility Code']
      csv << ['Foo', 'public', '1']
      csv << ['Bar', 'private', '0']
      csv << ['Baz', 'private', '0']
      csv << ['', '', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Visibility', use_as: 'new_field', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'label'},
      {header: 'Visibility Code', use_as: 'new_field', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'code'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)
    layers[1].name.should eq('Import wizard')

    fields = layers[1].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The visibility')
    fields[0].code.should eq('visibility')
    fields[0].kind.should eq('select_one')
    fields[0].config.should eq('next_id' => 3, 'options' => [{'id' => 1, 'code' => '1', 'label' => 'public'}, {'id' => 2, 'code' => '0', 'label' => 'private'}])

    sites = collection.sites.all
    sites.length.should eq(3)

    sites[0].properties.should eq({fields[0].es_code => 1})
    sites[1].properties.should eq({fields[0].es_code => 2})
    sites[2].properties.should eq({fields[0].es_code => 2})
  end

  it "imports with name and existing text property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'hi']
      csv << ['Bar', 'bye']
      csv << ['', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Column', use_as: 'existing_field', field_id: text.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({text.es_code => 'hi'})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({text.es_code => 'bye'})
  end

  it "imports with name and existing numeric property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', '10']
      csv << ['Bar', '20']
      csv << ['', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Column', use_as: 'existing_field', field_id: numeric.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({numeric.es_code => 10})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({numeric.es_code => 20})
  end

  it "imports with name and existing select_one property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'one']
      csv << ['Bar', 'two']
      csv << ['', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Column', use_as: 'existing_field', field_id: select_one.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({select_one.es_code => 1})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({select_one.es_code => 2})
  end

  it "imports with name and existing select_many property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'one']
      csv << ['Bar', 'one, two']
      csv << ['', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Column', use_as: 'existing_field', field_id: select_many.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({select_many.es_code => [1]})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({select_many.es_code => [1, 2]})
  end

  it "should update hierarchy fields in bulk update using name" do
     csv_string = CSV.generate do |csv|
        csv << ['Name', 'Column']
        csv << ['Foo', 'Son']
        csv << ['Bar', 'Bro']
      end

      specs = [
        {header: 'Name', use_as: 'name'},
        {header: 'Column', use_as: 'existing_field', field_id: hierarchy.id},
        ]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
      ImportWizard.execute user, collection, specs

      collection.layers.all.should eq([layer])
      sites = collection.sites.all

      sites[0].name.should eq('Foo')
      sites[0].properties.should eq({hierarchy.es_code => "100"})

      sites[1].name.should eq('Bar')
      sites[1].properties.should eq({hierarchy.es_code => "101"})
  end

  # The updates will be performed using the hierarchy name for now
  # but soon they this is going to change when solving Issue #459
  pending "should update hierarchy fields in bulk update using id" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', '100']
      csv << ['Bar', '101']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Column', use_as: 'existing_field', field_id: hierarchy.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])
    sites = collection.sites.all

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({hierarchy.es_code => "100"})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({hierarchy.es_code => "101"})
  end


  it "imports with name and existing date property" do
     csv_string = CSV.generate do |csv|
       csv << ['Name', 'Column']
       csv << ['Foo', '12/24/2012']
       csv << ['Bar', '10/23/2033']
       csv << ['', '']
     end

     specs = [
       {header: 'Name', use_as: 'name'},
       {header: 'Column', use_as: 'existing_field', field_id: date.id},
       ]

     ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
     ImportWizard.execute user, collection, specs

     collection.layers.all.should eq([layer])

     sites = collection.sites.all
     sites.length.should eq(2)

     sites[0].name.should eq('Foo')
     sites[0].properties.should eq({date.es_code => "2012-12-24T00:00:00Z"})

     sites[1].name.should eq('Bar')
     sites[1].properties.should eq({date.es_code => "2033-10-23T00:00:00Z"})
  end

  it "imports with name and existing site property" do

    collection.sites.make :name => 'Site1', :id => '123'

    csv_string = CSV.generate do |csv|
     csv << ['Name', 'Column']
     csv << ['Foo', '123']
     csv << ['', '']
    end

    specs = [
     {header: 'Name', use_as: 'name'},
     {header: 'Column', use_as: 'existing_field', field_id: site.id},
     ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Site1')

    sites[1].name.should eq('Foo')
    sites[1].properties.should eq({site.es_code => "123"})
  end

  it "should update all property values" do
    site1 = collection.sites.make name: 'Foo old', id: 1234, properties: {
      text.es_code => 'coco',
      numeric.es_code => 10,
      yes_no.es_code => true,
      select_one.es_code => 1,
      select_many.es_code => [1, 2],
      hierarchy.es_code => 60,
      date.es_code => "2012-10-24T00:00:00Z",
      director.es_code => user.email
    }
    site1.properties[site.es_code] = site1.id

    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235


    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Text', 'Numeric', 'Yes no', 'Select One', 'Select Many', 'Hierarchy', 'Site', 'Date', 'User']
      csv << ["#{site1.id}", 'Foo new', '1.2', '3.4', 'new val', 11, 'no', 'two', 'two, one', 'Dad',  1235, '12/26/1988', 'user2@email.com']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'Text', use_as: 'existing_field', field_id: text.id},
      {header: 'Numeric', use_as: 'existing_field', field_id: numeric.id},
      {header: 'Yes no', use_as: 'existing_field', field_id: yes_no.id},
      {header: 'Select One', use_as: 'existing_field', field_id: select_one.id},
      {header: 'Select Many', use_as: 'existing_field', field_id: select_many.id},
      {header: 'Hierarchy', use_as: 'existing_field', field_id: hierarchy.id},
      {header: 'Site', use_as: 'existing_field', field_id: site.id},
      {header: 'Date', use_as: 'existing_field', field_id: date.id},
      {header: 'User', use_as: 'existing_field', field_id: director.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(layer.name)

    fields = layers[0].fields.all
    fields.length.should eq(9)

    sites = collection.sites.all
    sites.length.should eq(2)

    site1.reload
    site1.name.should eq('Foo new')
    site1.properties.should eq({
      text.es_code => 'new val',
      numeric.es_code => 11,
      yes_no.es_code => false,
      select_one.es_code => 2,
      select_many.es_code => [2, 1],
      hierarchy.es_code => '60',
      site.es_code => '1235',
      date.es_code => "1988-12-26T00:00:00Z",
      director.es_code => 'user2@email.com'
    })

    site2.reload
    site2.name.should eq('Bar old')
    site2.properties.should eq({text.es_code => 'lala'})
  end

  it "should delete all property values" do
    site1 = collection.sites.make name: 'Foo old', id: 1234, properties: {
      text.es_code => 'coco',
      numeric.es_code => 10,
      select_one.es_code => 1,
      select_many.es_code => [1, 2],
      hierarchy.es_code => 60,
      date.es_code => "2012-10-24T00:00:00Z",
      director.es_code => user.email
    }
    site1.properties[site.es_code] = site1.id


    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235

    csv_string = CSV.generate do |csv|
     csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Text', 'Numeric', 'Select One', 'Select Many', 'Hierarchy', 'Site', 'Date', 'User']
     csv << ["#{site1.id}", 'Foo old', '1.2', '3.4', '', '', '', '', '',  '', '', '']
    end

    specs = [
     {header: 'resmap-id', use_as: 'id'},
     {header: 'Name', use_as: 'name'},
     {header: 'Text', use_as: 'existing_field', field_id: text.id},
     {header: 'Numeric', use_as: 'existing_field', field_id: numeric.id},
     {header: 'Select One', use_as: 'existing_field', field_id: select_one.id},
     {header: 'Select Many', use_as: 'existing_field', field_id: select_many.id},
     {header: 'Hierarchy', use_as: 'existing_field', field_id: hierarchy.id},
     {header: 'Site', use_as: 'existing_field', field_id: site.id},
     {header: 'Date', use_as: 'existing_field', field_id: date.id},
     {header: 'User', use_as: 'existing_field', field_id: director.id},
     ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(layer.name)

    fields = layers[0].fields.all
    fields.length.should eq(9)

    sites = collection.sites.all
    sites.length.should eq(2)

    site1.reload
    site1.name.should eq('Foo old')
    site1.properties.should eq({})

    site2.reload
    site2.name.should eq('Bar old')
    site2.properties.should eq({text.es_code => 'lala'})
  end

  it "should not create a new hierarchy field in import wizard" do
    csv_string = CSV.generate do |csv|
      csv << ['Hierarchy']
      csv << ['Dad']
    end

    specs = [
      {header: 'Hierarchy', use_as: 'new_field', kind: 'hierarchy', code: 'new_hierarchy'},
    ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    expect { ImportWizard.execute(user, collection, specs) }.to raise_error

  end

  it "should create new fields with all property values" do
    site1 = collection.sites.make name: 'Foo old', id: 1234, properties: {}

    site2 = collection.sites.make name: 'Bar old', properties: {}, id: 1235

    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Text', 'Numeric', 'Yes no', 'Select One', 'Select Many', 'Site', 'Date', 'User', 'Email', 'Phone']
      csv << ["#{site1.id}", 'Foo new', '1.2', '3.4', 'new val', 11, 'no', 'two', 'two, one',  1235, '12/26/1988', 'user2@email.com', 'new@email.com', '1456']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'Text', use_as: 'new_field', kind: 'text', code: 'new_text'},
      {header: 'Numeric', use_as: 'new_field', kind: 'numeric', code: 'new_numeric'},
      {header: 'Yes no', use_as: 'new_field', kind: 'yes_no', code: 'new_yes_no'},
      {header: 'Select One', use_as: 'new_field', kind: 'select_one', code: 'new_select_one', label: 'New Select One', selectKind: 'both'},
      {header: 'Select Many', use_as: 'new_field', kind: 'select_many', code: 'new_select_many', label: 'New Select Many', selectKind: 'both'},
      {header: 'Site', use_as: 'new_field', kind: 'site', code: 'new_site'},
      {header: 'Date', use_as: 'new_field', kind: 'date', code: 'new_date'},
      {header: 'User', use_as: 'new_field', kind: 'user', code: 'new_user'},
      {header: 'Email', use_as: 'new_field', kind: 'email', code: 'new_email'},
      {header: 'Phone', use_as: 'new_field', kind: 'phone', code: 'new_phone'},
    ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)

    new_layer = layers.detect{|l| l.name == "Import wizard"}

    fields = new_layer.fields.all
    fields.length.should eq(10)

    sites = collection.sites.all
    sites.length.should eq(2)

    site1.reload
    site1.name.should eq('Foo new')
    site1.properties.length.should eq(10)
    site1.properties[yes_no.es_code].should be_false

    site2.reload
    site2.name.should eq('Bar old')
    site2.properties.should eq({})
  end

  it "should guess column spec for existing fields" do
    email_field = layer.email_fields.make :code => 'email'

    csv_string = CSV.generate do |csv|
     csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'text', 'numeric', 'select_one', 'select_many', 'hierarchy', 'site', 'date', 'user', 'email']
     csv << ["123", 'Foo old', '1.2', '3.4', '', '', 'two', 'two', 'uno',  1235, '12/26/1988', 'user2@email.com', 'email@mail.com']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection

    column_spec.length.should eq(13)

    column_spec.should include({:header=>"resmap-id", :kind=> :id, :code=>"resmap-id", :label=>"Resmap", :use_as=>:id})
    column_spec.should include({:header=>"Name", :kind=>:name, :code=>"name", :label=>"Name", :use_as=>:name})
    column_spec.should include({:header=>"Lat", :kind=>:location, :code=>"lat", :label=>"Lat", :use_as=>:lat})
    column_spec.should include({:header=>"Lon", :kind=>:location, :code=>"lon", :label=>"Lon", :use_as=>:lng})
    column_spec.should include({:header=>"text", :kind=>:text, :code=>"text", :label=>"Text", :use_as=>:existing_field, :layer_id=> text.layer_id, :field_id=>text.id})
    column_spec.should include({:header=>"numeric", :kind=>:numeric, :code=>"numeric", :label=>"Numeric", :use_as=>:existing_field, :layer_id=>numeric.layer_id, :field_id=>numeric.id})
    column_spec.should include({:header=>"select_one", :kind=>:select_one, :code=>"select_one", :label=>"Select One", :use_as=>:existing_field, :layer_id=>select_one.layer_id, :field_id=>select_one.id})
    column_spec.should include({:header=>"select_many", :kind=>:select_many, :code=>"select_many", :label=>"Select Many", :use_as=>:existing_field, :layer_id=>select_many.layer_id, :field_id=>select_many.id})
    column_spec.should include({:header=>"hierarchy", :kind=>:hierarchy, :code=>"hierarchy", :label=>"Hierarchy", :use_as=>:existing_field, :layer_id=>hierarchy.layer_id, :field_id=>hierarchy.id})
    column_spec.should include({:header=>"site", :kind=>:site, :code=>"site", :label=>"Site", :use_as=>:existing_field, :layer_id=>site.layer_id, :field_id=>site.id})
    column_spec.should include({:header=>"date", :kind=>:date, :code=>"date", :label=>"Date", :use_as=>:existing_field, :layer_id=>date.layer_id, :field_id=>date.id})
    column_spec.should include({:header=>"user", :kind=>:user, :code=>"user", :label=>"User", :use_as=>:existing_field, :layer_id=>director.layer_id, :field_id=>director.id})
    column_spec.should include({:header=>"email", :kind=>:email, :code=>"email", :label=>"Email", :use_as=>:existing_field, :layer_id=>email_field.layer_id, :field_id=>email_field.id})

    ImportWizard.delete_file(user, collection)
  end

  it "should get sites & errors for invalid existing fields" do
    email_field = layer.email_fields.make :code => 'email'
    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235

    csv_string = CSV.generate do |csv|
      csv << ['text', 'numeric', 'select_one', 'select_many', 'hierarchy', 'site', 'date', 'user', 'email']
      csv << ['new val', '11', 'two', 'one', 'Dad', '1235', '12/26/1988', 'user2@email.com', 'email@mail.com']
      csv << ['new val', 'invalid11', 'inval', 'Dad, inv', 'inval', '999', '12/26', 'non-existing@email.com', 'email@ma@il.com']
      csv << ['new val', 'invalid11', 'inval', 'Dad, inv', 'inval', '999', '12/26', 'non-existing@email.com', 'email@ma@il.com']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection
    processed_sites = (ImportWizard.validate_sites_with_columns user, collection, column_spec)
    sites_preview = processed_sites[:sites]

    sites_preview.length.should eq(3)
    first_line = sites_preview.first
    first_line.should == [{:value=>"new val"}, {value: '11'}, {:value=>"two"}, {:value=>"one"}, {:value=>"Dad"},
      {:value=>"1235"}, {:value=>"12/26/1988"}, {:value=>"user2@email.com"}, {:value=>"email@mail.com"}]

    #Lines 2 and 3 are equals
    second_line = sites_preview.last
    second_line.should  == [{:value=>"new val"}, {:value=>"invalid11"}, {:value=>"inval"}, {:value=>"Dad, inv"}, {:value=>"inval"},
      {:value=>"999"}, {:value=>"12/26"}, {:value=>"non-existing@email.com"}, {:value=>"email@ma@il.com"}]

    sites_errors = processed_sites[:errors]

    data_errors = sites_errors[:data_errors]
    data_errors.length.should eq(8)

    data_errors[0][:description].should eq("Some of the values in column 2 are not valid for the type numeric.")
    data_errors[0][:type].should eq('numeric values')
    data_errors[0][:column].should eq(1)
    data_errors[0][:rows].should eq([1, 2])

    data_errors[1][:description].should eq("Some of the values in column 3 don't match any existing option.")
    data_errors[1][:column].should eq(2)
    data_errors[1][:type].should eq('option values')
    data_errors[1][:rows].should eq([1, 2])

    data_errors[2][:description].should eq("Some of the values in column 4 don't match any existing option.")
    data_errors[2][:column].should eq(3)
    data_errors[2][:type].should eq('option values')
    data_errors[2][:rows].should eq([1, 2])

    data_errors[3][:description].should eq("Some of the values in column 5 don't exist in the corresponding hierarchy.")
    data_errors[3][:column].should eq(4)
    data_errors[3][:type].should eq('values that can be found in the defined hierarchy')
    data_errors[3][:rows].should eq([1, 2])

    data_errors[4][:description].should eq("Some of the values in column 6 don't match any existing site id in this collection.")
    data_errors[4][:column].should eq(5)
    data_errors[4][:rows].should eq([1, 2])

    data_errors[5][:description].should eq("Some of the values in column 7 are not valid for the type date.")
    data_errors[5][:column].should eq(6)
    data_errors[5][:type].should eq('dates')
    data_errors[5][:rows].should eq([1, 2])

    data_errors[6][:description].should eq("Some of the values in column 8 don't match any email address of a member of this collection.")
    data_errors[6][:column].should eq(7)
    data_errors[6][:type].should eq('email addresses')
    data_errors[6][:rows].should eq([1, 2])

    data_errors[7][:description].should eq("Some of the values in column 9 are not valid for the type email.")
    data_errors[7][:column].should eq(8)
    data_errors[7][:type].should eq('email addresses')
    data_errors[7][:rows].should eq([1, 2])
    
    second_line.should include({:value=>"new val", :error=>nil})
    second_line.should include({:value=>"invalid11", :error=>"Invalid numeric value in numeric field"})
    second_line.should include({:value=>"inval", :error=>"Invalid option in select_one field"})
    second_line.should include({:value=>"Dad, inv", :error=>"Invalid option in select_many field"})
    second_line.should include({:value=>"inval", :error=>"Invalid option in hierarchy field"})
    second_line.should include({:value=>"999", :error=>"Non-existent site-id in site field"})
    second_line.should include({:value=>"non-existing@email.com", :error=>"Non-existent user email address in user field"})
    second_line.should include({:value=>"email@ma@il.com", :error=>"Invalid email address in email field"})

    ImportWizard.delete_file(user, collection)
  end

  it "should be include hints for format errors" do
    email_field = layer.email_fields.make :code => 'email'

    csv_string = CSV.generate do |csv|
      csv << ['numeric', 'date', 'email', 'hierarchy']
      csv << ['11', '12/26/1988', 'email@mail.com', 'Dad']
      csv << ['invalid11', '23/1/234', 'email@ma@il.com', 'invalid']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection
    sites_errors = (ImportWizard.validate_sites_with_columns user, collection, column_spec)[:errors]

    data_errors = sites_errors[:data_errors]

    data_errors[0][:example].should eq("Values must be integers.")
    data_errors[1][:example].should eq("Example of valid date: 1/25/2013.")
    data_errors[2][:example].should eq("Example of valid email: myemail@resourcemap.com.")
    data_errors[3][:example].should eq("Some valid values for this hierarchy are: Dad, Son, Bro.")
  end

  it "should get sites & errors for invalid existing fields if field_id is string" do
    csv_string = CSV.generate do |csv|
      csv <<  ['Numeric']
      csv << ['invalid']
    end

     specs = [
       {header: 'Numeric', use_as: 'existing_field', field_id: "#{numeric.id}"},
     ]

     ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
     errors = (ImportWizard.validate_sites_with_columns user, collection, specs)[:errors]
     sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_spec)[:sites]

     sites_preview.length.should eq(2)

     first_line = sites_preview.first
     first_line.should include({:value=>"new val", :error=>nil})
     first_line.should include({value: '11', error: nil})
     first_line.should include({:value=>"two", :error=>nil})
     first_line.should include({:value=>"one", :error=>nil})
     first_line.should include({:value=>"Dad", :error=> "Hierarchy fields can only be created via web in the Layers page"})
     first_line.should include({:value=>"1235", :error=>nil})
     first_line.should include({:value=>"12/26/1988", :error=>nil})
     first_line.should include({:value=>"user2@email.com", :error=>nil})
     first_line.should include({:value=>"email@mail.com", :error=>nil})

     second_line = sites_preview.last
     second_line.should include({:value=>"new val", :error=>nil})
     second_line.should include({:value=>"invalid11", :error=>"Invalid numeric value in numeric field"})
     #option will be created as news
     second_line.should include({:value=>"inval", :error=>nil})
     second_line.should include({:value=>"Dad, inv", :error=>nil})
     #hierarchy fields cannot be created using import wizard
     second_line.should include({:value=>"inval", :error=> "Hierarchy fields can only be created via web in the Layers page"})
     second_line.should include({:value=>"999", :error=>"Non-existent site-id in site field"})
     second_line.should include({:value=>"non-existing@email.com", :error=>"Non-existent user email address in user field"})
     second_line.should include({:value=>"email@ma@il.com", :error=>"Invalid email address in email field"})

     data_errors = errors[:data_errors]
     data_errors.length.should eq(1)

  end

  it "should get error for invalid new fields" do
    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235

    csv_string = CSV.generate do |csv|
     csv << ['text', 'numeric', 'select_one', 'select_many', 'hierarchy', 'site', 'date', 'user', 'email']
     csv << ['new val', '11', 'two', 'one', 'Dad', '1235', '12/26/1988', 'user2@email.com', 'email@mail.com']
     csv << ['new val', 'invalid11', 'inval', 'Dad, inv', 'inval', '999', '12/26', 'non-existing@email.com', 'email@ma@il.com']
     csv << ['new val', 'invalid11', '', '', '', '', '12/26', '', 'email@ma@il.com']

    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

    column_spec = [
     {header: 'Text', use_as: 'new_field', kind: 'text', code: 'text2', label: 'text2'},
     {header: 'Numeric', use_as: 'new_field', kind: 'numeric', code: 'numeric2', label: 'numeric2'},
     {header: 'Select One', use_as: 'new_field', kind: 'select_one', code: 'select_one2', label: 'select_one2'},
     {header: 'Select Many', use_as: 'new_field', kind: 'select_many', code: 'select_many2', label: 'select_many2'},
     {header: 'Hierarchy', use_as: 'new_field', kind: 'hierarchy', code: 'hierarchy2', label: 'hierarchy2'},
     {header: 'Site', use_as: 'new_field', kind: 'site', code: 'site2', label: 'site2'},
     {header: 'Date', use_as: 'new_field', kind: 'date', code: 'date2', label: 'date2'},
     {header: 'User', use_as: 'new_field', kind: 'user', code: 'user2', label: 'user2'},
     {header: 'Email', use_as: 'new_field', kind: 'email', code: 'email2', label: 'email2'},
    ]

    sites = (ImportWizard.validate_sites_with_columns user, collection, column_spec)
    sites_preview = sites[:sites]

    sites_preview.length.should eq(3)
    first_line = sites_preview.first
    first_line.should == [{:value=>"new val"}, {value: '11'}, {:value=>"two"}, {:value=>"one"}, {:value=>"Dad"},
      {:value=>"1235"}, {:value=>"12/26/1988"}, {:value=>"user2@email.com"}, {:value=>"email@mail.com"}]

    second_line = sites_preview[1]
    second_line.should  == [{:value=>"new val"}, {:value=>"invalid11"}, {:value=>"inval"}, {:value=>"Dad, inv"}, {:value=>"inval"},
      {:value=>"999"}, {:value=>"12/26"}, {:value=>"non-existing@email.com"}, {:value=>"email@ma@il.com"}]

    sites_errors = sites[:errors]

    sites_errors[:hierarchy_field_found].should eq([{:new_hierarchy_columns=>[4]}])
    sites_errors[:duplicated_code].should eq({})
    sites_errors[:duplicated_label].should eq({})
    sites_errors[:existing_code].should eq({})
    sites_errors[:existing_label].should eq({})

    data_errors = sites_errors[:data_errors]
    data_errors.length.should eq(5)

    data_errors[0][:description].should eq("Some of the values in column 2 are not valid for the type numeric.")
    data_errors[0][:column].should eq(1)
    data_errors[0][:rows].should eq([1, 2])

    data_errors[1][:description].should eq("Some of the values in column 6 don't match any existing site id in this collection.")
    data_errors[1][:column].should eq(5)
    data_errors[1][:rows].should eq([1])

    data_errors[2][:description].should eq("Some of the values in column 7 are not valid for the type date.")
    data_errors[2][:column].should eq(6)
    data_errors[2][:rows].should eq([1, 2])

    data_errors[3][:description].should eq("Some of the values in column 8 don't match any email address of a member of this collection.")
    data_errors[3][:column].should eq(7)
    data_errors[3][:rows].should eq([1])

    data_errors[4][:description].should eq("Some of the values in column 9 are not valid for the type email.")
    data_errors[4][:column].should eq(8)
    data_errors[4][:rows].should eq([1, 2])

    ImportWizard.delete_file(user, collection)
  end


  it "should not create fields with duplicated name or code" do
    layer.numeric_fields.make :code => 'new_field', :name => 'Existing field'

    csv_string = CSV.generate do |csv|
     csv << ['text']
     csv << ['new val']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

    column_spec = [
      {header: 'Text', use_as: 'new_field', kind: 'text', code: 'text', label: 'Non Existing field'},
    ]

    expect {ImportWizard.execute_with_entities(user, collection, column_spec)}.to raise_error(RuntimeError, "Can't save field from column Text: A field with code 'text' already exists in the layer named #{layer.name}")

    column_spec = [
     {header: 'Text', use_as: 'new_field', kind: 'text', code: 'newtext', label: 'Existing field'},
    ]

    expect {ImportWizard.execute_with_entities(user, collection, column_spec)}.to raise_error(RuntimeError, "Can't save field from column Text: A field with label 'Existing field' already exists in the layer named #{layer.name}")

    ImportWizard.delete_file(user, collection)
  end


  ['lat', 'lng', 'name', 'id'].each do |usage|
    it "should return validation errors when more than one column is selected to be #{usage}" do
      csv_string = CSV.generate do |csv|
      csv << ['col1', 'col2 ']
      csv << ['val', 'val']
      end

      column_specs = [
       {header: 'Column 1', use_as: "#{usage}"},
       {header: 'Column 2', use_as:"#{usage}"}
       ]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)

      sites_errors = sites_preview[:errors]
      sites_errors[:duplicated_usage].should eq("#{usage}" => [0,1])

      ImportWizard.delete_file(user, collection)
    end
  end

  it "should return validation errors when more than one column is selected to be the same existing field" do
    csv_string = CSV.generate do |csv|
      csv << ['col1', 'col2 ']
      csv << ['val', 'val']
    end

    column_specs = [
     {header: 'Column 1', use_as: "existing_field", field_id: text.id},
     {header: 'Column 2', use_as: "existing_field", field_id: text.id}
     ]

     ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

     sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)
     sites_errors = sites_preview[:errors]
     sites_errors[:duplicated_usage].should eq(text.id => [0,1])

     ImportWizard.delete_file(user, collection)
  end


  it "should not return duplicated_usage validation errror when there is more than one column with usage 'ignore'" do
    csv_string = CSV.generate do |csv|
      csv << ['col1', 'col2 ']
      csv << ['val', 'val']
    end

    column_specs = [
     {header: 'Column 1', use_as: "ignore"},
     {header: 'Column 2', use_as: "ignore"}
     ]

     ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

     sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)

     sites_errors = sites_preview[:errors]
     sites_errors[:duplicated_usage].should eq({})

    ImportWizard.delete_file(user, collection)

  end

  ['code', 'label'].each do |value|
    it "should return validation errors when there is new_fields with duplicated #{value}" do
      csv_string = CSV.generate do |csv|
        csv << ['col1', 'col2 ']
        csv << ['val', 'val']
      end

     column_specs = [
       {header: 'Column 1', use_as: 'new_field', kind: 'select_one', "#{value}" => "repeated" },
       {header: 'Column 2', use_as: 'new_field', kind: 'select_one', "#{value}" => "repeated" }
       ]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)

      sites_errors = sites_preview[:errors]
      key = "duplicated_#{value}".to_sym
      sites_errors[key].should eq("repeated" => [0,1])
      ImportWizard.delete_file(user, collection)

    end
  end

  ['code', 'label'].each do |value|
    it "should return validation errors when there is existing_field with duplicated #{value}" do
      if value == 'label'
        repeated = layer.text_fields.make "name" => "repeated"
      else
        repeated = layer.text_fields.make "#{value}" => "repeated"
      end

      csv_string = CSV.generate do |csv|
        csv << ['col1', 'col2 ']
        csv << ['val', 'val']
      end

       column_specs = [
         {header: 'Column 1', use_as: 'new_field', kind: 'select_one', "#{value}" => "repeated" },
         {header: 'Column 2', use_as: 'new_field', kind: 'select_one', "#{value}" => "repeated" }
         ]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)

      sites_errors = sites_preview[:errors]
      key = "existing_#{value}".to_sym
      sites_errors[key].should eq("repeated" => [0,1])
      ImportWizard.delete_file(user, collection)

    end
  end

  it "should not show errors if usage is ignore" do

   csv_string = CSV.generate do |csv|
     csv << ['numeric ']
     csv << ['11']
     csv << ['invalid11']
   end

   ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

   columns_spec = [{header: 'numeric', use_as: 'ignore', kind: 'ignore'}]
   validated_sites = (ImportWizard.validate_sites_with_columns user, collection, columns_spec)

   sites_preview = validated_sites[:sites]
   sites_preview.should  == [[{:value=>"11"}], [{:value=>"invalid11"}]]
   sites_errors = validated_sites[:errors]

   sites_errors[:data_errors].should == []

   ImportWizard.delete_file(user, collection)
 end

  it "should not generate a data error when updating a default property" do
    site1 = collection.sites.make name: 'Foo old'

    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name']
      csv << ["#{site1.id}", 'Foo new']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id', kind: 'id'},
      {header: 'Name', use_as: 'name', kind: 'name'}]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]
    sites_errors[:data_errors].should == []

    ImportWizard.delete_file(user, collection)
  end

  # Otherwise a missmatch will be generated
  it 'should not bypass columns with an empty value in the first row' do
    csv_string = CSV.generate do |csv|
      csv << ['0', '' , '']
      csv << ['1', '0', 'label2']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection

    column_spec.length.should eq(3)
    column_spec[1][:header].should eq("")
    column_spec[1][:code].should eq("")
    column_spec[1][:label].should eq("")
    column_spec[1][:use_as].should eq(:new_field)
    column_spec[2][:header].should eq("")
    column_spec[2][:code].should eq("")
    column_spec[2][:label].should eq("")
    column_spec[2][:use_as].should eq(:new_field)

    ImportWizard.delete_file(user, collection)
  end

  it 'should not fail if header has a nil value' do
    csv_string = CSV.generate do |csv|
      csv << ['0', nil , nil]
      csv << ['1', '0', 'label2']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection

    column_spec.length.should eq(3)
    column_spec[1][:header].should eq("")
    column_spec[1][:code].should eq("")
    column_spec[1][:label].should eq("")
    column_spec[1][:use_as].should eq(:new_field)
    column_spec[2][:header].should eq("")
    column_spec[2][:code].should eq("")
    column_spec[2][:label].should eq("")
    column_spec[2][:use_as].should eq(:new_field)

    ImportWizard.delete_file(user, collection)
  end

  it 'should not fail if label and code are missing in new fields' do
    csv_string = CSV.generate do |csv|
      csv << ['0', '' , '']
      csv << ['1', '0', 'label2']
    end

    specs = [
      {:header=>"0", :kind=>:numeric, :code=>"0", :label=>"0", :use_as=>:new_field},
      {:header=>"", :kind=>:text, :code=>"", :label=>"", :use_as=>:new_field},
      {:header=>"", :kind=>:text, :code=>"", :label=>"", :use_as=>:new_field}]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]
    sites_errors[:missing_label].should eq(:columns => [1,2])
    sites_errors[:missing_code].should eq(:columns => [1,2])

    ImportWizard.delete_file(user, collection)
  end

  it "should validate presence of name in column specs" do
    csv_string = CSV.generate do |csv|
      csv << ['numeric']
      csv << ['11']
    end

    specs = [{:header=>"numeric", :kind=>:numeric, :code=>"numeric", :label=>"numeric", :use_as=>:new_field}]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]
    sites_errors[:missing_name].should_not be_blank

    ImportWizard.delete_file(user, collection)


    specs = [{:header=>"numeric", :use_as=>:name}]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]
    sites_errors[:missing_name].should be_blank

    ImportWizard.delete_file(user, collection)

  end

  Field.reserved_codes().each do |reserved_code|
    it "should validate reserved code #{reserved_code} in new fields" do
      csv_string = CSV.generate do |csv|
        csv << ["#{reserved_code}"]
        csv << ['11']
      end

      specs = [{:header=>"#{reserved_code}", :kind=>:text, :code=>"#{reserved_code}", :label=>"Label", :use_as=>:new_field}]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
      sites_errors = sites_preview[:errors]
      sites_errors[:reserved_code].should eq({"#{reserved_code}"=>[0]})
      ImportWizard.delete_file(user, collection)

    end
  end

  it "should validate ids belong to collection's sites if a column is marked to be used as 'id'" do
    csv_string = CSV.generate do |csv|
      csv << ["resmap-id"]
      csv << ['']
      csv << ['11']
    end

    specs = [{:header=>"resmap-id", :use_as=>:id}]
    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]

    sites_errors[:non_existent_site_id].length.should eq(1)
    resmap_id_error = sites_errors[:non_existent_site_id][0]
    resmap_id_error[:rows].should eq([1])
    resmap_id_error[:column].should eq(0)
    ImportWizard.delete_file(user, collection)

  end

  it "should not show errors for valid sites ids(numeric or text)" do
    site1 = collection.sites.make name: 'Bar'
    site2 = collection.sites.make name: 'Foo'

    csv_string = CSV.generate do |csv|
      csv << ["resmap-id"]
      csv << ["#{site1.id}"]
      csv << [site2.id]
    end

    specs = [{:header=>"resmap-id", :use_as=>:id}]
    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]

    sites_errors[:non_existent_site_id].should be(nil)
    ImportWizard.delete_file(user, collection)

  end

  it "shouldn't fail with blank lines at the end" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon', 'Beds']
      csv << ['Foo', '1.2', '3.4', '10']
      csv << ['Bar', '5.6', '7.8', '20']
      csv << []
      csv << []
      csv << []
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'},
      {header: 'Beds', use_as: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string
    ImportWizard.mark_job_as_pending user, collection

    column_spec = ImportWizard.guess_columns_spec user, collection
    sites_errors = (ImportWizard.validate_sites_with_columns user, collection, column_spec)[:errors]
    # do nothing (the test is that it shouldn't raise)
  end

  it "should not import files with invalid extension" do
    File.open("example.txt", "w") do |f|
      f.write("one, two")
    end
    expect { ImportWizard.import user, collection, 'example.txt', "one, two" }.to raise_error
  end

  it "should not import malformed csv files" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', '2']
      csv << ['Foo', '1.2', '3.4', '10']
    end
    expect { ImportWizard.import user, collection, 'foo.csv', csv_string }.to raise_error
  end

  it "should not fail when there is latin1 characters" do
    csv_string = CSV.open("utf8.csv", "wb", encoding: "ISO-8859-1") do |csv|
      csv << ["é", "ñ", "ç", "ø"]
      csv << ["é", "ñ", "ç", "ø"]
    end

    specs = [
      {header: 'é', use_as: 'name'},
      {header: 'ñ', use_as: 'new_field', kind: 'text', code: 'text1', label: 'text 1'},
      {header: 'ç', use_as: 'new_field', kind: 'text', code: 'text2', label: 'text 2'},
      {header: 'ø', use_as: 'new_field', kind: 'text', code: 'text3', label: 'text 3'}
      ]

    expect { ImportWizard.import user, collection, 'utf8.csv', csv_string }.to_not raise_error
    expect { ImportWizard.mark_job_as_pending user, collection }.to_not raise_error
    expect { column_spec = ImportWizard.guess_columns_spec user, collection}.to_not raise_error
    column_spec = ImportWizard.guess_columns_spec user, collection
    expect {ImportWizard.validate_sites_with_columns user, collection, column_spec}.to_not raise_error
  end

  describe 'updates' do
    it 'only some fields of a valid site in a collection with one or more select one fields' do
      # The collection has a valid site before the import
      site1 = collection.sites.make name: 'Foo old', properties: {text.es_code => 'coco', select_one.es_code => 1}

      # User uploads a CSV with only the resmap-id, name and text fields set.
      # At the time of writing (1 Jul 2013), this causes the import to fail.
      csv_string = CSV.generate do |csv|
        csv << ['resmap-id', 'Name', text.name]
        csv << [site1.id, 'Foo old', 'coco2']
      end

      specs = [
        {header: 'resmap-id', use_as: :id},
        {header: 'Name', use_as: 'name'},
        {header: text.name , use_as: 'existing_field', field_id: text.id},
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string
      ImportWizard.mark_job_as_pending user, collection

      ImportWizard.execute user, collection, specs
      sites = collection.sites.all
      sites.length.should eq(1)

      sites[0].name.should eq('Foo old')
      sites[0].properties[text.es_code].should eq('coco2')
      sites[0].properties[select_one.es_code].should eq(1)
    end
  end
end
