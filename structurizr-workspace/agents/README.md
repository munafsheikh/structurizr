# Structurizr Architecture Documentation

This directory contains architecture documentation using [Structurizr](https://structurizr.com/) and the [C4 model](https://c4model.com/) for visualizing software architecture.

## 🏗️ Current Architecture: Content Scheduling System

A Google Apps Script-based automation platform that intelligently schedules content using ChatGPT AI and integrates with various productivity tools.

**Key Components:**
- **App Script Orchestrator**: Coordinates the scheduling workflow
- **External Integrations**: Notion, Article Database, Google Calendar, ChatGPT API, Slack
- **Automated Workflow**: Gathers prompts, analyzes calendar, uses AI for optimization, and updates systems

## 📁 Project Structure

```
Structurizr/
├── README.md                     # This file
├── TROUBLESHOOTING_GUIDE.md      # Comprehensive troubleshooting guide
├── QUICK_REFERENCE.md            # Quick reference card for common tasks
├── compose.yaml                  # Podman/Docker Compose configuration
├── .env                          # Environment variables (NOT in git)
├── .env.example                  # Environment template
├── .gitignore                    # Git ignore rules
└── structurizr-ws/               # Structurizr workspace
    ├── workspace.dsl             # Architecture definition (DSL)
    ├── workspace.json            # Generated cache (auto)
    ├── structurizr.properties    # Workspace configuration
    ├── docs/                     # Markdown documentation
    │   └── 01-context.md
    └── adrs/                     # Architecture Decision Records
        └── 0001-architecture-decisions.md
```

## 🚀 Quick Start

### Prerequisites

- **Podman** (or Docker)
- **Podman Compose** (or Docker Compose)

### Installation

```bash
# 1. Clone/navigate to this directory
cd /path/to/Structurizr

# 2. Create environment file (if needed)
cp .env.example .env
# Edit .env with your values

# 3. Start Structurizr Lite
podman compose up -d

# 4. Access the UI
firefox http://localhost:8080
```

### Making Changes

```bash
# 1. Edit the DSL file
vim structurizr-ws/workspace.dsl

# 2. Restart to apply changes
podman compose restart structurizr

# 3. Check for errors
podman compose logs structurizr --tail 20

# 4. Refresh browser (Ctrl+Shift+R)
```

## 📖 Documentation

### For Users

- **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Quick reference card for common operations
  - Essential commands
  - DSL syntax basics
  - Common patterns
  - Quick fixes

### For Troubleshooting

- **[TROUBLESHOOTING_GUIDE.md](./TROUBLESHOOTING_GUIDE.md)** - Comprehensive troubleshooting guide
  - DSL syntax and validation issues
  - Container and runtime issues
  - Podman/Compose issues
  - Environment and configuration issues
  - Debugging techniques
  - Complete reference materials

## 🔧 Common Operations

### View Logs
```bash
# Last 50 lines
podman compose logs structurizr --tail 50

# Follow in real-time
podman compose logs structurizr --follow

# Filter for errors
podman compose logs structurizr | grep -i error
```

### Restart Container
```bash
# Restart (keeps data)
podman compose restart structurizr

# Stop and start
podman compose stop
podman compose start

# Full rebuild
podman compose down
podman compose up -d --force-recreate
```

### Debug DSL Issues
```bash
# Check brace balance
grep -o '{' structurizr-ws/workspace.dsl | wc -l
grep -o '}' structurizr-ws/workspace.dsl | wc -l

# Find all element definitions
grep " = " structurizr-ws/workspace.dsl

# Find all relationships
grep " -> " structurizr-ws/workspace.dsl

# Clear cache and restart
rm structurizr-ws/workspace.json
podman compose restart structurizr
```

## 🎨 Architecture Views

The workspace includes the following views:

1. **System Landscape** - Overview of all systems and actors
2. **System Context** - Content Scheduling System and its external dependencies
3. **Container View** - Internal containers within the system
4. **Component View** - Detailed component architecture of App Script Orchestrator
5. **Dynamic View** - Scheduling workflow sequence from trigger to notification

Access all views at: http://localhost:8080/workspace/diagrams

## 📝 DSL Quick Example

```dsl
workspace "My System" {
    model {
        user = person "User"
        system = softwareSystem "System" {
            webapp = container "Web App" "UI" "React"
            api = container "API" "Backend" "Node.js"
            db = container "Database" "Storage" "PostgreSQL"
        }

        user -> system.webapp "Uses"
        system.webapp -> system.api "Calls"
        system.api -> system.db "Reads/writes"
    }

    views {
        systemContext system {
            include *
            autolayout lr
        }

        container system {
            include *
            autolayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
            }
        }
    }
}
```

## 🔐 Security Notes

### ⚠️ Important: API Key Management

The `.env` file may contain sensitive API keys. **Never commit it to version control!**

```bash
# Ensure .env is in .gitignore
echo ".env" >> .gitignore

# If already committed, remove it:
git rm --cached .env
git commit -m "Remove .env from version control"

# Rotate any exposed API keys immediately!
```

**Secure Practices:**
- Use `.env.example` as a template (no real values)
- Store real secrets in `.env` (not in git)
- Use secret management tools in production (Vault, AWS Secrets Manager, etc.)
- Rotate keys regularly

## 🐛 Troubleshooting

### Container won't start?
```bash
# Check logs
podman compose logs structurizr

# Check port availability
ss -tulpn | grep 8080

# Try minimal container
podman run --rm -it -p 8080:8080 structurizr/lite:latest
```

### DSL errors?
```bash
# View error details
podman compose logs structurizr | grep "StructurizrDslParserException"

# Common fix: Use fully qualified identifiers
# ❌ system1 -> container1
# ✅ system1 -> system2.container1

# Clear cache
rm structurizr-ws/workspace.json
```

### Changes not showing?
```bash
# Delete cache
rm structurizr-ws/workspace.json

# Restart container
podman compose restart structurizr

# Hard refresh browser (Ctrl+Shift+R)
```

**For detailed troubleshooting, see [TROUBLESHOOTING_GUIDE.md](./TROUBLESHOOTING_GUIDE.md)**

## 📚 Additional Resources

### Official Documentation
- [Structurizr DSL Documentation](https://github.com/structurizr/dsl)
- [Structurizr Lite](https://structurizr.com/help/lite)
- [C4 Model](https://c4model.com/)
- [Structurizr Examples](https://github.com/structurizr/examples)

### Tools
- [Structurizr VSCode Extension](https://marketplace.visualstudio.com/items?itemName=structurizr.structurizr-dsl)
- [Online DSL Playground](https://structurizr.com/dsl)

### Community
- [GitHub Discussions](https://github.com/structurizr/dsl/discussions)
- [C4 Model Slack](https://c4model.com/#Slack)

## 🤝 Contributing

When making changes to the architecture:

1. **Edit the DSL file**: `structurizr-ws/workspace.dsl`
2. **Update documentation**: Add/update markdown files in `docs/`
3. **Document decisions**: Create ADRs in `adrs/`
4. **Test changes**: Restart container and verify all views render
5. **Check for errors**: Review logs for any validation issues

### ADR Template

```markdown
# ADR XXX: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Context
What is the issue we're seeing that is motivating this decision?

## Decision
What is the change that we're proposing and/or doing?

## Consequences
What becomes easier or more difficult to do because of this change?
```

## 📋 Maintenance Checklist

### Regular Tasks
- [ ] Review and update architecture diagrams monthly
- [ ] Document significant architecture decisions
- [ ] Keep documentation in sync with code
- [ ] Update DSL when system architecture changes
- [ ] Validate all views render correctly

### Container Maintenance
- [ ] Update Structurizr image: `podman compose pull`
- [ ] Check disk usage: `podman system df`
- [ ] Prune old images: `podman image prune`
- [ ] Review logs for warnings: `podman compose logs structurizr | grep -i warn`

### Security Maintenance
- [ ] Rotate API keys quarterly
- [ ] Review access controls
- [ ] Audit `.env` file is not in git
- [ ] Update dependencies (container image)

## 🆘 Getting Help

1. **Check the guides**:
   - [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for common tasks
   - [TROUBLESHOOTING_GUIDE.md](./TROUBLESHOOTING_GUIDE.md) for detailed debugging

2. **Check logs**:
   ```bash
   podman compose logs structurizr --tail 100
   ```

3. **Validate DSL syntax**:
   - Use the validation scripts in TROUBLESHOOTING_GUIDE.md
   - Check the Structurizr VSCode extension

4. **Search for similar issues**:
   - [Structurizr DSL Issues](https://github.com/structurizr/dsl/issues)
   - [Structurizr Discussions](https://github.com/structurizr/dsl/discussions)

5. **Ask for help**:
   - Provide: Structurizr version, error messages, minimal reproducible DSL
   - See "Getting Help" section in TROUBLESHOOTING_GUIDE.md

## 📄 License

This workspace configuration is part of your project. Structurizr Lite itself is licensed under the MIT License.

---

**Last Updated:** 2026-01-13

**Structurizr Version:** structurizr/lite:latest (DSL v5.0.1)

**Maintained by:** [Your Name/Team]
