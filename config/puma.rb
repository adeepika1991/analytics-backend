# config/puma.rb - SINGLE MODE ONLY
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

port ENV.fetch("PORT") { 4000 }
environment ENV.fetch("RAILS_ENV") { "production" }
plugin :tmp_restart