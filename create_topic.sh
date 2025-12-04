#!/bin/bash

# Wait for Kafka to be ready
sleep 10

# Create topic
docker exec kafka kafka-topics --create --topic housing-data --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
