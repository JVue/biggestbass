FROM ruby:2.4.0

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

RUN gem install pg json sinatra sinatra-contrib sinatra-namespace

RUN mkdir /wagerz

# Copy necessary files to container
COPY . /wagerz

WORKDIR /wagerz

# Set entry point
ENTRYPOINT ["/usr/local/bin/ruby"]

# Command to execute
CMD ["./app.rb"]

EXPOSE 8080
