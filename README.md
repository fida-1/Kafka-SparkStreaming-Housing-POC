# Kafka Spark Streaming to PostgreSQL Pipeline

This project demonstrates a complete data pipeline that reads a CSV file, divides it into microbatches, sends them to Kafka, processes them in real-time with Spark Streaming, and stores the results in PostgreSQL.

## Prerequisites

- Docker
- Docker Compose
- Java 11 (for the Kafka producer)
- Maven (for building the producer)

## Project Structure

```
.
├── data/
│   └── housing.csv          # Boston Housing dataset
├── producer/                # Java Kafka producer
│   ├── pom.xml
│   └── src/main/java/com/example/KafkaProducerApp.java
├── consumer/
│   └── consumer.py          # PySpark consumer
├── docker-compose.yml       # Services configuration
├── init.sql                 # PostgreSQL schema
├── create_topic.sh          # Kafka topic creation script
├── submit_consumer.sh       # Consumer submission script
└── README.md
```

## Setup and Run

1. **Start the services:**
   ```bash
   docker-compose up -d
   ```

2. **Create Kafka topic:**
   ```bash
   chmod +x create_topic.sh
   ./create_topic.sh
   ```

3. **Build and run the producer (ensure Kafka is ready):**
   ```bash
   cd producer
   mvn clean compile
   mvn exec:java
   ```
   This will read `data/housing.csv`, divide into batches of 100 records, and send to Kafka.

4. **Submit the Spark Streaming consumer:**
   ```bash
   chmod +x submit_consumer.sh
   ./submit_consumer.sh
   ```
   This will start the PySpark streaming job that reads from Kafka and writes to PostgreSQL.

5. **Verify results:**
   - **Check data in PostgreSQL:**
     ```bash
     docker exec -it postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
     ```

   - **Web Visualizations:**
     - Spark UI: http://localhost:8080 (cluster status, running jobs)
     - Kafka UI: http://localhost:8082 (topics, messages, consumers)
     - pgAdmin: http://localhost:5050 (database tables, data. Login: admin@example.com / admin)
       - Add server: Host=postgres, User=kafka_user, Pass=kafka_pass, Database=kafka_streaming

   - **View Kafka messages:**
     ```bash
     docker exec -it kafka kafka-console-consumer --topic housing-data --bootstrap-server localhost:9092 --from-beginning
     ```

   - **Monitor logs:**
     ```bash
     docker-compose logs -f kafka  # Kafka logs
     docker-compose logs -f spark-master  # Spark logs
     docker-compose logs -f  # All services
     ```

## Components

- **Zookeeper & Kafka:** Message broker for real-time data distribution
- **PostgreSQL:** Target database for processed data
- **Spark Master & Worker:** Distributed processing cluster
- **Java Producer:** Reads CSV, batches data, sends to Kafka
- **PySpark Consumer:** Streams from Kafka, writes to PostgreSQL

## Data Flow

```
CSV File -> Microbatches -> Kafka -> Spark Streaming -> PostgreSQL
```

The pipeline demonstrates real-time processing of housing data, making it suitable for IoT, financial, or any high-throughput data scenarios.
