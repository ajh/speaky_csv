# Speaky CSV

CSV imports and exports for ActiveRecord.

## For example

Lets say there exists a User class:

    # in app/models/user.rb
    class User < ActiveRecord::Base
      ...
    end

Speaky can be used to import and export user records. The definition of
the csv format could look like this:

    # in app/csv/user_csv.rb
    class UserCsv < SpeakyCsv::Base
      define_csv_fields do |config|
        config.field :id, :email, :roles
      end
    end

Now lets import some user records. An import csv will always have an
initial header row, with each following row representing a user record.
lets import the following csv file (whitespace for clarity):

    # my_import.csv
    id, email,              roles
    22, admin@example.test, admin
      , newbie@user.test,   user

This file can be imported like this:

    File.open "my_import.csv", "r" do |io|
      importer = UserCsv.new.active_record_importer io, User
      importer.each { |user| user.save }
    end

## Custom CSV formats

Speaky


Speaky allows customization of csv files to a degree, but some
conventions need to be followed.

At a high level, the csv
ends up looking similar to the way active record data gets serialized
into form parameters which will be familiar to many rails developers.
The advantage of this approach is that associated records be imported
and exported.

## Installation

Add this line to your application's Gemfile:

    gem 'speaky_csv'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install speaky_csv

## Usage

Subclass SpeakyCsv::Base and define a csv format for an active
record class. For example:

    # in app/csv/user_csv.rb
    class UserCsv < SpeakyCsv::Base
      define_csv_fields do |config|
        config.field :id, :first_name, :last_name, :email

        config.has_many :roles do |r|
          r.field :role_name
        end
      end
    end

See the rdoc for more details on how to configure the format.

Once the format is defined records can be exported like this:

    $ exporter = UserCsv.new.exporter(User.all)
    $ File.open('users.csv', 'w') { |io| exporter.each { |row| io.write row } }

TODO:

* describe importing to attribute list
* describe importing to to active records
* describe how to transform with an enumerator

## Recommendations

* Add `id` and `_destroy` fields for active record models
* For associations, use `nested_attributes_for` and add `id` and
  `_destroy` fields
* Use optimistic locking and add `lock_version` to csv

## TODO

* [x] export only fields
* [x] configurable id field (key off an `external_id` for example)
* [x] export validations
* [x] attr import validations
* [x] active record import validations
* [ ] `has_one` associations
* [ ] required fields (make `lock_version` required for example)
* [ ] transformations for values via accessors on class
* [ ] public stable api for csv format definition
* [ ] assign attrs one at a time so they don't all fail together

## Contributing

1. Fork it ( http://github.com/ajh/speaky_csv/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
