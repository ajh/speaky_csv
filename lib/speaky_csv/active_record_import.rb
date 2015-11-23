require 'csv'
require 'active_record'
require 'English'

module SpeakyCsv
  # Imports a csv file as unsaved active record instances
  class ActiveRecordImport
    include Enumerable

    QUERY_BATCH_SIZE = 20
    TRUE_VALUES = ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES

    attr_accessor :logger

    def initialize(config, input_io, klass)
      @config = config
      @klass = klass

      @log_output = StringIO.new
      @logger = Logger.new @log_output

      @attr_import = AttrImport.new @config, input_io
      @attr_import.logger = @logger
    end

    def each
      block_given? ? enumerator.each { |a| yield a } : enumerator
    end

    # Returns a string of all the log output from the import. Or returns
    # nothing if a custom logger was used.
    def log
      @log_output.string
    end

    private

    def enumerator
      # One based index, where the header is row 1 and first record is row 2
      row_index = 1

      Enumerator.new do |yielder|
        @attr_import.each_slice(QUERY_BATCH_SIZE) do |rows|
          keys = rows.map { |attrs| attrs[@config.primary_key.to_s] }
          records = @klass.includes(@config.has_manys.keys)
                    .where(@config.primary_key => keys)
                    .inject({}) { |a, e| a[e.send(@config.primary_key).to_s] = e; a }

          rows.each do |attrs|
            row_index += 1

            record = if attrs[@config.primary_key.to_s].present?
                       records[attrs[@config.primary_key.to_s]]
                     else
                       @klass.new
                     end

            unless record
              logger.error "[row #{row_index}] record not found with primary key #{attrs[@config.primary_key]}"
              yielder << nil
              next
            end

            if @config.fields.include?(:_destroy)
              if TRUE_VALUES.include?(attrs['_destroy'])
                record.mark_for_destruction
                yielder << record
                next

              else
                attrs.delete '_destroy'
              end
            end

            @config.has_manys.keys.each do |name|
              if attrs.key?(name.to_s)
                # assume nested attributes feature is used
                attrs["#{name}_attributes"] = attrs.delete name.to_s
              end
            end

            begin
              record.attributes = attrs
            rescue ActiveRecord::UnknownAttributeError
              logger.error "[row #{row_index}] record doesn't respond to some configured fields: #{$ERROR_INFO.message}"
            end

            yielder << record
          end
        end
      end
    end
  end
end
