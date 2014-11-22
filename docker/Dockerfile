# There's an image at joevandyk/que-web.
# Run like:
# docker run -e DATABASE_URL=postgres://username:password@hostname/db_name -p 3002:8080 joevandyk/que-web

FROM dockerfile/ruby

run apt-get update
run apt-get install libpq-dev -y

# Define working directory.
WORKDIR /app

ADD Gemfile /app/
ADD Gemfile.lock /app/
RUN bundle install
ADD . /app

# Set environment variables.
ENV APPSERVER puma

# Define default command.
CMD bundle exec rackup -p 8080 /app/config.ru -s $APPSERVER

# Expose ports.
EXPOSE 8080
