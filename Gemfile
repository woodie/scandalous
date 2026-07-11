source "http://rubygems.org"

ruby "3.1.2", patchlevel: "20"

gem "mail"
gem "sinatra"
gem "puma", "~> 8.0"
gem "rackup", "~> 2.3"
gem "midi-smtp-server", "~> 3.1.2"
gem "dotenv"
# Local dev reference while adopting humane-ruby v0.9.0's new API -- not yet
# published. Revert to a version pin (gem "humane", "~> 0.9") once it's
# tagged, pushed, and released to RubyGems -- see docs/releases/2.7.0.md.
gem "humane", path: "../humane-ruby"

group :development do
  gem "pry"
  gem "standardrb"
end

group :test do
  gem "rack-test"
  gem "rspec"
  gem "rspec-html-matchers", "~> 0.10.0"
end
