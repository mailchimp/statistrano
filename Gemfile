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
  gem "rspec", "~> 3.0.0.beta1"
  gem "catch_and_release"
  gem "reek",  "~> 1.3.1"
  gem "simplecov", "~> 0.8.2", :require => false
end