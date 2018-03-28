module SolidusPostmates
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'solidus_postmates'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    config.autoload_paths += %W(#{config.root}/lib)

    initializer 'solidus_postmates.environment', before: 'spree.environment' do
      SolidusPostmates::Config = SolidusPostmates::Configuration.new
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      Dir.glob(File.join(File.dirname(__FILE__), '../../app/models/**/*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    initializer 'solidus_postmates.register.calculators', after: 'spree.register.calculators' do |app|
      if app.config.spree.calculators.shipping_methods
        app.config.spree.calculators.shipping_methods << 'Spree::Calculator::Shipping::Postmates'
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
