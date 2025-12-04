# ✅ CONFIGURATION FINALE - VÉRIFICATION PRÉALABLE

## 🎯 Avant de Lancer: Checklist

### 1️⃣ Vérifier Docker
```powershell
docker --version
docker-compose --version
```
✅ **Attendu:** Docker version 20.10+ et Docker Compose 2.0+

### 2️⃣ Vérifier Java
```powershell
java -version
```
✅ **Attendu:** Java 11 ou plus

### 3️⃣ Vérifier Maven
```powershell
mvn --version
```
✅ **Attendu:** Maven 3.6.0+

### 4️⃣ Vérifier le Dossier du Projet
```powershell
Test-Path "C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming"
```
✅ **Attendu:** `True`

### 5️⃣ Vérifier les Fichiers Critiques
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
Test-Path "docker-compose.yml"
Test-Path "producer/pom.xml"
Test-Path "producer/housing.csv"
Test-Path "consumer/consumer.py"
Test-Path "init.sql"
```
✅ **Attendu:** Tous `True`

### 6️⃣ Vérifier les Ports Disponibles
```powershell
# Vérifier que les ports ne sont pas utilisés
netstat -ano | findstr :9092     # Kafka
netstat -ano | findstr :5432     # PostgreSQL
netstat -ano | findstr :8080     # Spark
netstat -ano | findstr :5050     # PgAdmin
```
✅ **Attendu:** Pas de résultats (ports libres)

### 7️⃣ Vérifier l'Espace Disque
```powershell
# Au moins 5 GB libre pour les images Docker
Get-Volume C: | Select-Object SizeRemaining
```
✅ **Attendu:** SizeRemaining > 5 GB

---

## 🐳 Configuration Docker

### docker-compose.yml (Vérifications)

```yaml
# ✅ Services (7 total)
services:
  - zookeeper         ✅
  - kafka            ✅
  - postgres         ✅
  - spark-master     ✅
  - spark-worker     ✅
  - kafka-ui         ✅
  - pgadmin          ✅

# ✅ Ports
  zookeeper: 2181    ✅
  kafka: 9092        ✅
  postgres: 5432     ✅
  spark: 8080, 7077  ✅
  kafka-ui: 8082     ✅
  pgadmin: 5050      ✅
```

### Fichiers SQL (init.sql)

✅ Table `housing` créée
✅ Colonne `id SERIAL PRIMARY KEY`
✅ Colonne `created_at TIMESTAMP`
✅ Indexes sur `medv` et `created_at`

### Fichiers de Configuration

✅ `producer/pom.xml` - Dépendances Maven OK
✅ `consumer/consumer.py` - Code Spark OK
✅ `producer/housing.csv` - Données présentes (506 records)

---

## 📝 Scripts de Démarrage

### create_topic.sh ✅
```bash
docker exec kafka kafka-topics --create \
  --topic housing-data \
  --bootstrap-server localhost:9092 \
  --partitions 1 \
  --replication-factor 1
```

### submit_consumer.sh ✅
```bash
#!/bin/bash
echo "Waiting for Spark cluster to be ready..."
sleep 15

docker cp consumer/consumer.py spark-master:/opt/spark/work-dir/consumer.py
docker exec spark-master pip install psycopg2-binary > /dev/null 2>&1
docker exec spark-master /opt/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1,org.postgresql:postgresql:42.6.0 \
  /opt/spark/work-dir/consumer.py
```

---

## ☕ Code Java (KafkaProducerApp.java)

✅ Lecture du CSV
✅ Microbatches de 100 records
✅ Sérialisation JSON
✅ Envoi à Kafka

```java
private static final int BATCH_SIZE = 100;  // ✅ Correct
private static final String TOPIC = "housing-data";  // ✅ Correct
```

---

## 🐍 Code Spark (consumer.py)

✅ Lecture depuis Kafka
✅ Parsing JSON
✅ Cast des types
✅ Écriture dans PostgreSQL

```python
# ✅ Connexion PostgreSQL correcte
conn = psycopg2.connect(
    host="postgres",  # ✅ Nom du container
    port=5432,
    database="kafka_streaming",
    user="kafka_user",
    password="kafka_pass"
)
```

---

## 📊 Variables d'Environnement Docker

### PostgreSQL
```yaml
POSTGRES_DB: kafka_streaming        ✅
POSTGRES_USER: kafka_user           ✅
POSTGRES_PASSWORD: kafka_pass       ✅
```

### Kafka
```yaml
KAFKA_BROKER_ID: 1                  ✅
KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181  ✅
KAFKA_ADVERTISED_LISTENERS: 
  PLAINTEXT://kafka:29092,
  PLAINTEXT_HOST://localhost:9092   ✅
