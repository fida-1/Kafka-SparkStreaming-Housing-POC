# ⚡ QUICK START - 5 MINUTES

## 🚀 Exécution en 5 étapes

### Étape 1: Ouvrez 4 terminals PowerShell

Pour cela, appuyez 4 fois sur `Windows + Alt + T` ou ouvrez manuellement 4 PowerShell

---

## ✅ Terminal 1: Infrastructure

Copier-coller ceci:

```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming

# Démarrer Docker
docker-compose up -d

# Attendre
Write-Host "Attente de 20 secondes..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Créer le topic
docker exec kafka kafka-topics --create --topic housing-data --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --if-not-exists

# Compiler le producer
cd producer
mvn clean package
cd ..

Write-Host "✅ Infrastructure prête!" -ForegroundColor Green
Write-Host "Allez au Terminal 2..." -ForegroundColor Cyan
```

⏱️ **Temps: ~2-3 minutes** (attendre le Maven build)

---

## ✅ Terminal 2: Spark Consumer

Copier-coller ceci:

```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming

# Soumettre le job Spark
bash submit_consumer.sh

Write-Host "✅ Spark Streaming Job soumis!" -ForegroundColor Green
```

⏱️ **Temps: ~1 minute**

---

## ✅ Terminal 3: Producer

Copier-coller ceci:

```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming\producer

# Exécuter le producer (envoie les données)
mvn exec:java@default

# Attendez de voir "Sent batch of X records" plusieurs fois
# puis que ça se termine
```

⏱️ **Temps: ~30 secondes**

---

## ✅ Terminal 4: Vérification

Une fois que le Terminal 3 a fini, copier-coller ceci:

```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming

# Vérifier le nombre de records
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"

# Résultat attendu: 506 ✅
```

---

## 🌐 Ouvrir les Interfaces Web

Pendant que vous attendez, ouvrez ces URLs:

```powershell
Start-Process "http://localhost:8082"   # Kafka UI - voir les messages
Start-Process "http://localhost:8080"   # Spark - voir le job
Start-Process "http://localhost:5050"   # PgAdmin - voir les données
```

---

## 📋 Checklist Finale

- [ ] Terminal 1: ✅ Infrastructure prête
- [ ] Terminal 2: ✅ Spark job soumis
- [ ] Terminal 3: ✅ Producer exécuté (6 batches envoyés)
- [ ] Terminal 4: ✅ 506 records dans PostgreSQL
- [ ] Kafka UI: ✅ Messages visibles
- [ ] Spark UI: ✅ Application RUNNING
- [ ] PgAdmin: ✅ Données présentes

---

## 🎉 C'est Fait!

Le pipeline fonctionne! Les données CSV sont:
1. ✅ Divisées en microbatches
2. ✅ Envoyées via Kafka
3. ✅ Traitées par Spark Streaming
4. ✅ Stockées dans PostgreSQL

---

## 📖 Pour Aller Plus Loin

- **Documentation complète**: Lire `README_COMPLET.md`
- **Commandes détaillées**: Lire `COMMANDES_PRINCIPALES.md`
- **Guide PowerShell**: Lire `POWERSHELL_GUIDE.md`
- **Troubleshooting**: Lire `GUIDE_EXECUTION.md`

---

## 🆘 Ça N'a Pas Marché?

### Problème: Terminal 1 - Maven timeout
**Solution**: Attendre plus longtemps ou relancer:
```powershell
cd producer
mvn clean package -T 1
```

### Problème: Terminal 2 - psycopg2 error
**Solution**: Déjà installé automatiquement, attendez juste
```powershell
docker exec spark-master pip install psycopg2-binary
```

### Problème: Terminal 3 - Producer stuck
**Solution**: Vérifier Kafka est ready:
```powershell
docker logs kafka | tail -20
```

### Problème: Terminal 4 - 0 records
**Solution**: Attendez 60 secondes après que le Producer ait fini

### Problème: Kafka UI/Spark UI ne marche pas
**Solution**: Vérifier que les ports sont accessibles:
```powershell
docker ps  # Vérifier que les services tournent
```

---

## ⏰ Chronométrage Attendu

| Étape | Temps | Note |
|-------|-------|------|
| Terminal 1 | 2-3 min | Maven build inclus |
| Terminal 2 | 1 min | Soumission du job |
| Terminal 3 | 30 sec | Envoi des données |
| Terminal 4 | Immédiat | Vérification |
| **TOTAL** | **~4-5 min** | ✅ |

---

## 💡 Tips

1. **Ne fermez pas les terminals** - ils continuent de tourner
2. **Les Web Interfaces** - ouvrez-les pendant le temps d'attente
3. **Les logs** - utiles pour déboguer si quelque chose ne marche pas
4. **PgAdmin** - login avec `admin@example.com / admin`

---

## 🎯 Ensuite?

Explorez:
- Requêtes SQL avancées dans PgAdmin
- Augmentez le batch size du Producer
- Monitorer en temps réel via Spark UI
- Exporter les données en CSV

