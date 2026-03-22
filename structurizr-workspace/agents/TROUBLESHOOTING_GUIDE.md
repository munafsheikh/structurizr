# Structurizr DSL Troubleshooting & Development Guide

## Table of Contents

1. [Overview](#overview)
2. [DSL Syntax & Validation Issues](#dsl-syntax--validation-issues)
3. [Container & Runtime Issues](#container--runtime-issues)
4. [Podman & Compose Issues](#podman--compose-issues)
5. [Environment & Configuration Issues](#environment--configuration-issues)
6. [Common Patterns & Best Practices](#common-patterns--best-practices)
7. [Debugging Techniques](#debugging-techniques)
8. [Reference Materials](#reference-materials)

---

## Overview

This guide provides systematic approaches to resolve any issue when working with:
- Structurizr DSL files (`workspace.dsl`)
- Structurizr Lite container
- Podman/Docker Compose configuration
- Environment files and settings

### Quick Diagnostics Checklist

Before diving into specific issues, run these quick checks:

```bash
# 1. Check container status
podman compose ps

# 2. View recent logs
podman compose logs structurizr --tail 50

# 3. Check DSL file syntax
cat structurizr-ws/workspace.dsl | grep -n "^[[:space:]]*[a-zA-Z]"

# 4. Verify file permissions
ls -la structurizr-ws/

# 5. Check port availability
ss -tulpn | grep 8080
```

---

## DSL Syntax & Validation Issues

### Understanding Error Messages

Structurizr errors follow this pattern:
```
com.structurizr.dsl.StructurizrDslParserException: [ERROR DESCRIPTION] at line [LINE_NUMBER] of [FILE_PATH]: [PROBLEMATIC LINE]
```

### Common DSL Issues & Solutions

#### 1. **Element Does Not Exist**

**Error Pattern:**
```
The source/destination element "elementName" does not exist at line X
```

**Root Cause:** Attempting to reference an element outside its scope without using fully qualified identifiers.

**Solution:**
- **Understand hierarchical identifiers**: When `!identifiers hierarchical` is set, elements must be referenced using their full path outside their definition scope.

**Examples:**

❌ **WRONG:**
```dsl
model {
    system1 = softwareSystem "System 1" {
        container1 = container "Container 1"
    }

    system2 = softwareSystem "System 2"

    # This will fail - container1 is out of scope
    system2 -> container1 "Uses"
}
```

✅ **CORRECT:**
```dsl
model {
    system1 = softwareSystem "System 1" {
        container1 = container "Container 1"
    }

    system2 = softwareSystem "System 2"

    # Use fully qualified identifier
    system2 -> system1.container1 "Uses"
}
```

**Scope Rules:**
- **Within definition block**: Use simple identifier (e.g., `container1`)
- **Outside definition block**: Use fully qualified path (e.g., `system1.container1`)
- **Same level**: Siblings can reference each other directly

#### 2. **Invalid Identifier Characters**

**Error Pattern:**
```
Identifiers can only contain the following characters: a-zA-Z0-9_- at line X
```

**Root Cause:** Using dots (`.`) or other special characters in variable names.

**Solution:**
- Identifiers are variable names - use only: `a-z`, `A-Z`, `0-9`, `_`, `-`
- Don't confuse identifiers with fully qualified references

❌ **WRONG:**
```dsl
system1.container1 = container "Container" "Description"
```

✅ **CORRECT:**
```dsl
container1 = container "Container" "Description"
```

#### 3. **Redundant Relationships**

**Issue:** Defining relationships at multiple levels can cause confusion and errors.

**Best Practice Hierarchy:**
1. **System Level**: High-level dependencies between systems
2. **Container Level**: Generally not needed if you have system and component levels
3. **Component Level**: Detailed interactions between components

**Example Structure:**

```dsl
model {
    # System level relationships
    system1 -> system2 "High-level dependency"

    system1 = softwareSystem "System 1" {
        container1 = container "Container 1" {
            component1 = component "Component 1"
            component2 = component "Component 2"

            # Component relationships (use simple identifiers within same container)
            component1 -> component2 "Internal call"
        }
    }

    # Component to external system (use fully qualified identifier)
    system1.container1.component1 -> system2 "External call"
}
```

#### 4. **Missing Closing Braces**

**Symptom:** Cryptic errors about unexpected tokens far from the actual issue.

**Debugging:**
```bash
# Check brace balance
grep -o '{' workspace.dsl | wc -l
grep -o '}' workspace.dsl | wc -l

# Use a text editor with brace matching (VSCode, vim with matchit.vim)
```

**Prevention:**
- Use consistent indentation (4 spaces recommended)
- Use an editor with syntax highlighting
- Consider using the Structurizr DSL VSCode extension

#### 5. **Invalid View References**

**Error Pattern:**
```
The element/relationship X does not exist
```

**Common in:**
- `systemContext` views
- `container` views
- `component` views
- `dynamic` views

**Solution:**
```dsl
views {
    # Must reference defined elements with correct identifiers

    # ❌ WRONG: Using simple name for nested element
    systemContext mySystem {
        include container1
    }

    # ✅ CORRECT: Using fully qualified path
    systemContext mySystem {
        include mySystem.container1
    }

    # ✅ CORRECT: Using wildcard to include all
    systemContext mySystem {
        include *
        autolayout lr
    }
}
```

#### 6. **Tag Inheritance Issues**

**Issue:** Tags not applying correctly to elements.

**Understanding Tag Propagation:**
- Tags are inherited from parent to child elements
- You can add tags at any level
- Multiple tags can be applied

**Example:**
```dsl
softwareSystem "My System" {
    tags "Backend" "Critical"

    container "API" {
        tags "REST"  # This container has: Backend, Critical, REST

        component "Handler" {
            tags "HTTP"  # This component has: Backend, Critical, REST, HTTP
        }
    }
}

styles {
    element "Backend" {
        background #blue
    }
    element "Critical" {
        border Solid
    }
    element "REST" {
        shape Hexagon
    }
}
```

### DSL Validation Workflow

When editing DSL files, follow this workflow:

```bash
# 1. Make changes to workspace.dsl
vim structurizr-ws/workspace.dsl

# 2. Check syntax (basic)
cat structurizr-ws/workspace.dsl | grep -E "^\s*[a-zA-Z].*=$" | grep -v "//"

# 3. Delete cached JSON (forces re-parsing)
rm structurizr-ws/workspace.json

# 4. Restart container to reload DSL
podman compose restart structurizr

# 5. Check logs for errors
podman compose logs structurizr --since 30s | grep -i "error\|exception"

# 6. Access UI and verify
firefox http://localhost:8080/workspace/diagrams
```

---

## Container & Runtime Issues

### Container Lifecycle Management

#### Starting the Container

```bash
# First time start
podman compose up -d

# Start if stopped
podman compose start structurizr

# Restart (applies configuration changes)
podman compose restart structurizr

# Full rebuild
podman compose down
podman compose up -d --force-recreate
```

#### Checking Container Status

```bash
# List all containers in project
podman compose ps

# Expected output:
# NAME         IMAGE                        COMMAND     SERVICE       CREATED        STATUS        PORTS
# structurizr  structurizr/lite:latest      ...         structurizr   X minutes ago  Up X minutes  8080:8080

# Check if container is running
podman ps --filter "name=structurizr"

# Get container details
podman inspect structurizr
```

#### Viewing Logs

```bash
# All logs
podman compose logs structurizr

# Last 50 lines
podman compose logs structurizr --tail 50

# Follow logs in real-time
podman compose logs structurizr --follow

# Logs since specific time
podman compose logs structurizr --since 5m
podman compose logs structurizr --since "2024-01-13T10:00:00"

# Filter for errors
podman compose logs structurizr | grep -i "error\|exception\|fail"

# Find DSL parsing errors specifically
podman compose logs structurizr | grep "StructurizrDslParserException"
```

### Common Container Issues

#### Issue: Container Won't Start

**Symptoms:**
- `podman compose up` fails
- Container immediately exits
- Status shows "Exited" or "Error"

**Diagnostic Steps:**

```bash
# 1. Check container logs for startup errors
podman compose logs structurizr

# 2. Check if port is already in use
ss -tulpn | grep 8080
# or
netstat -tulpn | grep 8080

# 3. Try running container directly for verbose output
podman run --rm -it \
  -p 8080:8080 \
  -v ./structurizr-ws:/usr/local/structurizr:Z \
  structurizr/lite:latest

# 4. Check volume mount permissions
ls -la structurizr-ws/
# Should be readable by container (UID 1000 or world-readable)
```

**Solutions:**

**A. Port Conflict:**
```bash
# Option 1: Kill process using port 8080
sudo ss -tulpn | grep 8080  # Find PID
sudo kill -9 <PID>

# Option 2: Change port in compose.yaml
# Edit: ports: - "8081:8080"
```

**B. Permission Issues:**
```bash
# Fix permissions
chmod -R 755 structurizr-ws/
chmod 644 structurizr-ws/workspace.dsl

# For SELinux systems (Fedora, RHEL), ensure :Z flag in volume mount
# Already present in compose.yaml: - ./structurizr-ws:/usr/local/structurizr:Z
```

**C. Invalid DSL File:**
```bash
# Temporarily rename DSL to bypass it
mv structurizr-ws/workspace.dsl structurizr-ws/workspace.dsl.backup

# Create minimal valid DSL
cat > structurizr-ws/workspace.dsl << 'EOF'
workspace {
    model {
        user = person "User"
        system = softwareSystem "System"
        user -> system "Uses"
    }

    views {
        systemContext system {
            include *
            autolayout lr
        }
        styles {
            element "Element" {
                background #1168bd
            }
        }
    }
}
EOF

# Restart and check if container starts
podman compose restart structurizr

# If it works, the original DSL had syntax errors
# Restore and debug:
mv structurizr-ws/workspace.dsl.backup structurizr-ws/workspace.dsl
```

#### Issue: Workspace Not Loading / Shows Old Data

**Symptoms:**
- Changes to DSL not reflected in UI
- Old workspace appears
- Diagrams don't update

**Solutions:**

```bash
# 1. Delete cached workspace.json
rm structurizr-ws/workspace.json

# 2. Restart container
podman compose restart structurizr

# 3. Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)

# 4. Check auto-refresh settings in compose.yaml
# Ensure: STRUCTURIZR_AUTOREFRESHINTERVAL=2000

# 5. If still not working, check logs for parsing errors
podman compose logs structurizr --since 1m | grep -i "error"
```

#### Issue: Container Using Too Much CPU/Memory

**Diagnostic:**
```bash
# Check resource usage
podman stats structurizr

# Check container top processes
podman top structurizr
```

**Solutions:**

Add resource limits to `compose.yaml`:
```yaml
services:
  structurizr:
    image: structurizr/lite:latest
    ports:
      - "8080:8080"
    volumes:
      - ./structurizr-ws:/usr/local/structurizr:Z
    environment:
      - STRUCTURIZR_AUTOSAVEINTERVAL=2000
      - STRUCTURIZR_AUTOREFRESHINTERVAL=2000
      - STRUCTURIZR_EDITABLE=true
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
```

#### Issue: Diagrams Not Rendering / Graphviz Issues

**Symptom:** Diagrams appear but layout is poor or fails.

**Check Graphviz status:**
```bash
podman compose logs structurizr | grep -i graphviz

# Expected output should include:
# Graphviz (dot): true
```

**If Graphviz is disabled:**
- The `structurizr/lite:latest` image should include Graphviz
- If using a different image, ensure Graphviz is installed

**Manual layout override:**
```dsl
views {
    systemContext mySystem {
        include *
        # Don't rely on autolayout if Graphviz isn't working
        # Use manual positioning instead
    }
}
```

---

## Podman & Compose Issues

### Podman vs Docker

This project uses Podman, but the commands are largely compatible with Docker.

**Key Differences:**
- Podman is daemonless and rootless by default
- Replace `docker` with `podman` in commands
- Socket location: `/run/user/$UID/podman/podman.sock` (rootless)

### Common Podman Issues

#### Issue: Permission Denied on Docker Socket

**Error:**
```
permission denied while trying to connect to the Docker daemon socket
```

**Cause:** Trying to use `docker compose` instead of `podman compose`.

**Solution:**
```bash
# Always use podman compose
podman compose up -d
podman compose logs structurizr
podman compose restart structurizr

# If you want docker command to use podman:
alias docker=podman
alias docker-compose='podman compose'
```

#### Issue: Podman Compose Not Found

**Error:**
```
podman-compose: command not found
```

**Solution:**

```bash
# Check if docker-compose plugin is available
podman compose version

# If not, install podman-compose
# Fedora/RHEL:
sudo dnf install podman-compose

# Ubuntu/Debian:
sudo apt install podman-compose

# Using pip:
pip3 install podman-compose
```

#### Issue: Volume Mount Issues

**Error:**
```
Error: statfs /path/to/structurizr-ws: no such file or directory
```

**Solutions:**

```bash
# 1. Use absolute paths in compose.yaml
# ❌ WRONG: - ./structurizr-ws:/usr/local/structurizr:Z
# ✅ CORRECT:
volumes:
  - /home/m/git/github/munafsheikh/briefcase/Structurizr/structurizr-ws:/usr/local/structurizr:Z

# 2. Ensure directory exists
mkdir -p structurizr-ws
touch structurizr-ws/workspace.dsl

# 3. For SELinux systems, use :Z flag (already in compose.yaml)
# :z = shared volume, :Z = private volume

# 4. Check SELinux context
ls -Z structurizr-ws/

# 5. If SELinux is causing issues, relabel:
chcon -Rt container_file_t structurizr-ws/
# or
sudo restorecon -R structurizr-ws/
```

#### Issue: Port Already in Use

**Error:**
```
Error: failed to expose ports: cannot listen on the TCP port: listen tcp :8080: bind: address already in use
```

**Solution:**

```bash
# Find what's using port 8080
sudo ss -tulpn | grep :8080

# Kill the process
sudo kill -9 <PID>

# Or change port in compose.yaml
# Edit ports to: - "8081:8080"

# Or use a random port:
# - "0:8080"  # Podman will assign random host port
```

### Compose File Management

#### Validating compose.yaml

```bash
# Check syntax
podman compose config

# This will parse and display the resolved configuration
# Any YAML syntax errors will be shown
```

#### Environment Variable Substitution

**In compose.yaml:**
```yaml
services:
  structurizr:
    environment:
      - API_KEY=${OPENAI_API_KEY}
      - CUSTOM_VAR=${CUSTOM_VAR:-default_value}
```

**Test variable expansion:**
```bash
# See how variables are resolved
podman compose config | grep -A 10 environment
```

#### Multiple Compose Files

**Override configuration:**
```bash
# Base: compose.yaml
# Override: compose.override.yaml

# Podman automatically merges compose.override.yaml if it exists
podman compose up -d

# Explicit files:
podman compose -f compose.yaml -f compose.prod.yaml up -d
```

**Example compose.override.yaml:**
```yaml
services:
  structurizr:
    ports:
      - "8081:8080"  # Override port
    environment:
      - STRUCTURIZR_EDITABLE=false  # Override to read-only
```

---

## Environment & Configuration Issues

### Environment Files

#### Structure

```
Structurizr/
├── .env                          # Environment variables
├── compose.yaml                  # Docker/Podman Compose config
└── structurizr-ws/
    ├── workspace.dsl             # Main DSL file
    ├── workspace.json            # Generated/cached (auto)
    ├── structurizr.properties    # Workspace properties
    ├── docs/                     # Documentation
    ├── adrs/                     # Architecture Decision Records
    └── .structurizr/             # Runtime cache (auto)
```

#### .env File Management

**Security Warning:**
- ⚠️ **NEVER commit `.env` files with secrets to git**
- ⚠️ Add `.env` to `.gitignore`

**Current .env has exposed API keys!** Fix immediately:

```bash
# 1. Add to .gitignore
echo ".env" >> .gitignore
echo "*.env" >> .gitignore

# 2. Remove from git if already tracked
git rm --cached .env
git commit -m "Remove .env from tracking"

# 3. Create .env.example template
cat > .env.example << 'EOF'
# Copy this file to .env and fill in your values
OPENAI_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here
CEREBRAS_API_KEY=your_key_here
EOF

# 4. Rotate all exposed API keys immediately!
# Visit each provider and generate new keys
```

**Safe .env Management:**
```bash
# Check if .env is in git
git ls-files | grep .env

# If found, remove it:
git rm --cached .env
git commit -m "Remove .env from version control"

# Ensure .gitignore includes it
cat >> .gitignore << 'EOF'
# Environment files
.env
.env.*
!.env.example
*.env
EOF
```

#### Structurizr Configuration

**structurizr-ws/structurizr.properties:**
```properties
# Configure workspace settings
structurizr.editable=true
```

**Via Environment Variables in compose.yaml:**
```yaml
environment:
  - STRUCTURIZR_EDITABLE=true
  - STRUCTURIZR_AUTOSAVEINTERVAL=2000
  - STRUCTURIZR_AUTOREFRESHINTERVAL=2000
```

**Available Settings:**

| Setting | Default | Description |
|---------|---------|-------------|
| `STRUCTURIZR_EDITABLE` | `false` | Allow editing via UI |
| `STRUCTURIZR_AUTOSAVEINTERVAL` | `0` | Auto-save interval (ms), 0=disabled |
| `STRUCTURIZR_AUTOREFRESHINTERVAL` | `0` | Auto-refresh interval (ms), 0=disabled |

---

## Common Patterns & Best Practices

### DSL Organization

#### File Structure for Large Workspaces

**Single File (Small Projects):**
```dsl
workspace {
    model {
        # All model elements
    }
    views {
        # All views
    }
}
```

**Multiple Files (Large Projects):**
```dsl
workspace {
    !docs docs
    !adrs adrs

    model {
        !include model/people.dsl
        !include model/systems.dsl
        !include model/relationships.dsl
    }

    views {
        !include views/context.dsl
        !include views/containers.dsl
        !include views/components.dsl
        !include views/styles.dsl
    }
}
```

#### Naming Conventions

**Identifiers (Variable Names):**
```dsl
# Use camelCase for identifiers
contentSchedulingSystem = softwareSystem "Content Scheduling System"
appScript = container "App Script"
notionChecker = component "Notion Checker"

# Or snake_case
content_scheduling_system = softwareSystem "Content Scheduling System"

# Avoid hyphens in variable names (though allowed)
# ❌ Less readable: content-scheduling-system
```

**Element Names (Display Names):**
```dsl
# Use Title Case or Sentence case
softwareSystem "Content Scheduling System"  # Title Case
container "App Script Orchestrator"         # Title Case
component "Notion Checker"                  # Title Case
```

**Tags:**
```dsl
# Use PascalCase or lowercase
tags "External"           # PascalCase
tags "backend" "api"      # lowercase
tags "MicroService"       # PascalCase
```

### Relationship Patterns

#### Internal vs External Relationships

```dsl
model {
    system1 = softwareSystem "System 1" {
        container1 = container "Container 1" {
            component1 = component "Component 1"
            component2 = component "Component 2"

            # Internal relationships (within same scope) - simple identifiers
            component1 -> component2 "Calls"
        }

        container2 = container "Container 2"
    }

    system2 = softwareSystem "System 2"

    # Cross-container relationships - fully qualified
    system1.container1.component1 -> system1.container2 "Uses"

    # External system relationships - fully qualified
    system1.container1.component1 -> system2 "Integrates with"
}
```

#### Bidirectional Relationships

```dsl
# For request-response patterns, define both directions
clientApp -> apiServer "Sends request" "HTTPS"
apiServer -> clientApp "Returns response" "HTTPS/JSON"

# Or use a single relationship if one direction is primary
clientApp -> apiServer "Uses" "HTTPS"
```

#### Technology Labels

**Be Consistent:**
```dsl
# ✅ GOOD: Consistent format
component1 -> component2 "Calls" "REST API/HTTPS"
component2 -> database "Queries" "SQL/PostgreSQL"
component3 -> messageQueue "Publishes" "AMQP/RabbitMQ"

# ❌ BAD: Inconsistent
component1 -> component2 "Calls" "REST"
component2 -> database "Queries" "Postgres"
component3 -> messageQueue "Publishes" "rabbitmq"
```

### View Organization

#### Standard View Set

For a complete architecture documentation, include:

```dsl
views {
    # 1. System Landscape (highest level)
    systemLandscape "Landscape" "Overview of all systems" {
        include *
        autolayout lr
    }

    # 2. System Context (focus on one system)
    systemContext mySystem "Context" "System context for MySystem" {
        include *
        autolayout lr
    }

    # 3. Container View (zoom into system)
    container mySystem "Containers" "Container architecture" {
        include *
        autolayout lr
    }

    # 4. Component Views (zoom into containers)
    component mySystem.container1 "Components" "Component architecture" {
        include *
        autolayout tb
    }

    # 5. Dynamic Views (show interactions)
    dynamic mySystem "UserFlow" "User registration flow" {
        user -> mySystem.container1 "1. Submits registration"
        mySystem.container1 -> mySystem.container2 "2. Validates data"
        mySystem.container2 -> database "3. Stores user"
        autolayout lr
    }

    # 6. Deployment View (optional)
    deployment mySystem "Production" "Production" {
        include *
        autolayout lr
    }

    # Styles (consistent across all views)
    styles {
        # ... style definitions
    }

    # Theme
    theme default
}
```

#### Layout Strategies

**Auto Layout Options:**
```dsl
# Horizontal (left to right)
autolayout lr

# Vertical (top to bottom)
autolayout tb

# With spacing
autolayout lr 100 50  # rank separation=100, node separation=50

# Circular (experimental)
autolayout

# Disable auto layout (manual positioning)
# Don't include autolayout directive
```

**Manual Positioning:**
```dsl
systemContext mySystem {
    include *

    # Manual positioning requires Structurizr cloud/on-premises
    # Not fully supported in Lite
}
```

### Styling Best Practices

#### Color Schemes

**Use Semantic Colors:**
```dsl
styles {
    # People
    element "Person" {
        shape Person
        background #08427b  # Dark blue
        color #ffffff       # White text
    }

    # Internal systems
    element "Software System" {
        background #1168bd  # Blue
        color #ffffff
    }

    # External/third-party
    element "External" {
        background #999999  # Gray
        color #ffffff
    }

    # Database
    element "Database" {
        shape Cylinder
        background #438dd5  # Light blue
    }

    # Important/critical
    element "Critical" {
        background #c92d39  # Red
        color #ffffff
    }

    # Technology-specific
    element "AI" {
        background #10a37f  # OpenAI green
    }

    element "Legacy" {
        background #cccccc  # Light gray
        color #333333
        stroke #ff0000      # Red border
    }
}
```

**Shape Mapping:**
```dsl
element "Person" {
    shape Person
}
element "Mobile App" {
    shape MobileDevicePortrait
}
element "Web App" {
    shape WebBrowser
}
element "Database" {
    shape Cylinder
}
element "File Storage" {
    shape Folder
}
element "Queue" {
    shape Pipe
}
element "Microservice" {
    shape Hexagon
}
```

#### Relationship Styling

```dsl
styles {
    relationship "Relationship" {
        routing Curved     # Curved, Direct, Orthogonal
        thickness 2
        color #707070
        dashed false       # or true for optional/async
        fontSize 24
    }

    relationship "Async" {
        dashed true
        color #ff6600
    }

    relationship "Sync" {
        dashed false
        color #000000
    }
}
```

### Documentation Integration

#### Embedding Documentation

```dsl
workspace {
    !docs docs              # Link to docs/ directory
    !adrs adrs              # Link to adrs/ directory

    model {
        mySystem = softwareSystem "My System" {
            !docs docs      # System-specific docs
            !adrs adrs      # System-specific ADRs
        }
    }
}
```

**Directory Structure:**
```
structurizr-ws/
├── workspace.dsl
├── docs/
│   ├── 01-context.md
│   ├── 02-containers.md
│   └── 03-deployment.md
└── adrs/
    ├── 0001-use-microservices.md
    └── 0002-choose-database.md
```

**Markdown Format for ADRs:**
```markdown
# ADR 001: Use Microservices Architecture

## Status
Accepted

## Context
We need to scale different parts of the system independently...

## Decision
We will adopt a microservices architecture...

## Consequences
### Positive
- Independent scaling
- Technology flexibility

### Negative
- Increased complexity
- Network overhead
```

---

## Debugging Techniques

### Systematic Debugging Process

When encountering an issue:

#### 1. **Gather Information**

```bash
# Full environment snapshot
cat > debug_info.txt << 'EOF'
=== SYSTEM INFO ===
EOF
uname -a >> debug_info.txt
echo "" >> debug_info.txt

echo "=== PODMAN VERSION ===" >> debug_info.txt
podman --version >> debug_info.txt
echo "" >> debug_info.txt

echo "=== COMPOSE VERSION ===" >> debug_info.txt
podman compose version >> debug_info.txt
echo "" >> debug_info.txt

echo "=== CONTAINER STATUS ===" >> debug_info.txt
podman compose ps >> debug_info.txt
echo "" >> debug_info.txt

echo "=== RECENT LOGS ===" >> debug_info.txt
podman compose logs structurizr --tail 100 >> debug_info.txt
echo "" >> debug_info.txt

echo "=== FILE PERMISSIONS ===" >> debug_info.txt
ls -laR structurizr-ws/ >> debug_info.txt
echo "" >> debug_info.txt

echo "=== DSL FILE ===" >> debug_info.txt
cat structurizr-ws/workspace.dsl >> debug_info.txt

cat debug_info.txt
```

#### 2. **Isolate the Problem**

**Is it DSL-related?**
```bash
# Try minimal DSL
mv structurizr-ws/workspace.dsl structurizr-ws/workspace.dsl.backup
cat > structurizr-ws/workspace.dsl << 'EOF'
workspace {
    model {
        user = person "User"
        system = softwareSystem "System"
        user -> system "Uses"
    }
    views {
        systemContext system {
            include *
            autolayout
        }
    }
}
EOF

podman compose restart structurizr
podman compose logs structurizr --tail 20

# If this works, issue is in your DSL
# Gradually add back sections to find the problematic part
```

**Is it container-related?**
```bash
# Try running without compose
podman run --rm -it \
  -p 8080:8080 \
  -v $(pwd)/structurizr-ws:/usr/local/structurizr:Z \
  structurizr/lite:latest

# If this works, issue is in compose.yaml
```

**Is it environment-related?**
```bash
# Try with minimal environment
podman run --rm -it \
  -p 8080:8080 \
  structurizr/lite:latest

# This runs with empty workspace
# If this works, issue is in your workspace files
```

#### 3. **Use Binary Search for DSL Issues**

If a large DSL file has errors:

```bash
# 1. Comment out half the model
# 2. Test if it works
# 3. If it works, error is in commented half; uncomment that half and comment the other
# 4. Repeat until you find the problematic section

# Example:
workspace {
    model {
        # === BLOCK A ===
        user = person "User"
        system1 = softwareSystem "System 1"

        # === BLOCK B === (commented out for testing)
        # system2 = softwareSystem "System 2"
        # system3 = softwareSystem "System 3"
    }
}
```

#### 4. **Validate Individual Components**

**Check relationships:**
```bash
# Extract all relationships from DSL
grep -n "->  " structurizr-ws/workspace.dsl

# For each relationship, verify:
# 1. Source element exists
# 2. Destination element exists
# 3. Both are in scope or fully qualified
```

**Check identifiers:**
```bash
# Find all identifier assignments
grep -n " = " structurizr-ws/workspace.dsl | grep -E "(person|softwareSystem|container|component)"

# Find all identifier references
grep -n "-> " structurizr-ws/workspace.dsl | awk '{print $1, $2}'

# Cross-reference to ensure all referenced identifiers are defined
```

**Check view references:**
```bash
# Extract view definitions
awk '/views {/,/^}/' structurizr-ws/workspace.dsl > views.txt

# Check each include statement references valid elements
grep "include" views.txt
```

### Advanced Debugging Tools

#### Enable DSL Debug Mode

While Structurizr Lite doesn't have a built-in debug mode, you can:

```bash
# Run container with verbose Java logging
podman run --rm -it \
  -p 8080:8080 \
  -v $(pwd)/structurizr-ws:/usr/local/structurizr:Z \
  -e JAVA_OPTS="-Dlogging.level.com.structurizr=DEBUG" \
  structurizr/lite:latest
```

#### Monitor File Changes

```bash
# Watch for file changes and auto-restart
while inotifywait -e modify structurizr-ws/workspace.dsl; do
    echo "=== DSL file changed, restarting container ==="
    podman compose restart structurizr
    sleep 3
    podman compose logs structurizr --tail 30 | grep -i "error\|exception"
done
```

#### Syntax Validation Script

Create a validation script:

```bash
cat > validate_dsl.sh << 'EOF'
#!/bin/bash

DSL_FILE="structurizr-ws/workspace.dsl"

echo "=== DSL Validation Check ==="
echo ""

# Check file exists
if [ ! -f "$DSL_FILE" ]; then
    echo "❌ ERROR: $DSL_FILE not found"
    exit 1
fi

echo "✅ File exists"

# Check brace balance
OPEN=$(grep -o '{' "$DSL_FILE" | wc -l)
CLOSE=$(grep -o '}' "$DSL_FILE" | wc -l)

if [ $OPEN -eq $CLOSE ]; then
    echo "✅ Braces balanced ($OPEN opening, $CLOSE closing)"
else
    echo "❌ ERROR: Unbalanced braces ($OPEN opening, $CLOSE closing)"
    exit 1
fi

# Check for basic structure
if grep -q "workspace {" "$DSL_FILE" && \
   grep -q "model {" "$DSL_FILE" && \
   grep -q "views {" "$DSL_FILE"; then
    echo "✅ Basic structure present (workspace, model, views)"
else
    echo "⚠️  WARNING: Missing basic structure elements"
fi

# Extract identifier definitions
echo ""
echo "=== Defined Identifiers ==="
grep " = " "$DSL_FILE" | grep -E "(person|softwareSystem|container|component)" | \
    sed 's/^[[:space:]]*//' | cut -d'=' -f1 | sort | uniq

# Extract relationship references
echo ""
echo "=== Relationship References ==="
grep " -> " "$DSL_FILE" | sed 's/^[[:space:]]*//' | \
    awk '{print "Source:", $1, "-> Target:", $3}' | head -20

echo ""
echo "=== Validation Complete ==="
echo "Now restart container and check logs:"
echo "  podman compose restart structurizr"
echo "  podman compose logs structurizr --tail 50"
EOF

chmod +x validate_dsl.sh
./validate_dsl.sh
```

### Common Debugging Scenarios

#### Scenario 1: "Element does not exist" Error

**Error Message:**
```
The destination element "myContainer" does not exist at line 45
```

**Debug Process:**

```bash
# 1. Extract the line causing the issue
sed -n '45p' structurizr-ws/workspace.dsl

# 2. Find where "myContainer" is defined
grep -n "myContainer = " structurizr-ws/workspace.dsl

# 3. Check the scope
# If defined inside a system at line 20:
sed -n '15,50p' structurizr-ws/workspace.dsl

# 4. Determine the correct reference
# If myContainer is defined in system "mySystem", then:
# - Within mySystem block: myContainer
# - Outside mySystem block: mySystem.myContainer

# 5. Fix the reference
# Change: myContainer
# To: mySystem.myContainer
```

#### Scenario 2: Diagrams Not Rendering

**Symptoms:** Views show up but diagrams are blank.

**Debug Process:**

```bash
# 1. Check if elements are included in view
grep -A 10 "systemContext\|container\|component" structurizr-ws/workspace.dsl

# 2. Verify include statements
# Should have: include *
# Or specific includes: include elementName

# 3. Check for layout directive
# Should have: autolayout lr (or tb)

# 4. Try simplest possible view
cat > structurizr-ws/workspace.dsl << 'EOF'
workspace {
    model {
        u = person "User"
        s = softwareSystem "System"
        u -> s "Uses"
    }
    views {
        systemLandscape {
            include *
            autolayout
        }
    }
}
EOF

# 5. Restart and verify
podman compose restart structurizr
```

#### Scenario 3: Container Crash Loop

**Symptoms:** Container repeatedly starts and stops.

**Debug Process:**

```bash
# 1. Check exit code
podman inspect structurizr | grep ExitCode

# 2. Get full logs from all attempts
podman compose logs structurizr

# 3. Look for Java exceptions
podman compose logs structurizr | grep -i "exception\|error" | head -20

# 4. Check if it's a mount issue
podman compose exec structurizr ls -la /usr/local/structurizr
# If this fails, volume mount is the issue

# 5. Try without volume mount
podman run --rm -it -p 8080:8080 structurizr/lite:latest
# If this works, issue is with your workspace files

# 6. Check SELinux
getenforce
# If "Enforcing", try:
sudo setenforce 0
podman compose restart structurizr
# If this fixes it, SELinux labels need fixing:
chcon -Rt container_file_t structurizr-ws/
```

---

## Reference Materials

### Official Documentation

- **Structurizr DSL Language Reference**: https://github.com/structurizr/dsl/tree/master/docs
- **Structurizr Lite**: https://structurizr.com/help/lite
- **C4 Model**: https://c4model.com/
- **Structurizr Examples**: https://github.com/structurizr/examples

### DSL Quick Reference

#### Element Types

```dsl
# People
person "Name" "Description" {
    tags "tag1" "tag2"
}

# Software Systems
softwareSystem "Name" "Description" {
    tags "tag1"

    # Containers
    container "Name" "Description" "Technology" {
        tags "tag1"

        # Components
        component "Name" "Description" "Technology" {
            tags "tag1"
        }
    }
}

# Deployment Nodes
deploymentEnvironment "Production" {
    deploymentNode "Web Server" {
        containerInstance mySystem.webApp
    }
}
```

#### Relationship Syntax

```dsl
# Basic
source -> destination "Description"

# With technology
source -> destination "Description" "Technology"

# With tags
source -> destination "Description" "Technology" {
    tags "async" "important"
}
```

#### View Types

```dsl
# System Landscape
systemLandscape "key" "Title" {
    include *
    autolayout lr
}

# System Context
systemContext softwareSystem "key" "Title" {
    include *
    exclude relationship.tag==exclude
    autolayout lr
}

# Container
container softwareSystem "key" "Title" {
    include *
    autolayout lr
}

# Component
component container "key" "Title" {
    include *
    autolayout tb
}

# Dynamic
dynamic softwareSystem "key" "Title" {
    source -> destination "Description"
    autolayout lr
}

# Deployment
deployment softwareSystem "environment" "key" "Title" {
    include *
    autolayout lr
}

# Filtered
filtered "key" "Title" {
    include *
    exclude element.tag==exclude
}
```

#### Style Properties

```dsl
styles {
    element "Tag" {
        shape Box          # Box, RoundedBox, Circle, Ellipse, Hexagon,
                          # Cylinder, Component, Person, Robot, Folder,
                          # WebBrowser, MobileDevicePortrait, MobileDeviceLandscape,
                          # Pipe
        icon "url"        # URL to icon image
        width 450         # Width in pixels
        height 300        # Height in pixels
        background #ffffff
        color #000000     # Text color
        stroke #000000    # Border color
        strokeWidth 2     # Border thickness
        fontSize 24
        border Solid      # Solid, Dashed, Dotted
        opacity 100       # 0-100
        metadata true     # Show/hide metadata
        description true  # Show/hide description
    }

    relationship "Tag" {
        thickness 2
        color #707070
        dashed false      # true for dashed line
        routing Direct    # Direct, Orthogonal, Curved
        fontSize 24
        width 200
        position 50       # Label position 0-100
        opacity 100
    }
}
```

### Common Commands Cheat Sheet

```bash
# ===== CONTAINER MANAGEMENT =====
# Start
podman compose up -d

# Stop
podman compose stop

# Restart
podman compose restart structurizr

# View logs
podman compose logs structurizr --tail 50
podman compose logs structurizr --follow

# Execute command in container
podman compose exec structurizr /bin/sh

# ===== DSL WORKFLOW =====
# Edit DSL
vim structurizr-ws/workspace.dsl

# Quick validation
grep " -> " structurizr-ws/workspace.dsl  # Check relationships
grep " = " structurizr-ws/workspace.dsl   # Check definitions

# Clear cache and restart
rm structurizr-ws/workspace.json
podman compose restart structurizr

# Check for errors
podman compose logs structurizr --since 1m | grep -i "error\|exception"

# ===== DEBUGGING =====
# Container status
podman compose ps

# Container resource usage
podman stats structurizr

# Network info
podman inspect structurizr | grep -i ipaddress

# Port mapping
podman port structurizr

# Volume mounts
podman inspect structurizr | grep -A 20 Mounts

# ===== FILE MANAGEMENT =====
# Check permissions
ls -la structurizr-ws/

# Fix permissions
chmod -R 755 structurizr-ws/
chmod 644 structurizr-ws/workspace.dsl

# Fix SELinux context
chcon -Rt container_file_t structurizr-ws/

# ===== CLEANUP =====
# Stop and remove container
podman compose down

# Remove with volumes
podman compose down -v

# Clean up unused images
podman image prune

# Full cleanup
podman system prune -a
```

### Troubleshooting Decision Tree

```
Issue Encountered
│
├─ Container won't start
│  ├─ Check logs: podman compose logs structurizr
│  ├─ Check port: ss -tulpn | grep 8080
│  ├─ Check permissions: ls -la structurizr-ws/
│  └─ Try minimal container: podman run --rm -it -p 8080:8080 structurizr/lite
│
├─ DSL parsing error
│  ├─ Check error message for line number
│  ├─ Verify element exists: grep "elementName =" workspace.dsl
│  ├─ Check scope: element defined in parent?
│  ├─ Use fully qualified path if needed
│  └─ Validate braces: grep -o '{' workspace.dsl | wc -l
│
├─ Diagrams not showing
│  ├─ Check view includes: grep "include" workspace.dsl
│  ├─ Verify autolayout: grep "autolayout" workspace.dsl
│  ├─ Check browser console: F12 → Console tab
│  └─ Hard refresh browser: Ctrl+Shift+R
│
├─ Changes not reflected
│  ├─ Delete cache: rm structurizr-ws/workspace.json
│  ├─ Restart container: podman compose restart
│  ├─ Hard refresh browser
│  └─ Check auto-refresh setting in compose.yaml
│
└─ Performance issues
   ├─ Check resource usage: podman stats
   ├─ Add resource limits to compose.yaml
   ├─ Simplify DSL (reduce elements/views)
   └─ Increase JVM memory: JAVA_OPTS="-Xmx2g"
```

### Getting Help

When asking for help (GitHub issues, forums, etc.), include:

1. **Structurizr version:**
   ```bash
   podman compose logs structurizr | grep "structurizr-dsl:"
   ```

2. **Environment:**
   ```bash
   uname -a
   podman --version
   ```

3. **Error messages:**
   ```bash
   podman compose logs structurizr --tail 100
   ```

4. **Minimal reproducible DSL:**
   - Simplify your DSL to the smallest file that still shows the issue
   - Remove sensitive information

5. **What you've tried:**
   - List troubleshooting steps already taken
   - Show commands and their output

### Additional Resources

#### VSCode Extensions

- **Structurizr DSL**: Syntax highlighting and validation
  ```
  ext install structurizr.structurizr-dsl
  ```

#### Alternative Diagram Tools

If Structurizr doesn't meet your needs:

- **PlantUML**: Text-based UML diagrams
- **Mermaid**: Markdown-based diagrams
- **D2**: Modern declarative diagram language
- **Diagrams as Code** (Python): `diagrams` library

#### Learning Resources

- **C4 Model Documentation**: https://c4model.com/
- **Simon Brown's Blog**: https://simonbrown.je/
- **Architecture Decision Records**: https://adr.github.io/

---

## Appendix: Complete Working Example

### Minimal Working DSL

```dsl
workspace "Example Workspace" "A minimal working example" {

    !identifiers hierarchical

    model {
        # People
        user = person "End User" "Person using the system"
        admin = person "Administrator" "System administrator"

        # Main System
        mainSystem = softwareSystem "Main System" "Core business system" {

            webApp = container "Web Application" "User interface" "React" {
                tags "WebApp"

                ui = component "UI Components" "React components" "React"
                api = component "API Client" "REST client" "Axios"
            }

            apiGateway = container "API Gateway" "API entry point" "Kong" {
                tags "API"
            }

            backend = container "Backend Service" "Business logic" "Node.js" {
                tags "Backend"

                controller = component "Controller" "HTTP handlers" "Express"
                service = component "Business Service" "Business logic" "TypeScript"
                repository = component "Data Repository" "Data access" "TypeORM"
            }

            database = container "Database" "Data storage" "PostgreSQL" {
                tags "Database"
            }
        }

        # External Systems
        authService = softwareSystem "Auth Service" "Authentication provider" {
            tags "External"
        }

        emailService = softwareSystem "Email Service" "Email notifications" {
            tags "External"
        }

        # Relationships - User to System
        user -> mainSystem.webApp "Uses" "HTTPS"
        admin -> mainSystem.webApp "Administers" "HTTPS"

        # Relationships - System to External
        mainSystem -> authService "Authenticates users" "HTTPS"
        mainSystem -> emailService "Sends emails" "SMTP"

        # Relationships - Internal Container Level
        mainSystem.webApp -> mainSystem.apiGateway "Makes API calls" "HTTPS/REST"
        mainSystem.apiGateway -> mainSystem.backend "Routes requests" "HTTP"
        mainSystem.backend -> mainSystem.database "Reads/writes data" "SQL/TCP"

        # Relationships - Component Level
        mainSystem.webApp.ui -> mainSystem.webApp.api "Uses"
        mainSystem.webApp.api -> mainSystem.apiGateway "Calls" "HTTPS/REST"

        mainSystem.backend.controller -> mainSystem.backend.service "Calls"
        mainSystem.backend.service -> mainSystem.backend.repository "Uses"
        mainSystem.backend.repository -> mainSystem.database "Queries" "SQL"

        mainSystem.backend.service -> authService "Validates tokens" "HTTPS"
        mainSystem.backend.service -> emailService "Sends notifications" "SMTP"
    }

    views {
        # System Landscape
        systemLandscape "Landscape" "System landscape view" {
            include *
            autolayout lr
        }

        # System Context
        systemContext mainSystem "Context" "System context for Main System" {
            include *
            autolayout lr
        }

        # Container View
        container mainSystem "Containers" "Container view for Main System" {
            include *
            autolayout lr
        }

        # Component Views
        component mainSystem.webApp "WebAppComponents" "Web Application components" {
            include *
            autolayout tb
        }

        component mainSystem.backend "BackendComponents" "Backend Service components" {
            include *
            autolayout tb
        }

        # Dynamic View
        dynamic mainSystem "UserLogin" "User login flow" {
            user -> mainSystem.webApp "1. Opens application"
            mainSystem.webApp -> mainSystem.apiGateway "2. Submits credentials"
            mainSystem.apiGateway -> mainSystem.backend "3. Forwards request"
            mainSystem.backend -> authService "4. Validates credentials"
            authService -> mainSystem.backend "5. Returns auth token"
            mainSystem.backend -> mainSystem.apiGateway "6. Returns token"
            mainSystem.apiGateway -> mainSystem.webApp "7. Returns token"
            mainSystem.webApp -> user "8. Shows dashboard"
            autolayout lr
        }

        # Styles
        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }

            element "Software System" {
                background #1168bd
                color #ffffff
            }

            element "External" {
                background #999999
                color #ffffff
            }

            element "Container" {
                background #438dd5
                color #ffffff
            }

            element "WebApp" {
                shape WebBrowser
            }

            element "Database" {
                shape Cylinder
            }

            element "Component" {
                background #85bbf0
                color #000000
            }

            relationship "Relationship" {
                routing Curved
                thickness 2
                color #707070
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
```

### Complete compose.yaml

```yaml
version: '3.8'

services:
  structurizr:
    image: structurizr/lite:latest
    container_name: structurizr
    ports:
      - "8080:8080"
    volumes:
      - ./structurizr-ws:/usr/local/structurizr:Z
    environment:
      - STRUCTURIZR_AUTOSAVEINTERVAL=2000
      - STRUCTURIZR_AUTOREFRESHINTERVAL=2000
      - STRUCTURIZR_EDITABLE=true
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### .gitignore for Structurizr Projects

```gitignore
# Environment files
.env
.env.*
!.env.example
*.env

# Structurizr generated files
structurizr-ws/workspace.json
structurizr-ws/.structurizr/

# Backups
*.backup
*.bak
*~

# OS files
.DS_Store
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo

# Logs
*.log

# Temporary files
tmp/
temp/
```

---

## Summary

This guide covers:

✅ **DSL Issues**: Syntax, validation, scope, identifiers
✅ **Container Issues**: Startup, logs, performance
✅ **Podman Issues**: Permissions, volumes, networking
✅ **Best Practices**: Organization, naming, styling
✅ **Debugging**: Systematic processes and tools
✅ **Reference**: Quick commands and examples

**Remember:**
1. Always check logs first: `podman compose logs structurizr`
2. Validate DSL syntax before restarting
3. Use fully qualified identifiers when referencing elements outside their scope
4. Keep secrets out of version control
5. Document your architecture decisions

For further help, consult the official Structurizr documentation or create an issue with a minimal reproducible example.
