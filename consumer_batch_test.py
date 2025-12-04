from pyspark.sql import SparkSession
from pyspark.sql.functions import col

spark = SparkSession.builder \
    .appName("KafkaBatchTest") \
    .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1") \
    .getOrCreate()

df = spark \
    .read \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "kafka:29092") \
    .option("subscribe", "housing-data") \
    .option("startingOffsets", "earliest") \
    .load()

print(f"Messages RAW dans Kafka: {df.count()}")

parsed_df = df.selectExpr("CAST(value AS STRING) as json") \
    .select("json")

print("Premier message JSON:")
mensajes = parsed_df.limit(1).collect()
if len(mensajes) > 0:
    print(mensajes[0].json)
else:
    print("Aucune donnée trouvée")

spark.stop()
