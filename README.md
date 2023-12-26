# DeepMatching

This allows you to get detailed error messages on exactly where your heavily nested hashes differ

### Example
```ruby
actual   = {b: {c: 1, [{d: {e: 'actual_value'}}]}}
expected = {b: {c: 5, [{d: {e: 'expected_value'}}]}}

aggregate_failures do
  expect_deep_matching(actual, expected)
end
```

#### Fails with

```
  Got 2 failures from failure aggregation block
  1) Expected nested hash key at 'b.c'
        to eq
        # 5,
        but got
        1
  2) Expected nested hash key at 'b.[0].d.e'
        to eq
        # 'expected_value',
        but got
        'actual_value'
```

Note, only keys in the expected hash are checked.  If the actual hash has extra keys, they are ignored.
In this way it acts somewhat like `expect(actual).to match(hash_including(expected))`

## Installation

```
gem 'deep_matching'
```

## Usage

```ruby
require 'deep_matching'
RSpec.configure do |config|
  config.include DeepMatching
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/deep_matching.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
