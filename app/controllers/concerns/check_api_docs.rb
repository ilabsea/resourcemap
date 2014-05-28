module Concerns::CheckApiDocs
  extend ActiveSupport::Concern

  included do
    around_filter :rescue_with_check_api_docs
  end

  def rescue_with_check_api_docs
    yield
  rescue => ex

    Rails.logger.info ex.message
    Rails.logger.info ex.backtrace

    render text: "#{ex.message} - Check the API documentation: https://bitbucket.org/ilab/resource_map_sea/wiki/API", status: 400
  end
end