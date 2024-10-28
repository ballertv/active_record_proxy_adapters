# frozen_string_literal: true

require "active_record/tasks/postgresql_proxy_database_tasks"
require "active_record/connection_adapters/postgresql_adapter"
require "active_record_proxy_adapters/postgresql_proxy"
require "active_record_proxy_adapters/hijackable"

module ActiveRecord
  module ConnectionAdapters
    # This adapter is a proxy to the original PostgreSQLAdapter, allowing the use of the
    # ActiveRecordProxyAdapters::PrimaryReplicaProxy.
    class PostgreSQLProxyAdapter < PostgreSQLAdapter
      include ActiveRecordProxyAdapters::Hijackable

      ADAPTER_NAME = "PostgreSQLProxy"

      delegate_to_proxy :execute, :exec_query, :exec_no_cache, :exec_cache

      def initialize(...)
        @proxy = ActiveRecordProxyAdapters::PostgreSQLProxy.new(self)

        super
      end

      private

      attr_reader :proxy
    end
  end
end

if ActiveRecordProxyAdapters::ActiveRecordContext.active_record_v7_2?
  ActiveRecord::ConnectionAdapters.register(
    "postgresql_proxy",
    "ActiveRecord::ConnectionAdapters::PostgreSQLProxyAdapter",
    "active_record/connection_adapters/postgresql_proxy_adapter"
  )
end
