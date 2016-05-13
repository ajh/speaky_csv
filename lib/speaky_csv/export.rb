require 'csv'
require 'active_model'
require 'stringio'
require 'logger'

module SpeakyCsv
  # Exports records as csv. Will write a csv to the given IO object
  class Export
    include Enumerable

    attr_accessor :logger

    def initialize(config, records_enumerator)
      @config = config
      @records_enumerator = records_enumerator
      @log_output = StringIO.new
      @logger = Logger.new @log_output
    end

    # Writes csv string to io
    def each
      block_given? ? enumerator.each { |a| yield a } : enumerator
    end

    # Returns a string of all the log output from the import. Or returns
    # nothing if a custom logger was used.
    def log
      @log_output.string
    end

    private

    def valid_field?(record, field, prefix: nil)
      return true if record.respond_to? field
      return false if field == :_destroy

      error_name = prefix ? "#{prefix}_#{field}" : field
      logger.error "#{error_name} is not a method for class #{record.class}"

      false
    end

    def enumerator
      return @enumerator if defined? @enumerator

      @enumerator = Enumerator.new do |yielder|
        columns = @config.fields
        columns += @config.has_ones.flat_map do |name, config|
          config.fields.map {|f| "#{name}_#{f}" }
        end

        # header row
        yielder << CSV::Row.new(columns, columns, true).to_csv

        @records_enumerator.each do |record|
          values = @config.fields
                   .select { |f| valid_field? record, f }
                   .map { |f| record.send f }

          row = CSV::Row.new @config.fields, values

          @config.has_manys.select { |a| valid_field? record, a }.each do |name, config|
            record.send(name).each_with_index do |has_many_record, index|
              config.fields.select { |f| valid_field? has_many_record, f, prefix: name }.each do |field|
                row << "#{name.to_s.singularize}_#{index}_#{field}"
                row << has_many_record.send(field)
              end
            end
          end

          @config.has_ones.select { |a| valid_field? record, a }.each do |name, config|
            has_one_record = record.send name
            config.fields.select { |f| valid_field? has_one_record, f, prefix: name }.each do |field|
              row << has_one_record.send(field)
            end
          end

          yielder << row.to_csv
        end
      end
    end
  end
end
