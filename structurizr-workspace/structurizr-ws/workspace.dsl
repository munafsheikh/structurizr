workspace {
    !identifiers hierarchical

    name "Content Scheduling System"
    description "Google App Script system for automated content scheduling using ChatGPT"

    !docs docs
    !adrs adrs

    model {
        # People
        user = person "Content Creator" "User who manages content schedule and receives notifications"

        # Main Software System
        contentSchedulingSystem = softwareSystem "Content Scheduling System" "Automates content scheduling using AI and calendar integration" {
            !docs docs
            !adrs adrs

            # Main Container - Google App Script
            appScript = container "App Script Orchestrator" "Coordinates content scheduling workflow" "Google Apps Script" {
                tags "AppScript"

                notionChecker = component "Notion Checker" "Retrieves prompt updates from Notion" "Apps Script Module"
                articleLoader = component "Article Loader" "Loads new article ideas from database" "Apps Script Module"
                calendarRetriever = component "Calendar Retriever" "Fetches calendar entries from Google Calendar" "Apps Script Module"
                chatgptClient = component "ChatGPT Client" "Sends data to ChatGPT and receives schedule" "Apps Script Module"
                calendarUpdater = component "Calendar Updater" "Updates Google Calendar with new schedule" "Apps Script Module"
                notificationSender = component "Notification Sender" "Sends Slack notifications to user" "Apps Script Module"
            }
        }

        # External Systems
        notion = softwareSystem "Notion" "Knowledge management and collaboration platform" {
            tags "External"
        }

        articleDatabase = softwareSystem "Article Database" "Storage for article ideas and content" {
            tags "External"
        }

        googleCalendar = softwareSystem "Google Calendar" "Calendar system for scheduling" {
            tags "External"
        }

        chatgpt = softwareSystem "ChatGPT API" "OpenAI's ChatGPT for intelligent scheduling" {
            tags "External" "AI"
        }

        slack = softwareSystem "Slack" "Team communication platform" {
            tags "External"
        }

        # User Relationships
        user -> contentSchedulingSystem "Uses to automate content scheduling" "HTTPS"
        user -> notion "Manages prompts in" "HTTPS"
        user -> slack "Receives notifications via" "HTTPS"

        # System to External System Relationships
        contentSchedulingSystem -> notion "Retrieves prompt updates from" "Notion API/HTTPS"
        contentSchedulingSystem -> articleDatabase "Loads article ideas from" "HTTPS/API"
        contentSchedulingSystem -> googleCalendar "Retrieves and updates calendar entries" "Google Calendar API/HTTPS"
        contentSchedulingSystem -> chatgpt "Sends scheduling requests to" "OpenAI API/HTTPS"
        contentSchedulingSystem -> slack "Sends notifications via" "Slack API/HTTPS"

        chatgpt -> contentSchedulingSystem "Returns scheduled content to" "HTTPS/JSON"

        # Component Relationships (workflow)
        user -> contentSchedulingSystem.appScript "Triggers scheduling workflow" "HTTPS"

        contentSchedulingSystem.appScript.notionChecker -> notion "Fetches prompt updates" "Notion API/HTTPS"
        contentSchedulingSystem.appScript.articleLoader -> articleDatabase "Retrieves article ideas" "HTTPS/REST API"
        contentSchedulingSystem.appScript.calendarRetriever -> googleCalendar "Fetches calendar entries" "Google Calendar API/HTTPS"

        contentSchedulingSystem.appScript.chatgptClient -> contentSchedulingSystem.appScript.notionChecker "Gets prompts from" "Internal Call"
        contentSchedulingSystem.appScript.chatgptClient -> contentSchedulingSystem.appScript.articleLoader "Gets article ideas from" "Internal Call"
        contentSchedulingSystem.appScript.chatgptClient -> contentSchedulingSystem.appScript.calendarRetriever "Gets calendar data from" "Internal Call"
        contentSchedulingSystem.appScript.chatgptClient -> chatgpt "Sends scheduling request with context" "OpenAI API/HTTPS"

        contentSchedulingSystem.appScript.calendarUpdater -> contentSchedulingSystem.appScript.chatgptClient "Receives schedule from" "Internal Call"
        contentSchedulingSystem.appScript.calendarUpdater -> googleCalendar "Updates with scheduled articles" "Google Calendar API/HTTPS"

        contentSchedulingSystem.appScript.notificationSender -> contentSchedulingSystem.appScript.chatgptClient "Gets schedule details from" "Internal Call"
        contentSchedulingSystem.appScript.notificationSender -> slack "Sends schedule notifications" "Slack Webhook/HTTPS"
        contentSchedulingSystem.appScript.notificationSender -> user "Notifies via Slack" "Slack"
    }

    views {
        # System Landscape View
        systemLandscape "SystemLandscape" "Content scheduling system landscape showing all systems and actors" {
            include *
            autolayout lr
        }

        # System Context View
        systemContext contentSchedulingSystem "SystemContext" "System context for the Content Scheduling System" {
            include *
            autolayout lr
        }

        # Container View
        container contentSchedulingSystem "Containers" "Container diagram showing the App Script orchestrator" {
            include *
            autolayout lr
        }

        # Component View
        component contentSchedulingSystem.appScript "Components" "Component diagram showing App Script modules and workflow" {
            include *
            autolayout tb
        }

        # Dynamic View - Scheduling Workflow
        dynamic contentSchedulingSystem "SchedulingWorkflow" "Content scheduling workflow from trigger to notification" {
            user -> contentSchedulingSystem.appScript "Triggers content scheduling"
            contentSchedulingSystem.appScript -> notion "1. Check for prompt updates"
            notion -> contentSchedulingSystem.appScript "Returns prompts"
            contentSchedulingSystem.appScript -> articleDatabase "2. Load article ideas"
            articleDatabase -> contentSchedulingSystem.appScript "Returns articles"
            contentSchedulingSystem.appScript -> googleCalendar "3. Retrieve calendar entries"
            googleCalendar -> contentSchedulingSystem.appScript "Returns calendar data"
            contentSchedulingSystem.appScript -> chatgpt "4. Send scheduling request (prompts + articles + calendar)"
            chatgpt -> contentSchedulingSystem.appScript "5. Returns optimized schedule"
            contentSchedulingSystem.appScript -> googleCalendar "6. Update calendar with schedule"
            contentSchedulingSystem.appScript -> slack "7. Send schedule notifications"
            slack -> user "8. Notifies user of updates"
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

            element "AI" {
                background #10a37f
                color #ffffff
            }

            element "Container" {
                background #438dd5
                color #ffffff
            }

            element "AppScript" {
                shape WebBrowser
                background #4285f4
                color #ffffff
            }

            element "Component" {
                background #85bbf0
                color #000000
            }

            relationship "Relationship" {
                routing Curved
            }
        }

        # Themes
        theme default
    }

    configuration {
        scope softwaresystem

        properties {
            "structurizr.editable" "true"
        }
    }

}
