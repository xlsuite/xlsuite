#!/bin/sh
RAILS_ENV=development
rake db:migrate
nice rake test
