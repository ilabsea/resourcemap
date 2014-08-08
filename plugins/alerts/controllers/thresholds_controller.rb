class ThresholdsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]

  before_filter :fix_conditions, only: [:create, :update]

  def index
    if params[:collection_id]
      respond_to do |format|
        format.html do
          show_collection_breadcrumb
          add_breadcrumb "Properties", collection_path(collection)
          add_breadcrumb "Thresholds", collection_thresholds_path(collection)
        end
        format.json { render json: thresholds }
      end
    else
      respond_to do |format|
        format.json { render json: Threshold.all }
      end
    end
  end

  def create
    params[:threshold][:sites] = params[:threshold][:sites].values.map{|site| site["id"]} if params[:threshold][:sites]
    params[:threshold][:email_notification] = {} unless params[:threshold][:email_notification] # email not selected
    params[:threshold][:phone_notification] = {} unless params[:threshold][:phone_notification] # phone not selected
    threshold = thresholds.new params[:threshold].except(:sites) 
    threshold.sites = Site.get_id_and_name params[:threshold][:sites] if params[:threshold][:sites]#select only id and name
    threshold.save!
    # collection.recreate_index
    Resque.enqueue IndexRecreateTask, collection.id
    render json: threshold
  end

  def set_order
    threshold.update_attribute :ord, params[:ord]

    render json: threshold
  end

  def update
    params[:threshold][:email_notification] = {} unless params[:threshold][:email_notification] # email not selected
    params[:threshold][:phone_notification] = {} unless params[:threshold][:phone_notification] # phone not selected
    params[:threshold][:sites] = params[:threshold][:sites].values.map{|site| site["id"]} if params[:threshold][:sites]
    threshold.update_attributes! params[:threshold].except(:sites)
    if params[:threshold][:sites]
      threshold.sites = Site.get_id_and_name params[:threshold][:sites]
      threshold.save
    end
    # collection.recreate_index
    Resque.enqueue IndexRecreateTask, collection.id
    render json: threshold
  end

  def destroy
    threshold.destroy
    # collection.recreate_index
    Resque.enqueue IndexRecreateTask, collection.id

    render json: threshold
  end

  private

  def fix_conditions
    params[:threshold][:conditions] = params[:threshold][:conditions].values
  end
end
