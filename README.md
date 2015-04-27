# que-web [![Build Status](https://travis-ci.org/statianzo/que-web.svg?branch=master)](https://travis-ci.org/statianzo/que-web)

que-web is a web UI to the [Que](https://github.com/chanks/que) job queue.

![Que Web](https://raw.githubusercontent.com/statianzo/que-web/master/doc/queweb.png)

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

If you want to require authentication (Devise):

```ruby
authenticate :user do
  mount Que::Web, at: 'que'
end
```

If you want to use Docker, run:
```
docker run -e DATABASE_URL=postgres://username:password@hostname/db_name -p 3002:8080 joevandyk/que-web
```
Or use docker/Dockerfile to build your own container.
