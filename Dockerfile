#######  Intitial Base Image  ##########
FROM ruby:2.7.2-alpine as base

ARG DATABASE_URL
ARG PORT

ENV BUILD_PACKAGES bash build-base
ENV SOFTWARE_INCLUDES postgresql-dev tzdata

ENV DATABASE_URL ${DATABASE_URL}
ENV PORT $PORT

ENV RAILS_ENV=production
ENV USER=sofwarellc
ENV APP_HOME=/home/${USER}

WORKDIR ${APP_HOME}

RUN apk add --update --no-cache ${SOFTWARE_INCLUDES} \
  && apk --update add --no-cache --virtual run-dependencies ${BUILD_PACKAGES} \
  && rm -rf /var/cache/apk/* \
  && mkdir -p tmp/pids \
  && addgroup -S ${USER} \
  && adduser -S ${USER} -G ${USER}

COPY Gemfile* ${APP_HOME}
RUN bundle check || bundle install

COPY . ${APP_HOME}

RUN chown -R ${USER}:${USER} ${APP_HOME} \
  && chown -R ${USER}:${USER} tmp/pids \
  && apk del run-dependencies

####### Final Build ###########

FROM base as final
WORKDIR ${APP_HOME}

COPY --from=base ${APP_HOME} .

USER ${USER}

EXPOSE ${PORT}
CMD bundle exec puma -p ${PORT}
