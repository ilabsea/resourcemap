class TranslationsController < ApplicationController

	caches_page :index

  def index
    render json: I18n.t('javascripts')
  end
end