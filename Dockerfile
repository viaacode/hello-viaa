ARG RUBY_IMAGE=ruby:2.6-alpine

# BUILD_PACKAGES, add if needed: git postgresql-dev tzdata ...
ARG BUILD_PACKAGES='build-base'

# Required packages for vanilla Rails API 5.2.2
# ARG BUILD_PACKAGES='build-base sqlite-dev'
# ARG BUILD_TEST_PACKAGES='build-base'
# ARG TEST_PACKAGES='tzdata sqlite-libs'
# ARG RUN_PACKAGES='tzdata sqlite-libs'

# RUN_PACKAGES, add if needed: postgresql-client ...
ARG RUN_PACKAGES='tzdata'

# Stage: Builder (production build)
##########################################
FROM $RUBY_IMAGE as Builder

# https://github.com/moby/moby/issues/34715, bryanlarsen commented on 12 Sep 2018, must be unique per stage
# Line after FROM should be unique per stage so that multiple image --cache-from in docker build works correctly
RUN echo '=== Builder ==='

# Redeclare ARG otherwise it's empty after FROM
ARG BUILD_PACKAGES
RUN apk add --update --no-cache $BUILD_PACKAGES

COPY Gemfile* /

# Install production gems
# Freeze Gemfile
# Delete all files that are not needed
RUN bundle config --global frozen 1 \
 && bundle install --without development test -j4 --retry 3 \
 # Remove unneeded files (cached *.gem, *.o, *.c)
 && rm -rf /usr/local/bundle/cache/*.gem \
 && find /usr/local/bundle/gems/ -name "*.c" -delete \
 && find /usr/local/bundle/gems/ -name "*.o" -delete

# Stage: TestBuilder (production + test build)
##########################################
FROM $RUBY_IMAGE as TestBuilder

# https://github.com/moby/moby/issues/34715, bryanlarsen commented on 12 Sep 2018, must be unique per stage
# Line after FROM should be unique per stage so that multiple image --cache-from in docker build works correctly
RUN echo '=== TestBuilder ==='

# ARG BUILD_TEST_PACKAGES
# RUN apk add --update --no-cache $BUILD_TEST_PACKAGES

# Copy gems from Builder
COPY --from=Builder /usr/local/bundle/ /usr/local/bundle/

# Copy Gemfiles
COPY Gemfile* /

# Install test gems on top of production gems
# Delete without key in global bundle config (still set to development:test)
# Delete all files that are not needed
RUN bundle config --delete without \
 && bundle install --without development \
 # Remove unneeded files (cached *.gem, *.o, *.c)
 && rm -rf /usr/local/bundle/cache/*.gem \
 && find /usr/local/bundle/gems/ -name "*.c" -delete \
 && find /usr/local/bundle/gems/ -name "*.o" -delete

# Stage: Test (test)
##########################################
FROM $RUBY_IMAGE as Test

# https://github.com/moby/moby/issues/34715, bryanlarsen commented on 12 Sep 2018, must be unique per stage
# Line after FROM should be unique per stage so that multiple image --cache-from in docker build works correctly
RUN echo '=== Test ==='

# ARG TEST_PACKAGES
# RUN apk add --update --no-cache $TEST_PACKAGES

# Add userapp for security reasons (no root access), only execute code after this
# Add group with GID 1000 name app, adduser with UID 1000 name app to group app
RUN addgroup -g 1000 -S app && adduser -u 1000 -S app -G app
USER app

# Copy gems from Builder
COPY --from=TestBuilder /usr/local/bundle/ /usr/local/bundle/

# Copy code
COPY --chown=app:app . /app

WORKDIR /app

# Test script, change if needed, CMD instead of ENTRYPOINT so it can be run by Gitlab Docker executor and substituted for e.g. syntax tests
CMD ["rake", "test"]

# Stage: Server (production, or local server)
##########################################
FROM $RUBY_IMAGE as Server

# https://github.com/moby/moby/issues/34715, bryanlarsen commented on 12 Sep 2018, must be unique per stage
# Line after FROM should be unique per stage so that multiple image --cache-from in docker build works correctly
RUN echo '=== Server ==='

# Redeclare ARG otherwise it's empty after FROM
ARG RUN_PACKAGES
RUN apk add --update --no-cache $RUN_PACKAGES

# Add userapp for security reasons (no root access), only execute code after this
# Add group with GID 1000 name app, adduser with UID 1000 name app to group app
RUN addgroup -g 1000 -S app && adduser -u 1000 -S app -G app
USER app

# Copy gems from Builder
COPY --from=Builder /usr/local/bundle/ /usr/local/bundle/

# Copy code
COPY --chown=app:app . /app

WORKDIR /app

# Expose server, change port if needed
EXPOSE 4567

ENTRYPOINT ["ruby", "app/hello_world.rb"]

# Inspired by https://www.georg-ledermann.de/blog/2018/04/19/dockerize-rails-the-lean-way/
# https://medium.com/iron-io-blog/how-to-create-a-tiny-docker-image-for-your-ruby-app-f8d7d622d80b
# https://blog.codeship.com/build-minimal-docker-container-ruby-apps/
# https://docs.docker.com/develop/develop-images/multistage-build/
# https://gist.github.com/anonoz/b56e4e32b8c9252a3085fae74b78a7c8
# https://medium.com/@mccode/processes-in-containers-should-not-run-as-root-2feae3f0df3b

