# 🎯 TOUTES LES COMMANDES - ORDRE D'EXÉCUTION COMPLET

## ⚡ RÉSUMÉ RAPIDE (Copier-Coller Facile)

### Terminal 1: Infrastructure (2-3 minutes)
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming

docker-compose up -d

Start-Sleep -Seconds 20

docker exec kafka kafka-topics --create --topic housing-data --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --if-not-exists

cd producer && mvn clean package && cd ..

Write-Host "✅ Infrastructure OK! Allez au Terminal 2" -ForegroundColor Green
```

---

### Terminal 2: Spark Consumer (1 minute)
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming

bash submit_consumer.sh

Write-Host "✅ Spark Job soumis!" -ForegroundColor Green
```

---

### Terminal 3: Producer Java (30 secondes)
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming\producer

mvn exec:java@default

# Attendez que ça se termine (6 batches envoyés)
```

---

### Terminal 4: Vérification (1 minute)
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming

# Attendre 30-60 secondes après que Terminal 3 ait fini

docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"

# Résultat attendu: 506 ✅
```

---

## 📋 DÉTAIL COMPLET - LIGNE PAR LIGNE

### 🟢 PHASE 1: INFRASTRUCTURE DOCKER

#### 1.1 Naviguer au dossier projet
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
```

#### 1.2 Démarrer tous les services Docker
```powershell
docker-compose up -d
```
**Résultat attendu:**
```
Creating network "kafka-sparktreaming_default" with the default driver
Creating zookeeper ... done
Creating kafka ... done
Creating postgres ... done
Creating spark-master ... done
Creating spark-worker ... done
Creating kafka-ui ... done
Creating pgadmin ... done
```

#### 1.3 Attendre que les services soient prêts
```powershell
Start-Sleep -Seconds 20
```

#### 1.4 Vérifier que tous les 7 services tournent
```powershell
docker ps
```
**Résultat attendu:** 7 containers (zookeeper, kafka, postgres, spark-master, spark-worker, kafka-ui, pgadmin)

#### 1.5 Créer le topic Kafka
```powershell
docker exec kafka kafka-topics --create `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --partitions 1 `
  --replication-factor 1 `
  --if-not-exists
```
**Résultat attendu:**
```
Created topic housing-data.
```

#### 1.6 Vérifier que le topic a été créé
```powershell
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
```
**Résultat attendu:**
```
housing-data
```

#### 1.7 Naviguer au dossier producer
```powershell
cd producer
```

#### 1.8 Compiler le Producer Java (nettoyer les anciens builds)
```powershell
mvn clean
```
**Attendre:** ~30 secondes

#### 1.9 Compiler le code source
```powershell
mvn compile
```
**Attendre:** ~30 secondes

#### 1.10 Packager en JAR
```powershell
mvn package
```
**Attendre:** ~1-2 minutes
**Résultat attendu:**
```
BUILD SUCCESS
```

#### 1.11 Retourner au dossier racine
```powershell
cd ..
```

**Étape 1 TERMINÉE ✅ Allez maintenant au Terminal 2**

---

### 🟢 PHASE 2: SOUMETTRE LE JOB SPARK (Terminal 2)

#### 2.1 Naviguer au dossier projet
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
```

#### 2.2 Soumettre le job Spark Streaming
```powershell
bash submit_consumer.sh
```
**Résultat attendu:**
```
Waiting for Spark cluster to be ready...
Copying consumer.py to Spark container...
Installing psycopg2-binary...
Submitting Spark Streaming job...
```

#### 2.3 Vérifier que le job a été soumis
```powershell
docker logs spark-master | tail -20
```
**Résultat attendu:**
```
Submitted application app-XXX
```

**Étape 2 TERMINÉE ✅ Allez maintenant au Terminal 3**

---

### 🟢 PHASE 3: EXÉCUTER LE PRODUCER (Terminal 3)

#### 3.1 Naviguer au dossier producer
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming\producer
```

#### 3.2 Exécuter le Producer Java
```powershell
mvn exec:java@default
```

**Résultat attendu (plusieurs fois):**
```
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
Sent batch of 100 records to Kafka
Sent batch of 6 records to Kafka
```

**L'exécution dure:** ~30-60 secondes

