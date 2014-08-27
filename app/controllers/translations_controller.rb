class TranslationsController < ApplicationController

  def index
    render json: I18n.t('javascripts')
  end
end