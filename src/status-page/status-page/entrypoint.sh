#!/bin/bash
set -e

# If no arguments are passed from AWS, run the normal web server
if [ $# -eq 0 ]; then
    echo "Starting Gunicorn server..."
    # 1. Point to the correct contrib folder
    # 2. Tell Gunicorn to change directory into statuspage so it can find wsgi.py
    exec gunicorn -c contrib/gunicorn.py --chdir statuspage statuspage.wsgi

# If AWS passes a command (like "python manage.py migrate"), execute that instead!
else
    echo "Executing command: $@"
    exec "$@"
fi
