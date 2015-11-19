# Speaky CSV

CSV exporting and importing for ActiveRecord and ActiveModel records.

Speaky lets the format of csv files to be customized, but it does
require certain conventions to be followed. At a high level, the csv
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

## Contributing

1. Fork it ( http://github.com/ajh/speaky_csv/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
