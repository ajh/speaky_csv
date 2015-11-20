require 'csv'
require 'English'

module SpeakyCsv
  # Imports a csv file as attribute hashes.
  class AttrImport
    include Enumerable

    attr_accessor :logger

    def initialize(config, input_io)
      @config = config
      @input_io = input_io
      @log_output = StringIO.new
      @logger = Logger.new @log_output
    end

    # Yields successive attribute hashes for rows in the csv file
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
      return @enumerator if defined? @enumerator

      @enumerator = Enumerator.new do |yielder|
        begin
          csv = CSV.new @input_io, headers: true

          csv.each do |row|
            attrs = {}
            add_fields row, attrs
            add_has_manys row, attrs
            yielder << attrs
          end

        rescue CSV::MalformedCSVError
          logger.error "csv is malformed: #{$ERROR_INFO.message}"
        end
      end
    end

    # Adds configured fields to attrs
    def add_fields(row, attrs)
      row.headers.compact.each do |h|
        unless @config.fields.include?(h.to_sym)
          logger.warn "ignoring unknown column #{h}"
          next
        end
        if @config.export_only_fields.include?(h.to_sym)
          logger.warn "ignoring unknown column #{h}"
          next
        end

        attrs[h] = row.field h
      end
    end

    # Adds configured has manys to attrs
    def add_has_manys(row, attrs)
      headers_length = row.headers.compact.length
      pairs_start_on_evens = headers_length.even?
      (headers_length..row.fields.length).each do |i|
        i.send(pairs_start_on_evens ? :even? : :odd?) || next
        row[i] || next

        m = row[i].match(/^(\w+)_(\d+)_(\w+)$/)
        m || next
        has_many_name = m[1].pluralize
        has_many_index = m[2].to_i
        has_many_field = m[3]
        has_many_value = row[i + 1]

        has_many_config = @config.has_manys[has_many_name.to_sym]

        next unless has_many_config
        next unless has_many_config.fields.include?(has_many_field.to_sym)
        next if has_many_config.export_only_fields.include?(has_many_field.to_sym)

        attrs[has_many_name] ||= []
        attrs[has_many_name][has_many_index] ||= {}
        attrs[has_many_name][has_many_index][has_many_field] = has_many_value
      end
    end
  end
end
