ARG RUBY_IMAGE=ruby:2.6-alpine

# BUILD_PACKAGES, add if needed: git postgresql-dev tzdata ...
ARG BUILD_PACKAGES='build-base git'

# If needed add BUILD_TEST_PACKAGES and TEST_PACKAGES

# RUN_PACKAGES, add if needed: postgresql-client ...
ARG RUN_PACKAGES='tzdata'

# Stage: Builder (production build)
##########################################
FROM $RUBY_IMAGE as Builder

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

# Add userapp for security reasons (no root access), only execute code after this
# Add group with GID 1000 name app, adduser with UID 1000 name app to group app
RUN addgroup -g 1000 -S app && adduser -u 1000 -S app -G app
USER app

# Copy gems from Builder
COPY --from=TestBuilder /usr/local/bundle/ /usr/local/bundle/

# Copy code
COPY --chown=app:app . /app

WORKDIR /app

# Test script, change if needed
ENTRYPOINT ["rake", "test", "-v"]

# Stage: Server (production, or local server)
##########################################
FROM $RUBY_IMAGE as Server

# Add Alpine packages
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
