FROM ruby:2.5

RUN apt-get update -qq && apt-get install -y build-essential

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD . $APP_HOME

EXPOSE 4567

CMD ["ruby", "app.rb"]
