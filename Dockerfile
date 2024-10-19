ARG RUBY_VERSION=3.2.3-alpine
FROM docker.io/ruby:$RUBY_VERSION
ARG RAILS_VERSION="~> 6.1.0"
ENV RAILS_VERSION=$RAILS_VERSION

RUN apk --update add \
    build-base \
    git \
    postgresql-dev \
    postgresql-client
RUN gem install bundler -v 2.5.13

COPY . /app
WORKDIR /app

RUN bundle install

