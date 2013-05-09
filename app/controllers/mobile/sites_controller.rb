class Mobile::SitesController < SitesController

  skip_before_filter  :verify_authenticity_token
  def new
    render layout: 'mobile'
  end

  def create
    begin
      validated_site = validate_site_properties(params[:site])
      site = collection.sites.create(validated_site.merge(user: current_user))
      current_user.site_count += 1
      current_user.update_successful_outcome_status
      current_user.save!
      render json: {site: site, status: 201}
    rescue => ex
      render json: {message: ex.message, status: 500 }
    end
  end
end
