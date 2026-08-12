# Stage 1: Builder
FROM dhi.io/python:3.14-alpine-dev AS builder

# Install build dependencies
RUN apk add --no-cache build-base

# Install uv
RUN pip install --no-cache-dir --upgrade pip setuptools wheel uv

WORKDIR /app

# Copy project files
COPY pyproject.toml ./
COPY src/ ./src/

# Install dependencies into a virtual environment
RUN uv pip install --system .

# Stage 2: Runtime
FROM dhi.io/python:3.14-alpine

# Set working directory
WORKDIR /app

# Copy Python packages and scripts from builder
COPY --from=builder /usr/lib/python3.14/site-packages /usr/lib/python3.14/site-packages
COPY --from=builder /usr/bin /usr/bin

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

# Run gunicorn directly (runtime image may not include a shell)
ENTRYPOINT ["gunicorn", "--forwarded-allow-ips=127.0.0.1", "--bind", "0.0.0.0:5000", "--workers", "2", "--worker-class", "sync", "--timeout", "120", "--access-logfile", "-", "--error-logfile", "-", "employee_dialogue:app"]
