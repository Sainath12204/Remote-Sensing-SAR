FROM python:3.12-slim

# Create and set the working directory
WORKDIR /app

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Copy only the requirements file first to leverage Docker caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire application code
COPY . .

# Expose the port your application will run on
EXPOSE 8080

# Specify the command to run on container start
CMD ["gunicorn", "--bind", ":8080", "--workers", "1", "--threads", "8", "--timeout", "0", "app:app"]
