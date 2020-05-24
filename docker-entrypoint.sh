#!/bin/bash

# Fix permissions
chown -R www-data:www-data /var/www

# Verify that some files exist, and have contents
if [ ! -e /var/www/data/environment.php ]; then
  echo "/var/www/data/environment.php not found, creating..."
  cp -r /var/www/data/environment.sample.php /var/www/data/environment.php
  echo "Please edit this file with your environment's configuration."
  exit 1
fi

if [ ! -e /var/www/data/key.pem ]; then
  echo "/var/www/data/key.pem not found, creating..."
  cp -r /var/www/data/key.sample.pem /var/www/data/key.pem
  echo "Please edit this file with your base64 encoded RSA private key."
  exit 1
fi

# Start the first process
nginx
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start nginx: $status"
  exit $status
fi

# Start the second process
php-fpm
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start php-fpm: $status"
  exit $status
fi

# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

while sleep 60; do
  ps aux | grep nginx | grep -q -v grep
  NGINX_STATUS=$?
  ps aux | grep php-fpm | grep -q -v grep
  PHP_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $NGINX_STATUS -ne 0 -o $PHP_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done