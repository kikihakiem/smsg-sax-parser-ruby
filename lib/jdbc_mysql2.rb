require 'jdbc/mysql'
require 'java'

module Mysql2
  class Client
    def initialize(hsh)
      Jdbc::MySQL.load_driver
      @config = hsh
    end

    def query(sql, hsh = {})
      results = nil
      use_db = !(sql =~ /^(create|drop) database/)
      with_connection(use_db) do |statement|
        if sql.start_with? 'show'
          results = statement.execute_query sql
        else
          results = statement.execute_update sql
        end
      end

      results
    end

    def with_connection(use_db, &block)
      database = use_db ? "/#{@config[:database]}" : ''
      connection = java.sql.DriverManager.get_connection("jdbc:mysql://#{@config[:host]}#{database}", @config[:username], @config[:password])
      statement = connection.create_statement
      block.call(statement)
      statement.close
      connection.close
    end

    def escape(value)
      value.gsub("'", "\\'")
    end
  end

  class Error < StandardError
  end
end