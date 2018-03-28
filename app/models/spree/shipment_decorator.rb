Spree::Shipment.class_eval do
  private

  def after_ship
    send_order_to_provider
    order.shipping.ship_shipment(self, suppress_mailer: suppress_mailer)
  end

  def send_order_to_provider
    shipping_method = shipping_methods.detect { |sp| sp.name.include?('Postmates') }

    return 'Not applicable' unless shipping_method

    postmates_service = Spree::PostmatesService.new(order, self)
    postmates_service.push
  end
end
