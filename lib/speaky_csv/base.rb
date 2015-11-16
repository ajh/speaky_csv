module SpeakyCsv
  # Inherit from this class when using SpeakyCsv
  class Base
    class_attribute :csv_field_builder

    def self.define_csv_fields
      b = Builder.new
      yield b
      self.csv_field_builder = b
    end

    # Return a new exporter instance
    def exporter(records_enumerator)
      Export.new self.class.csv_field_builder,
                 records_enumerator
    end

    def attr_importer(input_io)
      AttrImport.new self.class.csv_field_builder,
                     input_io
    end

    def active_record_importer(input_io, klass)
      attr_importer = AttrImport.new \
        self.class.csv_field_builder,
        input_io

      ActiveRecordImport.new \
        self.class.csv_field_builder,
        attr_importer.each,
        klass
    end
  end

  # An instance of this class is yielded to the block passed to
  # define_csv_fields. Used to configure speaky csv.
  class Builder
    attr_reader :fields, :has_ones, :has_manys

    def initialize
      @fields = []
      @has_ones = {}
      @has_manys = {}
    end

    def field(*fields)
      @fields += fields.map(&:to_sym)
      @fields.uniq!
    end

    def has_one(name, fields)
      @has_ones[name] = fields.map(&:to_sym)
    end

    def has_many(name, fields)
      @has_manys[name] = fields.map(&:to_sym)
    end
  end
end
