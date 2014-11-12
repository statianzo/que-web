# que-web

que-web is a web UI to the [que](https://github.com/chanks/que) job queue.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'que-web'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install que-web

## Usage

In your `config.ru` add

```ruby
require "que/web"

map "/que" do
  run Que::Web
end
```

Or in Rails `config/routes.rb`

```ruby
require "que/web"
mount Que::Web => "/que"
```
