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
    attr_reader \
      :fields,
      :has_manys,
      :has_ones,
      :export_only_fields

    def initialize
      @fields = []
      @export_only_fields = []
      @has_ones = {}
      @has_manys = {}
    end

    def field(*fields, export_only: false, required: false)
      @fields += fields.map(&:to_sym)
      @fields.uniq!

      if export_only
        @export_only_fields += fields.map(&:to_sym)
        @export_only_fields.uniq!
      end

      nil
    end

    def has_one(name)
      builder = self.class.new
      yield builder
      @has_ones[name.to_sym] = self.class.new

      nil
    end

    def has_many(name)
      builder = self.class.new
      yield builder
      @has_manys[name.to_sym] = builder

      nil
    end
  end
end
