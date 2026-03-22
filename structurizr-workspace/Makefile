# Structurizr Makefile
# Convenient commands for managing Structurizr workspace

.PHONY: help start stop restart logs status validate clean rebuild open docs test

# Default target
.DEFAULT_GOAL := help

# Variables
COMPOSE := podman compose
CONTAINER := structurizr
WORKSPACE := structurizr-ws
DSL_FILE := $(WORKSPACE)/workspace.dsl
URL := http://localhost:8080

# Colors for help text
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

## help: Display this help message
help:
	@echo ""
	@echo "$(BLUE)Structurizr Workspace Management$(NC)"
	@echo ""
	@echo "$(GREEN)Available commands:$(NC)"
	@echo ""
	@grep -E '^## ' Makefile | sed 's/## /  $(BLUE)/' | sed 's/:/ $(NC)- /'
	@echo ""
	@echo "$(YELLOW)Quick start:$(NC)"
	@echo "  make start      - Start Structurizr"
	@echo "  make open       - Open in browser"
	@echo "  make logs       - View logs"
	@echo ""

## start: Start the Structurizr container
start:
	@echo "$(GREEN)Starting Structurizr...$(NC)"
	$(COMPOSE) up -d
	@echo "$(GREEN)✓ Structurizr started$(NC)"
	@echo "Access at: $(URL)"

## stop: Stop the Structurizr container
stop:
	@echo "$(YELLOW)Stopping Structurizr...$(NC)"
	$(COMPOSE) stop
	@echo "$(GREEN)✓ Structurizr stopped$(NC)"

## restart: Restart the container (useful after DSL changes)
restart:
	@echo "$(YELLOW)Restarting Structurizr...$(NC)"
	$(COMPOSE) restart $(CONTAINER)
	@sleep 2
	@echo "$(GREEN)✓ Structurizr restarted$(NC)"
	@echo "Checking for errors..."
	@$(COMPOSE) logs $(CONTAINER) --since 30s | grep -i "error\|exception" || echo "$(GREEN)No errors found$(NC)"

## logs: View container logs
logs:
	$(COMPOSE) logs $(CONTAINER) --tail 50

## logs-follow: Follow container logs in real-time
logs-follow:
	$(COMPOSE) logs $(CONTAINER) --follow

## logs-errors: Show only errors in logs
logs-errors:
	$(COMPOSE) logs $(CONTAINER) | grep -i "error\|exception"

## status: Check container status
status:
	@echo "$(BLUE)Container Status:$(NC)"
	@$(COMPOSE) ps
	@echo ""
	@echo "$(BLUE)Recent Logs:$(NC)"
	@$(COMPOSE) logs $(CONTAINER) --tail 5

## validate: Validate DSL syntax
validate:
	@echo "$(BLUE)Running DSL validation...$(NC)"
	@./validate-dsl.sh $(WORKSPACE)

## clean: Clean generated files and cache
clean:
	@echo "$(YELLOW)Cleaning generated files...$(NC)"
	@rm -f $(WORKSPACE)/workspace.json
	@rm -rf $(WORKSPACE)/.structurizr/
	@echo "$(GREEN)✓ Cleaned generated files$(NC)"

## clean-restart: Clean cache and restart
clean-restart: clean restart
	@echo "$(GREEN)✓ Cleaned and restarted$(NC)"

## rebuild: Completely rebuild container
rebuild:
	@echo "$(YELLOW)Rebuilding Structurizr...$(NC)"
	$(COMPOSE) down
	$(COMPOSE) pull
	$(COMPOSE) up -d --force-recreate
	@echo "$(GREEN)✓ Rebuild complete$(NC)"

## open: Open Structurizr in default browser
open:
	@echo "Opening $(URL)..."
	@if command -v xdg-open > /dev/null; then \
		xdg-open $(URL); \
	elif command -v open > /dev/null; then \
		open $(URL); \
	else \
		echo "Please open $(URL) in your browser"; \
	fi

## edit: Open DSL file in editor
edit:
	@if [ -n "$$EDITOR" ]; then \
		$$EDITOR $(DSL_FILE); \
	elif command -v vim > /dev/null; then \
		vim $(DSL_FILE); \
	elif command -v nano > /dev/null; then \
		nano $(DSL_FILE); \
	else \
		echo "No editor found. Set EDITOR environment variable or use: vim $(DSL_FILE)"; \
	fi

## docs: View documentation
docs:
	@echo "$(BLUE)Available Documentation:$(NC)"
	@echo ""
	@ls -1 *.md | sed 's/^/  - /'
	@echo ""
	@echo "To view: cat README.md"

