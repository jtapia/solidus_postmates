FactoryBot.modify do
  factory :address do
    lastname "Doe"
  end

  factory :variant do
    weight 10.0
  end

  factory :shipment do
    transient do
      inventory_units 1
    end

    after(:create) do |shipment, e|
      create_list(:inventory_unit, e.inventory_units, shipment: shipment)
    end
  end
end
