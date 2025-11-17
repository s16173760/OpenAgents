#!/usr/bin/env bash

#############################################################################
# Component Registration Script
# Automatically scans .opencode/ and updates registry.json
#############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
OPENCODE_DIR=".opencode"
REGISTRY_FILE="registry.json"
TEMP_REGISTRY="/tmp/registry-temp-$$.json"

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_step() { echo -e "\n${CYAN}${BOLD}▶${NC} $1\n"; }

#############################################################################
# Validation
#############################################################################

check_dependencies() {
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed"
        echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
        exit 1
    fi
}

validate_registry() {
    if [ ! -f "$REGISTRY_FILE" ]; then
        print_error "Registry file not found: $REGISTRY_FILE"
        exit 1
    fi
    
    if ! jq empty "$REGISTRY_FILE" 2>/dev/null; then
        print_error "Invalid JSON in registry file"
        exit 1
    fi
}

#############################################################################
# Component Discovery
#############################################################################

extract_frontmatter() {
    local file=$1
    local field=$2
    
    # Extract YAML frontmatter between --- markers
    awk -v field="$field" '
        BEGIN { in_fm=0; }
        /^---$/ { 
            if (in_fm == 0) { in_fm=1; next; }
            else { exit; }
        }
        in_fm && $0 ~ "^" field ":" {
            sub("^" field ": *", "");
            gsub(/^["\047]|["\047]$/, "");
            print;
            exit;
        }
    ' "$file"
}

