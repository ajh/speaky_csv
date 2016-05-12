require 'csv'
require 'active_record'

module SpeakyCsv
  # Imports a csv file as unsaved active record instances
  class ActiveRecordImport
    include Enumerable

    QUERY_BATCH_SIZE = 20
    TRUE_VALUES = ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES

    attr_accessor :logger

    def initialize(config, input_io_or_enumerable, klass)
      @config = config
      @klass = klass

      @log_output = StringIO.new
      @logger = Logger.new @log_output

      if duck_type_is_io?(input_io_or_enumerable)
        @rx = AttrImport.new @config, input_io_or_enumerable
        @rx.logger = @logger
      else
        @rx = input_io_or_enumerable
      end
    end

    def each
      block_given? ? enumerator.each { |a| yield a } : enumerator
    end

    # Returns a string of all the log output from the import. Or returns
    # nothing if a custom logger was used.
    def log
      @log_output.string
    end

    # Add includes options which will be used when querying records.
    #
    # Useful to avoid N+1 type problems. Configured has_manys are automaticaly
    # included and don't need to be specified here.
    def includes(options)
      @includes = options
    end

    # Add eager_load options which will be used when querying records.
    def eager_load(options)
      @eager_load = options
    end

    private

    def enumerator
      # One based index, where the header is row 1 and first record is row 2
      row_index = 1

      Enumerator.new do |yielder|
        @rx.each_slice(QUERY_BATCH_SIZE) do |rows|
          keys = rows.map { |attrs| attrs[@config.primary_key.to_s] }
          query = @klass.includes(@config.has_manys.keys)
                  .where(@config.primary_key => keys)
          query = query.includes(@includes) if @includes
          query = query.eager_load(@eager_load) if @eager_load

          records = query.inject({}) { |a, e| a[e.send(@config.primary_key).to_s] = e; a }

          rows.each do |attrs|
            record = if attrs[@config.primary_key.to_s].present?
                       records[attrs[@config.primary_key.to_s]]
                     else
                       @klass.new
                     end

            unless record
              logger.error "[row #{row_index}] record not found with primary key: #{attrs[@config.primary_key.to_s].inspect}"
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

            @config.has_ones.keys.each do |name|
              if attrs.key?(name.to_s)
                # assume nested attributes feature is used
                attrs["#{name}_attributes"] = attrs.delete name.to_s
              end
            end

            #warn attrs.inspect

            attrs.each do |attr, value|
              writer_method = "#{attr}="
              if record.respond_to? writer_method
                record.send writer_method, value
              else
                logger.error "[row #{row_index}] record doesn't respond to #{attr.inspect}"
              end
            end

            yielder << record
            row_index += 1
          end
        end
      end
    end

    def duck_type_is_io?(val)
      # check some arbitrary methods
      val.respond_to?(:gets) && val.respond_to?(:seek)
    end
  end
end
