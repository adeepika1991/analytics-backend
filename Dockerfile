# syntax=docker/dockerfile:1
# check=error=true

# ---- Base Image ----
    ARG RUBY_VERSION=3.3.6
    FROM ruby:$RUBY_VERSION-slim AS base
    
    WORKDIR /rails
    
    # Install only essentials
    RUN apt-get update -qq && \
        apt-get install --no-install-recommends -y curl libjemalloc2 build-essential git libyaml-dev pkg-config && \
        rm -rf /var/lib/apt/lists /var/cache/apt/archives
    
    # ---- Environment ----
    ENV RAILS_ENV=production \
        BUNDLE_DEPLOYMENT=1 \
        BUNDLE_PATH=/usr/local/bundle \
        BUNDLE_WITHOUT="development test"
    
    # ---- Install Gems ----
    COPY Gemfile Gemfile.lock ./
    RUN bundle install && \
        rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git
    
    # ---- Copy Application ----
    COPY . .
    
    # ---- Non-root User ----
    RUN groupadd --system rails && \
        useradd --system --gid rails --create-home rails && \
        chown -R rails:rails log tmp
    USER rails
    
    # ---- Entrypoint ----
    ENTRYPOINT ["/rails/bin/docker-entrypoint"]
    
    # ---- Port ----
    EXPOSE ${PORT:-4000}
    
    # ✅ Run Puma (uses your config/puma.rb which already respects ENV['PORT'])
    CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
    