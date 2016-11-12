module SqlHelper
  class Table
    attr_reader :name

    def initialize(mysql_client, name)
      @name = name
      @columns = {}
      @records = []
      @mysql_client = mysql_client
    end

    def add_record(record)
      record.each do |column_name, value|
        update_column_type(column_name, value)
      end

      @records << record
    end

    def update_column_type(column_name, value)
      @columns[column_name] ||= Column.new(column_name)
      @columns[column_name].update_type(value)
    end

    def create_table
      "create table if not exists s_#{@name} (" \
      "Id int(12) not null auto_increment, f_#{@columns.values.join(', f_')}, primary key (Id));"
    end

    def update_table(raw_columns)
      existings = to_columns(raw_columns)
      new_columns_names = @columns.keys - existings.keys
      new_columns = @columns.values_at(*new_columns_names)

      updated_columns = []
      @columns.each do |column_name, column|
        existings.each do |_, existing|
          if existing.need_update?(column)
            updated_columns << column
          end
        end
      end

      return nil if new_columns.blank? && updated_columns.blank?

      columns_definitions = []
      columns_definitions << "add column f_#{new_columns.join(', add column f_')}" if new_columns.present?
      columns_definitions << "modify column f_#{updated_columns.join(', modify column f_')}" if updated_columns.present?

      if columns_definitions.present?
        "alter table s_#{@name} " + columns_definitions.join(', ')
      end
    end

    def to_columns(raw_columns)
      result = {}
      raw_columns.each do |raw_column|
        column_name = raw_column[:Field].sub('f_', '')
        next if column_name == 'Id'

        if raw_column[:Type] =~ /(\w+)(\((\d+)\))?/
          data_type, max_size = $1.to_sym, $3
          result[column_name] = Column.new(column_name, data_type, max_size)
        end
      end

      result
    end

    def batch_insert
      update_columns_data_type

      "insert into s_#{@name} (f_#{@columns.keys.join(', f_')}) values (#{records_str});"
    end

    def update_columns_data_type
      @columns_data_type ||= {}
      @columns.each do |column_name, column_info|
        @columns_data_type[column_name] = column_info.data_type
      end
    end

    def records_str
      @records.map {|record| record_str(record)}.join('), (')
    end

    def record_str(record)
      @columns.keys.map do |column_name|
        value = record[column_name]
        if value.nil?
          'null'
        else
          @columns_data_type[column_name] == :int ? value : "'#{@mysql_client.escape(value)}'"
        end
      end.join(', ')
    end

    def size
      @records.size
    end

    def clear_records
      @records.clear
    end
  end
end