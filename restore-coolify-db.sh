#!/bin/bash

# Coolify PostgreSQL Database Restore Script
# Usage: ./restore-coolify-db.sh [backup_date]

# Configuration
BACKUP_DIR="/data/coolify/backups/coolify/coolify-db-hostdockerinternal"
CONTAINER_NAME="coolify-db"
DB_USER="coolify"
DB_NAME="coolify"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to list available backups with human-readable dates
list_backups() {
    echo -e "${YELLOW}Available backups:${NC}"
    echo "----------------------------------------"
    printf "%-25s %-15s %s\n" "DATE" "TIMESTAMP" "FILEPATH"
    echo "----------------------------------------"
    
    for backup in "$BACKUP_DIR"/pg-dump-all-*.gz; do
        # Extract timestamp from filename
        timestamp=$(echo "$backup" | grep -o '[0-9]\+\.gz' | sed 's/\.gz//')
        
        # Convert Unix timestamp to human-readable date
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS date command
            human_date=$(date -r "$timestamp" "+%Y-%m-%d %H:%M:%S")
        else
            # Linux date command
            human_date=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S")
        fi
        
        printf "%-25s %-15s %s\n" "$human_date" "$timestamp" "$backup"
    done
}

# Function to restart Coolify containers
restart_coolify() {
    echo -e "\n${YELLOW}Restarting Coolify containers...${NC}"
    docker restart $(docker ps -q -f name=coolify*)
    
    echo -e "\n${YELLOW}Waiting for containers to be ready...${NC}"
    sleep 10  # Give containers time to start up
    
    echo -e "\n${YELLOW}Current Coolify container status:${NC}"
    docker ps -f name=coolify*
}

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}Error: Backup directory $BACKUP_DIR not found${NC}"
    exit 1
fi

# List available backups and handle backup selection
if [ "$1" ]; then
    BACKUP_FILE="$BACKUP_DIR/pg-dump-all-$1.gz"
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}Error: Backup file for date $1 not found${NC}"
        echo ""
        list_backups
        exit 1
    fi
else
    echo -e "${RED}No backup date specified.${NC}"
    echo ""
    list_backups
    echo ""
    echo "Please run the script with a backup timestamp."
    echo "Example: ./restore-coolify-db.sh 1737590401"
    exit 1
fi

echo -e "${GREEN}Starting database restore process...${NC}"
echo "Using backup file: $BACKUP_FILE"

# Extract backup file
echo -e "\n${YELLOW}Extracting backup file...${NC}"
EXTRACTED_FILE="/tmp/pg-dump-all-$1.sql"
gunzip -c "$BACKUP_FILE" > "$EXTRACTED_FILE"

# Copy to container
echo -e "\n${YELLOW}Copying backup file to container...${NC}"
docker cp "$EXTRACTED_FILE" "$CONTAINER_NAME:/tmp/"

# Execute restore commands in container
echo -e "\n${YELLOW}Executing restore commands in container...${NC}"
docker exec -i "$CONTAINER_NAME" bash << EOF
# Terminate existing connections
echo "Terminating existing connections..."
psql -U "$DB_USER" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();"

# Drop and recreate database
echo "Dropping and recreating database..."
psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;"

# Restore the database
echo "Restoring database..."
psql -U "$DB_USER" -d "$DB_NAME" -f "$EXTRACTED_FILE"

# Verify restoration
echo "Verifying restoration..."
echo "Table count:"
psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"
EOF

# Cleanup
echo -e "\n${YELLOW}Cleaning up temporary files...${NC}"
rm "$EXTRACTED_FILE"

# Restart Coolify containers
restart_coolify

echo -e "\n${GREEN}Restore process completed!${NC}"
echo ""
echo "To verify or make manual adjustments, you can connect to the container with:"
echo "docker exec -it $CONTAINER_NAME bash"

