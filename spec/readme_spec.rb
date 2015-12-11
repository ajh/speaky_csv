require 'spec_helper'
require 'support/active_record'

describe "Examples in README.md", :db do
  it "has working examples" do
    # For example ...

    # in app/models/book.rb
    class Book < ActiveRecord::Base
      # ...
    end

    # in app/csvs/book_csv.rb
    class BookCsv < SpeakyCsv::Base
      define_csv_fields do |config|
        config.field :id, :author
      end
    end

    # Importing - create

    csv_io = StringIO.new <<-CSV
id,author
,Sneed
    CSV

    importer = BookCsv.active_record_importer csv_io, Book
    importer.each { |book| book.save }

    expect(Book.last.author).to eq 'Sneed'

    # Importing - update

    csv_io = StringIO.new <<-CSV
id,author
1,Simon Sneed
    CSV

    importer = BookCsv.active_record_importer csv_io, Book
    importer.each { |book| book.save }
    expect(Book.last.author).to eq 'Simon Sneed'

    # Importing - record not found

    csv_io = StringIO.new <<-CSV
id,author
234,I dont exist
    CSV

    importer = BookCsv.active_record_importer csv_io, Book
    expect(importer.to_a).to eq [nil]
    expect(importer.log).to include '[row 1] record not found with primary key: "234"'

    # Importing - destroy

    # in app/csvs/book_csv.rb
    class BookCsv < SpeakyCsv::Base
      define_csv_fields do |config|
        config.field :id, :author, :_destroy
      end
    end

    csv_io = StringIO.new <<-CSV
id,_destroy
1,true
    CSV

    importer = BookCsv.active_record_importer csv_io, Book
    book = importer.to_a.first
    expect(book).to be_marked_for_destruction
    if book.marked_for_destruction?
      book.destroy
    end

    # Exporting

    books = [
      Book.create!(author: 'Stevenson'),
      Book.create!(author: 'Melville'),
      Book.create!(author: 'Macaulay'),
    ]
    exporter = BookCsv.exporter books

    io = StringIO.new
    exporter.each { |row| io.write row }
    io.rewind
    expect(io.read).to eq <<-OUTPUT
id,author,_destroy
2,Stevenson,false
3,Melville,false
4,Macaulay,false
    OUTPUT
  end
end

