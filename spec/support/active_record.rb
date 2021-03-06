require 'active_record'
require 'database_cleaner'
require 'pathname'

ActiveRecord::Base.logger = Logger.new \
  Pathname.new(__dir__).join('../../log/active_record.log').to_s

ActiveRecord::Base.establish_connection adapter: 'sqlite3',
                                        database:  ':memory:'

ActiveRecord::Schema.define do
  create_table :books do |table|
    table.column :author, :string
    table.column :name, :string
    table.column :publisher_id, :integer
  end

  create_table :reviews do |table|
    table.column :book_id, :integer
    table.column :tomatoes, :integer
    table.column :publication, :string
  end

  create_table :publishers do |table|
    table.column :name, :string
  end
end

class Book < ActiveRecord::Base
  has_many :reviews, inverse_of: :book
  belongs_to :publisher, inverse_of: :books
  accepts_nested_attributes_for :reviews, allow_destroy: true
  accepts_nested_attributes_for :publisher, allow_destroy: true
end

class Review < ActiveRecord::Base
  belongs_to :book, inverse_of: :reviews
  accepts_nested_attributes_for :book, allow_destroy: true
end

class Publisher < ActiveRecord::Base
  has_many :books, inverse_of: :publisher
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each, db: true) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
