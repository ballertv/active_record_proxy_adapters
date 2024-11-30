# frozen_string_literal: true

require "simplecov"
require "simplecov_json_formatter"
require "active_support/core_ext/object/blank"

simple_cov_formatters = [SimpleCov::Formatter::JSONFormatter]
simple_cov_formatters << SimpleCov::Formatter::HTMLFormatter unless ENV["CI"]

SimpleCov.start do
  self.formatters = simple_cov_formatters
  add_filter "/spec/"
  add_group "PostgreSQL" do |src_file|
    [/postgresql/, /postgre_sql/].any? { |pattern| pattern.match?(src_file.filename) }
  end

  sanitize      = ->(filename) { filename.tr(".", "-").tr("~>", "").strip }
  ruby_version  = sanitize.call(ENV.fetch("RUBY_VERSION", ""))
  ar_version    = sanitize.call(ENV.fetch("RAILS_VERSION", ""))
  coverage_path = [
    "ruby",
    ruby_version,
    "ar",
    ar_version
  ].reject(&:blank?).join("-")

  coverage_dir "coverage/#{coverage_path}"
end
require "active_record_proxy_adapters"
require "active_record_proxy_adapters/connection_handling"

ActiveRecord::Base.extend ActiveRecordProxyAdapters::ConnectionHandling

module TestHelper # rubocop:disable Metrics/ModuleLength
  module_function

  def env_name
    :test
  end

  def setup_active_record_config
    active_record_context.legacy_connection_handling = false
    active_record_context.writing_role = :writing
    active_record_context.reading_role = :reading
  end

  def reading_role
    active_record_context.reading_role
  end

  def writing_role
    active_record_context.writing_role
  end

  def primary_pool
    ActiveRecord::Base.connection_handler.connection_pool_list(writing_role).first
  end

  def primary_pool_config
    @primary_pool_config
  end

  def primary_configuration_hash
    {
      adapter: "postgresql_proxy",
      username: ENV.fetch("PG_PRIMARY_USER", "postgres"),
      password: ENV.fetch("PG_PRIMARY_PASSWORD", "postgres"),
      host: ENV.fetch("PG_PRIMARY_HOST", "localhost"),
      port: Integer(ENV.fetch("PG_PRIMARY_PORT", 5432)),
      database: "primary_replica_proxy_test"
    }
  end

  def replica_pool
    ActiveRecord::Base.connection_handler.connection_pool_list(reading_role).first
  end

  def replica_configuration_hash
    {
      adapter: "postgresql",
      username: ENV.fetch("PG_REPLICA_USER", "postgres"),
      password: ENV.fetch("PG_REPLICA_PASSWORD", "postgres"),
      host: ENV.fetch("PG_REPLICA_HOST", "postgres_replica"),
      port: Integer(ENV.fetch("PG_REPLICA_PORT", 5433)),
      database: "primary_replica_proxy_test",
      replica: true
    }
  end

  def reset_database
    drop_database
    create_database
  end

  def drop_database
    ActiveRecord::Tasks::DatabaseTasks.drop(primary_configuration)
  end

  def create_database
    ActiveRecord::Tasks::DatabaseTasks.create(primary_configuration)
  rescue ActiveRecord::DatabaseAlreadyExists
    nil
  end

  def primary_configuration
    configurations = ActiveRecord::Base.configurations

    if ActiveRecord.version < Gem::Version.new("7.1")
      configurations.configs_for(env_name: env_name.to_s, name: "primary", include_replicas: false)
    else
      configurations.configs_for(env_name: env_name.to_s, name: "primary", include_hidden: false)
    end
  end

  def establish_connections
    ActiveRecord::Base.configurations = {
      env_name => {
        primary: primary_configuration_hash,
        primary_replica: replica_configuration_hash
      }
    }

    handler = ActiveRecord::Base.connection_handler

    handler.establish_connection(primary_configuration_hash, role: writing_role)
    handler.establish_connection(replica_configuration_hash, role: reading_role)
  end

  def migrate_database
    ActiveRecord::Base.connected_to(role: writing_role) do
      ActiveRecord::Base.connection.execute <<~SQL.strip
        CREATE TABLE users (
          id serial primary key,
          name text not null,
          email text not null,
          created_at timestamp without time zone not null default now(),
          updated_at timestamp without time zone not null default now()
        );
      SQL
    end
  end

  def truncate_database
    connection = ActiveRecord::Base.connection
    tables.each do |table|
      connection.execute_unproxied <<~SQL.squish
        TRUNCATE TABLE #{table} RESTART IDENTITY CASCADE;
      SQL
    end
  end

  def tables
    %i[users]
  end

  def active_record_context
    ActiveRecordProxyAdapters::ActiveRecordContext.new
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    TestHelper.setup_active_record_config
    TestHelper.establish_connections
    TestHelper.reset_database
    TestHelper.migrate_database
  end

  wrap_test_case_in_transaction = proc do |example|
    connection = ActiveRecord::Base.connection

    connection.execute_unproxied("BEGIN -- opening test wrapper transaction")

    example.run

    connection.execute_unproxied("ROLLBACK -- rolling back test wrapper transaction")
  end

  config.around(:each, :transactional, &wrap_test_case_in_transaction)

  config.before { TestHelper.truncate_database }
end
