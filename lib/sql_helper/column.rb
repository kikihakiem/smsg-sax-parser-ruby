module SqlHelper
  class Column
    attr_reader :name
    attr_accessor :data_type, :max_size

    STR_LEN = [16, 40, 64, 256]
    TYPE_ORDER = {int: 1, varchar: 2, text: 3}

    def initialize(name, data_type = :int, max_size = 11)
      @name = name
      @data_type = data_type
      @max_size = max_size
    end

    def update_type(value)
      return if @data_type == :text
      return if value.size <= 11 && value == value.to_i.to_s

      if value.size < 256
        @data_type = :varchar
        if value.size > @max_size
          @max_size = STR_LEN.detect {|len| len > value.size}
        end
      else
        @data_type = :text
      end
    end

    def need_update?(other_column)
      @name == other_column.name &&
        TYPE_ORDER[@data_type] > TYPE_ORDER[other_column.data_type] &&
        (@data_type == :text || @max_size > other_column.max_size)
    end

    def to_s
      if @data_type == :text
        "#{@name} text"
      else
        "#{@name} #{@data_type}(#{@max_size})"
      end
    end
  end
end