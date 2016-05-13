module SpeakyCsv
  # Inherit from this class when using SpeakyCsv
  class Base
    class_attribute :speaky_csv_config
    self.speaky_csv_config = Config.new

    def self.define_csv_fields
      self.speaky_csv_config = speaky_csv_config.deep_dup
      yield ConfigBuilder.new(config: speaky_csv_config)
    end

    # Return a new exporter instance
    def self.exporter(records_enumerator)
      Export.new speaky_csv_config,
                 records_enumerator
    end

    # Return a new attr importer instance from the given IO, which is expected
    # to be able to read a csv file. The importer will be an Enumerator that returns successive attribute hashes.
    #
    # For example:
    #
    # class SomeFormat < SpeakyCsv::Base
    #   define_csv_fields do |c|
    #     c.fields :id, :name
    #   end
    # end
    #
    # File.open('sample.csv', 'r') do |io|
    #   importer = SomeFormat.new.attr_importer io
    #
    #   importer.each do |attrs|
    #     # attrs will be hashes like { "id" => 123, "name" => "Curley" }
    #   end
    # end
    #
    def self.attr_importer(input_io)
      AttrImport.new speaky_csv_config,
                     input_io
    end

    # Return a new active record instance from the given IO, which is expected
    # to be able to read a csv file. The importer will be an Enumerator that returns successive active records.
    #
    # For example:
    #
    # class UserCsv < SpeakyCsv::Base
    #   define_csv_fields do |c|
    #     c.fields :id, :name
    #   end
    # end
    #
    # File.open('sample.csv', 'r') do |io|
    #   importer = SomeFormat.new.active_record_importer io, User
    #
    #   importer.each do |record|
    #     # record will be a User instance or nil
    #   end
    # end
    #
    # Optionally an Enumerable instance can be passed instead of an IO
    # instance. The enumerable should return attr hashes. This may be helpful
    # for transforming or chaining Enumerables.
    def self.active_record_importer(input_io_or_enumerable, klass)
      ActiveRecordImport.new \
        speaky_csv_config,
        input_io_or_enumerable,
        klass
    end
  end
end
