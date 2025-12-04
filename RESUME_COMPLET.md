# 📋 RÉSUMÉ COMPLET - Projet Kafka Spark Streaming → PostgreSQL

## 🎯 Objectif du Projet

Créer un **pipeline d'ingestion de données en temps réel** qui:
1. ✅ Lit des microbatches d'un fichier CSV (Boston Housing: 506 records)
2. ✅ Les envoie à **Kafka** en tant que messages JSON
3. ✅ **Spark Streaming** les consomme et traite en temps réel
4. ✅ Les stock finalement dans **PostgreSQL**

---

## 🔧 Corrections Apportées

### ❌ Problème 1: Script `submit_consumer.sh` incorrect
**Avant:**
```bash
docker exec spark-master sh -c "pip install psycopg2-binary"
/opt/spark/bin/spark-submit \  # ⚠️ Exécuté HORS du conteneur!
```

**Après:**
```bash
docker exec spark-master pip install psycopg2-binary > /dev/null 2>&1
docker exec spark-master /opt/spark/bin/spark-submit \  # ✅ Exécuté DANS le conteneur
```

### ❌ Problème 2: Table PostgreSQL sans clé primaire
**Avant:**
```sql
CREATE TABLE housing (
    crim DOUBLE PRECISION,
    -- ... pas de clé primaire
);
```

**Après:**
```sql
CREATE TABLE housing (
    id SERIAL PRIMARY KEY,  -- ✅ Clé primaire ajoutée
    -- ... colonnes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- ✅ Timestamp ajouté
);
```

### ❌ Problème 3: Manque de gestion des timeouts
**Avant:** Pas d'attente entre les étapes

**Après:**
```bash
sleep 15  # ✅ Attendez que Spark soit prêt
docker exec spark-master pip install psycopg2-binary > /dev/null 2>&1  # ✅ Installation silencieuse
```

---

## 📊 Architecture Détaillée

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                    KAFKA-SPARK STREAMING PIPELINE                  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

┌─────────────────────────────────────────────────────────────────────┐
│                    DONNÉES SOURCE                                    │
├─────────────────────────────────────────────────────────────────────┤
│  housing.csv (506 records, 14 colonnes)                             │
│  - CRIM, ZN, INDUS, CHAS, NOX, RM, AGE, DIS, RAD, TAX, PTRATIO,   │
│    B, LSTAT, MEDV                                                   │
└─────────────┬───────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────────┐
│              PHASE 1: PRODUCER (Java)                               │
├─────────────────────────────────────────────────────────────────────┤
│  KafkaProducerApp.java                                              │
│  - Lit le CSV ligne par ligne                                       │
│  - Accumule 100 records dans un batch                               │
│  - Sérialize en JSON                                                │
│  - Envoie à Kafka                                                   │
│                                                                      │
│  Résultat: 6 batches (100+100+100+100+100+6)                       │
└─────────────┬───────────────────────────────────────────────────────┘
              │
              ▼
    ┌─────────────────────┐
    │  KAFKA BROKER       │
    │  Topic: housing-    │
    │         data        │
    │  Partitions: 1      │
    │  Messages: 6        │
    └─────────────────────┘
              │
         ┌────┴────┐
         │          │
         ▼          ▼
    ┌─────────┐  ┌──────────┐
    │ Kafka   │  │  Spark   │
    │  UI     │  │ Consumer │
    │ :8082   │  │ Job      │
    └─────────┘  └────┬─────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│           PHASE 2: SPARK STREAMING CONSUMER (Python)               │
├─────────────────────────────────────────────────────────────────────┤
│  consumer.py                                                        │
│  - S'abonne au topic Kafka                                          │
│  - Parse les messages JSON (ArrayType de records)                   │
│  - Explode les records                                              │
│  - Cast les types (float, int, etc.)                                │
│  - Exécute foreachBatch                                             │
│                                                                      │
│  Résultat: DataFrames transformées                                  │
└─────────────┬───────────────────────────────────────────────────────┘
              │
         ┌────┴──────────────────────┐
         │                           │
         ▼                           ▼
    ┌──────────┐             ┌──────────────┐
    │  Spark   │             │  PgSQL       │
    │ Master   │             │  Write       │
    │  :8080   │             │  Query       │
    └──────────┘             └──────┬───────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│              PHASE 3: STOCKAGE (PostgreSQL)                         │
├─────────────────────────────────────────────────────────────────────┤
│  Table: housing                                                      │
│  - id (SERIAL PRIMARY KEY)                                          │
│  - 14 colonnes DOUBLE PRECISION / INTEGER                           │
│  - created_at (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)                 │
│  - Indexes sur: medv, created_at                                    │
│                                                                      │
│  Résultat: 506 records persistants                                  │
└─────────────┬───────────────────────────────────────────────────────┘
              │
         ┌────┴──────────┐
         │               │
         ▼               ▼
    ┌──────────┐   ┌───────────┐
    │ PgAdmin  │   │ Requêtes  │
    │  :5050   │   │   SQL     │
    └──────────┘   └───────────┘
