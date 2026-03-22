# 1. Use Google Apps Script as orchestration platform

Date: 2026-01-11

## Status

Accepted

## Context

We need a lightweight automation platform that can integrate with Google Workspace services (Calendar) and external APIs (Notion, ChatGPT, Slack) without requiring dedicated server infrastructure.

## Decision

We will use Google Apps Script as the central orchestration platform for the content scheduling system.

## Consequences

### Positive
- **Zero infrastructure**: Runs on Google's servers with no deployment needed
- **Native Google integration**: Direct access to Google Calendar API
- **Built-in triggers**: Can run on schedule or manual trigger
- **Free tier**: Generous quotas for personal/small team use
- **JavaScript-based**: Familiar language with good API support
- **Quick iteration**: Changes deploy instantly

### Negative
- **Execution limits**: 6-minute max execution time per run
- **Quota restrictions**: Daily quotas on API calls and execution time
- **Limited libraries**: Cannot install arbitrary npm packages
- **Debugging challenges**: Limited debugging tools compared to traditional IDEs
- **Vendor lock-in**: Tied to Google's platform

### Mitigation
- Design workflow to complete within execution limits
- Implement error handling and retry logic
- Monitor quota usage
- Use external logging (Slack notifications) for visibility

---

# 2. Use ChatGPT for intelligent scheduling

Date: 2026-01-11

## Status

Accepted

## Context

Content scheduling requires understanding context (calendar availability, content guidelines, article topics) and making intelligent decisions about timing and prioritization.

## Decision

We will use ChatGPT API to analyze all scheduling inputs and generate an optimized content schedule.

## Consequences

### Positive
- **Context-aware**: Can understand complex scheduling requirements
- **Flexible**: Adapts to changing prompts and guidelines
- **Natural output**: Provides human-readable scheduling rationale
- **Reduces logic complexity**: Offloads complex decision-making to AI
- **Easy to adjust**: Change behavior by modifying prompts

### Negative
- **API costs**: Pay per token for each scheduling request
- **Latency**: Network calls add execution time
- **Non-deterministic**: May produce different results for same input
- **Rate limits**: Subject to OpenAI API quotas
- **Requires validation**: AI output needs verification

### Mitigation
- Optimize prompts to minimize token usage
- Implement response caching where appropriate
- Add validation logic for ChatGPT responses
- Monitor API costs and usage
- Provide fallback scheduling logic if API fails
