#!/bin/bash
set -e

echo "==========================================="
echo "Viewing SonarQube logs on Railway..."
echo "Press CTRL+C to exit logs"
echo "==========================================="

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "Railway CLI not found, installing..."
    npm i -g @railway/cli
fi

# Login to Railway if needed
if ! railway whoami &> /dev/null; then
    echo "Logging in to Railway in browserless mode..."
    railway login --browserless
fi

# Link to project if not already linked
if ! railway status &> /dev/null; then
    echo "Not linked to a Railway project. Linking now..."
    railway link
fi

# View logs
echo "Fetching logs..."
railway logs