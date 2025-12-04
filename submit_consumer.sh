# Powershell equivalent
# Wait for Spark cluster to be ready
Write-Host "Waiting for Spark cluster to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Copy consumer.py to Spark master container for submission
Write-Host "Copying consumer.py to Spark container..." -ForegroundColor Yellow
docker cp consumer/consumer.py spark-master:/opt/spark/work-dir/consumer.py

# Install psycopg2 inside the container as root to avoid permission issues
Write-Host "Installing psycopg2-binary..." -ForegroundColor Yellow
docker exec --user root spark-master pip install psycopg2-binary

# Submit the PySpark streaming job (WITHIN the container) as root
Write-Host "Submitting Spark Streaming job..." -ForegroundColor Yellow
docker exec --user root spark-master /opt/spark/bin/spark-submit `
  --master spark://spark-master:7077 `
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1,org.postgresql:postgresql:42.6.0 `
  /opt/spark/work-dir/consumer.py
