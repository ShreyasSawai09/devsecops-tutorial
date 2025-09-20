FROM python:3.9-slim

# Vulnerability: Running as root user
# Best practice would be to create a non-root user

WORKDIR /app

# Copy requirements first for better layer caching
COPY requirements.txt .

# Vulnerability: Installing packages without version pinning in some cases
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create uploads directory
RUN mkdir -p uploads

# Vulnerability: Exposing application on all interfaces
# Best practice would be to use 127.0.0.1 or specific interface
EXPOSE 5000

# Vulnerability: Running with debug mode and broad network access
CMD ["python", "app.py"]