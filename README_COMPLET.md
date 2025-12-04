# 🚀 Pipeline Kafka-Spark Streaming → PostgreSQL

Un pipeline d'ingestion de données en temps réel qui :
1. **Lit** des microbatches d'un CSV via Java Producer
2. **Envoie** les données à Kafka
3. **Traite** les streams avec Spark Streaming
4. **Stocke** les résultats dans PostgreSQL

---

## 📊 Architecture

```
┌─────────────┐
│   housing   │
│   .csv      │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│  Java Producer (100 records)    │
│  - Batch processing             │
│  - JSON serialization           │
└────────────────┬────────────────┘
                 │
                 ▼
        ┌────────────────┐
        │     Kafka      │
        │  Topic: data   │
        └────────┬───────┘
                 │
         ┌───────┴────────┐
         │                │
      ┌──▼──┐         ┌───▼──┐
      │ UI  │         │Spark │
      │8082 │         │8080  │
      └─────┘         └───┬──┘
                          │
        ┌─────────────────┴─────────┐
        │   Spark Streaming Job    │
        │  - Parse JSON              │
        │  - Flatten schema          │
        │  - Type casting            │
        └─────────────────┬─────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │ PostgreSQL  │
                   │   housing   │
                   └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │  PgAdmin    │
                   │    5050     │
                   └─────────────┘
```

---

## 🛠️ Prérequis

- **Docker** et **Docker Compose** installés
- **Java 11+** et **Maven** (pour le Producer)
- **Python 3.8+** (dans les conteneurs Docker)
- **Git Bash** ou **PowerShell** pour exécuter les scripts

---

## 📦 Fichiers du Projet

```
├── docker-compose.yml          # Configuration de tous les services
├── init.sql                    # Schéma PostgreSQL
├── create_topic.sh             # Script création du topic Kafka
├── submit_consumer.sh           # Script soumission du job Spark
├── test_pipeline.sh            # Tests automatisés (Bash)
├── quick_start.ps1             # Quick start interactif (PowerShell)
├── GUIDE_EXECUTION.md          # Guide complet
├── producer/                   # Java Producer
│   ├── pom.xml                # Dépendances Maven
│   ├── src/main/java/...      # Code source
│   └── housing.csv            # Données source
├── consumer/                   # Spark Streaming Consumer
│   └── consumer.py            # Code PySpark
└── data/
    └── housing.csv            # Dataset (Boston Housing)
```

---

## 🚀 Démarrage Rapide (Windows PowerShell)

### Option 1️⃣ : Menu Interactif (Recommandé)

```powershell
# Exécuter le script interactif
powershell -ExecutionPolicy Bypass -File quick_start.ps1

# Ensuite, suivez le menu pour :
# 1. Démarrer les services Docker
# 2. Créer le topic Kafka
# 3. Compiler le Producer
# 4. Exécuter le Producer
# 5. Soumettre le job Spark
```

### Option 2️⃣ : Commandes Manuelles

#### Étape 1: Démarrer Docker
```powershell
docker-compose up -d
Start-Sleep -Seconds 20
```

#### Étape 2: Créer le Topic Kafka
```powershell
docker exec kafka kafka-topics --create `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --partitions 1 `
  --replication-factor 1 `
  --if-not-exists
```

#### Étape 3: Compiler et Exécuter le Producer
```powershell
cd producer
mvn clean package
mvn exec:java@default
```

#### Étape 4: Soumettre le Consumer Spark (Terminal 2)
```powershell
bash submit_consumer.sh
```

#### Étape 5: Vérifier les données (Terminal 3)
```powershell
# Attendre 30-60 secondes que les données arrivent dans PostgreSQL
docker exec -it postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
```

---

## 🚀 Démarrage Rapide (Linux/Mac)

```bash
# Démarrer les services
docker-compose up -d
sleep 20

# Créer le topic
bash create_topic.sh

# Terminal 1: Producer
cd producer && mvn clean package && mvn exec:java@default

# Terminal 2: Consumer
bash submit_consumer.sh

