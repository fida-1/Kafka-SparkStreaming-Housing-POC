# Guide Complet - Pipeline Kafka Spark Streaming → PostgreSQL

## 📊 Architecture du Pipeline

```
CSV (housing.csv)
    ↓
Java Producer (microbatches de 100 records)
    ↓
Kafka Topic (housing-data)
    ↓
Spark Streaming Consumer
    ↓
PostgreSQL Database
```

---

## 🚀 ÉTAPE 1 : Démarrer l'Infrastructure Docker

```powershell
# À la racine du projet
docker-compose up -d

# Vérifier que tous les services sont en cours d'exécution
docker ps
```

**Attendez 20-30 secondes** pour que tous les services soient complètement prêts.

---

## ✅ ÉTAPE 2 : Créer le Topic Kafka

```bash
# Exécuter le script de création du topic
bash create_topic.sh
```

Ou manuellement :
```powershell
docker exec kafka kafka-topics --create `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --partitions 1 `
  --replication-factor 1 `
  --if-not-exists
```

**Vérifier que le topic a été créé :**
```powershell
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
```

---

## 🔨 ÉTAPE 3 : Compiler et Exécuter le Producer Java

### 3a) Naviguer et compiler
```powershell
cd producer
mvn clean package
```

### 3b) Exécuter le Producer
```powershell
mvn exec:java@default -Dexec.mainClass="com.example.KafkaProducerApp"
```

Vous verrez des messages comme :
```
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
...
```

---

## 🔄 ÉTAPE 4 : Soumettre le Job Spark Streaming

### À partir de la racine du projet:
```bash
bash submit_consumer.sh
```

Cela va :
1. ✅ Attendre que Spark soit prêt
2. ✅ Copier le script consumer.py
3. ✅ Installer les dépendances Python
4. ✅ Soumettre le job au cluster Spark

**Attendez que vous voyiez :**
```
Sent batch of 100 records to Kafka
```

---

## 📡 ÉTAPE 5 : Vérifier les Web Interfaces

### 🔵 Kafka UI (visualiser les topics et messages)
```
http://localhost:8082
```

**Actions :**
- Voir le topic `housing-data`
- Vérifier les messages en temps réel
- Voir les partitions

### 🟠 Spark Master UI (visualiser les jobs)
```
http://localhost:8080
```

**Actions :**
- Voir le cluster Spark
- Voir les workers connectés
- Monitorer les applications en cours

### 🟠 Spark Worker UI
```
http://localhost:8081
```

**Actions :**
- Voir les ressources utilisées
- Voir les executors

### 🐘 PgAdmin (gérer PostgreSQL)
```
http://localhost:5050
```

**Connexion :**
- Email: `admin@example.com`
- Password: `admin`

**Ajouter le serveur PostgreSQL :**
- Host: `postgres`
- Port: `5432`
- Username: `kafka_user`
- Password: `kafka_pass`
- Database: `kafka_streaming`

---

## 🔍 ÉTAPE 6 : Vérifier les Données dans PostgreSQL

### Via Terminal (psql)
```powershell
# Nombre total de records
docker exec -it postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"

# Voir les 10 premiers records
docker exec -it postgres psql -U kafka_user -d kafka_streaming -c "SELECT * FROM housing LIMIT 10;"

# Voir les statistiques
docker exec -it postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*), AVG(medv), MIN(medv), MAX(medv) FROM housing;"

# Voir les données récentes
docker exec -it postgres psql -U kafka_user -d kafka_streaming -c "SELECT * FROM housing ORDER BY created_at DESC LIMIT 5;"
```

### Via PgAdmin (Interface Web)
1. Allez à http://localhost:5050
2. Connectez-vous avec `admin@example.com / admin`
3. Cliquez sur le serveur PostgreSQL
4. Naviguez vers `databases → kafka_streaming → schemas → public → tables → housing`
5. Cliquez sur "View All Rows"

---

## 🧪 ÉTAPE 7 : Vérifier les Messages Kafka

### Consommer les messages du topic
```powershell
docker exec kafka kafka-console-consumer `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --from-beginning `
  --max-messages 2
```

### Voir les statistiques du topic
```powershell
docker exec kafka kafka-topics --describe `
  --topic housing-data `
  --bootstrap-server localhost:9092
```

---

## 🛑 ÉTAPE 8 : Arrêter le Pipeline

### Arrêter et supprimer tous les containers
```powershell
docker-compose down
```

### Supprimer aussi les volumes (données persistantes)
```powershell
docker-compose down -v
```

---

## 📋 Commandes Utiles pour le Debugging

### Voir les logs du Producer
```powershell
cd producer
mvn exec:java@default -Dexec.mainClass="com.example.KafkaProducerApp" 2>&1 | Tee-Object -FilePath producer.log
```

### Voir les logs du Spark Job
```powershell
docker logs -f spark-master
```

### Voir les logs du Consumer Kafka
```powershell
docker logs -f kafka
```

### Voir les logs de PostgreSQL
```powershell
docker logs -f postgres
```

### Accéder au conteneur Spark pour déboguer
```powershell
docker exec -it spark-master bash
# À l'intérieur du conteneur:
ls -la /opt/spark/work-dir/
cat consumer.py
```

### Vérifier la connexion PostgreSQL depuis Spark
```powershell
docker exec spark-master python -c "import psycopg2; print('psycopg2 OK')"
```

---

## ⚠️ Problèmes Courants et Solutions

### ❌ "Topic does not exist"
```powershell
bash create_topic.sh
```

### ❌ "Connection refused to postgres"
- Vérifier que le conteneur postgres est en cours d'exécution: `docker ps | grep postgres`
- Attendre 10 secondes après `docker-compose up -d`

### ❌ "Spark job not receiving messages"
- Vérifier que le Producer a envoyé les données: `docker exec kafka kafka-console-consumer --topic housing-data --bootstrap-server localhost:9092 --from-beginning --max-messages 1`
- Vérifier les logs Spark: `docker logs spark-master`

### ❌ "No data in PostgreSQL"
- Vérifier que le Spark job s'exécute correctement
- Vérifier les logs: `docker logs spark-master | tail -50`
- Vérifier la table existe: `docker exec -it postgres psql -U kafka_user -d kafka_streaming -c "\dt"`

### ❌ "psycopg2 not found"
- Le script `submit_consumer.sh` installe automatiquement psycopg2
- Si problème persiste: `docker exec spark-master pip install --upgrade psycopg2-binary`

---

## 📊 Flux d'Exécution Complet (Quick Start)

```powershell
# 1. Démarrer Docker
docker-compose up -d
Start-Sleep -Seconds 20

# 2. Créer le topic
bash create_topic.sh

# 3. Compiler le Producer
cd producer
mvn clean package
cd ..

# 4. Soumettre le Consumer Spark
bash submit_consumer.sh

# 5. Exécuter le Producer (dans un autre terminal PowerShell)
cd producer
mvn exec:java@default

# 6. Vérifier dans un 3ème terminal
docker exec -it postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"

# 7. Ouvrir les interfaces web
# - Kafka UI: http://localhost:8082
# - Spark: http://localhost:8080
# - PgAdmin: http://localhost:5050
```

---

## 🎯 Points de Vérification

- ✅ `docker ps` : 7 services actifs (zookeeper, kafka, postgres, spark-master, spark-worker, kafka-ui, pgadmin)
- ✅ Kafka UI : topic `housing-data` visible avec messages
- ✅ Spark UI : application en cours d'exécution
- ✅ PostgreSQL : table `housing` remplie avec les données
- ✅ PgAdmin : connexion au DB OK, données visibles

