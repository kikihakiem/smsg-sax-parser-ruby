require 'nokogiri'

module ManagementNodeParser
  class Handler < Nokogiri::XML::SAX::Document
    def initialize(block)
      @yield_to = block
    end

    def start_element(name, attrs = [])
      if name == 'en:ManagementNode'
        @attributes = {}
      else
        @parent = name.split(':')[-1].freeze
      end
    end

    def characters(value)
      @attributes[@parent] = value.strip unless @attributes.nil?
    end

    def end_element(name)
      if name == 'en:ManagementNode'
        @yield_to.call(@attributes)
        @parent = nil
      end
    end
  end

  def self.each_node(path)
    proc = Proc.new do |attributes|
      yield attributes
    end

    parser = Nokogiri::XML::SAX::Parser.new(Handler.new(proc))
    parser.parse(File.open(path))
  end
end