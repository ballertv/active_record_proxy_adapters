# frozen_string_literal: true

require "active_record_proxy_adapters/primary_replica_proxy"

module ActiveRecordProxyAdapters
  # Proxy to the original PostgreSQLAdapter, allowing the use of the ActiveRecordProxyAdapters::PrimaryReplicaProxy.
  class PostgreSQLProxy < PrimaryReplicaProxy
    # ActiveRecord::PostgreSQLAdapter methods that should be proxied.
    hijack_method :execute, :exec_query, :exec_no_cache, :exec_cache
  end
end
