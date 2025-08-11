FROM ruby:3.1

WORKDIR /app

# Copy gemspec and Gemfile first for better layer caching
COPY cssminify2.gemspec Gemfile ./
COPY lib/cssminify2/version.rb ./lib/cssminify2/

# Install dependencies
RUN bundle install

# Copy the rest of the application
COPY . .

# Run tests by default
CMD ["bundle", "exec", "rspec"]