# 🚀 COMMANDES PRINCIPALES - KAFKA SPARK STREAMING

## ⏱️ ORDRE D'EXÉCUTION COMPLET

### Phase 1: Infrastructure (Terminal 1)
```powershell
# 1a. Démarrer Docker
docker-compose up -d

# 1b. Attendre 20 secondes
Start-Sleep -Seconds 20

# 1c. Créer le topic Kafka
docker exec kafka kafka-topics --create `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --partitions 1 `
  --replication-factor 1 `
  --if-not-exists

# 1d. Vérifier que le topic est créé
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
```

---

### Phase 2: Construire le Producer (Terminal 1)
```powershell
cd producer
mvn clean package
# Attendez que le build soit terminé (env. 30-60 secondes)
cd ..
```

---

### Phase 3: Soumettre le Job Spark (Terminal 2 - AVANT de lancer le Producer)
```powershell
# IMPORTANT: Faire ça avant de lancer le Producer!
bash submit_consumer.sh

# Attendez de voir des messages comme:
# "Waiting for Spark cluster to be ready..."
# "Submitting Spark Streaming job..."
```

---

### Phase 4: Exécuter le Producer (Terminal 1 ou 3)
```powershell
cd producer
mvn exec:java@default

# Vous verrez:
# Sent batch of 100 records to Kafka
# Sent batch of 100 records to Kafka
# ... (plusieurs fois)
# Sent batch of 6 records to Kafka
```

---

### Phase 5: Vérifier les Résultats (Terminal 3 ou 4)

#### 5a. Vérifier le nombre de records en PostgreSQL
```powershell
# Attendre 30-60 secondes après que le Producer ait fini
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"

# Résultat attendu:
#  count
# -------
#    506
# (1 row)
```

#### 5b. Voir les 10 premiers records
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT * FROM housing LIMIT 10;"
```

#### 5c. Voir les statistiques
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*), AVG(medv), MIN(medv), MAX(medv) FROM housing;"
```

#### 5d. Voir les données les plus récentes
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT *, created_at FROM housing ORDER BY created_at DESC LIMIT 5;"
```

---

## 🌐 OUVRIR LES WEB INTERFACES

### Dans votre navigateur:

```
Kafka UI:        http://localhost:8082
Spark Master:    http://localhost:8080
Spark Worker:    http://localhost:8081
PgAdmin:         http://localhost:5050
```

### Actions dans chaque interface:

**Kafka UI (8082):**
- Voir les messages du topic `housing-data`
- Voir les partitions
- Voir les offsets

**Spark Master (8080):**
- Voir l'application en cours
- Voir les statuts des executors
- Cliquer sur l'application pour les détails

**Spark Worker (8081):**
- Voir les ressources utilisées
- Voir les executors actifs

**PgAdmin (5050):**
- Login: `admin@example.com` / `admin`
- Ajouter le serveur PostgreSQL
- Voir les données en temps réel

---

## 🔍 COMMANDES DE MONITORING/DEBUGGING

### Vérifier l'état des services
```powershell
# Tous les containers
docker ps

# Logs Kafka
docker logs -f kafka

# Logs Spark
docker logs -f spark-master

# Logs PostgreSQL
docker logs -f postgres

# Stats en temps réel
docker stats
```

---

### Vérifier les données à chaque étape

#### Dans Kafka
```powershell
# Voir les messages du topic (les 2 premiers)
docker exec kafka kafka-console-consumer `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --from-beginning `
  --max-messages 2

# Voir les stats du topic
docker exec kafka kafka-topics --describe `
  --topic housing-data `
  --bootstrap-server localhost:9092
```

#### Dans PostgreSQL
```powershell
# Connexion interactive
docker exec -it postgres psql -U kafka_user -d kafka_streaming

# Puis à l'intérieur de psql:
SELECT COUNT(*) FROM housing;
SELECT * FROM housing LIMIT 5;
SELECT COUNT(*), AVG(medv), MIN(medv), MAX(medv) FROM housing;
\dt  # Voir les tables
\d housing  # Voir le schéma de la table
```

---

### Accéder aux conteneurs

```powershell
# Terminal dans Spark
docker exec -it spark-master bash

# Terminal dans Kafka
docker exec -it kafka bash

# Terminal dans PostgreSQL
docker exec -it postgres bash
```

---

## ⚙️ CONFIGURATION & PERSONALISATION

### Changer la taille du batch (Producer)
**Fichier:** `producer/src/main/java/com/example/KafkaProducerApp.java`
```java
private static final int BATCH_SIZE = 100;  // Changer cette valeur
```

### Changer le nombre de partitions Kafka
**Fichier:** `create_topic.sh`
```bash
--partitions 1  # Changer cette valeur
```

