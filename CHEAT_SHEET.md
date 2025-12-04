# 📋 CHEAT SHEET - COMMANDES ESSENTIELLES

## 🎯 EXÉCUTION COMPLÈTE EN 4 ÉTAPES

### Étape 1: Infrastructure (Terminal 1) - 2-3 min
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
docker-compose up -d
Start-Sleep -Seconds 20
docker exec kafka kafka-topics --create --topic housing-data --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --if-not-exists
cd producer && mvn clean package && cd ..
```

### Étape 2: Spark Consumer (Terminal 2) - 1 min
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
bash submit_consumer.sh
```

### Étape 3: Producer (Terminal 3) - 30 sec
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming\producer
mvn exec:java@default
```

### Étape 4: Vérification (Terminal 4) - 2 min
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
Start-Sleep -Seconds 60
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
```

✅ **Résultat attendu:** `506`

---

## 🌐 WEB INTERFACES (Ouvrir dans le navigateur)

| Service | URL |
|---------|-----|
| Kafka UI | http://localhost:8082 |
| Spark Master | http://localhost:8080 |
| Spark Worker | http://localhost:8081 |
| PgAdmin | http://localhost:5050 |

**PgAdmin Credentials:**
- Email: `admin@example.com`
- Password: `admin`
- Server Host: `postgres`
- Server Port: `5432`
- Username: `kafka_user`
- Password: `kafka_pass`

---

## 🔍 VÉRIFICATIONS RAPIDES

### Vérifier Docker
```powershell
docker ps
# Résultat: 7 containers
```

### Vérifier Kafka Topic
```powershell
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
# Résultat: housing-data
```

### Vérifier Kafka Messages
```powershell
docker exec kafka kafka-console-consumer --topic housing-data --bootstrap-server localhost:9092 --from-beginning --max-messages 1
# Résultat: JSON array
```

### Vérifier PostgreSQL
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
# Résultat: 506
```

### Voir Statistiques
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*), AVG(medv), MIN(medv), MAX(medv) FROM housing;"
# Résultat: 506 | 22.53 | 5.0 | 50.0
```

---

## 📊 REQUÊTES POSTGRESQL UTILES

### Nombre de records
```sql
SELECT COUNT(*) FROM housing;
```

### Tous les records
```sql
SELECT * FROM housing;
```

### Top 5 records
```sql
SELECT * FROM housing LIMIT 5;
```

### Records récents
```sql
SELECT * FROM housing ORDER BY created_at DESC LIMIT 10;
```

### Statistiques
```sql
SELECT 
  COUNT(*),
  AVG(medv)::numeric(5,2),
  MIN(medv),
  MAX(medv)
FROM housing;
```

### Par colonne
```sql
SELECT 
  COUNT(*) as count,
  AVG(crim)::numeric(5,2) as avg_crime,
  AVG(rm)::numeric(5,2) as avg_rooms,
  AVG(medv)::numeric(5,2) as avg_price
FROM housing;
```

---

## 🧹 NETTOYAGE

### Arrêter temporairement
```powershell
docker-compose stop
```

### Redémarrer
```powershell
docker-compose start
```

### Arrêter complètement
```powershell
docker-compose down
```

### Supprimer données ET containers
```powershell
docker-compose down -v
```

### Redémarrer un service
```powershell
docker-compose restart spark-master
```

---

## 📜 LOGS EN TEMPS RÉEL

### Logs Kafka
```powershell
docker logs -f kafka
```

### Logs Spark
```powershell
docker logs -f spark-master
```

### Logs PostgreSQL
```powershell
docker logs -f postgres
```

### Logs Spark Worker
```powershell
docker logs -f spark-worker
```

### Tous les logs
```powershell
docker-compose logs -f
```

### Dernières 20 lignes
```powershell
docker logs --tail 20 spark-master
```

---

## 🆘 TROUBLESHOOTING RAPIDE

### Problème: Timeout Maven
```powershell
cd producer
mvn clean package -X
```

### Problème: Topic n'existe pas
```powershell
bash create_topic.sh
```

