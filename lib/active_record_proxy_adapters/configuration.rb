# frozen_string_literal: true

require "active_support/core_ext/integer/time"

module ActiveRecordProxyAdapters
  # Provides a global configuration object to configure how the proxy should behave.
  class Configuration
    PROXY_DELAY      = 2.seconds.freeze
    CHECKOUT_TIMEOUT = 2.seconds.freeze

    # @return [ActiveSupport::Duration] How long the proxy should reroute all read requests to the primary database
    #   since the latest write. Defaults to PROXY_DELAY.
    attr_accessor :proxy_delay
    # @return [ActiveSupport::Duration] How long the proxy should wait for a connection from the replica pool.
    #   Defaults to CHECKOUT_TIMEOUT.
    attr_accessor :checkout_timeout

    def initialize
      self.proxy_delay      = PROXY_DELAY
      self.checkout_timeout = CHECKOUT_TIMEOUT
    end
  end
end
