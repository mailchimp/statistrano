source 'https://rubygems.org'

gemspec

group :document do
  gem "yard"
end

group :debug do
  if RUBY_VERSION >= "2.0"
    gem "pry-byebug",   "~> 1.2"
  else
    gem "pry-debugger", "~> 0.2.2"
  end
end

group :test do
  gem "rspec", "~> 3.3.0"
  gem "catch_and_release"
  gem "simplecov", "~> 0.10.0", :require => false
end
