SpreeGestpay
============

Gestpay payment gateway support for Spree.


## Installation

Add the following to your `Gemfile`:

```ruby
gem 'spree_gestpay', github: 'net2b/spree_gestpay', branch: 'X-X-stable'
```

Run `bundle install`

Run the generator

    rails g spree_gestpay:install

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

    $ bundle
    $ bundle exec rake test_app
    $ bundle exec rspec spec

Copyright (c) 2015 Net2b, released under the New BSD License
