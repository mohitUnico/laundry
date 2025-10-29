# Course Detail Page UI Design Document

## 1. Visual Analysis

### 1.1 Overview
The course detail page displays comprehensive information about a specific course including course metadata, instructor details, learning modules, and enrollment options. The layout follows a two-column structure with the main content area on the left and sidebar on the right.

### 1.2 Layout Structure
**Main Content Area (Left Column)**:
- Course header section with title, description, language info, and category tags
- Course statistics (level, experience, duration, schedule type)
- Course modules accordion with expandable sections showing module content

**Sidebar (Right Column)**:
- Course banner image
- Instructor profile card
- Points and certification information
- Enrollment button

### 1.3 Visual Elements
**Typography**:
- Course title: Large, bold heading
- Course description: Regular body text with comfortable line spacing
- Module titles: Medium weight headings
- Meta information: Smaller, muted text

**Colors**:
- Category tags: Outlined buttons with rounded corners
- Course stats: Icon + text combinations
- Modules: White background with subtle borders and shadows
- Enrollment button: Primary blue color

**Spacing**:
- Generous whitespace between sections
- Consistent padding within cards and modules
- Clear visual hierarchy

### 1.4 Interaction Points
- Category tag buttons (clickable for filtering)
- Module accordion expansion/collapse
- Enroll button with loading states
- Module content items (expandable details)

## 2. Component Architecture

### 2.1 Page Component
- **Name**: CourseDetailPageComponent
- **Route**: `/courses/:id`
- **Responsibilities**: Route parameter handling and container composition

### 2.2 Container Components

#### CourseDetailContainerComponent
- **Responsibilities**: Data fetching, state management, business logic coordination
- **Data Requirements**: Course data, enrollment status, user permissions
- **Service Dependencies**: CourseService, EnrollmentService
- **State Management**: Local component state with BehaviorSubjects

### 2.3 Presentation Components

#### CourseHeaderComponent
- **Inputs**: courseTitle, courseDescription, language, categoryTags
- **Outputs**: categorySelected
- **Rendering Responsibilities**: Course title, description, language info, clickable category tags
- **Styling Requirements**: Typography hierarchy, tag button styling

#### CourseStatsComponent
- **Inputs**: level, experience, duration, scheduleType
- **Outputs**: None
- **Rendering Responsibilities**: Display course metadata with icons
- **Styling Requirements**: Icon-text pairs, responsive layout

#### CourseModulesContainerComponent
- **Inputs**: modules
- **Outputs**: moduleSelected, contentItemSelected
- **Rendering Responsibilities**: Accordion-style module display
- **Styling Requirements**: Expandable sections, content item lists

#### InstructorCardComponent
- **Inputs**: instructor
- **Outputs**: None
- **Rendering Responsibilities**: Instructor photo, name, and role
- **Styling Requirements**: Card layout, circular avatar

#### CourseRewardsComponent
- **Inputs**: points, hasCompletionCertificate
- **Outputs**: None
- **Rendering Responsibilities**: Points and certification info
- **Styling Requirements**: Icon + text display

#### EnrollButtonComponent
- **Inputs**: isEnrolled, isProcessing
- **Outputs**: enroll
- **Rendering Responsibilities**: Context-aware enrollment button
- **Styling Requirements**: Primary button styling, loading states

### 2.4 Shared Components
- **Card Component**: For instructor card and rewards section
- **Button Component**: For enrollment and category tag buttons
- **Icon Component**: For stats and rewards sections
- **Accordion Component**: For course modules expansion

## 3. Implementation Requirements

### 3.1 Responsive Design
- Two-column layout on desktop
- Single column stack on mobile with sidebar content moved to top
- Responsive spacing and typography scaling

### 3.2 Accessibility
- Proper ARIA labels for expandable content
- Keyboard navigation support
- Screen reader friendly content structure
- Focus management for interactive elements

### 3.3 Performance Considerations
- OnPush change detection strategy
- Lazy loading for module content
- Optimized image loading for course banner and instructor photo

### 3.4 State Management
- Local state for UI interactions (module expansion)
- Observable patterns for async data
- Loading states for enrollment actions 