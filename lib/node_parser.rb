require 'ox'

module NodeParser
  class Handler < ::Ox::Sax
    def initialize(block)
      @yield_to = block
    end

    def start_element(name)
      if name == :'en:attributes'
        @table_name = @parent
        @attributes = {}
      else
        @parent = name.to_s.split(':')[-1].freeze
      end
    end

    def value(value)
      @attributes[@parent] = value.as_s.strip
    end

    def end_element(name)
      if name == :'en:attributes'
        @yield_to.call(@table_name, @attributes)
        @parent, @table_name, @attributes = nil, nil, nil
      end
    end
  end

  def self.each_node(path)
    proc = Proc.new do |table_name, attributes|
      yield [table_name, attributes]
    end

    handler = Handler.new(proc)
    Ox.sax_parse(handler, File.open(path))
  end
end