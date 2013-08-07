# RSpec Around All

Provides around(:all) hooks for RSpec.

## Usage

In your Gemfile:

``` ruby
gem 'rspec_around_all', git: 'git://gist.github.com/2005175.git'
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

You may want to check out my [blog post](http://myronmars.to/n/dev-blog/2012/03/building-an-around-hook-using-fibers) about this.

## Copyright

Copyright (c) 2012-2013 Myron Marston. Released under the terms of the
MIT license. See LICENSE for details.

