require 'csv'
require 'active_record'

module SpeakyCsv
  # Imports a csv file as unsaved active record instances
  class ActiveRecordImport
    include Enumerable

    QUERY_BATCH_SIZE = 20
    TRUE_VALUES = ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES

    attr_accessor :errors

    def initialize(config, input_io, klass)
      @config = config
      @errors = ActiveModel::Errors.new(self)
      @klass = klass

      @attr_import = AttrImport.new @config, input_io
      @attr_import.errors = @errors
    end

    def each
      errors.clear
      block_given? ? enumerator.each { |a| yield a } : enumerator
    end

    private

    def enumerator
      Enumerator.new do |yielder|
        attr_enumerator = @attr_import.each
        done = false

        while done == false
          rows = []

          QUERY_BATCH_SIZE.times do
            begin
              rows << attr_enumerator.next
            rescue StopIteration
              done = true
            end
          end

          keys = rows.map { |attrs| attrs[@config.primary_key.to_s] }
          records = @klass.includes(@config.has_manys.keys)
            .where(@config.primary_key => keys)
            .inject({}) { |a, e| a[e.send(@config.primary_key).to_s] = e; a }

          rows.each do |attrs|
            # TODO: What if there's no id field?
            # @config.fields.include?(:id) || break

            record = if attrs[@config.primary_key.to_s].present?
                       # TODO: what if can't find record?
                       records[attrs[@config.primary_key.to_s]]
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
              if attrs.key?(name.to_s)
                # assume nested attributes feature is used
                attrs["#{name}_attributes"] = attrs.delete name.to_s
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
