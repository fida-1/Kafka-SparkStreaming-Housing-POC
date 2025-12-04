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

# Flatten and cast the housing record to proper types
flattened_df = parsed_df.select(
    col("record.crim").cast("float"),
    col("record.zn").cast("float"),
    col("record.indus").cast("float"),
    col("record.chas").cast("int"),
    col("record.nox").cast("float"),
    col("record.rm").cast("float"),
    col("record.age").cast("float"),
    col("record.dis").cast("float"),
    col("record.rad").cast("int"),
    col("record.tax").cast("int"),
    col("record.ptratio").cast("float"),
    col("record.b").cast("float"),
    col("record.lstat").cast("float"),
    col("record.medv").cast("float")
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
    values = [tuple(row) for row in df.collect()]
    print(f"📊 [HOUSING] Processing {len(values)} housing records from microbatch")

    if values:
        try:
            # Insert into housing table with all 14 columns
            cur.executemany("""
                INSERT INTO housing (crim, zn, indus, chas, nox, rm, age, dis, rad, tax, ptratio, b, lstat, medv)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, values)
            conn.commit()
            print(f"✅ [HOUSING SUCCESS] Inserted {len(values)} housing records into 'housing' table")

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
