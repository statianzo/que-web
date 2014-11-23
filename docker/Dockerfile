# There's an image at joevandyk/que-web.
# Run like:
# docker run -e DATABASE_URL=postgres://username:password@hostname/db_name -p 3002:8080 joevandyk/que-web

FROM dockerfile/ruby

# Define working directory.
WORKDIR /app

EXPOSE 8080

# Define default command.
CMD bundle exec puma -e production -p 8080 /app/config.ru

RUN apt-get update && \
    apt-get install libpq-dev -y && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/*


ADD . /app
RUN bundle install

