#!/bin/bash

echo "================================================"
echo "  PIPELINE KAFKA-SPARK-POSTGRES TEST SUITE"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Test 1: Check Docker
print_step "Test 1: Checking Docker services..."
RUNNING=$(docker ps -q | wc -l)
if [ $RUNNING -ge 7 ]; then
    print_success "All Docker services running ($RUNNING containers)"
else
    print_error "Not all services running (expected 7, found $RUNNING)"
    echo "Starting docker-compose..."
    docker-compose up -d
    sleep 20
fi
echo ""

# Test 2: Check Kafka Topic
print_step "Test 2: Checking Kafka topic..."
TOPICS=$(docker exec kafka kafka-topics --list --bootstrap-server localhost:9092)
if echo "$TOPICS" | grep -q "housing-data"; then
    print_success "Topic 'housing-data' exists"
else
    print_warning "Topic does not exist, creating..."
    bash create_topic.sh
fi
echo ""

# Test 3: Check PostgreSQL Connection
print_step "Test 3: Checking PostgreSQL connection..."
if docker exec -i postgres psql -U kafka_user -d kafka_streaming -c "SELECT 1" > /dev/null 2>&1; then
    print_success "PostgreSQL connection OK"
else
    print_error "Cannot connect to PostgreSQL"
    exit 1
fi
echo ""

# Test 4: Check housing table
print_step "Test 4: Checking housing table..."
if docker exec -i postgres psql -U kafka_user -d kafka_streaming -c "SELECT * FROM housing LIMIT 1" > /dev/null 2>&1; then
    print_success "Table 'housing' exists"
    COUNT=$(docker exec postgres psql -U kafka_user -d kafka_streaming -c "SELECT COUNT(*) FROM housing;" | grep -oE '[0-9]+' | head -1)
    echo -e "  Records in table: ${BLUE}$COUNT${NC}"
else
    print_error "Table 'housing' does not exist"
    exit 1
fi
echo ""

# Test 5: Check Kafka messages
print_step "Test 5: Checking Kafka messages..."
MESSAGES=$(docker exec kafka kafka-console-consumer \
    --topic housing-data \
    --bootstrap-server localhost:9092 \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 5000 2>/dev/null | wc -l)

if [ $MESSAGES -gt 0 ]; then
    print_success "Messages found in Kafka topic"
else
    print_warning "No messages in Kafka topic (run producer first)"
fi
echo ""

# Test 6: Check Spark Cluster
print_step "Test 6: Checking Spark cluster..."
SPARK_STATUS=$(docker exec spark-master curl -s http://localhost:8080/json | grep -o '"status":"ALIVE"' | wc -l)
if [ $SPARK_STATUS -gt 0 ]; then
    print_success "Spark cluster is running"
else
    print_warning "Spark cluster status unknown"
fi
echo ""

# Test 7: Display Web Interfaces
print_step "Test 7: Web Interfaces Available"
echo -e "  ${BLUE}Kafka UI${NC}: http://localhost:8082"
echo -e "  ${BLUE}Spark Master${NC}: http://localhost:8080"
echo -e "  ${BLUE}Spark Worker${NC}: http://localhost:8081"
echo -e "  ${BLUE}PgAdmin${NC}: http://localhost:5050 (admin@example.com / admin)"
echo ""

# Test 8: Summary Statistics
print_step "Test 8: Database Summary"
echo ""
STATS=$(docker exec postgres psql -U kafka_user -d kafka_streaming -t -c \
    "SELECT COUNT(*) as total, 
            ROUND(AVG(medv)::numeric, 2) as avg_medv,
            MIN(medv) as min_medv,
            MAX(medv) as max_medv
     FROM housing;")

echo "$STATS" | while read line; do
    if [ ! -z "$line" ]; then
        echo -e "  ${BLUE}$line${NC}"
    fi
done
echo ""

echo "================================================"
print_success "Test suite completed!"
echo "================================================"
echo ""

# Next steps
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "1. If Kafka has no messages, run the Producer:"
echo "   cd producer && mvn exec:java@default"
echo ""
echo "2. If no Spark job running, submit consumer:"
echo "   bash submit_consumer.sh"
echo ""
echo "3. Open web interfaces to monitor:"
echo "   - Kafka UI: http://localhost:8082"
echo "   - Spark: http://localhost:8080"
echo "   - PgAdmin: http://localhost:5050"
echo ""
