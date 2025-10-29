# Course Player Video Page UI Design Document

## 1. Visual Analysis

### 1.1 Overview
The Course Player Video page provides learners with an immersive video learning experience within the DoorSync platform's Learn application. The page features a two-panel layout with a collapsible course structure sidebar on the left and a main video player area on the right, optimized for focused learning.

### 1.2 Layout Structure
- **Left Sidebar (Course Structure Panel)**:
  - Collapsible sidebar with course progress indicator at top (70% Completed)
  - Hierarchical course structure with numbered sections
  - Expandable/collapsible course modules
  - Individual lesson items with icons (video, document, etc.)
  - Duration indicators for each lesson
  - Progress indicators for completed items
  - Collapse/expand toggle button

- **Main Content Area (Video Player)**:
  - Full-width video player with dark background
  - Video controls overlay at bottom
  - Video title display ("Cold Little Heart")
  - Progress bar with current time and total duration (47:38 / 1:52:32)
  - Standard video controls (play/pause, previous, next, volume, settings, fullscreen)
  - AI-themed video content with neural network visualization

### 1.3 Visual Elements
- **Color Scheme**: 
  - Light sidebar with white background
  - Dark video player area with black background
  - Blue accent colors for progress indicators and active states
  - Gray text for secondary information
- **Typography**:
  - Course title: Medium-sized, bold font
  - Section headings: Semi-bold font with numbering
  - Lesson titles: Regular font weight
  - Duration text: Small, gray font
  - Video title: White text overlay on dark background
- **Icons**:
  - Video play icon for video lessons
  - Document icon for text-based content
  - Collapse/expand arrows for sections
  - Standard video control icons
- **Progress Indicators**:
  - Overall course progress bar at top
  - Individual lesson completion checkmarks
  - Video progress bar

### 1.4 Interaction Points
- **Sidebar Toggle**: Collapse/expand button to hide/show course structure
- **Course Navigation**: Clickable lesson items to navigate between content
- **Section Expansion**: Expandable course sections to show/hide lessons
- **Video Controls**: Standard video player controls (play, pause, seek, volume, fullscreen)
- **Progress Tracking**: Automatic progress updates as video plays
- **Lesson Selection**: Click on any lesson to jump to that content

## 2. Component Architecture

### 2.1 Page Component
- **Name**: CoursePlayerVideoPageComponent
- **Route**: '/courses/:courseId/player'
- **Responsibilities**: 
  - Main container for the course player interface
  - Manages course data loading and video playback
  - Handles sidebar toggle state
  - Coordinates between course structure and video player

### 2.2 Container Components

- **Name**: CoursePlayerContainerComponent
- **Responsibilities**: Manages the overall course player state and data
- **Data Requirements**: Course structure, current lesson, progress data, video URLs
- **Service Dependencies**: CourseService, ProgressService, VideoService
- **State Management**: Uses NgRx facade to manage course player state, video playback state, and progress tracking

- **Name**: CourseStructureSidebarContainerComponent
- **Responsibilities**: Manages the course structure sidebar and navigation
- **Data Requirements**: Course modules, lessons, progress data, current lesson
- **Service Dependencies**: CourseService, ProgressService
- **State Management**: Uses NgRx facade to manage course structure and navigation state

- **Name**: VideoPlayerContainerComponent
- **Responsibilities**: Manages video playback, controls, and progress tracking
- **Data Requirements**: Video URL, current time, duration, playback settings
- **Service Dependencies**: VideoService, ProgressService
- **State Management**: Uses NgRx facade to manage video player state and progress

### 2.3 Presentation Components

- **Name**: CourseStructureSidebarComponent
- **Inputs**: 
  - courseStructure: CourseModule[]
  - currentLesson: Lesson
  - overallProgress: number
  - isCollapsed: boolean
- **Outputs**: 
  - lessonSelected: EventEmitter<Lesson>
  - sidebarToggled: EventEmitter<boolean>
  - sectionToggled: EventEmitter<string>
- **Rendering Responsibilities**: Renders the collapsible sidebar with course structure
- **Styling Requirements**: Fixed width sidebar with smooth collapse animation

- **Name**: CourseModuleComponent
- **Inputs**: 
  - module: CourseModule
  - isExpanded: boolean
  - currentLesson: Lesson
- **Outputs**: 
  - lessonSelected: EventEmitter<Lesson>
  - moduleToggled: EventEmitter<string>
- **Rendering Responsibilities**: Renders a course module with expandable lesson list
- **Styling Requirements**: Hierarchical indentation and expansion animations

- **Name**: LessonItemComponent
- **Inputs**: 
  - lesson: Lesson
  - isActive: boolean
  - isCompleted: boolean
- **Outputs**: 
  - lessonSelected: EventEmitter<Lesson>
