from pyspark.sql import SparkSession
from pyspark.sql.functions import col
import json

spark = SparkSession.builder \
    .appName("TestKafkaRead") \
    .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1") \
    .getOrCreate()

# Simple read from Kafka
df = spark \
    .readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "kafka:29092") \
    .option("subscribe", "housing-data") \
    .option("startingOffsets", "earliest") \
    .option("groupId", "spark-consumer-test") \
    .option("auto.offset.reset", "earliest") \
    .load()

# Print raw values
def process_batch(df, epoch_id):
    print(f"Batch {epoch_id}: {df.count()} messages")
    if df.count() > 0:
        rows = df.collect()
        for row in rows:
            value = row.value.decode('utf-8') if isinstance(row.value, bytes) else str(row.value)
            print(f"Message: {value[:500]}...")

            # Try to parse JSON
            try:
                batch_data = json.loads(value)
                print(f"Parsed JSON array with {len(batch_data)} records")
                if len(batch_data) > 0:
                    print(f"First record: {batch_data[0]}")
            except Exception as e:
                print(f"JSON parsing error: {e}")

# Process in microbatches
query = df.writeStream \
    .foreachBatch(process_batch) \
    .option("checkpointLocation", "/tmp/checkpoint_test_debug") \
    .start()

print("Starting test consumer...")
query.awaitTermination()
