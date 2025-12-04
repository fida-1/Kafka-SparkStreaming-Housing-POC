# 🔧 GUIDE POWERSHELL - Commandes et Astuces

## 🎯 EXÉCUTION RAPIDE (Copier-Coller dans PowerShell)

### 1️⃣ Démarrer tout
```powershell
# Étape 1: Démarrer Docker (Terminal 1)
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
docker-compose up -d

# Attendre 20 secondes
Start-Sleep -Seconds 20

# Étape 2: Créer le topic
docker exec kafka kafka-topics --create `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --partitions 1 `
  --replication-factor 1 `
  --if-not-exists

# Étape 3: Compiler le producer
cd producer
mvn clean package
cd ..

Write-Host "✅ Infrastructure prête!" -ForegroundColor Green
Write-Host "Maintenant, ouvrez 2 autres terminals PowerShell..."
```

### 2️⃣ Soumettre le job Spark (Terminal 2)
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming
bash submit_consumer.sh
# Attendez de voir: "Submitting Spark Streaming job..."
```

### 3️⃣ Exécuter le Producer (Terminal 3)
```powershell
cd C:\Users\khamm\OneDrive\Bureau\Kafka-SparkTreaming\producer
mvn exec:java@default
# Attendez que tous les batches soient envoyés
```

### 4️⃣ Vérifier les résultats (Terminal 4)
```powershell
# Attendre 30-60 secondes après que le producer ait fini
Start-Sleep -Seconds 60

docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
# Résultat attendu: count = 506
```

---

## 🌐 Ouvrir les Interfaces Web

```powershell
# Kafka UI
Start-Process "http://localhost:8082"

# Spark Master
Start-Process "http://localhost:8080"

# Spark Worker
Start-Process "http://localhost:8081"

# PgAdmin
Start-Process "http://localhost:5050"
```

---

## 📊 COMMANDES DE VÉRIFICATION

### Vérifier que tous les services tournent
```powershell
docker ps

# Alternative: Afficher uniquement les noms et statuts
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Vérifier le topic Kafka
```powershell
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

# Détails du topic
docker exec kafka kafka-topics --describe --topic housing-data --bootstrap-server localhost:9092
```

### Vérifier les messages Kafka
```powershell
docker exec kafka kafka-console-consumer `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --from-beginning `
  --max-messages 2

# Voir le format JSON du premier message:
docker exec kafka kafka-console-consumer `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --from-beginning `
  --max-messages 1 | ConvertFrom-Json
```

### Vérifier PostgreSQL
```powershell
# Nombre de records
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"

# Voir les premières données
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT * FROM housing LIMIT 5;"

# Statistiques
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*), AVG(medv), MIN(medv), MAX(medv) FROM housing;"

# Voir les données les plus récentes
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT *, created_at FROM housing ORDER BY created_at DESC LIMIT 5;"
```

### Vérifier Spark
```powershell
# Voir les applications
docker exec spark-master curl -s http://localhost:8080/json | ConvertFrom-Json | Select-Object -ExpandProperty workers

# Voir la mémoire utilisée
docker exec spark-master curl -s http://localhost:8080/json | ConvertFrom-Json
```

---

## 📜 VOIR LES LOGS

### Logs en temps réel
```powershell
# Kafka
docker logs -f kafka

# Spark Master
docker logs -f spark-master

# Spark Worker
docker logs -f spark-worker

# PostgreSQL
docker logs -f postgres

# Toutes les 10 dernières lignes d'un service
docker logs --tail 10 kafka
```

### Sauvegarder les logs dans un fichier
```powershell
docker logs kafka > kafka_logs.txt
docker logs spark-master > spark_logs.txt
docker logs postgres > postgres_logs.txt

Write-Host "Logs sauvegardés!" -ForegroundColor Green
```

---

## 🧹 NETTOYAGE ET ARRÊT

### Arrêter temporairement (garder les données)
```powershell
docker-compose stop
```

### Redémarrer
```powershell
docker-compose start
```

### Supprimer les containers (garder les données)
```powershell
docker-compose down
```

### Supprimer TOUT y compris les données
```powershell
docker-compose down -v
Write-Host "✅ Tous les containers et données supprimés!" -ForegroundColor Green
```

### Nettoyer les images non utilisées
```powershell
docker image prune -a
```

---

## 🔍 DEBUGGING ET TROUBLESHOOTING

### Accéder au shell d'un container
```powershell
# Spark
docker exec -it spark-master bash

# PostgreSQL
docker exec -it postgres bash

# Kafka
docker exec -it kafka bash
```

### Vérifier les ressources utilisées
```powershell
docker stats

# Seul Spark
docker stats spark-master

