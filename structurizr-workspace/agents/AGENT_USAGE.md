# Structurizr Architect Agent - Usage Guide

## Overview

The Structurizr Architect Agent is a specialized AI assistant designed to help you create, edit, and troubleshoot Structurizr DSL files in a podman environment. This guide shows you how to use the agent effectively.

## Files in This Directory

| File | Purpose |
|------|---------|
| `structurizr-architect.md` | Detailed agent specification and capabilities |
| `structurizr-architect-agent.json` | Machine-readable agent configuration |
| `system-prompt.md` | System prompt for Claude/LLM integration |
| `AGENT_USAGE.md` | This file - usage instructions |
| `example-conversations.md` | Example interactions with the agent |

## How to Use the Agent

### Option 1: Using with Claude Code (Recommended)

If you're using Claude Code CLI:

```bash
# Navigate to project directory
cd /path/to/Structurizr

# Start a conversation with agent context
claude --agent agents/structurizr-architect-agent.json

# Or load the system prompt
claude --system agents/system-prompt.md
```

### Option 2: Using with Claude Web Interface

1. **Start a new conversation** in Claude

2. **Provide the system prompt**:
   ```
   Copy and paste the contents of agents/system-prompt.md at the start
   of your conversation to give Claude the specialized knowledge.
   ```

3. **Provide project context**:
   ```
   "I'm working on a Structurizr project. Here's the structure:
   - structurizr-ws/workspace.dsl - Main DSL file
   - TROUBLESHOOTING_GUIDE.md - Comprehensive guide
   - QUICK_REFERENCE.md - Quick reference

   I need help with [your task]."
   ```

### Option 3: Using with API

If integrating programmatically:

```python
import anthropic

# Load system prompt
with open('agents/system-prompt.md', 'r') as f:
    system_prompt = f.read()

# Create client
client = anthropic.Anthropic(api_key="your-api-key")

# Start conversation
response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=4096,
    system=system_prompt,
    messages=[{
        "role": "user",
        "content": "Create a Structurizr workspace for a web application..."
    }]
)
```

## Common Tasks

### Task 1: Create New Architecture

**Your Request:**
```
Create a Structurizr workspace for an e-commerce platform with:
- Web frontend (React)
- API backend (Node.js)
- PostgreSQL database
- Redis cache
- Payment gateway integration (Stripe)
- Email service (SendGrid)
```

**Agent Will:**
1. ✅ Analyze your requirements
2. ✅ Plan the architecture structure
3. ✅ Generate complete DSL with proper scoping
4. ✅ Create all necessary views (System Context, Container, Component, Dynamic)
5. ✅ Add appropriate styling
6. ✅ Validate the DSL
7. ✅ Provide deployment instructions

### Task 2: Debug DSL Error

**Your Request:**
```
I'm getting this error when I restart the container:

StructurizrDslParserException: The destination element "paymentService"
does not exist at line 67

Can you help fix this?
```

**Agent Will:**
1. ✅ Read your workspace.dsl file
2. ✅ Locate line 67 and understand the context
3. ✅ Identify the scope issue
4. ✅ Find where paymentService is actually defined
5. ✅ Determine the correct fully qualified path
6. ✅ Apply the fix with explanation
7. ✅ Validate the corrected DSL
8. ✅ Verify no errors remain

### Task 3: Add New Component

**Your Request:**
```
Add a new "Notification Service" component to the backend container that:
- Sends emails via SendGrid
- Sends SMS via Twilio
- Has a queue for async processing
```

**Agent Will:**
1. ✅ Read current architecture
2. ✅ Understand existing patterns
3. ✅ Add new component with consistent naming
4. ✅ Create relationships to external services
5. ✅ Update relevant views
6. ✅ Maintain consistent styling
7. ✅ Validate changes
8. ✅ Test in container

### Task 4: Refactor Architecture

**Your Request:**
```
We're splitting our monolithic backend into microservices.
Can you help refactor the architecture to show:
- User Service
- Order Service
- Payment Service
- Inventory Service
- API Gateway
```

