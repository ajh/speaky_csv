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

    def valid_field?(record, field, prefix: nil)
      return true if record.respond_to? field

      error_name = prefix ? "#{prefix}_#{field}" : field

      if errors[error_name].blank?
        errors.add error_name, "is not a method for class #{record.class}"
      end

      false
    end

    def enumerator
      errors.clear

      Enumerator.new do |yielder|
        # header row
        yielder << CSV::Row.new(@config.fields, @config.fields, true).to_csv

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

          yielder << row.to_csv
        end
      end
    end
  end
end
