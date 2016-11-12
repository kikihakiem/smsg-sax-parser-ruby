module Mysql2
  class Client
    def initialize(hsh)
    end

    def query(sql, hsh = {})
    end

    def escape(value)
    end
  end

  class Error < StandardError
  end
end