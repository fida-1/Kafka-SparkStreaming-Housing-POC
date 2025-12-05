Aller au répertoire du projet
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming

# Copier le consumer dans le container Spark
docker cp ./consumer/consumer.py spark-master:/opt/spark/work-dir/consumer.py

Write-Host "Consumer copie dans Spark container" -ForegroundColor Yellow
Start-Sleep -Seconds 2

# Soumettre le job Spark
docker exec --user root spark-master /opt/spark/bin/spark-submit --master local[*] --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1,org.postgresql:postgresql:42.6.0 /opt/spark/work-dir/consumer.py

Write-Host "Spark job soumis avec succes !" -ForegroundColor Green
