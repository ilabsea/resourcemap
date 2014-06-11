class RemindersController < ApplicationController
  before_filter :authenticate_user!

  def index
    respond_to do |format| format.html do
        show_collection_breadcrumb
        add_breadcrumb "Properties", collection_path(collection)
        add_breadcrumb "Reminders", collection_reminders_path(collection)
      end
      all_reminders = reminders.all.as_json(include: [:repeat], methods: [:reminder_date], except: [:schedule])
      format.json { render json: apply_time_zone(all_reminders)}
    end
  end

  def create
    if params[:reminder]["time_zone"]
      date_and_time = '%m-%d-%YT%H:%M:%S %Z'
      params[:reminder]["reminder_date"] = ActiveSupport::TimeZone[params[:reminder]["time_zone"]].parse(params[:reminder]["reminder_date"]).to_s
    end
    reminder = reminders.new params[:reminder].except(:sites)
    reminder.sites = Site.select("id, collection_id, name, properties").find params[:reminder][:sites] if params[:reminder][:sites]
    reminder.save!
    render json: reminder
  end
  
  def update
    reminder = reminders.find params[:id]
    if params[:reminder]["time_zone"]
      date_and_time = '%m-%d-%YT%H:%M:%S %Z'
      params[:reminder]["reminder_date"] = ActiveSupport::TimeZone[params[:reminder]["time_zone"]].parse(params[:reminder]["reminder_date"]).to_s
    end
    reminder.update_attributes! params[:reminder].except(:sites)
    reminder.sites = Site.select("id, collection_id, name, properties").find params[:reminder][:sites] if params[:reminder][:sites]
   
    reminder.save! 
    render json: reminder
  end
  
  def destroy
    reminder.destroy
    render json: reminder
  end
  
  def set_status
    reminder.update_attribute :status, params[:status]
    render json: reminder
  end

  def get_time_zone
    time_zones = []
    ActiveSupport::TimeZone.all.inject([]) do |result, tz|
      utc_offset = tz.utc_offset / 3600
      time_zones << {:identifier => "#{tz.name}", :text => "(GMT #{'%.2f' % utc_offset}): #{tz.name}"}
    end
    render :json => {:list_time_zone => time_zones, :user_time_zone => current_user.time_zone}
  end

  def apply_time_zone reminders
    arr = []
    reminders.each do |r|
      p r[:reminder_date].in_time_zone(r["time_zone"])
      r["next_run"] = r["next_run"].in_time_zone(r["time_zone"]) if r["time_zone"]
      r[:reminder_date] = r[:reminder_date].in_time_zone(r["time_zone"]) if r["time_zone"]
      arr.push r
    end
    arr
  end
end