```

### Spark
```yaml
SPARK_MODE: master / worker         ✅
SPARK_RPC_AUTHENTICATION_ENABLED: no  ✅
```

---

## 🔗 Connectivité (Intra-Docker)

| Component | Internal Name | Port | Protocol |
|-----------|--------------|------|----------|
| Kafka | kafka | 29092 | PLAINTEXT |
| PostgreSQL | postgres | 5432 | psycopg2 |
| Spark Master | spark-master | 7077 | Spark Protocol |
| Zookeeper | zookeeper | 2181 | Zookeeper |

✅ **Tous les noms de host correspondent aux noms de container**

---

## 🌐 Connectivité (Externe - Localhost)

| Service | URL | Port | Accès |
|---------|-----|------|-------|
| Kafka | localhost | 9092 | ✅ Producer |
| Kafka UI | localhost:8082 | 8082 | ✅ Browser |
| Spark Master | localhost:8080 | 8080 | ✅ Browser |
| Spark Worker | localhost:8081 | 8081 | ✅ Browser |
| PgAdmin | localhost:5050 | 5050 | ✅ Browser |

---

## 🔐 Credentials Vérifiés

### PostgreSQL
- User: `kafka_user` ✅
- Password: `kafka_pass` ✅
- Database: `kafka_streaming` ✅
- Host: `postgres` ✅
- Port: `5432` ✅

### PgAdmin
- Email: `admin@example.com` ✅
- Password: `admin` ✅

### Kafka (pas de credentials)
- Bootstrap: `localhost:9092` ✅
- Internal: `kafka:29092` ✅

---

## 📦 Dépendances Vérifiées

### Maven (pom.xml)
```xml
✅ org.apache.kafka:kafka-clients:3.4.0
✅ com.fasterxml.jackson.core:jackson-databind:2.15.2
```

### Spark Packages (--packages)
```
✅ org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1
✅ org.postgresql:postgresql:42.6.0
```

### Python (pip)
```
✅ psycopg2-binary (installé automatiquement)
```

---

## 🧪 Tests Préalables

### Test 1: Docker fonctionne
```powershell
docker run --rm hello-world
```
✅ **Attendu:** "Hello from Docker!"

### Test 2: Les ports sont libres
```powershell
# Kafka
Test-NetConnection -ComputerName localhost -Port 9092
# PostgreSQL
Test-NetConnection -ComputerName localhost -Port 5432
```
✅ **Attendu:** `TcpTestSucceeded : False` (port libre)

### Test 3: Java compile
```powershell
cd producer
mvn compile
```
✅ **Attendu:** Pas d'erreurs

### Test 4: CSV existe
```powershell
(Get-Item "producer/housing.csv").Length -gt 0
```
✅ **Attendu:** `True`

---

## ⚙️ Configurations Personnalisées (Optionnel)

### Augmenter Batch Size
**Fichier:** `producer/src/main/java/com/example/KafkaProducerApp.java`
```java
// De:
private static final int BATCH_SIZE = 100;
// À:
private static final int BATCH_SIZE = 500;
```
Puis: `mvn clean package`

### Augmenter Partitions Kafka
**Fichier:** `create_topic.sh`
```bash
# De:
--partitions 1
# À:
--partitions 4
```
Puis: `bash create_topic.sh`

### Augmenter Mémoire Spark
**Fichier:** `docker-compose.yml` (spark-master et spark-worker)
```yaml
environment:
  SPARK_DRIVER_MEMORY: 4g
  SPARK_EXECUTOR_MEMORY: 2g
```
Puis: `docker-compose up -d`

### Changer Credentials PostgreSQL
**Fichier:** `docker-compose.yml` (postgres)
```yaml
environment:
  POSTGRES_PASSWORD: your_new_password
```
✅ **Attention:** Aussi à jour dans init.sql si nécessaire

---

## 📋 Résumé des Fichiers Modifiés

| Fichier | Modification | ✅ |
|---------|-------------|-----|
| submit_consumer.sh | Exécution DANS le container | ✅ |
| init.sql | ID primaire + timestamp | ✅ |
| docker-compose.yml | PgAdmin password ajouté | ✅ |

---

## 🚨 Points Critiques à Vérifier

✅ **Ordre d'exécution:** Terminal 1 → 2 → 3 → 4
✅ **Attendre:** 20 sec après docker-compose up -d
✅ **Attendre:** 60 sec après que le Producer ait fini
✅ **Soumettre Spark:** AVANT de lancer le Producer
✅ **Ports:** Tous libres et accessibles
✅ **CSV:** Existe et contient 506 records
✅ **Credentials:** Corrects dans tous les fichiers

---

## ✅ PRÊT À LANCER!

Si tous les points ci-dessus sont vérifiés ✅, vous pouvez:

```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
# Puis ouvrir 4 terminaux et suivre QUICK_START_5MIN.md ou TOUTES_LES_COMMANDES.md
```

---

## 🆘 Si Quelque Chose N'est Pas OK

1. **Docker ne marche pas?**
   - Redémarrer Docker Desktop
   - Vérifier: `docker ps`

2. **Maven timeout?**
   - Attendre plus longtemps
   - Ou: `mvn clean package -T 1`

3. **Port déjà utilisé?**
   - Terminer le processus: `netstat -ano | findstr :PORT`
   - Puis: `taskkill /PID <PID> /F`

4. **CSV manquant?**
   - Télécharger Boston Housing dataset
   - Placer dans: `producer/housing.csv`

5. **Credentials incorrects?**
   - Vérifier docker-compose.yml
   - Vérifier init.sql
   - Vérifier KafkaProducerApp.java
   - Vérifier consumer.py

---

## 🎉 Configuration Validée!

Vous êtes prêt à exécuter le pipeline complet!

**Prochaine étape:** Lisez `QUICK_START_5MIN.md` ou `TOUTES_LES_COMMANDES.md`