## test: Run full validation and test workflow
test: validate
	@echo ""
	@echo "$(BLUE)Testing container startup...$(NC)"
	@$(COMPOSE) restart $(CONTAINER)
	@sleep 3
	@echo ""
	@echo "$(BLUE)Checking for errors...$(NC)"
	@if $(COMPOSE) logs $(CONTAINER) --since 1m | grep -qi "error\|exception"; then \
		echo "$(YELLOW)⚠ Errors found in logs:$(NC)"; \
		$(COMPOSE) logs $(CONTAINER) --since 1m | grep -i "error\|exception"; \
		exit 1; \
	else \
		echo "$(GREEN)✓ No errors found$(NC)"; \
	fi
	@echo ""
	@echo "$(BLUE)Testing HTTP access...$(NC)"
	@if curl -s -o /dev/null -w "%{http_code}" $(URL) | grep -q "200\|302"; then \
		echo "$(GREEN)✓ HTTP access successful$(NC)"; \
	else \
		echo "$(YELLOW)⚠ HTTP access failed$(NC)"; \
		exit 1; \
	fi
	@echo ""
	@echo "$(GREEN)✓ All tests passed$(NC)"

## backup: Create a backup of the workspace
backup:
	@BACKUP_NAME="backup_$$(date +%Y%m%d_%H%M%S).tar.gz"; \
	echo "$(BLUE)Creating backup: $$BACKUP_NAME$(NC)"; \
	tar -czf $$BACKUP_NAME $(WORKSPACE)/*.dsl $(WORKSPACE)/docs/ $(WORKSPACE)/adrs/ 2>/dev/null || true; \
	echo "$(GREEN)✓ Backup created: $$BACKUP_NAME$(NC)"

## stats: Show container resource usage
stats:
	@echo "$(BLUE)Container Resource Usage:$(NC)"
	@podman stats $(CONTAINER) --no-stream

## shell: Open a shell in the container
shell:
	@echo "$(BLUE)Opening shell in container...$(NC)"
	$(COMPOSE) exec $(CONTAINER) /bin/sh

## pull: Pull latest Structurizr image
pull:
	@echo "$(BLUE)Pulling latest Structurizr image...$(NC)"
	$(COMPOSE) pull
	@echo "$(GREEN)✓ Image updated$(NC)"

## update: Pull latest image and restart
update: pull restart
	@echo "$(GREEN)✓ Update complete$(NC)"

## check-env: Verify environment setup
check-env:
	@echo "$(BLUE)Environment Check:$(NC)"
	@echo ""
	@echo "Checking podman..."
	@if command -v podman > /dev/null; then \
		echo "  $(GREEN)✓$(NC) podman installed: $$(podman --version)"; \
	else \
		echo "  $(YELLOW)✗$(NC) podman not found"; \
	fi
	@echo ""
	@echo "Checking compose..."
	@if $(COMPOSE) version > /dev/null 2>&1; then \
		echo "  $(GREEN)✓$(NC) compose available"; \
	else \
		echo "  $(YELLOW)✗$(NC) compose not found"; \
	fi
	@echo ""
	@echo "Checking files..."
	@if [ -f "$(DSL_FILE)" ]; then \
		echo "  $(GREEN)✓$(NC) DSL file exists: $(DSL_FILE)"; \
	else \
		echo "  $(YELLOW)✗$(NC) DSL file not found"; \
	fi
	@if [ -f ".env" ]; then \
		echo "  $(GREEN)✓$(NC) .env file exists"; \
	else \
		echo "  $(YELLOW)⚠$(NC) .env file not found (may not be needed)"; \
	fi
	@echo ""
	@echo "Checking port..."
	@if ss -tulpn 2>/dev/null | grep -q ":8080 "; then \
		echo "  $(YELLOW)⚠$(NC) Port 8080 already in use"; \
	else \
		echo "  $(GREEN)✓$(NC) Port 8080 available"; \
	fi

## install: Initial setup (first time only)
install:
	@echo "$(BLUE)Initial Setup$(NC)"
	@echo ""
	@if [ ! -f ".env" ]; then \
		echo "Creating .env from template..."; \
		cp .env.example .env; \
		echo "$(YELLOW)⚠ Edit .env and add your API keys$(NC)"; \
	else \
		echo ".env already exists"; \
	fi
	@echo ""
	@echo "Pulling Structurizr image..."
	@$(COMPOSE) pull
	@echo ""
	@echo "Starting container..."
	@$(COMPOSE) up -d
	@echo ""
	@echo "$(GREEN)✓ Installation complete!$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Edit .env with your API keys"
	@echo "  2. Run: make open"
	@echo "  3. Start editing: make edit"

## uninstall: Remove container and clean up
uninstall:
	@echo "$(YELLOW)Removing Structurizr...$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE) down -v; \
		echo "$(GREEN)✓ Uninstalled$(NC)"; \
	else \
		echo "Cancelled"; \
	fi

## dev: Development mode - watch for changes and auto-restart
dev:
	@echo "$(BLUE)Starting development mode...$(NC)"
	@echo "Watching $(DSL_FILE) for changes..."
	@echo "Press Ctrl+C to stop"
	@while true; do \
		inotifywait -e modify $(DSL_FILE) 2>/dev/null && \
		echo "$(YELLOW)File changed, restarting...$(NC)" && \
		$(MAKE) --no-print-directory clean-restart; \
	done