# Terminal 3: Vérifier les données
docker exec -it postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
```

---

## 🌐 Web Interfaces

Ouvrez ces URLs dans votre navigateur :

| Service | URL | Credentials |
|---------|-----|-------------|
| **Kafka UI** | http://localhost:8082 | N/A |
| **Spark Master** | http://localhost:8080 | N/A |
| **Spark Worker** | http://localhost:8081 | N/A |
| **PgAdmin** | http://localhost:5050 | admin@example.com / admin |

### Actions dans chaque interface

#### 🔵 Kafka UI (8082)
- Voir le topic `housing-data`
- Visualiser les messages en temps réel
- Voir les partitions et offsets
- Monitorer les producers/consumers

#### 🟠 Spark Master (8080)
- Applications en cours d'exécution
- Cluster Overview
- Voir l'application Spark Streaming
- Cliquer sur l'app pour voir les détails
- Vérifier les executor status

#### 🐘 PgAdmin (5050)
1. Se connecter: `admin@example.com` / `admin`
2. Ajouter serveur :
   - Hostname: `postgres`
   - Port: `5432`
   - User: `kafka_user`
   - Password: `kafka_pass`
   - Database: `kafka_streaming`
3. Naviguer: `Servers → postgres → Databases → kafka_streaming → Schemas → public → Tables → housing`
4. Clic droit "View All Rows" pour voir les données

---

## ✅ Vérifications de l'Exécution

### 1️⃣ Vérifier que les services sont actifs
```powershell
docker ps
# Doit afficher: zookeeper, kafka, postgres, spark-master, spark-worker, kafka-ui, pgadmin
```

### 2️⃣ Vérifier le topic Kafka
```powershell
docker exec kafka kafka-topics --describe --topic housing-data --bootstrap-server localhost:9092
```

### 3️⃣ Vérifier les messages Kafka
```powershell
docker exec kafka kafka-console-consumer `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --from-beginning `
  --max-messages 2
```

### 4️⃣ Vérifier les données PostgreSQL
```powershell
# Nombre total
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"

# Voir les 10 premiers records
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT * FROM housing LIMIT 10;"

# Statistiques
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*), AVG(medv), MIN(medv), MAX(medv) FROM housing;"
```

### 5️⃣ Vérifier le job Spark
```powershell
# Logs du conteneur Spark
docker logs -f spark-master | tail -20

# Accéder au conteneur
docker exec -it spark-master bash
ls /opt/spark/work-dir/
cat consumer.py
```

---

## 🔄 Flux de Données Complet

```
1. CSV (506 records Boston Housing)
   ↓
2. Java Producer lit le CSV par microbatches (100 records)
   ↓
3. Sérialize en JSON et envoie à Kafka
   ↓
4. Kafka topic "housing-data" reçoit les messages
   ↓
5. Spark Streaming Consumer s'abonne au topic
   ↓
6. Parse le JSON, détecte le type de données
   ↓
7. Cast les types (float, int, etc.)
   ↓
8. Écrit par batch dans PostgreSQL
   ↓
9. Table housing contient les données persistantes
```

---

## 🧪 Test Automatisé

### Bash/Linux/Mac
```bash
bash test_pipeline.sh
```

### PowerShell (Windows)
```powershell
powershell -ExecutionPolicy Bypass -File quick_start.ps1
# Puis choisir option 8 (Run all tests)
```

---

## 🛑 Arrêter le Pipeline

### Arrêter les containers (données persistantes)
```powershell
docker-compose stop
```

### Supprimer les containers
```powershell
docker-compose down
```

### Supprimer complètement (données incluses)
```powershell
docker-compose down -v
```

---

## ⚠️ Troubleshooting

### ❌ "Topic does not exist"
```powershell
bash create_topic.sh
```

### ❌ "Connection refused to kafka:29092"
- Attendre 20-30 secondes après `docker-compose up -d`
- Vérifier que le conteneur kafka est actif: `docker logs kafka`

### ❌ "Can't connect to postgres"
- Vérifier que postgres est prêt: `docker logs postgres`
- Test manuel: `docker exec -it postgres psql -U kafka_user`

### ❌ "Spark job stuck / no data in PostgreSQL"
```powershell
# Voir les logs Spark
docker logs spark-master

# Vérifier que le job s'exécute
docker ps | grep spark

