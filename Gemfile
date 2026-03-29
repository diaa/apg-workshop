source "https://rubygems.org"

gem "jekyll", "~> 4.4"
gem "minima", "~> 2.5"
gem "webrick", "~> 1.9"

# Gems removed from Ruby 3.4+ stdlib
gem "csv"
gem "logger"
gem "base64"
gem "bigdecimal"

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.17"
end

# Windows-only dependencies
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "wdm", "~> 0.1", :platforms => [:mingw, :x64_mingw, :mswin]
