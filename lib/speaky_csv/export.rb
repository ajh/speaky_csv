require 'csv'
require 'active_model'

module SpeakyCsv
  # Exports records as csv. Will write a csv to the given IO object
  class Export
    include Enumerable

    def initialize(config, records_enumerator)
      @config = config
      @records_enumerator = records_enumerator
    end

    # Writes csv string to io
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
        # header row
        yielder << CSV::Row.new(@config.fields, @config.fields, true).to_csv

        @records_enumerator.each do |record|
          row = CSV::Row.new \
            @config.fields,
            @config.fields.map { |f| record.send f }

          @config.has_manys.each do |name, fields|
            record.send(name).each_with_index do |has_many_item, index|
              fields.each do |field|
                row << "#{name.singularize}_#{index}_#{field}"
                row << has_many_item.send(field)
              end
            end
          end

          yielder << row.to_csv
        end
      end
    end
  end
end
