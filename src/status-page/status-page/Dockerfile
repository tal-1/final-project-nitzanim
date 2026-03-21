# ==========================================
# STAGE 1: Build the Frontend (Node.js)
# ==========================================
FROM node:18-alpine AS frontend-builder
WORKDIR /app/statuspage/project-static
# Copy package files and install dependencies
COPY statuspage/project-static/package.json statuspage/project-static/yarn.lock ./
RUN yarn install
# Copy the rest of the static source code and build
COPY statuspage/project-static/ ./
RUN yarn run bundle

# ==========================================
# STAGE 2: Build the Backend (Python)
# ==========================================
FROM python:3.10-slim
WORKDIR /app

# Install system dependencies required for Postgres and Python packages
RUN apt-get update && apt-get install -y \
    libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copy the Django application code
COPY . .

# Copy the compiled frontend assets from Stage 1
COPY --from=frontend-builder /app/statuspage/project-static/dist /app/statuspage/project-static/dist

# Make the entrypoint script executable
RUN chmod +x /app/entrypoint.sh

# Run the entrypoint script when the container starts
ENTRYPOINT ["/app/entrypoint.sh"]
