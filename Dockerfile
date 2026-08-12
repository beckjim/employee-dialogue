# Stage 1: Builder
FROM dhi.io/python:3.14-alpine-dev AS builder

ARG APP_VERSION=0.1.0

# Install build dependencies
RUN apk add --no-cache build-base

# Keep build tooling in builder only
RUN pip install --no-cache-dir --root-user-action ignore --upgrade pip setuptools wheel

WORKDIR /app

# Copy project files
COPY pyproject.toml ./
COPY src/ ./src/

# Install only runtime dependencies into an isolated target directory
RUN pip install --no-cache-dir --root-user-action ignore --target /opt/appdeps .

# Stage 2: Runtime
FROM dhi.io/python:3.14-alpine

ARG APP_VERSION=0.1.0
LABEL org.opencontainers.image.title="employee-dialogue"
LABEL org.opencontainers.image.version="$APP_VERSION"

# Set working directory
WORKDIR /app

# Copy only app/runtime dependencies from builder
COPY --from=builder /opt/appdeps /opt/appdeps

# Ensure the instance directory exists in the image
WORKDIR /app/instance
WORKDIR /app

# Run as non-root numeric UID/GID
USER 1000:1000

# Expose port 5000
EXPOSE 5000

# Set environment variables
ENV FLASK_APP=employee_dialogue
ENV FLASK_INSTANCE_PATH=/app/instance
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV SKIP_DB_INIT=1
ENV APP_VERSION=$APP_VERSION
ENV PYTHONPATH=/opt/appdeps

# Run gunicorn directly (runtime image may not include a shell)
ENTRYPOINT ["python", "-m", "gunicorn", "--forwarded-allow-ips=127.0.0.1", "--bind", "0.0.0.0:5000", "--workers", "2", "--worker-class", "sync", "--timeout", "120", "--access-logfile", "-", "--error-logfile", "-", "employee_dialogue:app"]
