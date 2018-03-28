Solidus Postmates
==============

[![Build Status](https://travis-ci.org/jtapia/solidus_postmates.svg?branch=master)](https://travis-ci.org/jtapia/solidus_postmates)

Postmates Solidus integration
- Calculate shipping cost via Postmates API

Installation
------------

Add solidus_postmates to your Gemfile:

```ruby
gem 'solidus_postmates'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g solidus_postmates:install
```

Testing
-------

First bundle your dependencies, then run `rake`. `rake` will default to building the dummy app if it does not exist, then it will run specs, and [Rubocop](https://github.com/bbatsov/rubocop) static code analysis. The dummy app can be regenerated by using `rake test_app`.

```shell
bundle
bundle exec rake
```

When testing your application's integration with this extension you may use its factories.
Simply add this require statement to your spec_helper:

```ruby
require 'solidus_postmates/factories'
```
