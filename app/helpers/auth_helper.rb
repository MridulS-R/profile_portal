module AuthHelper
  def provider_enabled?(name)
    Devise.omniauth_configs.key?(name.to_sym)
  rescue
    false
  end
end

