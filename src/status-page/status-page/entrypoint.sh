#!/bin/bash
# entrypoint.sh

echo "Starting Gunicorn server..."
# Start the server
exec gunicorn -c contrib/gunicorn.py statuspage.wsgi