```

---

## 🚀 Services Docker Utilisés

| Service | Image | Port | Rôle |
|---------|-------|------|------|
| **Zookeeper** | confluentinc/cp-zookeeper:7.4.0 | 2181 | Coordination Kafka |
| **Kafka** | confluentinc/cp-kafka:7.4.0 | 9092 | Message Broker |
| **PostgreSQL** | postgres:15 | 5432 | Base de données |
| **Spark Master** | apache/spark:3.4.1 | 8080 | Orchestration Spark |
| **Spark Worker** | apache/spark:3.4.1 | 8081 | Exécution des jobs |
| **Kafka UI** | provectuslabs/kafka-ui | 8082 | Monitoring Kafka |
| **PgAdmin** | dpage/pgadmin4 | 5050 | Management PostgreSQL |

---

## 📋 Fichiers du Projet (Créés/Modifiés)

### 📁 Structure Complète
```
Kafka-SparkTreaming/
├── docker-compose.yml              # ✅ Configuration Docker
├── init.sql                        # ✅ Schéma PostgreSQL (modifié)
├── create_topic.sh                 # Topic Kafka
├── submit_consumer.sh              # ✅ Job Spark (CORRIGÉ)
│
├── README_COMPLET.md               # 📖 Guide complet
├── GUIDE_EXECUTION.md              # 📖 Guide détaillé d'exécution
├── COMMANDES_PRINCIPALES.md        # 📖 Commandes clés
│
├── quick_start.ps1                 # 🚀 Script interactif (PowerShell)
├── test_pipeline.sh                # 🧪 Tests automatisés (Bash)
│
├── producer/
│   ├── pom.xml                     # Maven configuration
│   ├── src/main/java/com/example/
│   │   └── KafkaProducerApp.java   # Java Producer
│   └── housing.csv                 # Données source
│
├── consumer/
│   └── consumer.py                 # PySpark Consumer
│
└── data/
    └── housing.csv                 # Dataset Boston Housing
```

---

## ⏱️ Ordre d'Exécution Recommandé

### 1️⃣ Terminal 1: Démarrer l'Infrastructure
```powershell
docker-compose up -d
Start-Sleep -Seconds 20
docker exec kafka kafka-topics --create --topic housing-data `
  --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --if-not-exists
cd producer && mvn clean package
```

### 2️⃣ Terminal 2: Soumettre Spark Streaming
```powershell
bash submit_consumer.sh
```

### 3️⃣ Terminal 3: Exécuter le Producer
```powershell
cd producer
mvn exec:java@default
```

### 4️⃣ Terminal 4: Vérifier les Résultats
```powershell
# Attendre 30-60 secondes
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
```

---

## 🌐 Web Interfaces de Monitoring

| Nom | URL | Login | Fonction |
|-----|-----|-------|----------|
| **Kafka UI** | http://localhost:8082 | - | Voir les messages Kafka en temps réel |
| **Spark Master** | http://localhost:8080 | - | Voir l'application Spark et les statuts |
| **Spark Worker** | http://localhost:8081 | - | Voir les ressources utilisées |
| **PgAdmin** | http://localhost:5050 | admin@example.com / admin | Gérer PostgreSQL et voir les données |

---

## ✅ Points de Contrôle Clés

### 1. Infrastructure Ready
```powershell
docker ps
# ✅ 7 containers actifs
```

### 2. Kafka Topic Créé
```powershell
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
# ✅ "housing-data" dans la liste
```

### 3. Spark Job Soumis
```powershell
docker logs spark-master | grep "Submitted application"
# ✅ Application soumise
```

### 4. Données dans PostgreSQL
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
# ✅ count = 506
```

### 5. Web Interfaces Accessibles
```
✅ Kafka UI: voir les 6 messages
✅ Spark UI: voir l'application RUNNING
✅ PgAdmin: voir 506 records
```

---

## 🧪 Commandes de Test

```powershell
# Test 1: Docker services
docker ps | Measure-Object -Line  # Doit être 7

# Test 2: Kafka messages
docker exec kafka kafka-console-consumer `
  --topic housing-data --bootstrap-server localhost:9092 `
  --from-beginning --max-messages 1

# Test 3: PostgreSQL data
docker exec postgres psql -U kafka_user -d kafka_streaming `
  -c "SELECT COUNT(*) FROM housing;"

# Test 4: Spark status
docker exec spark-master curl -s http://localhost:8080/json

# Test 5: Database stats
docker exec postgres psql -U kafka_user -d kafka_streaming `
  -c "SELECT COUNT(*), AVG(medv), MIN(medv), MAX(medv) FROM housing;"
