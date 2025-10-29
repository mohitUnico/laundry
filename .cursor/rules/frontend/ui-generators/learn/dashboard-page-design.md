# Learn Dashboard UI Design Document

## 1. Visual Analysis

### 1.1 Overview
The Learn Dashboard serves as the main landing page for users in the learning module. It provides a comprehensive overview of the user's learning journey, displaying their course progress, pending tasks, active courses, and personalized recommendations. The dashboard also includes achievement tracking with badges, a leaderboard for competitive motivation, and upcoming scheduled events.

### 1.2 Layout Structure
The dashboard follows a responsive grid layout with multiple card-based sections:
- Top notification alert (system-wide)
- Welcome section with user greeting
- Learning summary section with course statistics in a 4-column grid
- Tasks section with card-based list of pending assessments
- My Learning section with card-based course progress items
- Recommended courses section with card-based items
- Right sidebar containing:
  - Earned badges display
  - Leaderboard with ranking
  - Upcoming events list
  - Additional learning resources

### 1.3 Visual Elements
- **Color Scheme**: Primary blue for navigation, accents of green (completion indicators), yellow/orange (warnings), and purple/gold (achievement badges)
- **Typography**: Hierarchical text styles with varying weights for headers, subheaders, and body text
- **Cards**: Consistently styled card components with subtle shadows and rounded corners
- **Icons**: Circular progress indicators, clock icons for time tracking, and badge/achievement icons
- **Status Indicators**: Color-coded status indicators (green for completed, orange for overdue)
- **Progress Visualization**: Circular progress indicators for course completion status
- **Badges**: Achievement badges displayed as colorful circular icons

### 1.4 Interaction Points
- **Navigation**: Main navigation menu with "Learn" as active section
- **Notification Alert**: Dismissable system notification at the top
- **Course Cards**: Clickable course cards with play/resume/restart buttons
- **View All Links**: Expandable section links for tasks, courses, and events
- **Tab Navigation**: Leaderboard tab selection between "My Rank" and "Top 5"
- **Resource Links**: External learning resource links (Coursera, Pluralsight, Udemy)

## 2. Component Architecture

### 2.1 Page Component
- **Name**: LearnDashboardComponent
- **Route**: '/learn/dashboard'
- **Responsibilities**: 
  - Aggregate and coordinate all dashboard sections
  - Load user profile and learning data
  - Handle page-level user interactions

### 2.2 Container Components

- **Name**: LearningStatusContainerComponent
- **Responsibilities**: Manage and display learning progress statistics
- **Data Requirements**: Course counts by status (overdue, not started, in progress, completed)
- **Service Dependencies**: CourseService, UserProgressService
- **State Management**: Fetch and maintain course statistics state

- **Name**: TasksContainerComponent
- **Responsibilities**: Manage and display pending tasks/assessments
- **Data Requirements**: List of upcoming and pending assessments with due dates
- **Service Dependencies**: AssessmentService, TaskService
- **State Management**: Fetch and maintain tasks list with pagination if needed

- **Name**: ActiveCoursesContainerComponent
- **Responsibilities**: Manage and display active learning courses
- **Data Requirements**: User's active courses with progress information
- **Service Dependencies**: CourseService, UserProgressService
- **State Management**: Fetch and maintain active courses with progress data

- **Name**: RecommendedCoursesContainerComponent
- **Responsibilities**: Manage and display recommended courses
- **Data Requirements**: Personalized course recommendations
- **Service Dependencies**: CourseRecommendationService
- **State Management**: Fetch and maintain recommended courses

- **Name**: LeaderboardContainerComponent
- **Responsibilities**: Manage and display leaderboard data
- **Data Requirements**: User ranking data and top performers
- **Service Dependencies**: LeaderboardService
- **State Management**: Fetch and maintain leaderboard data with tab selection state

- **Name**: BadgesContainerComponent
- **Responsibilities**: Manage and display earned badges
- **Data Requirements**: User's achievement badges
- **Service Dependencies**: BadgeService, UserAchievementService
- **State Management**: Fetch and maintain badge data

