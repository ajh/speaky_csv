module SpeakyCsv

  # An instance of this class is yielded to the block passed to
  # define_csv_fields. Used to configure speaky csv.
  class Builder
    attr_reader \
      :export_only_fields,
      :fields,
      :has_manys,
      :has_ones,
      :primary_key

    def initialize
      @export_only_fields = []
      @fields = []
      @has_manys = {}
      @has_ones = {}
      @primary_key = :id
    end

    # Add one or many fields to the csv format.
    #
    # If options are passed, they apply to all given fields.
    def field(*fields, export_only: false)
      @fields += fields.map(&:to_sym)
      @fields.uniq!

      if export_only
        @export_only_fields += fields.map(&:to_sym)
        @export_only_fields.uniq!
      end

      nil
    end

    # Define a custom primary key. By default an `id` column as used.
    #
    # Accepts the same options as #field
    def primary_key=(name, options={})
      field name, options
      @primary_key = name.to_sym
    end

    def has_one(name)
      @has_ones[name.to_sym] ||= self.class.new
      yield @has_ones[name.to_sym]

      nil
    end

    def has_many(name)
      @has_manys[name.to_sym] ||= self.class.new
      yield @has_manys[name.to_sym]

      nil
    end

    def dup
      other = super
      other.instance_variable_set '@has_manys', @has_manys.deep_dup
      other.instance_variable_set '@has_ones', @has_ones.deep_dup

      other
    end
  end

  # Inherit from this class when using SpeakyCsv
  class Base
    class_attribute :csv_field_builder
    self.csv_field_builder = Builder.new

    def self.define_csv_fields
      self.csv_field_builder = csv_field_builder.deep_dup
      yield csv_field_builder
    end

    # Return a new exporter instance
    def self.exporter(records_enumerator)
      Export.new csv_field_builder,
                 records_enumerator
    end

    def attr_importer(input_io)
      AttrImport.new self.class.csv_field_builder,
                     input_io
    end

    def active_record_importer(input_io, klass)
      ActiveRecordImport.new \
        self.class.csv_field_builder,
        input_io,
        klass
    end
  end
end
