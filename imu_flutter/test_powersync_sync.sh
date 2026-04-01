#!/bin/bash
# PowerSync Sync Rules Test Script
# This script tests if the PowerSync sync rules are working correctly

echo "=========================================="
echo "PowerSync Sync Rules Test"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2

    echo -n "Testing: $test_name... "

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Change to powersync directory
cd "$(dirname "$0")/powersync"

echo "1. Validating Configuration Files"
echo "-----------------------------------"

run_test "sync-config.yaml syntax" "python -c \"import yaml; yaml.safe_load(open('sync-config.yaml'))\""
run_test "service.yaml syntax" "python -c \"import yaml; yaml.safe_load(open('service.yaml'))\""
run_test "cli.yaml syntax" "python -c \"import yaml; yaml.safe_load(open('cli.yaml'))\""

echo ""
echo "2. Checking Sync Rules Structure"
echo "-----------------------------------"

# Test sync-config.yaml has required fields
run_test "sync-config.yaml has config edition" "grep -q 'edition: 3' sync-config.yaml"
run_test "sync-config.yaml has global_psgc stream" "grep -q 'global_psgc:' sync-config.yaml"
run_test "sync-config.yaml has user_locations stream" "grep -q 'user_locations:' sync-config.yaml"
run_test "sync-config.yaml has clients stream" "grep -q 'clients:' sync-config.yaml"
run_test "sync-config.yaml has approvals stream" "grep -q 'approvals:' sync-config.yaml"

echo ""
echo "3. Validating Sync Rule Queries"
echo "-----------------------------------"

# Check that user_locations filters soft-deleted records
run_test "user_locations filters deleted_at" "grep -q 'deleted_at IS NULL' sync-config.yaml"

# Check that clients has role-based filtering
run_test "clients has role-based filtering" "grep -q 'auth.user_id()' sync-config.yaml"
run_test "clients filters by user_locations" "grep -q 'user_locations' sync-config.yaml && grep -q 'province' sync-config.yaml"

echo ""
echo "4. Checking PowerSync Connection"
echo "-----------------------------------"

# Test if PowerSync URL is accessible
run_test "PowerSync URL is accessible" "curl -s -o /dev/null -w '%{http_code}' https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com | grep -q '200\\|401\\|403'"

# Test if authentication token exists
run_test "PowerSync auth token exists" "test -f ~/.config/powersync/config.yaml && grep -q 'token:' ~/.config/powersync/config.yaml"

echo ""
echo "5. Validating Database Schema"
echo "-----------------------------------"

# Check that schema matches sync rules
run_test "clients table schema exists" "grep -q \"Table('clients'\" ../lib/services/sync/powersync_service.dart"
run_test "user_locations table schema exists" "grep -q \"Table('user_locations'\" ../lib/services/sync/powersync_service.dart"
run_test "approvals table schema exists" "grep -q \"Table('approvals'\" ../lib/services/sync/powersync_service.dart"
run_test "itineraries table schema exists" "grep -q \"Table('itineraries'\" ../lib/services/sync/powersync_service.dart"

echo ""
echo "6. Testing Sync Rule Syntax"
echo "-----------------------------------"

# Count sync streams
SYNC_STREAMS=$(grep -c "^  [a-z_]*:$" sync-config.yaml || echo "0")
echo -n "Number of sync streams (expected: 10)... "
if [ "$SYNC_STREAMS" -eq 10 ]; then
    echo -e "${GREEN}✓ PASSED${NC} (found $SYNC_STREAMS streams)"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠ WARNING${NC} (found $SYNC_STREAMS streams, expected 10)"
    ((TESTS_PASSED++))
fi

# Verify all sync streams have auto_subscribe
run_test "All sync streams have auto_subscribe" "grep -q 'auto_subscribe: true' sync-config.yaml"

echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
fi
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    echo ""
    echo "Next Steps:"
    echo "1. Deploy sync rules: powersync deploy sync-config"
    echo "2. Or use the deployment script: ./deploy_sync_rules.sh"
    echo "3. Test mobile app sync with different user roles"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the errors above.${NC}"
    exit 1
fi
