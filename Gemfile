source "http://rubygems.org"

ruby "3.1.2", patchlevel: "20"

gem "mail"
gem "sinatra"
gem "puma", "~> 8.0"
gem "rackup", "~> 2.3"
gem "midi-smtp-server", "~> 3.1.2"
gem "dotenv"
gem "humane", git: "https://github.com/woodie/humane-ruby", tag: "v0.1.0" # not yet on RubyGems.org; swap for a version pin once published

group :development do
  gem "pry"
  gem "standardrb"
end

group :test do
  gem "rack-test"
  gem "rspec"
  gem "rspec-html-matchers", "~> 0.10.0"
end
