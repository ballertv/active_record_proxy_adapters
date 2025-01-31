# frozen_string_literal: true

require "active_record/tasks/postgresql_proxy_database_tasks"
require "active_record/connection_adapters/postgresql_adapter"
require "active_record_proxy_adapters/primary_replica_proxy"

module ActiveRecordProxyAdapters
  # Defines mixins to delegate specific methods from the proxy to the adapter.
  module Hijackable
    extend ActiveSupport::Concern

    class_methods do
      # Renames the methods from the original Adapter using the proxy suffix (_unproxied)
      # and delegate the original method name to the proxy.
      # Example: delegate_to_proxy(:execute) creates a method `execute_unproxied`,
      # while delegating :execute to the proxy.
      # @param method_name [Array<Symbol>] the names of methods to be redefined.
      def delegate_to_proxy(*method_names)
        method_names.each do |method_name|
          proxy_method_name = proxy_method_name_for(method_name)
          proxy_method_private = private_method_defined?(method_name)

          # some adapter methods are private. We need to make them public before aliasing.
          public method_name if proxy_method_private

          alias_method proxy_method_name, method_name

          # If adapter method was originally private. We now make them private again.
          private method_name, proxy_method_name if proxy_method_private
        end

        delegate(*method_names, to: :proxy)
      end

      private

      def proxy_method_name_for(method_name)
        :"#{method_name}#{ActiveRecordProxyAdapters::PrimaryReplicaProxy::UNPROXIED_METHOD_SUFFIX}"
      end
    end
  end
end
