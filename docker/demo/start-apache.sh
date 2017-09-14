#!/bin/bash

if [ -z "$(cat /var/www/index.html | grep 'MY_')" ] ; then
  echo "<br>MY_STATIC_ENV = $MY_STATIC_ENV <br>" >> /var/www/index.html
  echo "MY_BUILD_ENV = $MY_BUILD_ENV <br>" >> /var/www/index.html
fi

echo "MY_RUN_ENV: $(date) = $MY_RUN_ENV <br>" >> /var/www/index.html

exec /usr/sbin/apachectl -DFOREGROUND