**Étape 3 TERMINÉE ✅ Une fois que le Producer a fini, allez au Terminal 4**

---

### 🟢 PHASE 4: VÉRIFICATION (Terminal 4)

#### 4.1 Naviguer au dossier projet
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
```

#### 4.2 Attendre que les données arrivent dans PostgreSQL
```powershell
Start-Sleep -Seconds 60
```
**(Important: Attendre 60 secondes pour que Spark traite et écrive les données)**

#### 4.3 ✅ Vérifier le nombre total de records
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
```
**Résultat attendu:**
```
 count
-------
   506
(1 row)
```

#### 4.4 Voir les premiers records
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT * FROM housing LIMIT 5;"
```
**Résultat attendu:** 5 lignes avec les colonnes du housing dataset

#### 4.5 Voir les statistiques détaillées
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*), AVG(medv)::numeric(5,2) as avg_price, MIN(medv) as min_price, MAX(medv) as max_price FROM housing;"
```
**Résultat attendu:**
```
 count | avg_price | min_price | max_price
-------+-----------+-----------+-----------
   506 |     22.53 |       5.0 |      50.0
```

#### 4.6 Voir les données les plus récentes
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT *, created_at FROM housing ORDER BY created_at DESC LIMIT 5;"
```
**Résultat attendu:** 5 derniers records avec timestamp

---

## 🌐 ÉTAPE 5: OUVRIR LES WEB INTERFACES

#### 5.1 Ouvrir Kafka UI dans le navigateur
```powershell
Start-Process "http://localhost:8082"
```
**À faire:** Voir le topic `housing-data` avec 6 messages

#### 5.2 Ouvrir Spark Master UI
```powershell
Start-Process "http://localhost:8080"
```
**À faire:** Voir l'application Spark RUNNING

#### 5.3 Ouvrir Spark Worker UI
```powershell
Start-Process "http://localhost:8081"
```
**À faire:** Voir les ressources utilisées

#### 5.4 Ouvrir PgAdmin
```powershell
Start-Process "http://localhost:5050"
```
**À faire:**
1. Connectez-vous: `admin@example.com` / `admin`
2. Cliquez sur "Servers" → Ajouter serveur
3. Remplissez:
   - Hostname: `postgres`
   - Port: `5432`
   - User: `kafka_user`
   - Password: `kafka_pass`
   - Database: `kafka_streaming`
4. Naviguez vers la table `housing`
5. Cliquez "View All Rows"

---

## 🧪 ÉTAPE 6: TESTS ET VÉRIFICATIONS SUPPLÉMENTAIRES

### Test 1: Vérifier les messages Kafka
```powershell
docker exec kafka kafka-console-consumer `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --from-beginning `
  --max-messages 1
```

### Test 2: Vérifier le descriptif du topic
```powershell
docker exec kafka kafka-topics --describe `
  --topic housing-data `
  --bootstrap-server localhost:9092
```

### Test 3: Vérifier la connexion PostgreSQL
```powershell
docker exec -it postgres psql -U kafka_user -d kafka_streaming

# À l'intérieur de psql, tapez:
SELECT * FROM housing WHERE id = 1;
\q  # Pour quitter
```

### Test 4: Voir tous les records
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
```

### Test 5: Vérifier les logs Spark
```powershell
docker logs -f spark-master | tail -50
```

### Test 6: Vérifier que Spark a bien écrit les données
```powershell
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT * FROM housing WHERE created_at IS NOT NULL ORDER BY created_at DESC LIMIT 10;"
```

---

## 🛑 ÉTAPE 7: ARRÊT PROPRE DU PIPELINE

### Option 1: Arrêter temporairement (garder les données)
```powershell
docker-compose stop
```

### Option 2: Arrêter et supprimer les containers (garder les données)
```powershell
docker-compose down
```

### Option 3: Suppression COMPLÈTE y compris les données
```powershell
docker-compose down -v
```

---

## 📊 COMMANDES DE MONITORING CONTINU

### Voir les logs en temps réel
```powershell
# Kafka
docker logs -f kafka

# Spark Master
docker logs -f spark-master

# PostgreSQL
docker logs -f postgres

# Tous les logs
docker-compose logs -f
```

### Voir les ressources utilisées
```powershell
docker stats

# Avec refresh continu
docker stats --no-stream
```

