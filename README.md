# que-web

que-web is a web UI to the [Que](https://github.com/chanks/que) job queue customized for Chi

![Que Web](doc/queweb.png)

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

#### With `config.ru`

Add in `config.ru`:

```ruby
require "que/web"

map "/que" do
  run Que::Web
end
```

### Rails

In `config/routes.rb`:

```ruby
require "que/web"
mount Que::Web => "/que"
```

### Authentication

#### Devise
```ruby
# config/routes.rb
authenticate :user do
  mount Que::Web, at: 'que'
end
```

#### Basic HTTP auth

In `config/initializers/queweb.rb`:
```ruby
Que::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == [ENV["QUEWEB_USERNAME"], ENV["QUEWEB_PASSWORD"]]
end
```
Then add the two environment variables to your production environment.

### Docker

Run:
```
docker run -e DATABASE_URL=postgres://username:password@hostname/db_name -p 3002:8080 joevandyk/que-web
```
Or use docker/Dockerfile to build your own container.
