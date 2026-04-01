#!/bin/bash
# PowerSync Sync Rules Deployment Script
# This script deploys the sync-config.yaml to PowerSync Cloud

set -e

echo "=========================================="
echo "PowerSync Sync Rules Deployment"
echo "=========================================="
echo ""

# Check if logged in
echo "Step 1: Checking authentication status..."
if ! powersync fetch instances &>/dev/null; then
  echo "Not authenticated. Please login first:"
  echo "  powersync login"
  echo ""
  exit 1
fi

echo "✓ Authenticated"
echo ""

# Validate configuration
echo "Step 2: Validating sync configuration..."
if ! powersync validate; then
  echo "✗ Validation failed. Please fix the errors before deploying."
  exit 1
fi

echo "✓ Configuration is valid"
echo ""

# Deploy sync rules
echo "Step 3: Deploying sync rules..."
echo "Instance: https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com"
echo ""

if powersync deploy sync-config; then
  echo ""
  echo "✓ Sync rules deployed successfully!"
  echo ""
  echo "Step 4: Verifying deployment..."
  powersync fetch status
  echo ""
  echo "=========================================="
  echo "Deployment completed successfully!"
  echo "=========================================="
else
  echo ""
  echo "✗ Deployment failed. Please check the errors above."
  exit 1
fi