scan_agents() {
    print_step "Scanning agents..."
    
    local json_array="[]"
    
    while IFS= read -r -d '' file; do
        local id=$(basename "$file" .md)
        local name=$(extract_frontmatter "$file" "name")
        local desc=$(extract_frontmatter "$file" "description")
        
        # Use defaults if not found in frontmatter
        [ -z "$name" ] && name=$(echo "$id" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        [ -z "$desc" ] && desc="Agent: $name"
        
        local path="${file#./}"
        
        # Build JSON using jq
        json_array=$(echo "$json_array" | jq \
            --arg id "$id" \
            --arg name "$name" \
            --arg path "$path" \
            --arg desc "$desc" \
            '. += [{
                "id": $id,
                "name": $name,
                "type": "agent",
                "path": $path,
                "description": $desc,
                "tags": [],
                "dependencies": [],
                "category": "core"
            }]')
        
        print_info "Found agent: $id"
    done < <(find "$OPENCODE_DIR/agent" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
    
    echo "$json_array"
}

scan_subagents() {
    print_step "Scanning subagents..."
    
    local subagents=()
    
    while IFS= read -r -d '' file; do
        local id=$(basename "$file" .md)
        local name=$(extract_frontmatter "$file" "name")
        local desc=$(extract_frontmatter "$file" "description")
        
        [ -z "$name" ] && name=$(echo "$id" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        [ -z "$desc" ] && desc="Subagent: $name"
        
        local path="${file#./}"
        
        subagents+=("{\"id\":\"$id\",\"name\":\"$name\",\"type\":\"subagent\",\"path\":\"$path\",\"description\":\"$desc\",\"tags\":[],\"dependencies\":[],\"category\":\"core\"}")
        
        print_info "Found subagent: $id"
    done < <(find "$OPENCODE_DIR/agent/subagents" -name "*.md" -type f -print0 2>/dev/null)
    
    if [ ${#subagents[@]} -gt 0 ]; then
        echo "[$(IFS=,; echo "${subagents[*]}")]"
    else
        echo "[]"
    fi
}

scan_commands() {
    print_step "Scanning commands..."
    
    local commands=()
    
    while IFS= read -r -d '' file; do
        local id=$(basename "$file" .md)
        local name=$(extract_frontmatter "$file" "name")
        local desc=$(extract_frontmatter "$file" "description")
        
        [ -z "$name" ] && name=$(echo "$id" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        [ -z "$desc" ] && desc="Command: $name"
        
        local path="${file#./}"
        
        commands+=("{\"id\":\"$id\",\"name\":\"$name\",\"type\":\"command\",\"path\":\"$path\",\"description\":\"$desc\",\"tags\":[],\"dependencies\":[],\"category\":\"core\"}")
        
        print_info "Found command: $id"
    done < <(find "$OPENCODE_DIR/command" -name "*.md" -type f -print0 2>/dev/null)
    
    if [ ${#commands[@]} -gt 0 ]; then
        echo "[$(IFS=,; echo "${commands[*]}")]"
    else
        echo "[]"
    fi
}

scan_tools() {
    print_step "Scanning tools..."
    
    local tools=()
    
    # Look for directories with index.ts
    while IFS= read -r -d '' dir; do
        local id=$(basename "$dir")
        
        # Skip node_modules and template
        [[ "$id" == "node_modules" || "$id" == "template" ]] && continue
        
        local index_file="$dir/index.ts"
        [ ! -f "$index_file" ] && continue
        
        local name=$(echo "$id" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        local desc="Tool: $name"
        
        # Try to extract description from comments
        local comment_desc=$(grep -m 1 "^\s*\*.*" "$index_file" | sed 's/^\s*\*\s*//' || echo "")
        [ -n "$comment_desc" ] && desc="$comment_desc"
        
        local path="${index_file#./}"
        
        tools+=("{\"id\":\"$id\",\"name\":\"$name\",\"type\":\"tool\",\"path\":\"$path\",\"description\":\"$desc\",\"tags\":[],\"dependencies\":[],\"category\":\"core\"}")
        
        print_info "Found tool: $id"
    done < <(find "$OPENCODE_DIR/tool" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    
    if [ ${#tools[@]} -gt 0 ]; then
        echo "[$(IFS=,; echo "${tools[*]}")]"
    else
        echo "[]"
    fi
}

scan_plugins() {
    print_step "Scanning plugins..."
    
    local plugins=()
    
    while IFS= read -r -d '' file; do
        local id=$(basename "$file" .ts)
        
        # Skip lib directory files
        [[ "$file" == *"/lib/"* ]] && continue
        
        local name=$(echo "$id" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        local desc="Plugin: $name"
        
        # Try to extract description from comments
        local comment_desc=$(grep -m 1 "^\s*\*.*" "$file" | sed 's/^\s*\*\s*//' || echo "")
        [ -n "$comment_desc" ] && desc="$comment_desc"
        
        local path="${file#./}"
        
        plugins+=("{\"id\":\"$id\",\"name\":\"$name\",\"type\":\"plugin\",\"path\":\"$path\",\"description\":\"$desc\",\"tags\":[],\"dependencies\":[],\"category\":\"extended\"}")
        
        print_info "Found plugin: $id"
    done < <(find "$OPENCODE_DIR/plugin" -maxdepth 1 -name "*.ts" -type f -print0 2>/dev/null)
    
    if [ ${#plugins[@]} -gt 0 ]; then
        echo "[$(IFS=,; echo "${plugins[*]}")]"
    else
        echo "[]"
    fi
}

scan_contexts() {
    print_step "Scanning contexts..."
    
    local contexts=()
    
    while IFS= read -r -d '' file; do
        local id=$(basename "$file" .md)
        local name=$(extract_frontmatter "$file" "name")
        local desc=$(extract_frontmatter "$file" "description")
        
        [ -z "$name" ] && name=$(echo "$id" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        [ -z "$desc" ] && desc="Context: $name"
        
        local path="${file#./}"
        
        contexts+=("{\"id\":\"$id\",\"name\":\"$name\",\"type\":\"context\",\"path\":\"$path\",\"description\":\"$desc\",\"tags\":[],\"dependencies\":[],\"category\":\"core\"}")
        
        print_info "Found context: $id"
    done < <(find "$OPENCODE_DIR/context" -name "*.md" -type f -print0 2>/dev/null)
    
    if [ ${#contexts[@]} -gt 0 ]; then
        echo "[$(IFS=,; echo "${contexts[*]}")]"
    else
        echo "[]"
    fi
}

#############################################################################
# Registry Update
#############################################################################

update_registry() {
    print_step "Updating registry..."
    
    # Scan all components
    local agents_json=$(scan_agents)
    local subagents_json=$(scan_subagents)
    local commands_json=$(scan_commands)
    local tools_json=$(scan_tools)
    local plugins_json=$(scan_plugins)
    local contexts_json=$(scan_contexts)
    
    # Read existing registry
    local existing_registry=$(cat "$REGISTRY_FILE")
    
    # Update components while preserving profiles and metadata
    local updated_registry=$(echo "$existing_registry" | jq \
        --argjson agents "$agents_json" \
        --argjson subagents "$subagents_json" \
        --argjson commands "$commands_json" \
        --argjson tools "$tools_json" \
        --argjson plugins "$plugins_json" \
        --argjson contexts "$contexts_json" \
        '
        .components.agents = $agents |
        .components.subagents = $subagents |
        .components.commands = $commands |
        .components.tools = $tools |
        .components.plugins = $plugins |
        .components.contexts = $contexts |
        .metadata.lastUpdated = (now | strftime("%Y-%m-%d"))
        ')
    
    # Write to temp file first
    echo "$updated_registry" | jq '.' > "$TEMP_REGISTRY"
    
    # Validate
    if jq empty "$TEMP_REGISTRY" 2>/dev/null; then
        mv "$TEMP_REGISTRY" "$REGISTRY_FILE"
        print_success "Registry updated successfully"
    else
        print_error "Generated invalid JSON, registry not updated"
        rm -f "$TEMP_REGISTRY"
        exit 1
    fi
}

#############################################################################
# Statistics
#############################################################################

show_statistics() {
    print_step "Registry Statistics"
    
    local agents=$(jq '.components.agents | length' "$REGISTRY_FILE")
    local subagents=$(jq '.components.subagents | length' "$REGISTRY_FILE")
    local commands=$(jq '.components.commands | length' "$REGISTRY_FILE")
    local tools=$(jq '.components.tools | length' "$REGISTRY_FILE")
    local plugins=$(jq '.components.plugins | length' "$REGISTRY_FILE")
    local contexts=$(jq '.components.contexts | length' "$REGISTRY_FILE")
    local total=$((agents + subagents + commands + tools + plugins + contexts))
    
    echo "  Agents:    $agents"
    echo "  Subagents: $subagents"
    echo "  Commands:  $commands"
    echo "  Tools:     $tools"
    echo "  Plugins:   $plugins"
    echo "  Contexts:  $contexts"
    echo "  ─────────────"
    echo "  Total:     $total"
    echo ""
}

#############################################################################
# Main
#############################################################################

main() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║           Component Registration Script                       ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_dependencies
    validate_registry
    
    update_registry
    show_statistics
    
    print_success "Done!"
}

main "$@"
