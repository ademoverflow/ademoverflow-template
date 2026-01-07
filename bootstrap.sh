#!/bin/bash

# Bootstrap script for initializing the project template
# This script updates project name, description, and port configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Current values
CURRENT_NAME="ademoverflow-template"

# Helper function for sed (handles macOS vs Linux)
run_sed() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Project Bootstrap Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to validate project name
validate_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Project name cannot be empty${NC}"
        return 1
    fi
    if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        echo -e "${RED}Error: Project name must start with a letter and contain only lowercase letters, numbers, and hyphens${NC}"
        return 1
    fi
    return 0
}

# Function to validate port
validate_port() {
    local port="$1"
    if [[ -z "$port" ]]; then
        echo -e "${RED}Error: Port cannot be empty${NC}"
        return 1
    fi
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Port must be a number${NC}"
        return 1
    fi
    if [[ "$port" -lt 1024 ]] || [[ "$port" -gt 65525 ]]; then
        echo -e "${RED}Error: Port must be between 1024 and 65525 (allowing +10 offset)${NC}"
        return 1
    fi
    return 0
}

# Prompt for project name
while true; do
    echo -e "${YELLOW}Enter project name${NC} (lowercase, hyphens allowed, e.g., 'my-awesome-project'):"
    read -r PROJECT_NAME
    if validate_name "$PROJECT_NAME"; then
        break
    fi
done

# Prompt for project description
echo ""
echo -e "${YELLOW}Enter project description${NC} (e.g., 'My Awesome Project'):"
read -r PROJECT_DESCRIPTION
if [[ -z "$PROJECT_DESCRIPTION" ]]; then
    # Default to title-cased project name
    PROJECT_DESCRIPTION=$(echo "$PROJECT_NAME" | sed -E 's/(^|-)([a-z])/\U\2/g' | sed 's/-/ /g')
    echo -e "${BLUE}Using default description: ${PROJECT_DESCRIPTION}${NC}"
fi

# Prompt for base port
echo ""
while true; do
    echo -e "${YELLOW}Enter base port number${NC} (e.g., 8990 for ports 8997, 8998, 8999):"
    read -r BASE_PORT
    if validate_port "$BASE_PORT"; then
        break
    fi
done

# Calculate ports
ADMINER_PORT=$((BASE_PORT + 7))
WEBAPP_PORT=$((BASE_PORT + 8))
CORE_PORT=$((BASE_PORT + 9))

# Show confirmation
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Configuration Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "  Project Name:        ${GREEN}${PROJECT_NAME}${NC}"
echo -e "  Description:         ${GREEN}${PROJECT_DESCRIPTION}${NC}"
echo -e "  Adminer Port:        ${GREEN}${ADMINER_PORT}${NC}"
echo -e "  Webapp Port:         ${GREEN}${WEBAPP_PORT}${NC}"
echo -e "  Core API Port:       ${GREEN}${CORE_PORT}${NC}"
echo ""
echo -e "${BLUE}Files to be modified:${NC}"
echo "  - package.json"
echo "  - pyproject.toml"
echo "  - compose.yaml"
echo "  - core/Dockerfile"
echo "  - README.md"
echo "  - CLAUDE.md"
echo "  - core/README.md"
echo "  - webapp/README.md"
echo ""

# Confirm
echo -e "${YELLOW}Proceed with these changes? (y/n)${NC}"
read -r CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo -e "${RED}Aborted.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Applying changes...${NC}"

# Update package.json
echo -e "  Updating ${GREEN}package.json${NC}..."
run_sed "s/\"name\": \"${CURRENT_NAME}\"/\"name\": \"${PROJECT_NAME}\"/" package.json

# Update pyproject.toml (root)
echo -e "  Updating ${GREEN}pyproject.toml${NC}..."
run_sed "s/name = \"${CURRENT_NAME}\"/name = \"${PROJECT_NAME}\"/" pyproject.toml

