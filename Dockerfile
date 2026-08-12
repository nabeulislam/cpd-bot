# Use the specified Python 3.11 slim image based on Bookworm
FROM python:3.11-slim-bookworm

# Set working directory
WORKDIR /app

# Install necessary system dependencies in one layer to reduce image size,
# then clean up the apt cache to save space.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libcairo2-dev \
    libgirepository1.0-dev \
    libpango1.0-dev \
    pkg-config \
    gir1.2-pango-1.0 \
    libjpeg62-turbo-dev \
    zlib1g-dev \
    gcc \
    git \
    cmake \
    meson \
    ninja-build && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user 'tle' for better security
RUN useradd -m -s /bin/bash tle

# Copy requirements first to leverage Docker layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Change ownership of the application code to the non-root user
RUN chown -R tle:tle /app

# Switch to the non-root user
USER tle

# Set environment variable for font configuration
ENV FONTCONFIG_FILE=/app/extra/fonts.conf

# Healthcheck to ensure the bot environment is sane (discord package is available)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import discord" || exit 1

# Run the bot
CMD ["python", "-m", "tle"]
