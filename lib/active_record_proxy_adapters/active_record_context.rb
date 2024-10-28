# frozen_string_literal: true

module ActiveRecordProxyAdapters
  # Collection of helpers to handle common active record methods that are defined in different places in different
  # versions of rails.
  class ActiveRecordContext
    delegate :reading_role, :reading_role=, :writing_role, :writing_role=, to: :role_context
    delegate :legacy_connection_handling, :legacy_connection_handling=, to: :connection_handling_context
    delegate :version, to: :ActiveRecord, prefix: :active_record

    class << self
      delegate_missing_to :new
    end

    NullConnectionHandlingContext = Class.new do
      def legacy_connection_handling
        false
      end

      def legacy_connection_handling=(_value)
        nil
      end
    end

    def reading_role
      role_context.reading_role
    end

    def writing_role
      role_context.writing_role
    end

    def connection_class_for(connection)
      klass = active_record_v6_1? ? connection.connection_klass : connection.connection_class

      klass || ActiveRecord::Base
    end

    def connection_handling_context
      # This config option has been removed in Rails 7.1+
      return NullConnectionHandlingContext.new if active_record_v7_1? || active_record_v7_2?

      global_configuration_context
    end

    def role_context
      global_configuration_context
    end

    def global_configuration_context
      active_record_v6_1? ? ActiveRecord::Base : ActiveRecord
    end

    def active_record_v6_1?
      active_record_version >= Gem::Version.new("6.1") && active_record_version < Gem::Version.new("7.0")
    end

    def active_record_v7_1?
      active_record_version >= Gem::Version.new("7.1") && active_record_version < Gem::Version.new("7.2")
    end

    def active_record_v7_2?
      active_record_version >= Gem::Version.new("7.2") && active_record_version < Gem::Version.new("8.0")
    end
  end
end
