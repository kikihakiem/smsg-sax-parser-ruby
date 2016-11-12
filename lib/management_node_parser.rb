require 'ox'

module ManagementNodeParser
  class Handler < ::Ox::Sax
    def initialize(block)
      @yield_to = block
    end

    def start_element(name)
      if name == :'en:ManagementNode'
        @attributes = {}
      else
        @parent = name.to_s.split(':')[-1].freeze
      end
    end

    def value(value)
      @attributes[@parent] = value.as_s.strip
    end

    def end_element(name)
      if name == :'en:ManagementNode'
        @yield_to.call(@attributes)
        @parent = nil
      end
    end
  end

  def self.each_node(path)
    proc = Proc.new do |attributes|
      yield attributes
    end

    handler = Handler.new(proc)
    Ox.sax_parse(handler, File.open(path))
  end
end