#!/bin/bash
# Script to check and fix system requirements for SonarQube's Elasticsearch
# This script addresses the common "max virtual memory areas vm.max_map_count" error

echo "=== SonarQube Elasticsearch System Requirements Check ==="

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Warning: This script should be run as root to modify system settings."
    echo "Please run with sudo: sudo $0"
    exit 1
fi

# Function to check vm.max_map_count
check_max_map_count() {
    local current_value
    current_value=$(sysctl -n vm.max_map_count 2>/dev/null)
    local result=$?
    
    if [ $result -ne 0 ]; then
        echo "❌ Error: Could not check vm.max_map_count value."
        return 1
    fi
    
    echo "📊 Current vm.max_map_count = $current_value"
    
    if [ "$current_value" -lt 262144 ]; then
        echo "❌ Value too low: Elasticsearch requires at least 262144"
        return 1
    else
        echo "✅ Value sufficient for Elasticsearch"
        return 0
    fi
}

# Function to fix vm.max_map_count
fix_max_map_count() {
    echo "🔧 Setting vm.max_map_count to 262144..."
    
    if sysctl -w vm.max_map_count=262144; then
        echo "✅ Successfully set vm.max_map_count=262144"
    else
        echo "❌ Failed to set vm.max_map_count"
        return 1
    fi
    
    # Check if already in sysctl.conf
    if grep -q "vm.max_map_count" /etc/sysctl.conf; then
        echo "📝 Updating vm.max_map_count in /etc/sysctl.conf..."
        sed -i 's/vm.max_map_count=[0-9]*/vm.max_map_count=262144/' /etc/sysctl.conf
    else
        echo "📝 Adding vm.max_map_count to /etc/sysctl.conf for persistence..."
        echo "vm.max_map_count=262144" >> /etc/sysctl.conf
    fi
    
    echo "✅ Changes will persist after reboot."
    return 0
}

# Function to check file descriptors limit
check_file_descriptors() {
    local soft_limit
    soft_limit=$(ulimit -Sn)
    local hard_limit
    hard_limit=$(ulimit -Hn)
    
    echo "📊 Current file descriptor limits: soft=$soft_limit, hard=$hard_limit"
    
    if [ "$soft_limit" -lt 65536 ] || [ "$hard_limit" -lt 65536 ]; then
        echo "❌ File descriptor limits too low. SonarQube recommends at least 65536."
        return 1
    else
        echo "✅ File descriptor limits are sufficient."
        return 0
    fi
}

# Function to suggest fixes for file descriptors
suggest_file_descriptor_fix() {
    echo "🔧 To increase file descriptor limits:"
    echo "1. Edit /etc/security/limits.conf as root"
    echo "2. Add the following lines:"
    echo "   *               soft    nofile          65536"
    echo "   *               hard    nofile          65536"
    echo "3. Save the file and log out and back in for changes to take effect"
}

# Main execution
echo "Checking vm.max_map_count..."
if ! check_max_map_count; then
    echo "Do you want to fix vm.max_map_count now? (y/n)"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        fix_max_map_count
    else
        echo "❌ vm.max_map_count remains too low for Elasticsearch."
    fi
fi

echo ""
echo "Checking file descriptor limits..."
if ! check_file_descriptors; then
    suggest_file_descriptor_fix
fi

echo ""
echo "=== Summary ==="
echo "To ensure SonarQube works properly:"
echo "1. vm.max_map_count must be at least 262144"
echo "2. File descriptor limits should be at least 65536"
echo "3. These settings must be applied on the Docker host, not just in the container"
echo ""
echo "For Kubernetes deployments, use an init container with privileged access."
echo "See the k8s/init-sysctl.yaml example file for details."
echo ""
echo "For more information: https://docs.sonarqube.org/latest/requirements/prerequisites-and-overview/"