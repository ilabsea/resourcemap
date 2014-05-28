class Api::RegistrationsController < Devise::RegistrationsController
  def create
    build_resource
    render json: json_response, status: response_status
  end

  private
    def json_response
      json = {
        success:  resource.save,
        email:    resource.email,
        messages: resource.errors.full_messages
      }
    end

    def response_status
      resource.new_record? ? :bad_request : :created
    end

    def resource_name
      :user
    end
end