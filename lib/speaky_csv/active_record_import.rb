require 'csv'
require 'active_record'

module SpeakyCsv
  # Imports a csv file as unsaved active record instances
  class ActiveRecordImport
    include Enumerable

    QUERY_BATCH_SIZE = 20
    TRUE_VALUES = ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES

    def initialize(config, attr_enumerator, klass)
      @config = config
      @attr_enumerator = attr_enumerator
      @klass = klass
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
        done = false

        while done == false
          rows = []

          QUERY_BATCH_SIZE.times do
            begin
              rows << @attr_enumerator.next
            rescue StopIteration
              done = true
            end
          end

          ids = rows.map { |attrs| attrs['id'] }
          records = @klass.includes(@config.has_manys.keys)
            .where(id: ids)
            .inject({}) { |a, e| a[e.id.to_s] = e; a }

          rows.each do |attrs|
            # TODO: What if there's no id field?
            # @config.fields.include?(:id) || break

            record = if attrs['id'].present?
                       # TODO: what if can't find record?
                       records[attrs['id']]
                     else
                       @klass.new
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
              if attrs.key?(name)
                # assume nested attributes feature is used
                attrs["#{name}_attributes"] = attrs.delete name
              end
            end

            # TODO: what if attrs has unknown attribute? ActiveRecord::UnknownAttributeError
            record.attributes = attrs

            yielder << record
          end
        end
      end
    end
  end
end