**Agent Will:**
1. ✅ Analyze current monolithic structure
2. ✅ Plan microservices decomposition
3. ✅ Create new container structure
4. ✅ Map existing components to new services
5. ✅ Update relationships (service-to-service communication)
6. ✅ Add API Gateway as entry point
7. ✅ Update all views to reflect new architecture
8. ✅ Validate and test

### Task 5: Create Dynamic View

**Your Request:**
```
Add a dynamic view showing the "User Checkout" flow:
1. User adds items to cart
2. User proceeds to checkout
3. System validates inventory
4. System processes payment
5. System confirms order
6. System sends confirmation email
```

**Agent Will:**
1. ✅ Understand the workflow steps
2. ✅ Map steps to existing components
3. ✅ Create dynamic view with proper sequence
4. ✅ Use correct element references (fully qualified)
5. ✅ Apply sequential numbering
6. ✅ Choose appropriate layout
7. ✅ Validate and test

## Best Practices for Working with the Agent

### 1. Be Specific

❌ **Vague:**
```
"Add a database to my system"
```

✅ **Specific:**
```
"Add a PostgreSQL database container to the backend system.
It should store user data, orders, and products.
The API server should read/write to it via SQL."
```

### 2. Provide Context

❌ **No Context:**
```
"Fix the error on line 45"
```

✅ **With Context:**
```
"I'm getting an 'element does not exist' error on line 45
after I added a new component. The error message is:
[paste error]

Here's what I was trying to do:
[explain your intent]"
```

### 3. Ask Questions

❌ **Silent Confusion:**
```
[Trying to understand hierarchical identifiers on your own]
```

✅ **Ask for Help:**
```
"I don't understand when to use simple identifiers vs fully qualified paths.
Can you explain the rule and show me examples?"
```

### 4. Iterate Incrementally

❌ **All at Once:**
```
"Add 15 new components, 5 external systems, 3 containers,
and 10 dynamic views all at once"
```

✅ **Step by Step:**
```
"Let's start by adding the User Service container with its 3 main components.
Once that's working, we'll add the other services."
```

### 5. Validate Frequently

❌ **Build Up, Then Test:**
```
[Make 50 changes]
[Try to test everything at once]
```

✅ **Test Often:**
```
"Let's validate this before moving on"
"Can you check if this works before we add more?"
```

## Understanding Agent Responses

### Successful Creation

The agent will show:
```
✅ Created Structurizr workspace

**Structure:**
- [Summary of what was created]

**Validation Results:**
✅ Syntax: Valid
✅ Braces: Balanced
✅ Identifiers: Correct
✅ Relationships: Valid

**Next Steps:**
1. Restart container: podman compose restart structurizr
2. View at: http://localhost:8080
3. Check logs: podman compose logs structurizr --tail 20
```

### Error Fixed

The agent will show:
```
🔧 Fixed Error

**Original Issue:**
[Error explanation]

**Root Cause:**
[Why it happened]

**Solution Applied:**
[What was changed]

**Validation:**
✅ No errors found
✅ Container restarted successfully

The fix is complete and ready to view.
```

### Modification Complete

The agent will show:
```
✅ Architecture Updated

**Changes Made:**
- Added: [New elements]
- Modified: [Changed elements]
- Updated: [Affected views]

**Affected Views:**
- System Context (updated relationships)
- Container View (new container visible)
- Component View (new components added)

**Validation:**
✅ All checks passed

**Testing:**
✅ Container restarted successfully
✅ No errors in logs
✅ Changes visible in UI
```

## Troubleshooting Agent Usage

### Issue: Agent Seems Unaware of Project Files

**Solution:**
The agent needs to read files to understand your project. Explicitly ask:
```
"Please read my workspace.dsl file to understand the current architecture"
"Check the TROUBLESHOOTING_GUIDE.md for solutions to this error"
```

### Issue: Agent Provides Generic Advice

**Solution:**
Provide specific context:
```
"I'm working with the Structurizr project in /path/to/Structurizr
The workspace uses hierarchical identifiers.
I need help with [specific task]."
```

### Issue: Agent Suggests Wrong Scope

**Solution:**
Remind about hierarchical identifiers:
```
"Remember we're using !identifiers hierarchical, so cross-scope
references need fully qualified paths"
```

