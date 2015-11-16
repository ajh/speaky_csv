require 'csv'

module SpeakyCsv
  # Imports a csv file as attribute hashes.
  class AttrImport
    include Enumerable

    def initialize(config, input_io)
      @config = config
      @input_io = input_io
    end

    # yields successive
    def each
      errors.clear
      block_given? ? enumerator.each { |a| yield a } : enumerator
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    private

    def enumerator
      Enumerator.new do |yielder|
        csv = CSV.new @input_io, headers: true

        csv.each do |row|
          attrs = {}

          row.headers.compact.each do |h|
            next if @config.output_only_fields.include?(h.to_sym)
            attrs[h] = row.field h
          end

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

            attrs[has_many_name] ||= []
            attrs[has_many_name][has_many_index] ||= {}
            attrs[has_many_name][has_many_index][has_many_field] = has_many_value
          end

          yielder << attrs
        end
      end
    end
  end
end
