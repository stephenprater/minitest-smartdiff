# Minitest::Smartdiff

Have you ever found yourself staring cross-eyed and bewildered at walls of diffs that are **absolutely the same damn it**.

Well, it's the future, and you don't have to do that anymore.  Let the endlessly patient Robot go looking for the needle in the needle stack.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'minitest-smartdiff'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install minitest-smartdiff

## Usage

In your `test_helper.rb` file:

```ruby
require 'minitest-smartdiff'
```

And in your test file:

```ruby
class MyTestThatProducesAnAnnoyingDiff < Minitest::Test
  include Minitest::Smartdiff

  def test_that_produces_an_annoying_obscure_diff
    some_result = my_method()

    smart_diff do
      assert_equal "Mayonnaise is delicious", "Mayonnaise is delicioous"
    end
  end
end
```

Alternatively - you can call `smart_diff_on` and `smart_diff_off` to turn the functionality on/off without using a block.

Smartdiff is smart enough not to ask the LLM for the difference if the assertion passes, so you don't accrue OpenAI costs for passing tests. However - you should consider this primarily a debugging tool - use at high volume at your own risk.

You can configure the OpenAI client like so:

```ruby
class MyTestThatProducesAnAnnoyingDiff < Minitest::Test
  include Minitest::Smartdiff

  openai({
    access_token: ENV['OPENAI_KEY']
  })

  model('gpt-3.5-turbo')

  prompt(<<~ERB
    You are a differ - you diff things.  Diff this:
    <%= expected %>
    <%= actual %>
    <%= mode %> is either `:json`, `:object` or `:text`
    ERB
  )


  def test_that_produces_an_annoying_obscure_diff
    some_result = my_method()

    smart_diff do
      assert_equal "Mayonnaise is delicious", "Mayonnaise is delicioous"
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stephenprater/minitest-smartdiff.
