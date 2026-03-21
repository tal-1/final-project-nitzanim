#!/bin/bash
set -e

# If no arguments are passed from AWS, run the normal web server
if [ $# -eq 0 ]; then
    echo "Starting Gunicorn server..."
    exec gunicorn -c statuspage/contrib/gunicorn.py statuspage.wsgi

# If AWS passes a command (like "python manage.py migrate"), execute that instead!
else
    echo "Executing command: $@"
    exec "$@"
fi
