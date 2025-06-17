#!/bin/bash
set -e

echo "==========================================="
echo "WARNING: This script will reset your SonarQube database"
echo "All projects, issues, and settings will be LOST!"
echo "==========================================="
echo "Press CTRL+C to cancel or ENTER to continue"
read

# Extract database info from Railway.toml
if [ -f railway.toml ]; then
    JDBC_URL=$(grep "SONAR_JDBC_URL" railway.toml | cut -d '=' -f2 | tr -d ' "')
    DB_USER=$(grep "SONAR_JDBC_USERNAME" railway.toml | cut -d '=' -f2 | tr -d ' "')
    DB_PASS=$(grep "SONAR_JDBC_PASSWORD" railway.toml | cut -d '=' -f2 | tr -d ' "')
    
    echo "Found database connection in railway.toml"
    
    # Extract database name and host from JDBC URL
    if [[ $JDBC_URL =~ jdbc:postgresql://([^/]+)/([^?]+) ]]; then
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
        PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "
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
        echo "JDBC URL: $JDBC_URL"
    fi
else
    echo "railway.toml not found. Please reset the database manually."
fi

echo "==========================================="
echo "Now you can redeploy SonarQube to Railway."
echo "==========================================="