### Issue: Validation Fails

**Solution:**
Ask agent to run validation:
```
"Can you validate this DSL using ./validate-dsl.sh and show the results?"
```

## Example Workflows

### Workflow 1: Complete New Project

```
You: "I need to document a microservices architecture. Let's start fresh."

Agent: [Asks clarifying questions about your architecture]

You: [Provide details about systems, containers, technologies]

Agent: [Generates complete workspace.dsl]

You: "This looks good! Can you validate it?"

Agent: [Runs validation, shows results]

You: "Great! Add a dynamic view for the user registration flow."

Agent: [Adds dynamic view, validates, tests]

You: "Perfect! Now add styles to make external systems gray."

Agent: [Updates styles, validates, tests]

You: "Excellent! Save and deploy."

Agent: [Provides final deployment instructions]
```

### Workflow 2: Debugging Session

```
You: "My container won't start. The logs show: [paste error]"

Agent: [Reads logs, identifies issue]

You: "What's causing this?"

Agent: [Explains root cause with examples]

You: "How do I fix it?"

Agent: [Shows exact fix needed]

You: "Please apply that fix."

Agent: [Edits DSL, validates, tests]

You: "Does it work now?"

Agent: [Confirms container started successfully, no errors]
```

### Workflow 3: Iterative Development

```
You: "Let's add a new Payment Service."

Agent: [Adds service, validates]

You: "Now add components for: payment processing, refund handling, receipt generation."

Agent: [Adds components, updates views, validates]

You: "Add relationships to Stripe and the database."

Agent: [Adds relationships with correct scoping, validates]

You: "Create a dynamic view for the payment flow."

Agent: [Creates dynamic view, validates]

You: "Perfect! Let's test it."

Agent: [Deploys changes, verifies in UI]
```

## Advanced Usage

### Custom Validation Rules

Ask the agent to check specific things:
```
"Before you finalize, please verify:
1. All external systems have the 'External' tag
2. All databases use Cylinder shape
3. All API calls specify the protocol (REST, GraphQL, etc.)
4. All components have descriptions"
```

### Consistent Patterns

Establish patterns:
```
"For this project, always use these conventions:
- Container identifiers: [systemName][ContainerName]
- Component identifiers: [containerName][ComponentName]
- Tags: Use PascalCase
- Technologies: Always specify version (e.g., 'Node.js 18')"
```

### Documentation Integration

Connect to docs:
```
"After making these changes, please:
1. Update docs/02-containers.md to describe the new containers
2. Create an ADR documenting why we chose this architecture
3. Add inline comments in the DSL explaining complex relationships"
```

## Tips for Success

1. **Start Simple**: Begin with minimal structure, add complexity gradually
2. **Validate Often**: Ask agent to validate after each significant change
3. **Reference Guides**: Point agent to TROUBLESHOOTING_GUIDE.md for complex issues
4. **Be Patient**: Complex architectures take time to model correctly
5. **Ask Questions**: Don't guess - ask agent to explain concepts
6. **Iterate**: Refine architecture based on feedback and testing
7. **Document**: Have agent help create ADRs and documentation

## Getting Help

If you're stuck:

1. **Check Examples**: See `example-conversations.md` in this directory
2. **Read Guides**: Review QUICK_REFERENCE.md for syntax help
3. **Ask Agent**: "I'm stuck on [problem]. Can you help me understand [concept]?"
4. **Reset Context**: Start new conversation with fresh system prompt if needed

## Next Steps

Now that you understand how to use the agent:

1. ✅ Choose your preferred method (Claude Code, Web, API)
2. ✅ Load the system prompt or agent configuration
3. ✅ Try a simple task (create minimal workspace)
4. ✅ Review the output and ask questions
5. ✅ Progress to more complex tasks
6. ✅ Reference this guide as needed

**Ready to start? Try asking:**
```
"Hi! I need help creating a Structurizr workspace for my application.
Can you start by asking me questions to understand my architecture?"
```

The agent will guide you from there!

---

**Pro Tip**: Bookmark this guide and `QUICK_REFERENCE.md` for quick access during development sessions.
