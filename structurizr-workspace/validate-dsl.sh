#!/bin/bash
#
# Structurizr DSL Validation Script
# Validates DSL syntax and structure before deploying changes
#
# Usage: ./validate-dsl.sh [workspace-directory]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default workspace directory
WORKSPACE_DIR="${1:-structurizr-ws}"
DSL_FILE="${WORKSPACE_DIR}/workspace.dsl"

# Statistics
ERRORS=0
WARNINGS=0
CHECKS=0

# Functions
print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE} Structurizr DSL Validation${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

print_check() {
    CHECKS=$((CHECKS + 1))
    echo -e "${BLUE}[CHECK $CHECKS]${NC} $1"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_warning() {
    WARNINGS=$((WARNINGS + 1))
    echo -e "  ${YELLOW}⚠${NC} $1"
}

print_error() {
    ERRORS=$((ERRORS + 1))
    echo -e "  ${RED}✗${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}ℹ${NC} $1"
}

print_summary() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE} Validation Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Checks performed: ${BLUE}$CHECKS${NC}"
    echo -e "Errors found:     ${RED}$ERRORS${NC}"
    echo -e "Warnings found:   ${YELLOW}$WARNINGS${NC}"
    echo ""

    if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed! DSL appears valid.${NC}"
        return 0
    elif [ $ERRORS -eq 0 ]; then
        echo -e "${YELLOW}⚠ Validation passed with warnings.${NC}"
        return 0
    else
        echo -e "${RED}✗ Validation failed! Please fix errors before deploying.${NC}"
        return 1
    fi
}

# Main validation logic
print_header

# Check 1: File exists
print_check "Checking if DSL file exists"
if [ ! -f "$DSL_FILE" ]; then
    print_error "DSL file not found: $DSL_FILE"
    exit 1
fi
print_success "File exists: $DSL_FILE"

# Check 2: File is readable
print_check "Checking file permissions"
if [ ! -r "$DSL_FILE" ]; then
    print_error "DSL file is not readable"
    exit 1
fi
print_success "File is readable"

# Check 3: File is not empty
print_check "Checking file is not empty"
if [ ! -s "$DSL_FILE" ]; then
    print_error "DSL file is empty"
    exit 1
fi
FILE_SIZE=$(wc -c < "$DSL_FILE")
print_success "File size: ${FILE_SIZE} bytes"

# Check 4: Basic structure
print_check "Checking basic DSL structure"
if ! grep -q "workspace" "$DSL_FILE"; then
    print_error "Missing 'workspace' declaration"
else
    print_success "Found workspace declaration"
fi

if ! grep -q "model {" "$DSL_FILE"; then
    print_error "Missing 'model' block"
else
    print_success "Found model block"
fi

if ! grep -q "views {" "$DSL_FILE"; then
    print_error "Missing 'views' block"
else
    print_success "Found views block"
fi

# Check 5: Brace balance
print_check "Checking brace balance"
OPEN_BRACES=$(grep -o '{' "$DSL_FILE" | wc -l)
CLOSE_BRACES=$(grep -o '}' "$DSL_FILE" | wc -l)

if [ "$OPEN_BRACES" -eq "$CLOSE_BRACES" ]; then
    print_success "Braces balanced ($OPEN_BRACES opening, $CLOSE_BRACES closing)"
else
    print_error "Unbalanced braces ($OPEN_BRACES opening, $CLOSE_BRACES closing)"
fi

# Check 6: Identifier format
print_check "Checking identifier declarations"
IDENTIFIERS=$(grep -E "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_-]* = (person|softwareSystem|container|component)" "$DSL_FILE" | wc -l)
if [ "$IDENTIFIERS" -gt 0 ]; then
    print_success "Found $IDENTIFIERS element declarations"

    # Check for invalid identifier characters
    INVALID_IDS=$(grep -E "^[[:space:]]*[a-zA-Z_][^=]*\. = " "$DSL_FILE" | wc -l)
    if [ "$INVALID_IDS" -gt 0 ]; then
        print_error "Found $INVALID_IDS identifiers with dots (invalid)"
        grep -n -E "^[[:space:]]*[a-zA-Z_][^=]*\. = " "$DSL_FILE" | while IFS=: read -r line_num content; do
            print_info "Line $line_num: $(echo $content | xargs)"
        done
    fi
else
    print_warning "No element declarations found"
fi

# Check 7: Relationship syntax
print_check "Checking relationship syntax"
RELATIONSHIPS=$(grep -E " -> " "$DSL_FILE" | wc -l)
if [ "$RELATIONSHIPS" -gt 0 ]; then
    print_success "Found $RELATIONSHIPS relationships"
else
    print_warning "No relationships found"
fi

# Check 8: View definitions
print_check "Checking view definitions"
VIEWS=$(grep -E "^[[:space:]]*(systemLandscape|systemContext|container|component|dynamic|deployment)" "$DSL_FILE" | wc -l)
if [ "$VIEWS" -gt 0 ]; then
    print_success "Found $VIEWS view definitions"
