class Mobile::SitesController < SitesController

  skip_before_filter  :verify_authenticity_token
  def new
    render layout: 'mobile'
  end

  def create
    begin     
      # site_params = JSON.parse params[:site]
      site_params = {}
      site_params[:name] = params[:name]
      site_params[:lng] = params[:lng]
      site_params[:lat] = params[:lat]
      if params[:properties]
        site_params[:properties] = params[:properties]
        site_params[:properties] = fix_timezone_on_date_properties(site_params[:properties])
        site_params[:properties] = self.store_image_file(site_params[:properties])
      end
      site = collection.sites.create(site_params.merge(user: current_user))
      if site.valid?
        Site::UploadUtils.uploadFile(params[:fileUpload])
        current_user.site_count += 1
        current_user.update_successful_outcome_status
        current_user.save!
        render json: {site: site, status: 201}
      end
    rescue => ex
      render json: {message: ex.message, status: 500 }
    end
  end

  def create_offline_site
    begin     
      # site_params = JSON.parse params[:site]
      site_params = {}
      site_params[:name] = params[:name]
      site_params[:lng] = params[:lng]
      site_params[:lat] = params[:lat]
      if params[:properties]
        site_params[:properties] = params[:properties]
        site_params[:properties] = fix_timezone_on_date_properties(site_params[:properties])
        site_params[:properties] = self.store_offline_image_file(site_params[:properties])
      end
      site = collection.sites.create(site_params.merge(user: current_user))
      if site.valid?
        Site::UploadUtils.uploadFile(params[:fileUpload])
        current_user.site_count += 1
        current_user.update_successful_outcome_status
        current_user.save!
        render json: {site: site, status: 201}
      end
    rescue => ex
      render json: {message: ex.message, status: 500 }
    end
  end

  def store_image_file(properties)
    properties.each do |key, value|
      if Field.find_by_id(key.to_i) and Field.find_by_id(key.to_i).kind == "photo"
        if value
          file_name = properties[key].original_filename
          Site::UploadUtils.uploadSingleFile(file_name, properties[key].read.to_s)
          properties[key] = file_name
        end
      end
    end
    properties
  end

  def store_offline_image_file(properties)
    properties.each do |key, value|
      if Field.find_by_id(key.to_i) and Field.find_by_id(key.to_i).kind == "photo"
        if value
          file_name = "#{key}#{DateTime.now.to_i}.jpg"
          # File.open("public/photo_field/#{file_name}", 'w') {|f| f.write(Base64.decode64(value)) }
          Site::UploadUtils.uploadSingleFile(file_name, Base64.decode64(value[(value.index(",")+1)..value.size]))
          properties[key] = file_name
        end
      end
    end
    properties
  end

  def fix_timezone_on_date_properties(properties)
    properties.each do |key, value|
      if Field.find_by_id(key.to_i) and Field.find_by_id(key.to_i).kind == "date"   
        unless(value.strip == "")
          properties[key] = value + "T00:00:00Z"
        end 
      end
    end
    properties
  end

end