- **Name**: EventsContainerComponent
- **Responsibilities**: Manage and display upcoming events
- **Data Requirements**: Scheduled learning events and sessions
- **Service Dependencies**: EventService, CalendarService
- **State Management**: Fetch and maintain upcoming events data

- **Name**: ResourcesContainerComponent
- **Responsibilities**: Manage and display additional learning resources
- **Data Requirements**: List of external learning platforms
- **Service Dependencies**: ResourceService
- **State Management**: Fetch and maintain resource links

### 2.3 Presentation Components

- **Name**: WelcomeCardComponent
- **Inputs**: userName
- **Outputs**: None
- **Rendering Responsibilities**: Display personalized welcome message with user avatar
- **Styling Requirements**: Card with user avatar, welcoming text styling

- **Name**: StatusCardComponent
- **Inputs**: count, label, icon, statusType
- **Outputs**: cardClick
- **Rendering Responsibilities**: Display a course status card with count and label
- **Styling Requirements**: Status-specific styling (overdue, not started, in progress, completed)

- **Name**: TaskItemComponent
- **Inputs**: taskTitle, dueDate, daysAgo
- **Outputs**: taskClick
- **Rendering Responsibilities**: Display a task item with title and due date
- **Styling Requirements**: Task card with deadline indicator

- **Name**: CourseCardComponent
- **Inputs**: courseTitle, courseImage, duration, dueDate, progress, status
- **Outputs**: playClick, restartClick, continueClick
- **Rendering Responsibilities**: Display a course card with progress and action buttons
- **Styling Requirements**: Media card with course image, progress indicator, and action buttons

- **Name**: BadgeDisplayComponent
- **Inputs**: badges (array of badge objects)
- **Outputs**: badgeClick
- **Rendering Responsibilities**: Display earned badges in a grid
- **Styling Requirements**: Badge icons with hover effects

- **Name**: LeaderboardItemComponent
- **Inputs**: userName, userAvatar, points, rank
- **Outputs**: None
- **Rendering Responsibilities**: Display a leaderboard entry with user info and rank
- **Styling Requirements**: Leaderboard row with avatar, name, points, and rank position

- **Name**: EventItemComponent
- **Inputs**: eventDate, eventTitle, eventType
- **Outputs**: eventClick
- **Rendering Responsibilities**: Display upcoming event with date and title
- **Styling Requirements**: Event list item with date indicator

- **Name**: ResourceLinkComponent
- **Inputs**: resourceName, resourceIcon
- **Outputs**: resourceClick
- **Rendering Responsibilities**: Display external resource link with icon
- **Styling Requirements**: Resource button with icon and name

### 2.4 Shared Components

- **Name**: CardComponent
- **Library Path**: libs/ui-components/src/lib/card  -We already have course card in ui-components. create only others.
- **Customization**: Apply different styles based on card purpose (status, task, course)

- **Name**: ProgressIndicatorComponent
- **Library Path**: libs/ui-components/src/lib/progress
- **Customization**: Circular progress indicator with customizable colors

- **Name**: TabsComponent
- **Library Path**: libs/ui-components/src/lib/tabs
- **Customization**: Used for leaderboard tab navigation

- **Name**: MediaCardComponent
- **Library Path**: libs/ui-components/src/lib/media-card
- **Customization**: Used for course cards with media preview

- **Name**: AvatarComponent
- **Library Path**: libs/ui-components/src/lib/avatar
- **Customization**: Used for user avatars in welcome section and leaderboard

- **Name**: BadgeComponent
- **Library Path**: libs/ui-components/src/lib/badge
- **Customization**: Used for achievement badges display

- **Name**: AlertComponent
- **Library Path**: libs/ui-components/src/lib/alert
- **Customization**: Used for the system notification banner

- **Name**: ButtonComponent
- **Library Path**: libs/ui-components/src/lib/button - Already have in UI-Components
- **Customization**: Various button styles for different actions (play, view all, etc.)

- **Name**: DateDisplayComponent
- **Library Path**: libs/ui-components/src/lib/date-display
- **Customization**: Used for showing due dates and event dates 