else
    print_warning "No views found"
fi

# Check 9: Include statements in views
print_check "Checking view include statements"
if grep -q "views {" "$DSL_FILE"; then
    VIEW_INCLUDES=$(awk '/views {/,/^}/' "$DSL_FILE" | grep -c "include" || true)
    if [ "$VIEW_INCLUDES" -gt 0 ]; then
        print_success "Found $VIEW_INCLUDES include statements in views"
    else
        print_warning "No include statements found in views (diagrams may be empty)"
    fi
fi

# Check 10: Autolayout directives
print_check "Checking autolayout directives"
AUTOLAYOUTS=$(grep -c "autolayout" "$DSL_FILE" || true)
if [ "$AUTOLAYOUTS" -gt 0 ]; then
    print_success "Found $AUTOLAYOUTS autolayout directives"
else
    print_warning "No autolayout directives (may use manual layout)"
fi

# Check 11: Hierarchical identifiers
print_check "Checking identifier mode"
if grep -q "!identifiers hierarchical" "$DSL_FILE"; then
    print_success "Using hierarchical identifiers"
    print_info "Remember to use fully qualified paths for cross-scope references"
else
    print_warning "Not using hierarchical identifiers (may cause naming conflicts)"
fi

# Check 12: Tags usage
print_check "Checking tags"
TAGS=$(grep -c "tags " "$DSL_FILE" || true)
if [ "$TAGS" -gt 0 ]; then
    print_success "Found $TAGS tag declarations"
else
    print_warning "No tags found (styling may be limited)"
fi

# Check 13: Styles block
print_check "Checking styles"
if grep -q "styles {" "$DSL_FILE"; then
    print_success "Found styles block"

    # Check for element styles
    ELEMENT_STYLES=$(awk '/styles {/,/^[[:space:]]*}/' "$DSL_FILE" | grep -c "element " || true)
    if [ "$ELEMENT_STYLES" -gt 0 ]; then
        print_success "Found $ELEMENT_STYLES element style definitions"
    else
        print_warning "No element styles defined"
    fi

    # Check for relationship styles
    REL_STYLES=$(awk '/styles {/,/^[[:space:]]*}/' "$DSL_FILE" | grep -c "relationship " || true)
    if [ "$REL_STYLES" -gt 0 ]; then
        print_success "Found $REL_STYLES relationship style definitions"
    fi
else
    print_warning "No styles block found (default styling will be used)"
fi

# Check 14: Documentation references
print_check "Checking documentation references"
if grep -q "!docs" "$DSL_FILE"; then
    print_success "Found documentation references"

    # Check if docs directory exists
    DOCS_DIR="${WORKSPACE_DIR}/docs"
    if [ -d "$DOCS_DIR" ]; then
        DOC_COUNT=$(find "$DOCS_DIR" -name "*.md" | wc -l)
        print_success "Found $DOC_COUNT markdown files in docs/"
    else
        print_warning "docs/ directory not found (referenced but missing)"
    fi
fi

if grep -q "!adrs" "$DSL_FILE"; then
    print_success "Found ADR references"

    # Check if adrs directory exists
    ADRS_DIR="${WORKSPACE_DIR}/adrs"
    if [ -d "$ADRS_DIR" ]; then
        ADR_COUNT=$(find "$ADRS_DIR" -name "*.md" | wc -l)
        print_success "Found $ADR_COUNT ADR files in adrs/"
    else
        print_warning "adrs/ directory not found (referenced but missing)"
    fi
fi

# Check 15: Common syntax errors
print_check "Checking for common syntax errors"

# Missing quotes around descriptions
MISSING_QUOTES=$(grep -E " -> .* [A-Z][^\"]*$" "$DSL_FILE" | grep -v "//" | wc -l || true)
if [ "$MISSING_QUOTES" -gt 0 ]; then
    print_warning "Found $MISSING_QUOTES potential relationships with unquoted descriptions"
fi

# Duplicate identifiers (simple check)
DUPLICATE_IDS=$(grep -E "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_-]* = " "$DSL_FILE" | \
                 awk '{print $1}' | sort | uniq -d | wc -l || true)
if [ "$DUPLICATE_IDS" -gt 0 ]; then
    print_error "Found $DUPLICATE_IDS potential duplicate identifiers"
fi

# Check 16: Container status (if running)
print_check "Checking container status"
if command -v podman &> /dev/null; then
    if podman compose ps 2>/dev/null | grep -q structurizr; then
        CONTAINER_STATUS=$(podman compose ps --format "{{.State}}" | grep structurizr || echo "not found")
        if [ "$CONTAINER_STATUS" = "running" ]; then
            print_success "Structurizr container is running"
        else
            print_warning "Structurizr container status: $CONTAINER_STATUS"
        fi
    else
        print_info "Structurizr container not running"
    fi
else
    print_info "Podman not available (skipping container check)"
fi

# Print summary and exit
print_summary
exit $?