# Redémarrer le job
bash submit_consumer.sh
```

### ❌ "Producer stuck on sending"
- Vérifier Kafka: `docker logs kafka | tail -20`
- Vérifier le fichier CSV existe: `ls producer/housing.csv`
- Redémarrer: `docker-compose restart kafka`

### ❌ "psycopg2 not found in Spark"
- Le script `submit_consumer.sh` installe automatiquement psycopg2
- Si encore erreur: `docker exec spark-master pip install --upgrade psycopg2-binary`

### ❌ "OutOfMemory in Spark"
- Augmenter la mémoire des conteneurs dans `docker-compose.yml`
- Ajouter à `spark-master`:
```yaml
environment:
  SPARK_DRIVER_MEMORY: 2g
  SPARK_EXECUTOR_MEMORY: 1g
```

---

## 📋 Logs et Debugging

### Voir les logs en temps réel
```powershell
docker logs -f kafka          # Kafka
docker logs -f spark-master   # Spark
docker logs -f postgres       # PostgreSQL
```

### Accéder aux conteneurs
```powershell
docker exec -it spark-master bash
docker exec -it postgres bash
docker exec -it kafka bash
```

### Vérifier les ressources
```powershell
docker stats
```

---

## 📊 Schéma PostgreSQL

```sql
CREATE TABLE housing (
    id SERIAL PRIMARY KEY,
    crim DOUBLE PRECISION,
    zn DOUBLE PRECISION,
    indus DOUBLE PRECISION,
    chas INTEGER,
    nox DOUBLE PRECISION,
    rm DOUBLE PRECISION,
    age DOUBLE PRECISION,
    dis DOUBLE PRECISION,
    rad INTEGER,
    tax INTEGER,
    ptratio DOUBLE PRECISION,
    b DOUBLE PRECISION,
    lstat DOUBLE PRECISION,
    medv DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Colonnes
- **crim**: Crime rate per capita
- **zn**: Proportion of residential land
- **indus**: Proportion of industrial business
- **chas**: Charles River dummy variable
- **nox**: Nitrogen oxides concentration
- **rm**: Average number of rooms
- **age**: Proportion of buildings built before 1940
- **dis**: Distance to employment centers
- **rad**: Index of accessibility to radial highways
- **tax**: Property tax rate
- **ptratio**: Pupil-teacher ratio by town
- **b**: 1000(B - 0.63)^2 where B is the proportion of blacks
- **lstat**: Percentage lower status of the population
- **medv**: Median value of homes in $1000s

---

## 🎯 Résultats Attendus

### Producer Output
```
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
Sent batch of 100 records of Kafka
Sent batch of 6 records to Kafka
```

### PostgreSQL Final
```
count
-----
 506

(1 row)
```

### Spark Streaming (visible dans http://localhost:8080)
- Status: RUNNING
- Uptime: variable
- Records processed: 506

---

## 📝 Configuration

### Batch Size (Producer)
```java
private static final int BATCH_SIZE = 100; // Dans KafkaProducerApp.java
```

### Kafka Partition
```yaml
--partitions 1      # Dans create_topic.sh
```

### PostgreSQL Connection
```python
conn = psycopg2.connect(
    host="postgres",
    port=5432,
    database="kafka_streaming",
    user="kafka_user",
    password="kafka_pass"
)
```

---

## 📚 Ressources Utiles

- **Kafka Documentation**: https://kafka.apache.org/documentation/
- **Spark Streaming**: https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html
- **PostgreSQL JDBC**: https://jdbc.postgresql.org/
- **Docker Compose**: https://docs.docker.com/compose/

---

## 🤝 Support

Si vous rencontrez des problèmes :

1. Vérifiez les **logs** : `docker logs <service_name>`
2. Consultez le **GUIDE_EXECUTION.md** pour des détails
3. Testez avec **test_pipeline.sh** ou **quick_start.ps1**
4. Vérifiez les **Web Interfaces** pour le statut en temps réel

---

## ✨ Prochaines Étapes

- Augmenter le batch size pour plus de données
- Ajouter des transformations Spark supplémentaires
- Implémenter des requêtes analytiques PostgreSQL
- Ajouter de la monitoring (Prometheus, Grafana)
- Mettre en place des alertes Kafka