```

---

## ❌ Problèmes Courants & Solutions

| Problème | Solution |
|----------|----------|
| **Topic does not exist** | `bash create_topic.sh` |
| **Connection refused kafka** | `Start-Sleep -Seconds 30; docker logs kafka` |
| **psycopg2 not found** | `docker exec spark-master pip install psycopg2-binary` |
| **No data in PostgreSQL** | `docker logs spark-master` et `bash submit_consumer.sh` |
| **Spark job stuck** | `docker exec spark-master pkill -f spark-submit` puis redémarrer |
| **Maven timeout** | Attendre ou augmenter timeout dans pom.xml |
| **Out of memory** | Augmenter SPARK_DRIVER_MEMORY et SPARK_EXECUTOR_MEMORY |

---

## 📊 Résultats Attendus

### Output Producer
```
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
Sent batch of 6 records to Kafka
```

### Output Spark (logs)
```
Submitting Spark Streaming job...
20XX-XX-XX XX:XX:XX INFO AppStatusListener: Registered BlockManagerMaster
20XX-XX-XX XX:XX:XX INFO BlockManagerMasterEndpoint: BlockManagerMaster started
```

### Output PostgreSQL
```
 count
-------
   506
(1 row)
```

---

## 🔐 Credentials et Configuration

| Composant | Credential | Valeur |
|-----------|------------|--------|
| **PostgreSQL** | User | `kafka_user` |
| **PostgreSQL** | Password | `kafka_pass` |
| **PostgreSQL** | Database | `kafka_streaming` |
| **PgAdmin** | Email | `admin@example.com` |
| **PgAdmin** | Password | `admin` |
| **Kafka** | Bootstrap Server | `localhost:9092` |
| **Kafka (interne)** | - | `kafka:29092` |
| **Spark Master** | Host | `spark-master` |
| **Spark Master** | Port | `7077` |

---

## 🎯 Checklist Finale

- [ ] Docker-compose up -d ✅
- [ ] Tous les 7 services running ✅
- [ ] Topic Kafka créé ✅
- [ ] Producer compilé (mvn clean package) ✅
- [ ] Spark job soumis (bash submit_consumer.sh) ✅
- [ ] Producer exécuté (mvn exec:java@default) ✅
- [ ] Kafka UI accessible et voit les messages ✅
- [ ] Spark UI accessible et application RUNNING ✅
- [ ] PostgreSQL contient 506 records ✅
- [ ] PgAdmin accessible et données visibles ✅

---

## 🚀 Quick Start PowerShell (Copier-Coller)

```powershell
# Phase 1: Infrastructure
docker-compose up -d
Start-Sleep -Seconds 20
docker exec kafka kafka-topics --create --topic housing-data --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --if-not-exists
cd producer
mvn clean package

# Phase 2 (nouveau terminal): Spark
bash submit_consumer.sh

# Phase 3 (nouveau terminal): Producer
cd producer
mvn exec:java@default

# Phase 4 (nouveau terminal): Vérification
Start-Sleep -Seconds 30
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"

# Ouvrir les interfaces web
# Kafka UI: http://localhost:8082
# Spark: http://localhost:8080
# PgAdmin: http://localhost:5050
```

---

## 📚 Ressources Créées

### Documentation
- 📖 **README_COMPLET.md** - Guide complet du projet
- 📖 **GUIDE_EXECUTION.md** - Instructions détaillées
- 📖 **COMMANDES_PRINCIPALES.md** - Commandes clés et debugging
- 📋 **Ce fichier** - Résumé complet

### Scripts Utiles
- 🚀 **quick_start.ps1** - Menu interactif PowerShell
- 🧪 **test_pipeline.sh** - Tests automatisés Bash
- ✅ **submit_consumer.sh** - Job Spark (CORRIGÉ)

### Configurations
- ⚙️ **docker-compose.yml** - Services Docker (amélioré)
- 📝 **init.sql** - Schéma PostgreSQL (amélioré)

---

## 🎓 Prochaines Étapes (Améliorations Possibles)

1. **Augmenter les données**
   - Batch size: 100 → 500
   - Partitions Kafka: 1 → 4

2. **Ajouter de la résilience**
   - Replication factor: 1 → 3
   - Monitoring: Prometheus + Grafana

3. **Optimiser les performances**
   - Augmenter la mémoire Spark
   - Ajouter des indexes PostgreSQL supplémentaires

4. **Ajouter de la sécurité**
   - TLS/SSL pour Kafka
   - Authentication Kafka SASL
   - Chiffrer les mots de passe

5. **Monitoring & Alertes**
   - Prometheus pour les métriques
   - Grafana pour les dashboards
   - Alertes basées sur les seuils

---

## 💡 Tips & Tricks

**Sauvegarde rapide des données:**
```powershell
docker exec postgres pg_dump -U kafka_user kafka_streaming > backup.sql
```

**Nettoyer complètement (y compris données):**
```powershell
docker-compose down -v
```

**Voir les logs en temps réel:**
```powershell
docker logs -f spark-master
docker logs -f kafka
docker logs -f postgres
```

**Redémarrer un service:**
```powershell
docker-compose restart spark-master
```

