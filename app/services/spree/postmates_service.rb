require 'net/http'
require 'net/https'
require 'active_utils/connection'
require 'active_utils/country'

module Spree
  class PostmatesService
    include ActiveUtils::PostsData
    include ActionView::Helpers::NumberHelper

    cattr_reader :name
    @@name = 'Postmates'

    ###
    # Status
    #
    # pending: We've accepted the delivery and will be assigning it to a courier.
    # pickup: Courier is assigned and is en route to pick up the items.
    # pickup_complete: Courier has picked up the items.
    # dropoff: Courier is moving towards the dropoff.
    # canceled: Items won't be delivered. Deliveries are either canceled by the customer or by our customer service team.
    # delivered: Items were delivered successfully.
    # returned: The delivery was canceled and a new job created to return items to sender. (See related_deliveries in delivery object.)
    ###
    RESPONSE_STATUS = [:pending, :pickup, :pickup_complete, :dropoff, :canceled, :deliverd, :returned]

    HOST = 'api.postmates.com'

    ENDPOINT = "/v1/customers/#{SolidusPostmates::Config[:postmates_customer_id]}/deliveries"

    attr_accessor :order, :shipment, :ship_address, :shipping_method, :shipping_provider, :test

    def initialize(order, shipment, options={})
      @order = order
      @shipment = shipment
      @ship_address = order.ship_address
      @shipping_method = shipment.shipping_method
      @shipping_provider = shipment.shipping_provider
      @test = Spree::ActiveShipping::Config[:test_mode]
    end

    def push
      begin
        response = ssl_post(request_url, request_params, headers)
        update_shipment(response)
      rescue ::ActiveUtils::ResponseError, ::ActiveShipping::ResponseError => e
        data          = JSON.parse(e.response.body)
        attributes    = data['params'].map{ |k, v| "#{k}: #{v}" }.join('\n')
        error_message = data['kind'] == 'error' && data['code'] ? [data['message'], attributes].join('\n') : 'unknown'

        RateResponse.new(false, error_message, data)
      end
    end

    private

    def request_url
      URI::HTTPS.build(host: HOST, path: ENDPOINT).to_s
    end

    def headers
      { 'Authorization': SolidusPostmates::Config[:postmates_basic_auth] }
    end

    ###
    # Endpoint: POST /v1/customers/:customer_id/deliveries
    #
    # Query Parameters
    # quote_id: The ID of a previously generated delivery quote. Optional, but recommended. Example: "del_KSsT9zJdfV3P9k"
    # manifest: A detailed description of what the courier will be delivering. Example: "A box of gray kittens"
    # manifest_reference: Optional reference that identifies the manifest. Example: "Order #690"
    # pickup_name: Name of the place where the courier will make the pickup. Example: "Kitten Warehouse"
    # pickup_address: The pickup address for the delivery. Example: "20 McAllister St, San Francisco, CA"
    # pickup_phone_number: The phone number of the pickup location. Example: "415-555-4242"
    # pickup_business_name: Optional business name of the pickup location. Example: "Feline Enterprises, Inc."
    # pickup_notes: Additional instructions for the courier at the pickup location. Example: "Ring the doorbell twice, and only delivery the package if a human answers."
    # dropoff_name: Name of the place where the courier will make the dropoff. Example: "Alice"
    # dropoff_address: The dropoff address for the delivery. Example: "678 Green St, San Francisco, CA"
    # dropoff_phone_number: The phone number of the dropoff location. Example: "415-555-8484"
    # dropoff_business_name: Optional business name of the dropoff location. Example: "Alice's Cat Cafe"
    # dropoff_notes: Additional instructions for the courier at the dropoff location. Example: "Tell the security guard that you're here to see Alice."
    # requires_id Optional: flag if this job requires id verification. Example: "1" or "true"
    # pickup_ready_dt: Optional ISO8601 datetime to specify when a delivery is ready for pickup. Example: 2028-03-24T18:00:00.00Z. Omitting this field will result in a default pickup_ready_dt of now
    # pickup_deadline_dt: Optional ISO8601 datetime to specify by when a delivery must be picked up. Example: 2028-03-24T19:00:00.00Z
    # dropoff_ready_dt: Optional ISO8601 datetime to specify when a delivery is ready to be dropped off. Example: 2028-03-24T18:30:00.00Z
    # dropoff_deadline_dt: Optional ISO8601 datetime to specify by when a delivery must be dropped off. Example: 2028-03-24T19:30:00.00Z
    ###
    def request_params
      {
        pickup_address:       build_address(origin),
        dropoff_address:      build_address(destination),
        pickup_name:          ship_address.full_name,
        dropoff_name:         Spree::Store.default.name,
        pickup_phone_number:  number_to_phone(ship_address.phone),
        dropoff_phone_number: number_to_phone(SolidusPostmates::Config[:postmates_phone]),
        manifest:             order.line_items.map(&:name).join(', '),
      }.to_query
    end

    def build_address(address)
      number = address[:address1].scan(/\d+/).first
      street = address[:address1].gsub(number, '')
      city   = address[:city]
      state  = address[:state]

      "#{number} #{street}, #{city}, #{state}"
    end

    ###
    # address1:      Street line 1
    # address2:      Optional
    # postal_code:   Postal code
    # city:          City
    # state:         State
    # country:       Country
    # phone:         Phone number
    ###
    def origin
      {
        address1:    SolidusPostmates::Config[:postmates_address1],
        address2:    SolidusPostmates::Config[:postmates_address2],
        postal_code: SolidusPostmates::Config[:postmates_postal_code],
        city:        SolidusPostmates::Config[:postmates_city],
        state:       SolidusPostmates::Config[:postmates_state],
        country:     SolidusPostmates::Config[:postmates_country],
        phone:       SolidusPostmates::Config[:postmates_phone]
      }
    end

    def destination
      {
        address1:    ship_address.address1,
        address2:    ship_address.address2,
        postal_code: ship_address.zipcode,
        city:        ship_address.city,
        state:       ship_address.state.abbr,
        country:     ship_address.country.iso,
        phone:       ship_address.phone
      }
    end

    def update_shipment(response)
      data = JSON.parse(response)

      byebug
      if data['status'] == 'pending'
        shipment.update_attributes(tracking: data['id'])
        shipment.shipping_provider.update_attributes(reference: data['tracking_url'])
        shipping_provider.ship!
      else
        shipment.errors.add(:base, Spree.t(:'postmates.cant_ship'))
        shipping_provider.error!
      end
    end
  end
end
