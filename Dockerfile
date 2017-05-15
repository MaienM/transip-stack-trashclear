FROM ruby
MAINTAINER Michon van Dooren <michon1992@gmail.com>

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install --frozen
ADD trashclear.rb .

CMD ["ruby", "trashclear.rb"]
