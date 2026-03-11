#!/bin/bash
# ============================================================
# Inbox Zero Commander — gws CLI Setup
# Verify and configure gws CLI for Gmail access
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_step() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Step $1: $2${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}  $1${NC}"
}

print_error() {
    echo -e "${RED}  $1${NC}"
}

# ============================================================
# Header
# ============================================================
echo ""
echo -e "${BOLD}  Inbox Zero Commander — gws CLI Setup${NC}"
echo -e "  Verify and configure gws for Gmail access"
echo ""

# ============================================================
# Step 1: Check if gws CLI is installed
# ============================================================
print_step "1" "Checking for gws CLI"

if ! command -v gws &> /dev/null; then
    print_error "gws CLI is not installed or not on PATH."
    echo ""
    echo "  Install gws following your organization's installation guide,"
    echo "  then re-run this setup script."
    echo ""
    exit 1
fi

GWS_VERSION=$(gws --version 2>/dev/null || echo "unknown")
print_success "gws CLI found — version: $GWS_VERSION"

# ============================================================
# Step 2: Check authentication status
# ============================================================
print_step "2" "Checking Gmail authentication"

if gws gmail +triage --max 1 --format json &> /dev/null; then
    print_success "Gmail authentication — OK"
else
    print_warning "Gmail authentication required."
    echo ""
    echo "  Running: gws auth login"
    echo ""
    gws auth login
fi

# ============================================================
# Step 3: Verify Gmail access
# ============================================================
print_step "3" "Verifying Gmail access"

if gws gmail +triage --max 1 --format json &> /dev/null; then
    print_success "Gmail access — OK"
    echo ""
    echo -e "${GREEN}${BOLD}  Setup complete!${NC}"
    echo ""
    echo "  Your Gmail is now connected via gws CLI."
    echo "  Use the plugin in Claude Desktop Code tab:"
    echo ""
    echo "    /founder-os-inbox-zero:inbox-triage"
    echo ""
else
    print_error "Gmail access failed after authentication."
    echo ""
    echo "  Try running manually:"
    echo "    gws auth login"
    echo "    gws gmail +triage --max 1 --format json"
    echo ""
    exit 1
fi
