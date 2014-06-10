[![Build Status](https://secure.travis-ci.org/seanwalbran/rspec_around_all.png?branch=master)](http://travis-ci.org/seanwalbran/rspec_around_all)

# RSpec Around All

Provides around(:all) hooks for RSpec.

## Usage

In your Gemfile:

``` ruby
gem 'rspec_around_all', require: false
```

In a spec:

``` ruby
require 'rspec_around_all'

describe "MyClass" do
  around(:all) do |group|
    # do something before
    group.run_examples
    # do something after
  end

  # or...
  around(:all) do |group|
    transactionally(&group)
  end
end
```

See also the original [blog post](http://myronmars.to/n/dev-blog/2012/03/building-an-around-hook-using-fibers) about this.

## Contributing

* Fork the project
* Add tests
* Fix the issue / add the feature
* Submit pull request on github

## Copyright

Copyright (c) 2012-2013 Myron Marston. Released under the terms of the
MIT license. See LICENSE for details.

