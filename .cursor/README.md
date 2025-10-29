# AI Assistant Configuration for Laundry App

This directory contains the comprehensive AI assistant configuration system for the Laundry App project, supporting development workflows, code generation, task management, and knowledge capture.

## 🎯 Overview

The `.cursor` folder provides:
- **Rules & Guidelines**: Architecture patterns, coding standards, and review checklists
- **Commands**: Automated code generation and workflow commands
- **Task Management**: Track development progress with structured tasks
- **Knowledge Base**: Capture solutions to recurring technical issues
- **Architecture Documentation**: Technical specifications and design principles

---

## 📁 Directory Structure

```
.cursor/
├── README.md                    # This file
├── MIGRATION_COMPLETE.md        # Migration summary from DoorSync
├── rules/                       # AI behavior rules and guidelines
│   ├── core/                   # Foundation rules
│   │   ├── commands.mdc        # Available commands reference
│   │   ├── product-overview.mdc # Laundry App business domain
│   │   ├── tech-overview.mdc   # Technology stack overview
│   │   ├── task-management.mdc # Task workflow rules
│   │   ├── knowledge-base.mdc  # KB management rules
│   │   └── vocabulary.mdc      # Project terminology
│   ├── backend/                # Backend-specific rules
│   │   ├── backend-architecture.mdc
│   │   ├── backend-api-guideline.mdc
│   │   ├── javascript-coding-standards.mdc
│   │   └── backend-review-checklist.mdc
│   ├── frontend/               # Frontend-specific rules
│   │   ├── frontend-architecture.mdc
│   │   ├── react-coding-standards.mdc
│   │   ├── flutter-coding-standards.mdc
│   │   ├── frontend-review-checklist.mdc
│   │   └── user-experience.mdc
│   ├── commands/              # Automated command workflows
│   │   ├── ops/              # Operations commands
│   │   ├── service/          # Backend code generation
│   │   ├── task/             # Task management
│   │   └── web/              # Frontend code generation
│   └── templates/            # Code and documentation templates
│       └── kb-article-template.md
└── ctx-store/                # Context and knowledge storage
    ├── tasks/               # Task tracking
    │   ├── active/         # In-progress tasks
    │   ├── completed/      # Finished tasks
    │   └── archive/        # Deprecated/canceled tasks
    ├── architecture/       # Technical documentation
    │   ├── technical/      # Architecture documents
    │   └── experience/     # UX design principles
    └── kb/                 # Knowledge base articles
        ├── index.md        # KB index (top 5 per category)
        ├── backend/        # Backend solutions
        ├── frontend/       # Frontend solutions
        ├── devops/         # DevOps solutions
        └── general/        # General solutions
```

---

## 🛠️ Technology Stack

### Backend
- **Language**: JavaScript/TypeScript (Node.js 18+)
- **Framework**: Express.js
- **Database**: PostgreSQL 14+ with Prisma ORM
- **Storage**: Amazon S3
- **Deployment**: Docker + Docker Compose/Kubernetes

### Frontend
- **Admin Panel**: React 18 with Material-UI/Ant Design
- **Mobile Apps**: Flutter (Customer App & Delivery Partner App)
- **State Management**: Context API/Redux (React), Provider/Riverpod (Flutter)

### DevOps
- **Containerization**: Docker
- **CI/CD**: GitHub Actions
- **Testing**: Jest (backend), React Testing Library (admin), flutter_test (mobile)

---

## 🚀 Available Commands

### Operations Commands (`ops/`)
- `/command commit` - Commit with conventional commit format
- `/command deploy` - Deploy to Docker environments
- `/command fix` - Auto-fix linting/compilation issues
- `/command validate` - Validate REST APIs
- `/command create-kb` - Create knowledge base article
- `/command search-kb` - Search KB for solutions
- `/command quick-fix` - Apply KB solutions
- `/command cleanup` - Remove service registrations

### Task Commands (`task/`)
- `/command create-task` - Create new task
- `/command list-tasks` - List all tasks
- `/command resume-task` - Resume existing task
- `/command complete-task` - Mark task complete
- `/command update-task-journal` - Update task journal

### Service Commands (`service/`)
- `/command create-controller` - Generate Express.js controller
- `/command create-service` - Generate service class with Prisma
- `/command create-prisma-model` - Generate Prisma schema model

### Web Commands (`web/`)
- `/command create-react-component` - Generate React component

---

## 📚 Rules and Guidelines

### Core Rules (Always Applied)
Located in `rules/core/`, these rules are always active:
- **commands.mdc**: Command system documentation
- **product-overview.mdc**: Business domain overview
- **tech-overview.mdc**: Technology stack details
- **task-management.mdc**: Task lifecycle management
- **knowledge-base.mdc**: KB workflow and principles
- **vocabulary.mdc**: Project-specific terminology

### Backend Rules (Context-Based)
Located in `rules/backend/`, fetch when needed:
- **backend-architecture**: Node.js/Express/Prisma architecture
- **backend-api-guideline**: REST API design standards
- **javascript-coding-standards**: JavaScript/TypeScript conventions
- **backend-review-checklist**: Code review criteria

### Frontend Rules (Context-Based)
Located in `rules/frontend/`, fetch when needed:
- **frontend-architecture**: React/Flutter architecture
- **react-coding-standards**: React best practices
- **flutter-coding-standards**: Flutter/Dart conventions
- **frontend-review-checklist**: Frontend review criteria
- **user-experience**: UX principles and patterns

---

## 📝 Task Management

### Task Structure
Tasks are stored as JSON files in `ctx-store/tasks/`:

```json
{
  "id": "251029-01",
  "title": "Implement order creation API",
  "description": "Create REST endpoint for order creation",
  "status": "In Progress",
  "priority": "High",
  "assignee": "developer",
  "type": "Implementation",
  "component": "Backend",
  "created": "2025-10-29T10:00:00Z",
  "subtasks": [],
  "journal": []
}
```

