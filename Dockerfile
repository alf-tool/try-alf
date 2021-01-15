FROM ruby:2.7.2-slim-buster as build

RUN apt-get update && apt-get install -y build-essential libpq-dev libsqlite3-dev git

WORKDIR /try-alf
COPY Gemfile* /try-alf/
RUN bundle install

FROM ruby:2.7.2-slim-buster as runtime
WORKDIR /try-alf
COPY --from=build /usr/lib/x86_64-linux-gnu/libsqlite3.so.0 /usr/lib/x86_64-linux-gnu/libsqlite3.so.0 
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY . .

EXPOSE 4000
ENTRYPOINT [ "bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "4000" ]