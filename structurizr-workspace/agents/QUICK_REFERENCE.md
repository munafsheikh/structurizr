# Structurizr Quick Reference Card

## Essential Commands

### Container Operations
```bash
# Start
podman compose up -d

# Stop
podman compose stop

# Restart (after DSL changes)
podman compose restart structurizr

# View logs
podman compose logs structurizr --tail 50
podman compose logs structurizr --follow

# Container status
podman compose ps
```

### DSL Edit Workflow
```bash
# 1. Edit DSL file
vim structurizr-ws/workspace.dsl

# 2. Clear cache (optional but recommended)
rm structurizr-ws/workspace.json

# 3. Restart container
podman compose restart structurizr

# 4. Check for errors
podman compose logs structurizr --since 1m | grep -i error

# 5. Access UI
firefox http://localhost:8080
```

### Troubleshooting
```bash
# Quick health check
podman compose ps
podman compose logs structurizr --tail 20 | grep -i "error\|exception"
curl -s http://localhost:8080 | head -5

# Find DSL errors
podman compose logs structurizr | grep "StructurizrDslParserException"

# Check file permissions
ls -la structurizr-ws/

# Verify port is accessible
ss -tulpn | grep 8080
```

## DSL Syntax Quick Reference

### Basic Structure
```dsl
workspace "Name" "Description" {
    !identifiers hierarchical

    model {
        # Define elements here
    }

    views {
        # Define views here
    }
}
```

### Elements
```dsl
# Person
user = person "User Name" "Description"

# Software System
system = softwareSystem "System Name" "Description" {
    # Container
    container1 = container "Container Name" "Description" "Technology" {
        # Component
        component1 = component "Component Name" "Description" "Technology"
    }
}
```

### Relationships
```dsl
# Within same scope - simple identifiers
source -> destination "Description"
source -> destination "Description" "Technology"

# Across scopes - fully qualified identifiers
system1.container1 -> system2 "Description"
system1.container1.component1 -> system2 "Description"
```

### Views
```dsl
views {
    # System Landscape
    systemLandscape "key" "Title" {
        include *
        autolayout lr
    }

    # System Context
    systemContext mySystem "key" "Title" {
        include *
        autolayout lr
    }

    # Container
    container mySystem "key" "Title" {
        include *
        autolayout lr
    }

    # Component
    component mySystem.container1 "key" "Title" {
        include *
        autolayout tb
    }

    # Dynamic (sequence)
    dynamic mySystem "key" "Title" {
        element1 -> element2 "1. First step"
        element2 -> element3 "2. Second step"
        autolayout lr
    }

    # Styles
    styles {
        element "Tag" {
            shape Box
            background #1168bd
            color #ffffff
        }
        relationship "Relationship" {
            routing Curved
        }
    }

    theme default
}
```

## Common Patterns

### Scope Rules
```dsl
model {
    system1 = softwareSystem "System 1" {
        container1 = container "Container 1" {
            component1 = component "Component 1"
            component2 = component "Component 2"

            # ✅ Same scope - simple identifiers
            component1 -> component2 "Calls"
        }

        container2 = container "Container 2"

        # ✅ Different containers in same system
        container1.component1 -> container2 "Uses"
    }

    system2 = softwareSystem "System 2"

    # ✅ Different systems - fully qualified
    system1.container1.component1 -> system2 "Integrates"
}
```

### Tags & Styles
```dsl
model {
    mySystem = softwareSystem "My System" {
        tags "Important" "Backend"
    }
}

views {
    styles {
        element "Important" {
            background #c92d39
            color #ffffff
        }
        element "Backend" {
            shape Hexagon
        }
    }
}
```

## Error Messages & Quick Fixes

### "Element does not exist"
**Error:** `The destination element "X" does not exist at line Y`

**Fix:**
```bash
# Find where element is defined
grep -n "X = " structurizr-ws/workspace.dsl

# Use fully qualified identifier
# Change: X
# To: parentSystem.parentContainer.X
```