# Format tabletté avec refresh
docker stats --no-stream
```

### Redémarrer un service spécifique
```powershell
docker-compose restart spark-master
# Puis vérifier: docker logs -f spark-master
```

### Redémarrer Kafka complètement
```powershell
docker-compose restart kafka zookeeper
Start-Sleep -Seconds 10
```

### Forcer la suppression d'un container
```powershell
docker-compose down
docker rm -f spark-master spark-worker kafka zookeeper postgres
docker-compose up -d
```

---

## 🧪 TESTS AUTOMATISÉS

### Test complet du pipeline
```powershell
$WORKING = $true
$ERRORS = @()

# Test 1: Docker
$count = (docker ps | Measure-Object -Line).Lines
if ($count -lt 7) {
    $WORKING = $false
    $ERRORS += "❌ Seulement $count containers actifs (attendu 7)"
} else {
    Write-Host "✅ Tous les containers sont actifs" -ForegroundColor Green
}

# Test 2: Kafka
$topic = docker exec kafka kafka-topics --list --bootstrap-server localhost:9092 | Select-String "housing-data"
if (!$topic) {
    $WORKING = $false
    $ERRORS += "❌ Topic 'housing-data' n'existe pas"
} else {
    Write-Host "✅ Topic Kafka OK" -ForegroundColor Green
}

# Test 3: PostgreSQL
try {
    docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT 1" > $null 2>&1
    Write-Host "✅ PostgreSQL OK" -ForegroundColor Green
} catch {
    $WORKING = $false
    $ERRORS += "❌ PostgreSQL non accessible"
}

# Test 4: Données
$count = docker exec postgres psql -U kafka_user -d kafka_streaming -t -c "SELECT COUNT(*) FROM housing;" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[0-9]+$' }
Write-Host "ℹ️  Records en base: $count" -ForegroundColor Cyan

# Résumé
Write-Host ""
if ($WORKING) {
    Write-Host "🎉 TOUS LES TESTS RÉUSSIS!" -ForegroundColor Green
} else {
    Write-Host "⚠️  ERREURS DÉTECTÉES:" -ForegroundColor Red
    $ERRORS | ForEach-Object { Write-Host $_ }
}
```

---

## 🛠️ COMMANDES DE MAINTENANCE

### Rebuild du producer
```powershell
cd producer
mvn clean
mvn compile
mvn package
cd ..
Write-Host "✅ Producer recompilé!" -ForegroundColor Green
```

### Réinitialiser PostgreSQL
```powershell
# Supprimer et recréer les données
docker exec postgres psql -U kafka_user -d kafka_streaming -c "DROP TABLE IF EXISTS housing; CREATE TABLE housing (id SERIAL PRIMARY KEY, crim DOUBLE PRECISION, zn DOUBLE PRECISION, indus DOUBLE PRECISION, chas INTEGER, nox DOUBLE PRECISION, rm DOUBLE PRECISION, age DOUBLE PRECISION, dis DOUBLE PRECISION, rad INTEGER, tax INTEGER, ptratio DOUBLE PRECISION, b DOUBLE PRECISION, lstat DOUBLE PRECISION, medv DOUBLE PRECISION, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

Write-Host "✅ Table housing réinitialisée!" -ForegroundColor Green
```

### Exporter les données
```powershell
docker exec postgres pg_dump -U kafka_user kafka_streaming > backup_$(Get-Date -Format "yyyyMMdd_HHmmss").sql

Write-Host "✅ Données exportées!" -ForegroundColor Green
Get-ChildItem backup_*.sql | Sort-Object -Descending | Select-Object -First 1
```

### Importer des données sauvegardées
```powershell
$backupFile = Read-Host "Entrez le nom du fichier de sauvegarde (ex: backup_20240101_120000.sql)"

docker exec -i postgres psql -U kafka_user kafka_streaming < $backupFile

Write-Host "✅ Données importées!" -ForegroundColor Green
```

---

## 📈 COMMANDES DE PERFORMANCE

### Augmenter la mémoire Spark
**Éditez docker-compose.yml et ajoutez:**
```yaml
spark-master:
  environment:
    SPARK_DRIVER_MEMORY: 4g
    SPARK_EXECUTOR_MEMORY: 2g

spark-worker:
  environment:
    SPARK_EXECUTOR_MEMORY: 2g
```

Puis redémarrez:
```powershell
docker-compose restart spark-master spark-worker
```

### Voir la consommation mémoire en temps réel
```powershell
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Monitorer un processus spécifique
```powershell
while($true) {
    Clear-Host
    Write-Host "$(Get-Date): Statut Docker"
    docker stats --no-stream kafka spark-master postgres
    Start-Sleep -Seconds 5
}
```

---

## 🔐 COMMANDES D'ADMINISTRATION BD

