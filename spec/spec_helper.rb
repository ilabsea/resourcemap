# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require 'simplecov'
SimpleCov.start
require File.expand_path("../../config/environment", __FILE__)
require File.expand_path("../../spec/blueprints", __FILE__)
require 'rspec/rails'
require 'capybara/rspec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("spec/integration/spec/helpers/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  ###########
  #capybara
  # config.include Warden::Test::Helpers
  # config.include Capybara::DSL,           example_group: { file_path: config.escaped_path(%w[spec integration])}
  # config.include Capybara::CustomFinders, example_group: { file_path: config.escaped_path(%w[spec integration])}
  # config.include Capybara::AccountHelper, example_group: { file_path: config.escaped_path(%w[spec integration])}
  # config.include Capybara::CollectionHelper, example_group: { file_path: config.escaped_path(%w[spec integration])}
  # config.include Capybara::SettingsHelper, example_group: { file_path: config.escaped_path(%w[spec integration])}
  # config.include Capybara::MailHelper, example_group: { file_path: config.escaped_path(%w[spec integration])}
  config.filter_run_excluding(js: true)   unless config.filter_manager.inclusions[:js]

  Warden.test_mode!

  # Capybara.default_max_wait_time = 5
  # Capybara.javascript_driver = :selenium
  # Capybara.default_selector = :css

  config.before :each do
    DatabaseCleaner.strategy = if Capybara.current_driver == :rack_test
      :transaction
    else
      [:truncation]
    end
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
  ##########

  # Uncomment to view full backtraces
  # config.backtrace_clean_patterns = []

  # Helper for ignoring blocks of tests
  def ignore(*args); end;

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  def stub_time(time)
    time = Time.parse time
    allow(Time).to receive(:now) { time }
  end

  def with_tmp_file(filename)
    file = "#{Dir.tmpdir}/#{filename}"
    yield file
    File.delete file
  end

  # Delete all test indexes before and after running each spec
  def delete_all_elasticsearch_indices
    Elasticsearch::Client.new.indices.delete index: "collection_test_*"
  end

  config.before(:all) { delete_all_elasticsearch_indices }
  config.after(:all) { delete_all_elasticsearch_indices }

# Mock nuntium access and gateways management
  config.before(:each) do
    @nuntium = double("nuntium")
    allow(Nuntium).to receive(:new_from_config).and_return(@nuntium)
    allow(@nuntium).to receive(:create_channel)
    allow(@nuntium).to receive(:update_channel)
    allow(@nuntium).to receive(:delete_channel)
    allow_any_instance_of(Channel).to receive(:gateway_url).and_return(true)
    allow_any_instance_of(Channel).to receive(:handle_nuntium_channel_response).and_return(true)
  end

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!
end