### "Invalid identifier characters"
**Error:** `Identifiers can only contain a-zA-Z0-9_-`

**Fix:**
```dsl
# ❌ WRONG: Using dots in variable name
system.container = container "Name"

# ✅ CORRECT: Dots only in references, not definitions
container1 = container "Name"
```

### "Unbalanced braces"
**Check:**
```bash
# Count opening and closing braces
grep -o '{' structurizr-ws/workspace.dsl | wc -l
grep -o '}' structurizr-ws/workspace.dsl | wc -l
```

## File Structure
```
Structurizr/
├── compose.yaml              # Container configuration
├── .env                      # Environment variables (DO NOT COMMIT!)
├── .gitignore               # Git ignore rules
├── TROUBLESHOOTING_GUIDE.md # Detailed troubleshooting
├── QUICK_REFERENCE.md       # This file
└── structurizr-ws/
    ├── workspace.dsl        # Main architecture definition
    ├── workspace.json       # Generated cache (delete if issues)
    ├── docs/               # Markdown documentation
    │   └── *.md
    └── adrs/               # Architecture Decision Records
        └── *.md
```

## Common Shapes
```dsl
# People
shape Person

# Containers
shape Box              # Default rectangle
shape RoundedBox      # Rounded rectangle
shape Circle
shape Ellipse
shape Hexagon         # Microservices
shape WebBrowser      # Web apps
shape MobileDevicePortrait   # Mobile apps
shape Cylinder        # Databases
shape Folder          # File storage
shape Pipe            # Queues/streams
shape Component       # Software components
```

## Auto Layout Options
```dsl
# Left to right
autolayout lr

# Top to bottom
autolayout tb

# With spacing (rankSeparation nodeSeparation)
autolayout lr 100 50

# No auto layout (manual positioning)
# (omit autolayout directive)
```

## Debugging Checklist

When something goes wrong:

- [ ] Check container is running: `podman compose ps`
- [ ] Check logs: `podman compose logs structurizr --tail 50`
- [ ] Look for errors: `grep -i error`
- [ ] Verify DSL syntax: Use validation script
- [ ] Check file permissions: `ls -la structurizr-ws/`
- [ ] Delete cache: `rm structurizr-ws/workspace.json`
- [ ] Restart: `podman compose restart structurizr`
- [ ] Hard refresh browser: Ctrl+Shift+R

## Useful Grep Commands
```bash
# Find all element definitions
grep " = " structurizr-ws/workspace.dsl

# Find all relationships
grep " -> " structurizr-ws/workspace.dsl

# Find all tags
grep "tags" structurizr-ws/workspace.dsl

# Find specific element
grep "myElement" structurizr-ws/workspace.dsl

# Check view definitions
grep -A 5 "systemContext\|container\|component" structurizr-ws/workspace.dsl
```

## Environment Variables
```yaml
# In compose.yaml
environment:
  - STRUCTURIZR_EDITABLE=true              # Allow UI editing
  - STRUCTURIZR_AUTOSAVEINTERVAL=2000      # Auto-save (ms)
  - STRUCTURIZR_AUTOREFRESHINTERVAL=2000   # Auto-refresh (ms)
```

## Access URLs
- **Main UI:** http://localhost:8080
- **Diagrams:** http://localhost:8080/workspace/diagrams
- **Documentation:** http://localhost:8080/workspace/documentation
- **Decisions:** http://localhost:8080/workspace/decisions

## Tips

1. **Always use hierarchical identifiers** (`!identifiers hierarchical`)
2. **Use fully qualified paths** for cross-scope references
3. **Delete workspace.json** when making major DSL changes
4. **Check logs immediately** after restarting container
5. **Use `include *`** in views for quick iteration
6. **Start simple** then add complexity gradually
7. **Test each change** before adding more
8. **Keep backups** of working DSL files

## Resources

- **Full Guide:** See `TROUBLESHOOTING_GUIDE.md` in this directory
- **Official Docs:** https://github.com/structurizr/dsl
- **C4 Model:** https://c4model.com
- **Examples:** https://github.com/structurizr/examples