### Voir le statut de tous les containers
```powershell
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

## 🔄 ÉTAPE 8: REPRISE APRÈS ARRÊT

### Si vous avez arrêté avec `docker-compose stop`
```powershell
docker-compose start

# Attendre 10 secondes
Start-Sleep -Seconds 10

# Vérifier les données sont toujours là
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
```

### Si vous avez supprimé avec `docker-compose down -v`
**Les données sont perdues, recommencez depuis le Terminal 1**

---

## 🎯 CHECKLIST COMPLÈTE

- [ ] Terminal 1: Infrastructure Docker démarrée
- [ ] Terminal 1: Topic Kafka créé
- [ ] Terminal 1: Producer compilé (mvn clean package)
- [ ] Terminal 1: TERMINÉ ✅

- [ ] Terminal 2: Spark job soumis (bash submit_consumer.sh)
- [ ] Terminal 2: TERMINÉ ✅

- [ ] Terminal 3: Producer exécuté (mvn exec:java@default)
- [ ] Terminal 3: 6 batches envoyés
- [ ] Terminal 3: TERMINÉ ✅

- [ ] Terminal 4: Attendre 60 secondes
- [ ] Terminal 4: 506 records vérifiés dans PostgreSQL ✅
- [ ] Terminal 4: Statistiques correctes ✅
- [ ] Terminal 4: TERMINÉ ✅

- [ ] Kafka UI (8082): Messages visibles ✅
- [ ] Spark UI (8080): Application RUNNING ✅
- [ ] PgAdmin (5050): Données visibles ✅

---

## ⚠️ TROUBLESHOOTING PAR COMMANDE

### Si mvn clean package échoue
```powershell
# Nettoyer complètement
mvn clean -X

# Vérifier Java version
java -version

# Réessayer
mvn clean package
```

### Si Docker containers ne démarrent pas
```powershell
# Vérifier Docker
docker ps

# Redémarrer Docker Desktop
# Puis:
docker-compose up -d --force-recreate
```

### Si Kafka topic ne se crée pas
```powershell
# Vérifier Kafka est prêt
docker logs kafka | tail -20

# Attendre puis réessayer
Start-Sleep -Seconds 30
bash create_topic.sh
```

### Si Spark job ne s'exécute pas
```powershell
# Voir les logs
docker logs spark-master

# Redémarrer Spark
docker-compose restart spark-master spark-worker

# Resubmit
bash submit_consumer.sh
```

### Si PostgreSQL a 0 records
```powershell
# Vérifier que Spark a écrit
docker logs spark-master | grep -i "write"

# Vérifier que la table existe
docker exec postgres psql -U kafka_user -d kafka_streaming -c "\dt"

# Réinitialiser la table
docker exec postgres psql -U kafka_user -d kafka_streaming -c "TRUNCATE housing;"

# Recommencer depuis Terminal 2
```

---

## 🚀 COMMANDE UNIQUE ONE-LINER (Avec Délais)

Pour exécuter tout d'un coup dans un seul terminal (pas recommandé, mais fonctionne):

```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming; `
docker-compose up -d; `
Start-Sleep -Seconds 20; `
docker exec kafka kafka-topics --create --topic housing-data --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --if-not-exists; `
cd producer; mvn clean package; cd ..; `
bash submit_consumer.sh; `
Start-Sleep -Seconds 5; `
cd producer; mvn exec:java@default; `
Start-Sleep -Seconds 60; `
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
```

---

## 📈 TEMPS TOTAL

| Étape | Temps |
|-------|-------|
| Terminal 1 (Infrastructure) | 2-3 minutes |
| Terminal 2 (Spark) | 1 minute |
| Terminal 3 (Producer) | 30-60 secondes |
| Terminal 4 (Vérification) | 2 minutes (dont 1 min d'attente) |
| **TOTAL** | **~5-7 minutes** |

---

## ✅ SUCCÈS = CES 4 SIGNES

1. **Terminal 3 affiche:** `Sent batch of 6 records to Kafka`
2. **Terminal 4 affiche:** `506` records dans PostgreSQL
3. **Kafka UI (8082):** Voit le topic avec 6 messages
4. **PgAdmin (5050):** Affiche 506 rows dans la table housing

Si vous voyez ces 4 points = **SUCCÈS COMPLET ✅**

