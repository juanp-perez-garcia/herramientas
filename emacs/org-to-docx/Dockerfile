FROM python:3.12.3-slim

# Install pandoc and emacs
RUN apt-get update && apt-get install -y pandoc emacs-nox && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY elisp/ elisp/
COPY scripts/ scripts/
RUN chmod +x scripts/entry-point.sh
RUN chmod +x scripts/md-to-org.sh
RUN chmod +x scripts/run-export.sh

# Set environment
ENV PYTHONPATH=/app
ENV PROJECT_ROOT=/app

ENTRYPOINT ["/app/scripts/entry-point.sh"]
