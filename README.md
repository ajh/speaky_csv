# speaky csv

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'speaky_csv'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install speaky_csv

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

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( http://github.com/ajh/speaky_csv/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
