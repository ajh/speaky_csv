# Speaky CSV

CSV imports and exports for ActiveRecord.

Speaky CSV features:

* An easy to use API,
* Speedy stream processing using enumerators.

## Installation

Add this line to your application's Gemfile:

    gem 'speaky_csv'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install speaky_csv

## Usage

Let's say you build software for your local public library and there
exists a Book model:

```ruby
# in app/models/book.rb
class Book < ActiveRecord::Base
  # ...
end
```

Speaky can be used to import and export book records using csv files.
The definition of the csv format could look like this:

```ruby
# in app/csvs/book_csv.rb
class BookCsv < SpeakyCsv::Base
  define_csv_fields do |config|
    config.field :id, :author
  end
end
```

This defines a CSV format that looks like this:

    id,author
    3,Stevenson
    19,Melville
    1,Macaulay

## Exporting

Creating a csv file from records in a database can be done with the
exporter:

```ruby
# in app/csvs/book_csv.rb
class BookCsv < SpeakyCsv::Base
  define_csv_fields do |config|
    config.field :id, :author, :_destroy
  end
end

books = [
  Book.create!(author: 'Stevenson'),
  Book.create!(author: 'Melville'),
  Book.create!(author: 'Macaulay'),
]

exporter = BookCsv.exporter books

io = StringIO.new
exporter.each { |row| io.write row }
```

`io` will have the following contents:

    id,author,_destroy
    2,Stevenson,false
    3,Melville,false
    4,Macaulay,false

##### With Associations

Associations can also be exported.

```ruby
# in app/csvs/book_csv.rb
class BookCsv < SpeakyCsv::Base
  define_csv_fields do |config|
    config.field :id, :author

    config.belongs_to :publisher do |p|
      p.field :id, :name
    end

    config.has_many :reviews do |r|
      r.field :id, :tomatoes, :publication
    end
  end
end
```

This defines a CSV format that looks like this:

    id,author,publisher_id,publisher_name
    3,Stevenson,22,Blam Ltd
    19,Melville,,
    1,Macaulay,83,NY Tiempo,reviews_0_id,8,reviews_0_tomatoes,50,review_0_publication,Daily

Since a book only ever has one publisher, these can get dedicated
columns with headers (the `publisher_id` and `publisher_name` columns).
Reviews are more tricky because there can be several that need to be
serialized to a single csv row. Speaky CSV uses a convention similar to
how rails and rack deal with query parameters for things like multi
select form inputs.

## Importing

Now lets import some books. Speaky will expect an import to have
an initial header row, and each subsequent row to represent a user record.
Columns can be in any order.

Let's create a book by importing a csv.

```ruby
csv_io = StringIO.new <<-CSV
id,author
,Sneed
CSV
```

Notice the empty id column. This tells Speaky that the operation is
a create. The file can be imported like this:

```ruby
importer = BookCsv.active_record_importer csv_io, Book
importer.each { |book| book.save }
Book.last.author == 'Sneed' # => true
```

This importer is an `active record importer`, which means that `#each`
will return active record instances. There is also an `attribute importer`
that will return hashes of attribute name => values. See the rdoc for
more info on that.

##### Update

Let's change the author value:

```ruby
csv_io = StringIO.new <<-CSV
id,author
1,Simon Sneed
CSV
```

Now there is an id value in the csv. Having an id value will cause
Speaky to find the record with the given id and update it.

```ruby
importer = BookCsv.active_record_importer csv_io, Book
importer.each { |book| book.save }
expect(Book.last.author).to eq 'Simon Sneed'
```

If a record with the given id isn't found, the importer will return a
nil for that row instead of an active record and add a message a log
file:

```ruby
csv_io = StringIO.new <<-CSV
id,author
234,I dont exist
CSV

importer = BookCsv.active_record_importer csv_io, Book
importer.to_a # => [nil]
importer.log  # => '...[row 1] record not found with primary key: "234"....'
```

For more info on the log file see below.

##### Destroy

To destroy the record, we'll need to change the csv format to add a
`_destroy` field. If this column contains a true value like: 'true' or
'1', the record will be marked for destruction.

Marking an active record for destruction is documented here:
http://api.rubyonrails.org/v4.2.0/classes/ActiveRecord/AutosaveAssociation.html#method-i-marked_for_destruction-3F

```ruby
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
if book.marked_for_destruction?
  book.destroy
end
```

##### With Associations

Speaky uses the active record `accepts_nested_attributes_for` feature to
deal with importing association data.

For example, if a belongs\_to association is configured:

```ruby
# in app/csvs/book_csv.rb
class BookCsv < SpeakyCsv::Base
  define_csv_fields do |config|
    config.field :id, :author

    config.belongs_to :publisher do |p|
      p.field :id, :name
    end
  end
end
```

And the csv file being imported is this:

    id,author,publisher_id,publisher_name
    3,Stevenson,22,Blam Ltd

Then speaky will find a Booking record with id `3` and call:

```ruby
booking.publisher_attributes = {id: '22', name: 'Blam Ltd'}
```

For a has\_many association, if the configuration looked like this:

```ruby
# in app/csvs/book_csv.rb
class BookCsv < SpeakyCsv::Base
  define_csv_fields do |config|
    config.field :id, :author

    config.has_many :reviews do |r|
      r.field :id, :tomatoes, :publication
    end
  end
end
```

And an import csv looked like this:

    id,author,publisher_id,publisher_name
    1,Macaulay,83,NY Tiempo,reviews_0_id,8,reviews_0_tomatoes,50,review_0_publication,Daily

The speaky will find a Booking record with id `1` and call:

```ruby
booking.reviews_attributes = [{id: '8', tomatoes: '50', publication: 'Daily'}]
```

## Log Messages

Importers and exporters use a `Logger` instance to write messages during
processing. The default logger writes to a string that can be retrieved
by the `#log` method. A custom Logger can be set by the `#logger=`
method.

See `Logger` in the ruby stdlib for more details.

## Best Practices

* Configure speaky with `id` and `_destroy` fields for active record models
* For associations, use `nested_attributes_for` and add `id` and
  `_destroy` fields
* Use optimistic locking and configure a `lock_version` field
* Consider building a draft or preview feature for importing which
  doesn't persist the record by calling `save` but instead reports what
  the changes would be using `ActiveModel::Dirty`

## TODO

* [x] export only fields
* [x] configurable id field (key off an `external_id` for example)
* [x] export validations
* [x] attr import validations
* [x] active record import validations
* [x] `has_one` associations
* [ ] required fields (make `lock_version` required for example)
* [ ] transformations for values via accessors on class
* [x] public stable api for csv format definition
* [x] assign attrs one at a time so they don't all fail together
* [x] decide what empty cells mean
* [ ] figure out why SpeakyCsv is a class and not a module

## Contributing

1. Fork it ( http://github.com/ajh/speaky_csv/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
