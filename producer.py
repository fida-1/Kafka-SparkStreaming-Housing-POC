import pandas as pd
from kafka import KafkaProducer
import json
import time

def main():
    # Utilisation d'un CSV simple standard avec virgules
    df = pd.read_csv('housing_simple.csv')
    print(f"Fichier CSV chargé avec succès: {df.shape[0]} lignes, {df.shape[1]} colonnes")

    producer = KafkaProducer(
        bootstrap_servers=['kafka:29092'],
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )

    print(f"Lecture de {len(df)} lignes depuis le CSV")

    for i in range(0, len(df), 50):
        batch = df.iloc[i:i+50].to_dict('records')
        producer.send('housing-data', batch)
        producer.flush()
        print(f"Envoyé batch de {len(batch)} records à Kafka")
        time.sleep(1)  # Petite pause

    producer.close()
    print("Tous les enregistrements envoyés à Kafka !")

if __name__ == "__main__":
    main()