### Changer les credentials PostgreSQL
**Fichier:** `docker-compose.yml`
```yaml
environment:
  POSTGRES_DB: kafka_streaming
  POSTGRES_USER: kafka_user
  POSTGRES_PASSWORD: kafka_pass  # Changer le mot de passe
```

---

## 🛑 ARRÊT ET NETTOYAGE

```powershell
# Arrêter les containers (garder les données)
docker-compose stop

# Arrêter et supprimer les containers
docker-compose down

# Arrêter, supprimer et EFFACER les données
docker-compose down -v

# Voir le statut après
docker ps
```

---

## 🧪 TESTS RAPIDES

### Test 1: Les services Docker tournent-ils?
```powershell
docker ps | Measure-Object -Line  # Doit afficher 7 containers
```

### Test 2: Kafka est-il ready?
```powershell
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
```

### Test 3: PostgreSQL est-il ready?
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT 1"
```

### Test 4: Le topic a des messages?
```powershell
docker exec kafka kafka-console-consumer `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --from-beginning `
  --max-messages 1 `
  --timeout-ms 5000
```

### Test 5: Les données arrivent dans PostgreSQL?
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
```

---

## 📊 RÉSULTATS ATTENDUS

### Avant d'exécuter le Producer
```
count
-------
    0
(1 row)
```

### Après avoir exécuté le Producer et Spark Streaming
```
count
-------
  506
(1 row)
```

### Avec les statistiques
```
count | avg(medv) | min(medv) | max(medv)
------+-----------+-----------+----------
  506 |  22.53    |   5.0     |   50.0
(1 row)
```

---

## ⚠️ PROBLÈMES COURANTS

### Problème: "Topic does not exist"
**Solution:**
```powershell
bash create_topic.sh
```

### Problème: "Connection refused to kafka"
**Solution:**
```powershell
# Attendre 20-30 secondes après docker-compose up -d
docker logs kafka
```

### Problème: "psycopg2 not found"
**Solution:**
```powershell
docker exec spark-master pip install psycopg2-binary
```

### Problème: "No data in PostgreSQL after 5 minutes"
**Solution:**
```powershell
# Vérifier les logs Spark
docker logs spark-master | tail -50

# Redémarrer le job Spark
docker exec spark-master pkill -f spark-submit
bash submit_consumer.sh
```

### Problème: Producer stuck ou Maven timeout
**Solution:**
```powershell
# Augmenter le timeout Maven
cd producer
mvn exec:java@default -DskipTests -T 1C -X
```

---

## 💾 SAUVEGARDE DES DONNÉES

### Exporter les données de PostgreSQL
```powershell
docker exec postgres pg_dump -U kafka_user kafka_streaming > backup.sql
```

### Restaurer les données
```powershell
docker exec -i postgres psql -U kafka_user kafka_streaming < backup.sql
```

---

## 🔐 SÉCURITÉ (Production)

### Changer les passwords
```yaml
# docker-compose.yml
environment:
  POSTGRES_PASSWORD: votre_nouveau_password_securise
```

### Ajouter l'authentification Kafka
```yaml
# docker-compose.yml
environment:
  KAFKA_SECURITY_PROTOCOL: SASL_PLAINTEXT
  KAFKA_SASL_MECHANISM: PLAIN
```

---

## 📈 PERFORMANCE TUNING

### Augmenter la mémoire Spark
```yaml
# docker-compose.yml - spark-master
environment:
  SPARK_DRIVER_MEMORY: 4g
  SPARK_EXECUTOR_MEMORY: 2g
```

### Augmenter le batch size
```java
// KafkaProducerApp.java
private static final int BATCH_SIZE = 500;  // De 100 à 500
```

### Augmenter les partitions Kafka
```bash
# create_topic.sh
--partitions 4  # De 1 à 4
```

---

## 🎯 CHECKLIST COMPLÈTE

- [ ] Docker-compose up -d exécuté
- [ ] Tous les 7 services sont actifs (docker ps)
- [ ] Topic Kafka créé
- [ ] Producer compilé (mvn clean package)
- [ ] Spark Streaming job soumis (bash submit_consumer.sh)
- [ ] Producer exécuté (mvn exec:java@default)
- [ ] Kafka UI accessible et voir les messages
- [ ] Spark Master UI accessible
- [ ] PostgreSQL contient 506 records
- [ ] PgAdmin accessible et connecté

---

## 🚀 QUICK START ONE-LINER (PowerShell)

```powershell
docker-compose up -d; Start-Sleep -Seconds 20; docker exec kafka kafka-topics --create --topic housing-data --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --if-not-exists; cd producer; mvn clean package
```

Puis dans 3 terminals séparés:
```powershell
# Terminal 1
bash submit_consumer.sh

# Terminal 2
cd producer; mvn exec:java@default

# Terminal 3
Start-Sleep -Seconds 30; docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
```

