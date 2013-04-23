class Mobile::CollectionsController < ApplicationController
  before_filter :authenticate_user!
  def index
    render layout: 'mobile'
  end
end
