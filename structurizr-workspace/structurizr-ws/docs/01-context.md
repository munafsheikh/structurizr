# Content Scheduling System - Context

## Overview

The Content Scheduling System is a Google Apps Script-based automation platform that intelligently schedules content using ChatGPT AI and integrates with various productivity tools.

## Purpose

Automate the content scheduling workflow by:
1. Gathering prompts from Notion
2. Loading article ideas from a database
3. Analyzing calendar availability
4. Using ChatGPT to create an optimized schedule
5. Updating the calendar automatically
6. Notifying the user via Slack

## Key Components

### Google Apps Script Orchestrator
The central automation engine that coordinates all integrations and manages the scheduling workflow.

### External Integrations
- **Notion**: Source of content prompts and guidelines
- **Article Database**: Repository of article ideas to schedule
- **Google Calendar**: Calendar system for viewing availability and storing schedule
- **ChatGPT API**: AI engine that analyzes context and creates optimal schedule
- **Slack**: Notification system for user updates

## Workflow

1. User triggers the scheduling process
2. System gathers prompts from Notion
3. System loads unscheduled articles from database
4. System retrieves current calendar availability
5. All data is sent to ChatGPT for intelligent scheduling
6. ChatGPT returns an optimized content schedule
7. System updates Google Calendar with scheduled articles
8. System sends Slack notifications to user with schedule details

## Benefits

- **Automated**: Reduces manual scheduling effort
- **Intelligent**: Uses AI to optimize content timing
- **Integrated**: Works seamlessly with existing tools (Notion, Calendar, Slack)
- **Efficient**: Considers calendar availability and content guidelines
- **Transparent**: Provides clear notifications of all changes
