require_relative './sql_helper/column'
require_relative './sql_helper/table'
require_relative './sql_helper/accumulator'

module SqlHelper
  def self.accumulate(config, &block)
    accumulator = SqlHelper::Accumulator.new(config)
    block.call(accumulator)
    accumulator.flush
  end
end