### Problème: Spark n'a pas écrit les données
```powershell
docker logs spark-master | tail -50
docker-compose restart spark-master
bash submit_consumer.sh
```

### Problème: PostgreSQL vide
```powershell
# Attendre plus longtemps
Start-Sleep -Seconds 120
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
```

### Problème: Docker ne démarre pas
```powershell
docker-compose up -d --force-recreate
```

### Problème: psycopg2 not found
```powershell
docker exec spark-master pip install psycopg2-binary
bash submit_consumer.sh
```

---

## 💾 SAUVEGARDE ET RESTORE

### Exporter les données
```powershell
docker exec postgres pg_dump -U kafka_user kafka_streaming > backup.sql
```

### Importer les données
```powershell
docker exec -i postgres psql -U kafka_user kafka_streaming < backup.sql
```

### Vider la table
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "TRUNCATE housing;"
```

---

## 📊 RESSOURCES UTILISÉES

### Voir la mémoire et CPU
```powershell
docker stats
```

### Voir sans refresh
```powershell
docker stats --no-stream
```

### Voir juste Spark
```powershell
docker stats spark-master spark-worker
```

---

## 🔑 CREDENTIALS

| Service | Key | Value |
|---------|-----|-------|
| **PostgreSQL** | User | kafka_user |
| **PostgreSQL** | Password | kafka_pass |
| **PostgreSQL** | Database | kafka_streaming |
| **PostgreSQL** | Port | 5432 |
| **PgAdmin** | Email | admin@example.com |
| **PgAdmin** | Password | admin |
| **Kafka** | External | localhost:9092 |
| **Kafka** | Internal | kafka:29092 |
| **Spark Master** | Host | spark-master |
| **Spark Master** | Port | 7077 |

---

## 📁 CHEMINS IMPORTANTS

```
Racine:        C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
Producer:      C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming\producer
Code Java:     producer\src\main\java\com\example\KafkaProducerApp.java
CSV:           producer\housing.csv
Python:        consumer\consumer.py
Config:        docker-compose.yml, init.sql
```

---

## ⏱️ TIMELINE

| Étape | Commande | Durée |
|-------|----------|-------|
| T1 | Infrastructure | 2-3 min |
| T2 | Spark job | 1 min |
| T3 | Producer | 30 sec |
| T4 | Vérification | 1-2 min |
| **TOTAL** | | **~5-7 min** |

---

## ✅ CHECKLIST SUCCESS

- [ ] Terminal 1: ✅ Infrastructure prête
- [ ] Terminal 2: ✅ Spark job soumis
- [ ] Terminal 3: ✅ 6 batches envoyés
- [ ] Terminal 4: ✅ 506 records en BD
- [ ] Kafka UI: ✅ Messages visibles
- [ ] Spark UI: ✅ Application RUNNING
- [ ] PgAdmin: ✅ Données présentes

---

## 🎯 RÉSUMÉ EN 1 PAGE

```
1. Ouvrir 4 terminaux PowerShell

2. Terminal 1:
   cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
   docker-compose up -d
   Start-Sleep -Seconds 20
   docker exec kafka kafka-topics --create --topic housing-data --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --if-not-exists
   cd producer && mvn clean package && cd ..

3. Terminal 2:
   cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
   bash submit_consumer.sh

4. Terminal 3:
   cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming\producer
   mvn exec:java@default

5. Terminal 4 (après 60 sec):
   cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
   docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"

6. Ouvrir navigateur:
   http://localhost:8082  (Kafka UI)
   http://localhost:8080  (Spark)
   http://localhost:5050  (PgAdmin)

7. Résultat: 506 records ✅
```

---

## 📚 DOCUMENTATION COMPLÈTE

Pour plus de détails, voir:
- `START_HERE.md` - Point de départ
- `QUICK_START_5MIN.md` - Démarrage rapide
- `TOUTES_LES_COMMANDES.md` - Toutes les commandes
- `README_COMPLET.md` - Guide complet
- `GUIDE_EXECUTION.md` - Instructions détaillées

---

**Imprimez cette feuille et gardez-la à proximité!** 🖨️

