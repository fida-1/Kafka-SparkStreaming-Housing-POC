from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col, explode, struct
from pyspark.sql.types import ArrayType, StructType, StructField, StringType, FloatType
import psycopg2
from psycopg2 import sql

spark = SparkSession.builder \
    .appName("KafkaSparkStreamingToPostgres") \
    .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1,org.postgresql:postgresql:42.6.0") \
    .getOrCreate()

# Define schema for each housing record (506 Boston Housing records)
schema = StructType([
    StructField("crim", StringType()),
    StructField("zn", StringType()),
    StructField("indus", StringType()),
    StructField("chas", StringType()),
    StructField("nox", StringType()),
    StructField("rm", StringType()),
    StructField("age", StringType()),
    StructField("dis", StringType()),
    StructField("rad", StringType()),
    StructField("tax", StringType()),
    StructField("ptratio", StringType()),
    StructField("b", StringType()),
    StructField("lstat", StringType()),
    StructField("medv", StringType())
])

# Define batch schema (array of records)
batch_schema = ArrayType(schema)

# Read from Kafka (temps réel streaming)
df = spark \
    .readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "kafka:29092") \
    .option("subscribe", "housing-data") \
    .option("startingOffsets", "earliest") \
    .load()

# Parse JSON batch (désérialisation)
parsed_df = df.selectExpr("CAST(value AS STRING)") \
    .select(from_json(col("value"), batch_schema).alias("batch")) \
    .select(explode(col("batch")).alias("record"))

# Use built-in Spark SQL functions for reliable numeric parsing
from pyspark.sql.functions import col, regexp_replace, trim

# Flatten and cast with proper handling of space-padded strings
flattened_df = parsed_df.select(
    # First trim spaces, then cast to handle "  18.00 " format
    regexp_replace(trim(col("record.crim")), "^$", "0").cast("float").alias("crim"),
    regexp_replace(trim(col("record.zn")), "^$", "0").cast("float").alias("zn"),
    regexp_replace(trim(col("record.indus")), "^$", "0").cast("float").alias("indus"),
    regexp_replace(trim(col("record.chas")), "^$", "0").cast("int").alias("chas"),
    regexp_replace(trim(col("record.nox")), "^$", "0").cast("float").alias("nox"),
    regexp_replace(trim(col("record.rm")), "^$", "0").cast("float").alias("rm"),
    regexp_replace(trim(col("record.age")), "^$", "0").cast("float").alias("age"),
    regexp_replace(trim(col("record.dis")), "^$", "0").cast("float").alias("dis"),
    regexp_replace(trim(col("record.rad")), "^$", "0").cast("int").alias("rad"),
    regexp_replace(trim(col("record.tax")), "^$", "0").cast("int").alias("tax"),
    regexp_replace(trim(col("record.ptratio")), "^$", "0").cast("float").alias("ptratio"),
    regexp_replace(trim(col("record.b")), "^$", "0").cast("float").alias("b"),
    regexp_replace(trim(col("record.lstat")), "^$", "0").cast("float").alias("lstat"),
    regexp_replace(trim(col("record.medv")), "^$", "0").cast("float").alias("medv")
)

def write_to_postgres_housing(df, epoch_id):
    print(f"🏠 [HOUSING PIPELINE] Writing batch epoch_id: {epoch_id} to PostgreSQL")
    # Connect to PostgreSQL
    conn = psycopg2.connect(
        host="postgres",
        port=5432,
        database="kafka_streaming",
        user="kafka_user",
        password="kafka_pass"
    )
    cur = conn.cursor()

    # The housing table is created by init.sql at container startup
    # with all proper columns (crim, zn, indus, chas, nox, rm, age, dis, rad, tax, ptratio, b, lstat, medv)

    # Insert housing data (each record from microbatch)
    raw_values = [tuple(row) for row in df.collect()]
    print(f"📊 [HOUSING] Processing {len(raw_values)} housing records from microbatch")

    # 🚨 CRITICAL FIX: Clean NULL characters (\u0000) from Java strings
    values = []
    for row in raw_values:
        cleaned_row = []
        for field in row:
            if isinstance(field, str):
                # Remove NULL characters and clean up the string
                cleaned_field = field.replace('\x00', '').strip()
                # Try to convert numeric strings to float, keep as string if fails
                try:
                    # Remove any extra spaces and convert to float
                    cleaned_field = float(cleaned_field.replace(' ', ''))
                    cleaned_row.append(cleaned_field)
                except (ValueError, AttributeError):
                    cleaned_row.append(cleaned_field)
            else:
                cleaned_row.append(field)
        values.append(tuple(cleaned_row))

    if values:
        try:
            # Insert into housing table with all 14 columns
            cur.executemany("""
                INSERT INTO housing (crim, zn, indus, chas, nox, rm, age, dis, rad, tax, ptratio, b, lstat, medv)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, values)
            conn.commit()
            print(f"✅ [HOUSING SUCCESS] Inserted {len(values)} housing records into 'housing' table")
            print(f"🎯 SAMPLE DATA: CRIM={values[0][0] if len(values) > 0 else 'N/A'}, MEDV={values[0][13] if len(values) > 0 and len(values[0]) > 13 else 'N/A'}")

        except Exception as e:
            print(f"❌ [HOUSING ERROR] Insertion failed: {str(e)}")
            conn.rollback()
    else:
        print("⚠️ [HOUSING] No housing data to insert")

    cur.close()
    conn.close()

# Write to PostgreSQL in real-time streaming mode
query = flattened_df.writeStream \
    .foreachBatch(write_to_postgres_housing) \
    .start()

query.awaitTermination()
