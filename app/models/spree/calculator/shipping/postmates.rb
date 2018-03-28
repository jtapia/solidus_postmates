require_dependency 'spree/calculator'
require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class Postmates < ShippingCalculator
      def compute_package(package)
        compute_from_postmates(package)
      end

      def compute_from_postmates(package)
        order = package.order
        from  = build_address(origin)
        to    = build_address(destination(order.shipping_address))
        quote = client.quote(pickup_address: from, dropoff_address: to)

        quote.fee / 100.0
      end

      protected

      def client
        @client ||= build_client
      end

      def build_client
        # Create a new Postmates client
        client = ::Postmates.new

        # Set basic config variables
        client.configure do |config|
          config.api_key = SolidusPostmates::Config.api_key
          config.customer_id = SolidusPostmates::Config.customer_id
        end

        client
      end

      private

      def origin
        { address1:    SolidusPostmates::Config.address1,
          address2:    SolidusPostmates::Config.address2,
          postal_code: SolidusPostmates::Config.postal_code,
          city:        SolidusPostmates::Config.city,
          state:       SolidusPostmates::Config.state,
          country:     SolidusPostmates::Config.country }
      end

      def build_address(address)
        number = address[:address1].scan(/\d+/).first
        street = address[:address1].gsub(number, '')
        city   = address[:city]
        state  = address[:state]

        "#{number} #{street}, #{city}, #{state}"
      end

      def destination(address)
        { address1:    address.address1,
          address2:    address.address1,
          postal_code: address.zipcode,
          city:        address.city,
          state:       address.state ? address.state.abbr : address.state_name,
          country:     address.country.iso }
      end
    end
  end
end