### Accès direct à psql
```powershell
docker exec -it postgres psql -U kafka_user -d kafka_streaming
```

Puis à l'intérieur de psql:
```sql
-- Voir les tables
\dt

-- Voir le schéma d'une table
\d housing

-- Voir les statistiques
SELECT * FROM housing LIMIT 5;

-- Quitter
\q
```

### Sauvegarde PostgreSQL complète
```powershell
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "backup_full_$timestamp.sql"

docker exec postgres pg_dump -U kafka_user kafka_streaming > $backupFile

Write-Host "✅ Sauvegarde: $backupFile" -ForegroundColor Green
```

### Restauration PostgreSQL
```powershell
$backupFile = "backup_full_20240101_120000.sql"
docker exec -i postgres psql -U kafka_user kafka_streaming < $backupFile
Write-Host "✅ Restauration complétée!" -ForegroundColor Green
```

---

## 📊 COMMANDES DE REPORTING

### Rapport complet du système
```powershell
Write-Host "=== RAPPORT SYSTÈME ===" -ForegroundColor Cyan
Write-Host ""

# Docker
Write-Host "1️⃣  DOCKER SERVICES" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Status}}"

Write-Host ""
Write-Host "2️⃣  KAFKA TOPIC" -ForegroundColor Cyan
docker exec kafka kafka-topics --describe --topic housing-data --bootstrap-server localhost:9092

Write-Host ""
Write-Host "3️⃣  POSTGRESQL DATA" -ForegroundColor Cyan
docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) as total, AVG(medv)::numeric(5,2) as avg_medv FROM housing;"

Write-Host ""
Write-Host "4️⃣  RESSOURCES" -ForegroundColor Cyan
docker stats --no-stream

Write-Host ""
Write-Host "=== FIN RAPPORT ===" -ForegroundColor Cyan
```

---

## ⚡ SHORTCUTS & ALIASES

Ajouter à votre profil PowerShell (`$PROFILE`):

```powershell
# Ouvrir le profil
notepad $PROFILE

# Ajouter ces lignes:
Set-Alias dc docker-compose
Set-Alias de docker exec

function kafka-logs { docker logs -f kafka }
function spark-logs { docker logs -f spark-master }
function postgres-logs { docker logs -f postgres }

function check-count {
    docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;"
}

function check-all {
    Write-Host "Containers:" -ForegroundColor Cyan
    docker ps --format "table {{.Names}}\t{{.Status}}"
    Write-Host ""
    Write-Host "Records:" -ForegroundColor Cyan
    check-count
}
```

Puis redémarrer PowerShell et utiliser:
```powershell
dc up -d              # Docker compose
kafka-logs            # Voir les logs Kafka
spark-logs            # Voir les logs Spark
check-count           # Voir le nombre de records
check-all             # Voir tout
```

---

## 🎨 FORMATTING AVANCÉ

### Affichage coloré des résultats
```powershell
$count = docker exec postgres psql -U kafka_user -d kafka_streaming -t -c "SELECT COUNT(*) FROM housing;" | ForEach-Object { $_.Trim() }

if ([int]$count -eq 506) {
    Write-Host "✅ Succès! $count records" -ForegroundColor Green
} elseif ([int]$count -gt 0) {
    Write-Host "⚠️  Attention: $count records (attendu 506)" -ForegroundColor Yellow
} else {
    Write-Host "❌ Erreur: 0 records" -ForegroundColor Red
}
```

### Tableau formaté
```powershell
docker ps | Select-Object Names, Status, Image | Format-Table -AutoSize
```

### JSON parsing
```powershell
$json = docker exec kafka kafka-console-consumer `
  --topic housing-data `
  --bootstrap-server localhost:9092 `
  --from-beginning `
  --max-messages 1

$data = $json | ConvertFrom-Json
$data | ForEach-Object { Write-Host "Record: $_" }
```

---

## 🔄 AUTOMATION & SCHEDULING

### Script d'auto-vérification (Runs toutes les 5 minutes)
```powershell
# Sauvegarder comme: auto-check.ps1
while ($true) {
    Clear-Host
    Write-Host "$(Get-Date) - Auto-check en cours..."
    
    $count = docker exec postgres psql -U kafka_user -d kafka_streaming -t -c "SELECT COUNT(*) FROM housing;" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[0-9]+$' }
    
    Write-Host "Records: $count"
    Write-Host "Prochain check dans 5 minutes..."
    
    Start-Sleep -Seconds 300
}

# Exécuter:
powershell -NoExit -File auto-check.ps1
```

---

## 📞 AIDE & SUPPORT

```powershell
# Documentation complète
docker --help
docker-compose --help
docker exec --help

# Aide spécifique
docker logs --help
docker ps --help
docker stats --help

# Version Docker
docker --version
docker-compose --version
```

