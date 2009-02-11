#!/bin/sh
mongrel_rails stop >/dev/null 2>&1
sleep 1
rm log/mongrel*.pid >/dev/null 2>&1
FERRET_USE_LOCAL_INDEX=1 mongrel_rails start -p 5789 -e ${RAILS_ENV=development} 2>&1 -d
