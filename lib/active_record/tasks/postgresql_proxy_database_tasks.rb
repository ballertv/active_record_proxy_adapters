# frozen_string_literal: true

module ActiveRecord
  module Tasks
    # Defines the postgresql tasks for dropping, creating, loading schema and dumping schema.
    # Bypasses all the proxy logic to send all requests to primary.
    class PostgreSQLProxyDatabaseTasks < PostgreSQLDatabaseTasks
      def create(...)
        sticking_to_primary { super }
      end

      def drop(...)
        sticking_to_primary { super }
      end

      def structure_dump(...)
        sticking_to_primary { super }
      end

      def structure_load(...)
        sticking_to_primary { super }
      end

      def purge(...)
        sticking_to_primary { super }
      end

      private

      def sticking_to_primary(&)
        ActiveRecord::Base.connected_to(role: context.writing_role, &)
      end

      def context
        ActiveRecordProxyAdapters::ActiveRecordContext.new
      end
    end
  end
end

# Allow proxy adapter to run rake tasks, i.e. db:drop, db:create, db:schema:load db:migrate, etc...
ActiveRecord::Tasks::DatabaseTasks.register_task(
  /postgresql_proxy/,
  "ActiveRecord::Tasks::PostgreSQLProxyDatabaseTasks"
)
