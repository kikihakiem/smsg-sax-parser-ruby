# use fake_mysql2 to eliminate network & DB overhead
# so we can focus on our code performance
# require './fake_mysql2'
require 'mysql2'

module SqlHelper
  class Accumulator
    def initialize(config)
      @tables = {}
      @batch_size = config[:batch_size]
      @mysql_client = Mysql2::Client.new(config[:db_connection])
    end

    def add_record(table_name, record)
      return if record.blank?
      if @current_table_name == table_name
        @tables[table_name].add_record(record)

        if @tables[table_name].size >= @batch_size
          batch_insert(@tables[table_name])
          @tables[table_name].clear_records
        end
      else
        @tables[table_name] = Table.new(@mysql_client, table_name)
        @tables[table_name].add_record(record)

        unless @current_table_name.nil?
          batch_insert(@tables[@current_table_name])
          @tables.delete(@current_table_name)
        end

        @current_table_name = table_name
      end
    end

    def create_or_update_table(table)
      existing_table = existing_table_fields(table)
      if existing_table.nil?
        create_table_sql = table.create_table
        query(create_table_sql)
      else
        alter_table_sql = table.update_table(existing_table)
        query(alter_table_sql) if alter_table_sql.present?
      end
    end

    def existing_table_fields(table)
      query "show fields from s_#{table.name}", symbolize_keys: true
    rescue => e
      nil
    end

    def batch_insert(table)
      return unless table.size > 0

      create_or_update_table(table)
      query table.batch_insert
    end

    def flush
      @tables.each do |table_name, table|
        batch_insert(table)
      end
    end

    def query(sql, options = {})
      options.merge!({cast: false, cache_rows: false})
      @mysql_client.query sql, options
    end
  end
end