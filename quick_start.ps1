# Quick Start Script for Kafka-Spark-Postgres Pipeline on Windows PowerShell

function Print-Success { Write-Host "[✓] $args" -ForegroundColor Green }
function Print-Error { Write-Host "[✗] $args" -ForegroundColor Red }
function Print-Step { Write-Host "[STEP] $args" -ForegroundColor Cyan }
function Print-Warning { Write-Host "[!] $args" -ForegroundColor Yellow }

$SCRIPT_DIR = Get-Location

Print-Step "KAFKA-SPARK-POSTGRES PIPELINE STARTUP"
Write-Host "================================================`n"

# Function 1: Start Docker Services
function Start-Services {
    Print-Step "Starting Docker services..."
    docker-compose up -d
    Print-Success "Docker services started"
    Write-Host "Waiting 25 seconds for services to be ready..."
    Start-Sleep -Seconds 25
}

# Function 2: Create Kafka Topic
function Create-Topic {
    Print-Step "Creating Kafka topic..."
    $topicExists = docker exec kafka kafka-topics --list --bootstrap-server localhost:9092 | Select-String "housing-data"
    
    if ($topicExists) {
        Print-Success "Topic already exists"
    } else {
        docker exec kafka kafka-topics --create `
            --topic housing-data `
            --bootstrap-server localhost:9092 `
            --partitions 1 `
            --replication-factor 1 `
            --if-not-exists
        Print-Success "Topic created"
    }
}

# Function 3: Build Producer
function Build-Producer {
    Print-Step "Building Java Producer..."
    Push-Location producer
    mvn clean package -q
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Producer built successfully"
    } else {
        Print-Error "Producer build failed"
        Pop-Location
        return $false
    }
    Pop-Location
    return $true
}

# Function 4: Run Producer
function Run-Producer {
    Print-Step "Running Producer (sending data to Kafka)..."
    Push-Location producer
    mvn exec:java@default
    Pop-Location
}

# Function 5: Submit Spark Job
function Submit-Spark-Job {
    Print-Step "Submitting Spark Streaming job..."
    bash submit_consumer.sh
    Print-Success "Spark job submitted"
}

# Function 6: Check Database
function Check-Database {
    Print-Step "Checking PostgreSQL data..."
    $count = docker exec postgres psql -U kafka_user -d kafka_streaming -t -c "SELECT COUNT(*) FROM housing;" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[0-9]+$' }
    Print-Success "Total records in database: $count"
}

# Function 7: Show Web Interfaces
function Show-Interfaces {
    Print-Step "Web Interfaces Available:"
    Write-Host "  🔵 Kafka UI: http://localhost:8082" -ForegroundColor Cyan
    Write-Host "  🟠 Spark Master: http://localhost:8080" -ForegroundColor Cyan
    Write-Host "  🟠 Spark Worker: http://localhost:8081" -ForegroundColor Cyan
    Write-Host "  🐘 PgAdmin: http://localhost:5050" -ForegroundColor Cyan
    Write-Host "     Login: admin@example.com / admin`n"
}

# Main Menu
function Show-Menu {
    Write-Host "`n================================================"
    Write-Host "KAFKA-SPARK-POSTGRES PIPELINE MENU" -ForegroundColor Cyan
    Write-Host "================================================"
    Write-Host "1. [FULL] Start everything and test"
    Write-Host "2. Start Docker services only"
    Write-Host "3. Create Kafka topic"
    Write-Host "4. Build Producer"
    Write-Host "5. Run Producer (sends data to Kafka)"
    Write-Host "6. Submit Spark Streaming job"
    Write-Host "7. Check database records"
    Write-Host "8. Run all tests"
    Write-Host "9. Stop all services (docker-compose down)"
    Write-Host "10. Show web interfaces"
    Write-Host "11. Exit"
    Write-Host "================================================"
    $choice = Read-Host "Enter your choice (1-11)"
    return $choice
}

# Run Full Test Suite
function Run-All-Tests {
    Print-Step "Running full test suite..."
    Write-Host ""
    
    # Check Docker
    Print-Step "Test 1: Checking Docker services..."
    $running = (docker ps --format "{{.Names}}" | Measure-Object -Line).Lines
    if ($running -ge 7) {
        Print-Success "All services running ($running containers)"
    } else {
        Print-Warning "Only $running containers running (expected 7)"
        Print-Step "Starting services..."
        Start-Services
    }
    Write-Host ""
    
    # Check Topic
    Print-Step "Test 2: Checking Kafka topic..."
    $topic = docker exec kafka kafka-topics --list --bootstrap-server localhost:9092 | Select-String "housing-data"
    if ($topic) {
        Print-Success "Topic 'housing-data' exists"
    } else {
        Print-Warning "Creating topic..."
        Create-Topic
    }
    Write-Host ""
    
    # Check PostgreSQL
    Print-Step "Test 3: Checking PostgreSQL..."
    try {
        docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT 1" > $null 2>&1
        Print-Success "PostgreSQL connection OK"
    } catch {
        Print-Error "Cannot connect to PostgreSQL"
        return
    }
    Write-Host ""
    
    # Check Table
    Print-Step "Test 4: Checking housing table..."
    try {
        docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT * FROM housing LIMIT 1" > $null 2>&1
        Print-Success "Table 'housing' exists"
        Check-Database
    } catch {
        Print-Error "Table error"
    }
    Write-Host ""
    
    # Show Interfaces
    Show-Interfaces
    
    Print-Success "All tests completed!"
}

# Stop Services
function Stop-Services {
    Print-Warning "Stopping all services..."
    docker-compose down
    Print-Success "Services stopped"
}

# Main Loop
while ($true) {
    $choice = Show-Menu
    
    switch ($choice) {
        "1" {
            Start-Services
            Create-Topic
            if (Build-Producer) {
                # Ask user if they want to run producer
                $runProd = Read-Host "`nRun Producer now? (y/n)"
                if ($runProd -eq "y") {
                    Run-Producer
                }
            }
            Print-Step "Now run these commands in separate terminals:"
            Write-Host "  Terminal 2: bash submit_consumer.sh"
            Write-Host "  Terminal 3: cd producer && mvn exec:java@default"
        }
        "2" {
            Start-Services
        }
        "3" {
            Create-Topic
        }
        "4" {
            Build-Producer
        }
        "5" {
            Run-Producer
        }
        "6" {
            Submit-Spark-Job
        }
        "7" {
            Check-Database
        }
        "8" {
            Run-All-Tests
        }
        "9" {
            Stop-Services
        }
        "10" {
            Show-Interfaces
        }
        "11" {
            Print-Success "Exiting..."
            exit 0
        }
        default {
            Print-Error "Invalid choice. Please try again."
        }
    }
}
