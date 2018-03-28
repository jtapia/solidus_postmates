module SolidusPostmates
  class Configuration < Spree::Preferences::Configuration
    # Postmates
    preference :api_key, :string, default: ''
    preference :customer_id, :string, default: ''
    preference :address1, :string, default: ''
    preference :address2, :string, default: ''
    preference :postal_code, :string, default: ''
    preference :city, :string, default: ''
    preference :state, :string, default: ''
    preference :country, :string, default: ''
    preference :phone, :string, default: ''
  end
end
