#!/bin/bash
# entrypoint.sh

echo "Gathering static files..."
python statuspage/manage.py collectstatic --noinput

echo "Running database migrations..."
python statuspage/manage.py migrate --noinput

echo "Starting Gunicorn server..."
# Start the server (adjust the path to gunicorn.py if needed)
exec gunicorn -c statuspage/contrib/gunicorn.py statuspage.wsgi
