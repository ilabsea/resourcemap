class ChannelsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    respond_to do |format| 
      format.html do
        show_collection_breadcrumb
        add_breadcrumb I18n.t('views.collections.index.properties'), collection_path(collection)
        add_breadcrumb I18n.t('views.plugins.channels.channels'), collection_channels_path(collection)
      end
      format.json { render json: collection.channels.all.as_json, :root => false }
    end
  end

  end
