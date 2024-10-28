# frozen_string_literal: true

require "active_support"

module ActiveRecordProxyAdapters
  # Hooks into rails boot process to extend ActiveRecord with the proxy adapter.
  class Railtie < Rails::Railtie
    ActiveSupport.on_load :active_record do
      require "active_record_proxy_adapters/connection_handling"
      ActiveRecord::Base.extend(ActiveRecordProxyAdapters::ConnectionHandling)
    end

    config.to_prepare do
      Rails.autoloaders.each do |autoloader|
        autoloader.inflector.inflect(
          "postgresql_proxy_adapter" => "PostgreSQLProxyAdapter"
        )
      end
    end
  end
end
