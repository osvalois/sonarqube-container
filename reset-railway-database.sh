#!/bin/bash
set -e

echo "==========================================="
echo "WARNING: This script will reset your SonarQube database on Railway"
echo "All projects, issues, and settings will be LOST!"
echo "==========================================="
echo "Press CTRL+C to cancel or ENTER to continue"
read

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "Railway CLI not found, installing..."
    npm i -g @railway/cli
fi

# Login to Railway if needed
echo "Logging in to Railway in browserless mode..."
railway login --browserless

# Link to project if not already linked
if ! railway status &> /dev/null; then
    echo "Not linked to a Railway project. Linking now..."
    railway link
fi

# Get database information from Railway environment
echo "Retrieving database information from Railway..."
# List all variables and filter with grep
RAILWAY_VARS=$(railway variables)
POSTGRES_URL=$(echo "$RAILWAY_VARS" | grep "SONAR_JDBC_URL" | awk '{print $2}')
POSTGRES_USER=$(echo "$RAILWAY_VARS" | grep "SONAR_JDBC_USERNAME" | awk '{print $2}')
POSTGRES_PASSWORD=$(echo "$RAILWAY_VARS" | grep "SONAR_JDBC_PASSWORD" | awk '{print $2}')

if [ -z "$POSTGRES_URL" ] || [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]; then
    echo "Could not retrieve database information from Railway."
    echo "Please make sure you're linked to the correct project and have PostgreSQL configured."
    exit 1
fi

echo "Database information retrieved successfully."

# Extract database name and host from JDBC URL
if [[ $POSTGRES_URL =~ jdbc:postgresql://([^/]+)/([^?]+) ]]; then
    DB_HOST="${BASH_REMATCH[1]}"
    DB_NAME="${BASH_REMATCH[2]%%\?*}"
    
    echo "Database Host: $DB_HOST"
    echo "Database Name: $DB_NAME"
    
    # Check if psql is installed
    if ! command -v psql &> /dev/null; then
        echo "PostgreSQL client (psql) is not installed."
        echo "Please install PostgreSQL client tools and try again."
        exit 1
    fi
    
    echo "Connecting to database and dropping all tables..."
    
    # Connect to the database and drop all tables
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$DB_HOST" -U "$POSTGRES_USER" -d "$DB_NAME" -c "
    DO \$\$ DECLARE
        r RECORD;
    BEGIN
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
            EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
        END LOOP;
    END \$\$;
    "
    
    echo "Database reset complete. SonarQube will recreate the schema on next start."
else
    echo "Could not parse JDBC URL. Please reset the database manually."
    echo "JDBC URL: $POSTGRES_URL"
fi

echo "==========================================="
echo "Restarting SonarQube service on Railway..."
railway service restart

echo "==========================================="
echo "Database has been reset and SonarQube is restarting."
echo "It may take a few minutes for SonarQube to initialize the new database."
echo "==========================================="