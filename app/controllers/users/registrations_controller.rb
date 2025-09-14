class Users::RegistrationsController < Devise::RegistrationsController
  # Inherit Turbo behavior via Devise parent set in initializer

  # Add a flash alert on failed sign up so users see a clear message.
  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :signed_up_but_inactive
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      flash.now[:alert] = resource.errors.full_messages.to_sentence.presence || "Sign up failed. Please check the form."
      respond_with resource, status: :unprocessable_entity
    end
  end

  private
  # Permit :name during sign up (required by model validation)
  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