- **Rendering Responsibilities**: Renders individual lesson item with icon, title, duration, and status
- **Styling Requirements**: Hover states, active states, and completion indicators

- **Name**: VideoPlayerComponent
- **Inputs**: 
  - videoUrl: string
  - currentTime: number
  - duration: number
  - isPlaying: boolean
  - volume: number
  - title: string
- **Outputs**: 
  - timeUpdate: EventEmitter<number>
  - playStateChanged: EventEmitter<boolean>
  - volumeChanged: EventEmitter<number>
  - seekTo: EventEmitter<number>
  - fullscreenToggled: EventEmitter<boolean>
- **Rendering Responsibilities**: Renders video player with custom controls overlay
- **Styling Requirements**: Full-width responsive video player with custom control styling

- **Name**: VideoControlsComponent
- **Inputs**: 
  - currentTime: number
  - duration: number
  - isPlaying: boolean
  - volume: number
  - title: string
- **Outputs**: 
  - playPause: EventEmitter<void>
  - seekTo: EventEmitter<number>
  - volumeChanged: EventEmitter<number>
  - previousVideo: EventEmitter<void>
  - nextVideo: EventEmitter<void>
  - fullscreen: EventEmitter<void>
- **Rendering Responsibilities**: Renders video control overlay with progress bar and buttons
- **Styling Requirements**: Semi-transparent overlay with smooth fade animations

- **Name**: ProgressBarComponent
- **Inputs**: 
  - progress: number
  - total: number
  - showTime: boolean
- **Outputs**: 
  - progressChanged: EventEmitter<number>
- **Rendering Responsibilities**: Renders progress bar with time display
- **Styling Requirements**: Interactive progress bar with hover and drag states

### 2.4 Shared Components

- **Name**: Button
- **Library Path**: libs/ui-components/src/lib/button
- **Customization**: Icon buttons for video controls and sidebar toggle

- **Name**: Icon
- **Library Path**: libs/ui-components/src/lib/icon
- **Customization**: Video control icons (play, pause, volume, fullscreen, etc.)

- **Name**: ProgressBar
- **Library Path**: libs/ui-components/src/lib/progress-bar
- **Customization**: Course progress indicator and video progress bar

- **Name**: Tooltip
- **Library Path**: libs/ui-components/src/lib/tooltip
- **Customization**: Tooltips for video controls and lesson information

- **Name**: Accordion
- **Library Path**: libs/ui-components/src/lib/accordion
- **Customization**: Course module expansion/collapse functionality

## 3. Data Models

```typescript
interface Course {
  id: string;
  title: string;
  description: string;
  modules: CourseModule[];
  totalDuration: number;
  progress: number;
}

interface CourseModule {
  id: string;
  title: string;
  order: number;
  lessons: Lesson[];
  isExpanded: boolean;
}

interface Lesson {
  id: string;
  title: string;
  type: 'video' | 'document' | 'quiz' | 'assignment';
  duration: number;
  videoUrl?: string;
  isCompleted: boolean;
  order: number;
}

interface VideoPlayerState {
  currentTime: number;
  duration: number;
  isPlaying: boolean;
  volume: number;
  isFullscreen: boolean;
  playbackRate: number;
}

interface CourseProgress {
  courseId: string;
  currentLessonId: string;
  completedLessons: string[];
  overallProgress: number;
  lastAccessedAt: Date;
}
```

## 4. State Management

### 4.1 Course Player State
- Current course data
- Current lesson and video
- Sidebar collapse state
- Course structure expansion states

### 4.2 Video Player State
- Video playback state (playing, paused, ended)
- Current time and duration
- Volume and playback rate
- Fullscreen state

### 4.3 Progress State
- Overall course progress
- Individual lesson completion status
- Time spent on each lesson
- Bookmark positions

## 5. Responsive Design Considerations

- **Desktop**: Full two-panel layout with sidebar and video player
- **Tablet**: Collapsible sidebar that overlays video player when expanded
- **Mobile**: 
  - Sidebar becomes a bottom sheet or modal overlay
  - Video player takes full width
  - Controls optimized for touch interaction
  - Course structure accessible via floating action button

## 6. Accessibility Considerations

- Video player must support keyboard navigation
- Screen reader compatibility for course structure
- Closed captions support for videos
- High contrast mode support
- Focus management for modal overlays
- ARIA labels for all interactive elements
- Keyboard shortcuts for video controls

## 7. Performance Considerations

- Lazy loading of video content
- Efficient video streaming with adaptive bitrate
- Optimized course structure rendering
- Progress auto-save with debouncing
- Video preloading for smooth navigation
- Memory management for video player instances

## 8. User Experience Features

- Auto-resume from last watched position
- Automatic progress tracking
- Smooth transitions between lessons
- Keyboard shortcuts for common actions
- Picture-in-picture mode support
- Playback speed controls
- Video quality selection
- Bookmark and note-taking capabilities 