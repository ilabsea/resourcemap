class Mobile::SitesController < SitesController

  skip_before_filter  :verify_authenticity_token
  def new
    render layout: 'mobile'
  end

  def create
    begin
      site_params = JSON.parse params[:site]
      Site::UploadUtils.uploadFile(params[:fileUpload])
      site = collection.sites.create(site_params.merge(user: current_user))
      if site.valid?
        current_user.site_count += 1
        current_user.update_successful_outcome_status
        current_user.save!
        render json: {site: site, status: 201}
      end
    rescue => ex
      render json: {message: ex.message, status: 500 }
    end
  end
end