# Update compose.yaml - image names and ports
echo -e "  Updating ${GREEN}compose.yaml${NC}..."
run_sed "s/${CURRENT_NAME}-core/${PROJECT_NAME}-core/g" compose.yaml
run_sed "s/${CURRENT_NAME}-webapp/${PROJECT_NAME}-webapp/g" compose.yaml
run_sed "s/\"8997:8080\"/\"${ADMINER_PORT}:8080\"/" compose.yaml
run_sed "s/\"8999:80\"/\"${CORE_PORT}:80\"/" compose.yaml
run_sed "s/\"8998:3000\"/\"${WEBAPP_PORT}:3000\"/" compose.yaml

# Update core/Dockerfile
echo -e "  Updating ${GREEN}core/Dockerfile${NC}..."
run_sed "s/--package ${CURRENT_NAME}/--package ${PROJECT_NAME}/" core/Dockerfile

# Update README.md - remove bootstrap section and update project info
echo -e "  Updating ${GREEN}README.md${NC}..."
# Update title
run_sed "s/# Ademoverflow Template/# ${PROJECT_DESCRIPTION}/" README.md
# Update ports in the documentation
run_sed "s/localhost:8997/localhost:${ADMINER_PORT}/g" README.md
run_sed "s/localhost:8998/localhost:${WEBAPP_PORT}/g" README.md
run_sed "s/localhost:8999/localhost:${CORE_PORT}/g" README.md
# Remove bootstrap section (lines between "### 1. Bootstrap" and "### 2. Configure")
run_sed '/### 1\. Bootstrap the Project/,/### 2\. Configure Environment/{/### 2\. Configure Environment/!d;}' README.md
# Renumber remaining steps
run_sed 's/### 2\. Configure Environment/### 1. Configure Environment/' README.md
run_sed 's/### 3\. Start Development/### 2. Start Development/' README.md
run_sed 's/### 4\. Access Services/### 3. Access Services/' README.md
# Remove bootstrap.sh from project structure
run_sed '/bootstrap.sh/d' README.md

# Update CLAUDE.md - update ports
echo -e "  Updating ${GREEN}CLAUDE.md${NC}..."
run_sed "s/| Adminer | 8997 |/| Adminer | ${ADMINER_PORT} |/" CLAUDE.md
run_sed "s/| Webapp  | 8998 |/| Webapp  | ${WEBAPP_PORT} |/" CLAUDE.md
run_sed "s/| Core API| 8999 |/| Core API| ${CORE_PORT} |/" CLAUDE.md

# Update core/README.md - update port
echo -e "  Updating ${GREEN}core/README.md${NC}..."
run_sed "s/localhost:8999/localhost:${CORE_PORT}/g" core/README.md

# Update webapp/README.md - update port
echo -e "  Updating ${GREEN}webapp/README.md${NC}..."
run_sed "s/localhost:8998/localhost:${WEBAPP_PORT}/g" webapp/README.md

# Remove bootstrap.sh itself
echo -e "  Removing ${GREEN}bootstrap.sh${NC}..."
rm -f bootstrap.sh

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Bootstrap Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo ""
echo "  1. Copy and configure environment:"
echo -e "     ${YELLOW}cp env.example .env${NC}"
echo ""
echo "  2. Update .env with your local IP for WEBAPP_URL and COOKIE_DOMAIN"
echo ""
echo "  3. Start the development stack:"
echo -e "     ${YELLOW}docker compose up${NC}"
echo ""
echo "  4. Access your services:"
echo -e "     Webapp:   ${GREEN}http://localhost:${WEBAPP_PORT}${NC}"
echo -e "     Core API: ${GREEN}http://localhost:${CORE_PORT}${NC}"
echo -e "     Adminer:  ${GREEN}http://localhost:${ADMINER_PORT}${NC}"
echo ""
echo -e "${BLUE}Happy coding!${NC}"
