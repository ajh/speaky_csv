require 'active_support/all'
require 'csv'

require 'speaky_csv/version'

module SpeakyCsv
  extend ActiveSupport::Concern

  included do
    cattr_accessor :csv_field_builder
  end

  module ClassMethods
    def define_csv_fields
      b = Builder.new
      yield b
      self.csv_field_builder = b
    end
  end

  def to_csv(list)
    table = CSV::Table.new []
    headers = csv_field_builder.fields

    list.each do |item|
      row = CSV::Row.new(headers, headers.map { |f| item.send f })

      csv_field_builder.has_manys.each do |name, fields|
        item.send(name).each_with_index do |has_many_item, index|
          fields.each do |field|
            row << "#{name.singularize}_#{index}_#{field}"
            row << has_many_item.send(field)
          end
        end
      end
      table << row
    end

    table.to_csv
  end

  def from_csv(csv_string)
    list = []

    csv = CSV.parse csv_string, headers: true
    csv.each do |row|
      item = {}

      row.headers.compact.each do |h|
        item[h] = row.field h
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

        item[has_many_name] ||= []
        item[has_many_name][has_many_index] ||= {}
        item[has_many_name][has_many_index][has_many_field] = has_many_value
      end

      csv_field_builder.has_manys.each do |name, fields|
      end

      list << item
    end

    list
  end

  class Builder
    attr_reader :fields, :has_ones, :has_manys

    def initialize
      @fields = []
      @has_ones = {}
      @has_manys = {}
    end

    def field(*fields)
      @fields += fields
      @fields.uniq!
    end

    def has_one(name, fields)
      @has_ones[name] = fields
    end

    def has_many(name, fields)
      @has_manys[name] = fields
    end
  end
end