### Task Lifecycle
1. **Create**: `/command create-task` → Store in `active/`
2. **Work**: Update via `/command update-task-journal`
3. **Complete**: `/command complete-task` → Move to `completed/`
4. **Resume**: `/command resume-task` to continue

---

## 🧠 Knowledge Base

### KB Structure
- **Index**: `ctx-store/kb/index.md` - Top 5 most-used articles per category
- **Categories**: backend, frontend, devops, general
- **Article Format**:
  ```markdown
  ---
  id: KB-YYMMDD-XXX
  category: prisma-transactions
  tags: [prisma, database, concurrency]
  frequency: 1
  created: 2025-10-29T12:00:00Z
  updated: 2025-10-29T12:00:00Z
  ---
  
  # Problem Title
  
  ## Problem
  Brief description (2-3 sentences)
  
  ## Root Cause
  Why it happens (2-3 sentences)
  
  ## Solution
  Step-by-step solution with code examples
  
  ## Related Articles
  Links to related KB articles
  ```

### KB Workflow
1. **Encounter Issue**: Try to solve it
2. **Check KB**: `/command search-kb [keywords]`
3. **Apply Solution**: If found, use it and increment frequency
4. **Create Article**: If solved manually, `/command create-kb`
5. **Update Index**: Top 5 articles auto-updated by frequency

### Example KB Articles
- `KB-251029-001`: Prisma transaction deadlocks in concurrent order creation
- `KB-251029-002`: React infinite re-render loops with useEffect

---

## 🏗️ Architecture Documentation

### Technical Docs (`ctx-store/architecture/technical/`)
- **backend-architecture.md**: Node.js/Express/Prisma architecture
- **frontend-architecture.md**: React admin & Flutter mobile apps

### Experience Docs (`ctx-store/architecture/experience/`)
- **design-principles.md**: UX guidelines for all applications

---

## 🔄 Migration from DoorSync

This configuration was migrated from the DoorSync community management platform (Java/Spring Boot/AWS Lambda/Angular) to the Laundry App (Node.js/Express/PostgreSQL/React/Flutter).

**See [MIGRATION_COMPLETE.md](./MIGRATION_COMPLETE.md) for comprehensive migration details.**

### Migration Status: ✅ 100% COMPLETE

**What's Production-Ready:**
- ✅ All core rules adapted to new stack
- ✅ Backend rules (architecture, API guidelines, coding standards)
- ✅ Frontend rules (React + Flutter standards)
- ✅ Essential commands (ops, task, basic service & web)
- ✅ Task management system
- ✅ Knowledge base with example articles
- ✅ Architecture documentation

**What's Not Included:**
- ❌ Old DDD/Java-specific service commands (deleted)
- ❌ Angular-specific web commands (deleted)
- ❌ AWS Lambda/SAM deployment configs (replaced with Docker)

---

## 🎓 Usage Examples

### Create a New Task
```
/command create-task

AI will prompt for:
- Title: "Implement delivery tracking API"
- Description: "Create endpoints for real-time delivery tracking"
- Priority: "High"
```

### Generate Backend Controller
```
/command create-controller

AI will prompt for:
- Controller name: "delivery"
- Description: "Delivery management endpoints"
```

### Search Knowledge Base
```
/command search-kb prisma transactions

Returns relevant KB articles about Prisma transaction handling
```

### Create Knowledge Base Article
```
/command create-kb

When you encounter a recurring issue:
1. Solve it manually
2. Create KB article with problem, cause, solution
3. Future occurrences can reference the KB
```

---

## 🔑 Best Practices

### For Backend Development
1. Follow layered architecture (controllers → services → Prisma)
2. Use Prisma transactions for multi-step operations
3. Implement proper error handling with custom error classes
4. Write unit tests with Jest for services
5. Document APIs with OpenAPI/Swagger

### For Frontend Development
1. **React**: Use functional components with hooks
2. **Flutter**: Prefer stateless widgets with const constructors
3. Keep components small and focused
4. Use proper state management (Context/Redux for React, Provider for Flutter)
5. Write tests for critical components

### For Task Management
1. Create tasks for complex features (3+ steps)
2. Update journal entries for significant progress
3. Mark tasks complete when all criteria met
4. Resume tasks to maintain context across sessions

### For Knowledge Base
1. Create KB articles for issues solved after multiple attempts
2. Keep articles concise (problem + cause + solution)
3. Include code examples for clarity
4. Tag appropriately for searchability
5. Increment frequency when applying solutions

---

## 📊 Metrics & Monitoring

- **Task Completion Rate**: Track via completed/ directory
- **KB Article Usage**: Monitor via frequency counters
- **Command Usage**: Common commands should be refined
- **Code Quality**: Use review checklists for all PRs

---

## 🤝 Contributing

When adding new rules or commands:
1. Follow existing structure and naming conventions
2. Update this README with new entries
3. Test commands thoroughly before committing
4. Add examples and documentation
5. Update related KB articles if applicable

---

## 🔗 Related Documentation

- **Product Overview**: `.cursor/rules/core/product-overview.mdc`
- **Tech Stack**: `.cursor/rules/core/tech-overview.mdc`
- **Backend Architecture**: `.cursor/ctx-store/architecture/technical/backend-architecture.md`
- **Frontend Architecture**: `.cursor/ctx-store/architecture/technical/frontend-architecture.md`
- **UX Principles**: `.cursor/ctx-store/architecture/experience/design-principles.md`

---

**Last Updated**: October 29, 2025  
**Version**: 2.0 (Laundry App - Fully Migrated)  
**Migration Status**: ✅ COMPLETE
