require 'nokogiri'

module NodeParser
  class Handler < Nokogiri::XML::SAX::Document
    def initialize(block)
      @yield_to = block
    end

    def start_element(name, attrs = {})
      if name == 'en:attributes'
        @table_name = @parent
        @attributes = {}
      else
        @parent = name.split(':')[-1].freeze
      end
    end

    def characters(value)
      @attributes[@parent] = value.strip unless @attributes.nil?
    end

    def end_element(name)
      if name == 'en:attributes'
        @yield_to.call(@table_name, @attributes)
        @parent, @table_name, @attributes = nil, nil, nil
      end
    end
  end

  def self.each_node(path)
    proc = Proc.new do |table_name, attributes|
      yield(table_name, attributes)
    end

    parser = Nokogiri::XML::SAX::Parser.new(Handler.new(proc))
    parser.parse(File.open(path))
  end
end