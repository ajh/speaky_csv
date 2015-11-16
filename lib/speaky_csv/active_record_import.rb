require 'csv'
require 'active_record'

module SpeakyCsv
  # Imports a csv file as attribute hashes.
  class ActiveRecordImport
    # QUERY_BATCH_SIZE=20
    TRUE_VALUES = ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES

    def initialize(config, attr_enumerator, klass)
      @config = config
      @attr_enumerator = attr_enumerator
      @klass = klass
    end

    # yields successive
    def each
      errors.clear

      Enumerator.new do |yielder|
        # TODO: optimize queries by batching
        @attr_enumerator.each do |attrs|
          # TODO: What if there's no id field?
          #@config.fields.include?(:id) || break

          record = if attrs['id'].present?
                     @klass.find_by_id(attrs['id'])
                   else
                     @klass.new
                   end

          if @config.fields.include?(:_destroy) &&
             TRUE_VALUES.include?(attrs['_destroy'])
            record.mark_for_destruction
            yielder << record
            next
          end

          @config.has_manys.keys.each do |name|
            if attrs.key?(name)
              # assume nested attributes feature is used
              attrs["#{name}_attributes"] = attrs.delete name
            end
          end

          record.attributes = attrs

          yielder << record
        end
      end
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end
  end
end
