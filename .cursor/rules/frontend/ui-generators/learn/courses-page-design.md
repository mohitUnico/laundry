# Courses Page UI Design Document

## 1. Visual Analysis

### 1.1 Overview
The Courses page serves as the main course discovery interface within the DoorSync Learn application. It provides learners with a comprehensive catalog of available courses, organized into sections with robust filtering, searching, and viewing options. The page emphasizes course discovery and accessibility with clear visual hierarchy and intuitive navigation.

### 1.2 Layout Structure
- **Main Content Area**: 
  - Page header with title "Courses" and descriptive subtitle "Browse and explore courses available to enhance your skills."
  - Primary action button "Create" (blue, positioned top-right)
  - Two distinct course sections:
    - "Available Courses" section
    - "Popular Courses" section
  - Each section contains:
    - Section title
    - Filter and search controls
    - Course grid display (4 columns on desktop)
    - "Load more" pagination button

### 1.3 Visual Elements
- **Color Scheme**: 
  - Primary background: Light/white theme
  - Accent color: Blue (#1976D2 or similar) for interactive elements
  - Text colors: Dark gray/black for headings, medium gray for body text
  - Card backgrounds: White with subtle shadows
- **Typography**:
  - Page title: Large, bold sans-serif font
  - Section headings: Medium-sized, semi-bold font  
  - Course titles: Semi-bold, readable font size
  - Course duration: Regular weight with icon prefix
  - Subtitle: Regular weight, muted color
- **Course Cards**: 
  - Consistent rectangular format with rounded corners
  - High-quality thumbnail images with proper aspect ratio
  - Clean typography hierarchy
  - Duration displayed with clock icon
- **Filter Controls**:
  - Two dropdown selectors: "Select Topic" and "Select Level"
  - Search input field with integrated search icon
  - Consistent styling across all filter elements
- **View Controls**: 
  - Grid/list view toggle buttons with appropriate icons
  - Located in top-right of filter area
- **Interactive Elements**:
  - "Create" button with primary blue styling
  - "Load more" buttons with secondary blue styling
  - Hover states on all clickable elements

### 1.4 Interaction Points
- **Primary Navigation**: Sidebar navigation with "Courses" highlighted as active state
- **Course Discovery**:
  - Topic filter dropdown with selectable options
  - Level filter dropdown with selectable options  
  - Search input box for text-based course discovery
  - View mode toggle (grid/list display options)
- **Course Cards**: Clickable cards that navigate to course detail pages
- **Pagination**: "Load more" buttons for progressive loading of additional courses
- **Content Creation**: "Create" button for course creation (admin/instructor access)
- **Shell Navigation**: 
  - Top navigation bar with app switcher, notifications, settings, user profile
  - Breadcrumb navigation showing: Home > Courses

## 2. Component Architecture

### 2.1 Page Component
- **Name**: CoursesPageComponent
- **Route**: '/courses'
- **Route Configuration**:
  ```typescript
  {
    path: 'courses',
    component: CoursesPageComponent,
    data: { 
      title: 'Courses',
      breadcrumb: 'Courses'
    }
  }
  ```
- **Responsibilities**: 
  - Main container orchestrating the entire courses page
  - Manages page-level state and data loading
  - Handles route parameters and query string management
  - Coordinates between different course sections

### 2.2 Container Components

#### CoursesPageContainerComponent
- **Name**: CoursesPageContainerComponent  
- **Responsibilities**: 
  - Orchestrates data loading for both course sections
  - Manages global filter state
  - Handles view mode preferences
  - Coordinates search functionality across sections
- **Data Requirements**: 
  - Available courses list
  - Popular courses list
  - Filter options (topics, levels)
  - User preferences (view mode)
- **Service Dependencies**: 
  - CourseService
  - FilterService  
  - UserPreferencesService
- **State Management**: 
  - Uses CoursesFacade for NgRx state management
  - Manages loading states and error handling

#### AvailableCoursesContainerComponent
- **Name**: AvailableCoursesContainerComponent
- **Responsibilities**: 
  - Manages "Available Courses" section data and state
  - Handles section-specific filtering
  - Manages pagination for available courses
- **Data Requirements**: 
  - Filtered available courses
  - Pagination metadata
  - Loading states
- **Service Dependencies**: CourseService
- **State Management**: Connects to availableCourses$ stream from facade

#### PopularCoursesContainerComponent  
- **Name**: PopularCoursesContainerComponent
- **Responsibilities**: 
  - Manages "Popular Courses" section data and state
  - Handles popularity-based course ranking
  - Manages pagination for popular courses
- **Data Requirements**: 
  - Popular courses list
  - Popularity metrics
  - Pagination metadata
- **Service Dependencies**: CourseService, AnalyticsService
- **State Management**: Connects to popularCourses$ stream from facade

### 2.3 Presentation Components

#### CourseFiltersComponent
- **Name**: CourseFiltersComponent
- **Inputs**: 
  ```typescript
  @Input() topics: Topic[];
  @Input() levels: Level[];
  @Input() selectedTopic: string | null;
  @Input() selectedLevel: string | null;
  @Input() searchQuery: string;
  @Input() viewMode: 'grid' | 'list';
  ```
- **Outputs**: 
  ```typescript
  @Output() topicChange = new EventEmitter<string>();
  @Output() levelChange = new EventEmitter<string>();  
  @Output() searchChange = new EventEmitter<string>();
  @Output() viewModeChange = new EventEmitter<'grid' | 'list'>();
  ```
- **Rendering Responsibilities**: 
  - Renders filter dropdown controls
  - Renders search input with icon
  - Renders view mode toggle buttons
- **Styling Requirements**: 
  - Consistent spacing between filter elements
  - Proper alignment and responsive behavior
  - Focus states for accessibility

#### CourseGridComponent
- **Name**: CourseGridComponent  
- **Inputs**: 
  ```typescript
  @Input() courses: Course[];
  @Input() viewMode: 'grid' | 'list' = 'grid';
  @Input() loading: boolean = false;
  @Input() hasMore: boolean = false;
  ```
- **Outputs**: 
  ```typescript
  @Output() courseSelected = new EventEmitter<Course>();
  @Output() loadMore = new EventEmitter<void>();
  ```
- **Rendering Responsibilities**: 
  - Renders responsive grid/list of course cards
  - Handles empty states and loading indicators
  - Renders "Load more" button when applicable
- **Styling Requirements**: 
  - Responsive grid layout (4 cols desktop, 2-3 tablet, 1 mobile)
  - Consistent spacing between cards
  - Smooth transitions between view modes

#### CourseCardComponent
- **Name**: CourseCardComponent
- **Inputs**: 
  ```typescript
  @Input() course: Course;
  @Input() viewMode: 'grid' | 'list' = 'grid';
  ```
- **Outputs**: 
  ```typescript
  @Output() courseClick = new EventEmitter<Course>();
  ```
- **Rendering Responsibilities**: 
  - Renders course thumbnail with proper aspect ratio
  - Displays course title, duration with clock icon
  - Handles hover and focus states
- **Styling Requirements**: 
  - Consistent card styling with shadows
  - Proper image loading and fallback states
  - Accessible contrast ratios

#### CourseSectionComponent
- **Name**: CourseSectionComponent
- **Inputs**: 
  ```typescript
  @Input() title: string;
  @Input() courses: Course[];
  @Input() loading: boolean = false;
  @Input() hasMore: boolean = false;
  @Input() viewMode: 'grid' | 'list' = 'grid';
  ```
- **Outputs**: 
  ```typescript
  @Output() courseSelected = new EventEmitter<Course>();
  @Output() loadMore = new EventEmitter<void>();
  ```
- **Rendering Responsibilities**: 
  - Renders section title
  - Embeds CourseGridComponent
  - Manages section-specific loading states
- **Styling Requirements**: 
  - Consistent section spacing and typography
  - Clear visual separation between sections

### 2.4 Shared Components

#### DropdownComponent
- **Name**: DropdownComponent
- **Library Path**: `libs/ui-components/src/lib/dropdown`
- **Customization**: 
  - Custom placeholder text ("Select Topic", "Select Level")
  - Consistent styling with filter design
  - Proper accessibility attributes

#### SearchBoxComponent  
- **Name**: SearchBoxComponent
- **Library Path**: `libs/ui-components/src/lib/search-box`
- **Customization**: 
  - Integrated search icon
  - Placeholder text: "Search"
  - Debounced input handling

#### ButtonComponent
- **Name**: ButtonComponent  
- **Library Path**: `libs/ui-components/src/lib/button`
- **Customization**: 
  - Primary variant for "Create" button
  - Secondary variant for "Load more" buttons
  - Proper loading states

#### ViewToggleComponent
- **Name**: ViewToggleComponent
- **Library Path**: `libs/ui-components/src/lib/view-toggle`  
- **Customization**: 
  - Grid and list view icons
  - Toggle button group styling
  - Active state indication

#### LoadingSpinnerComponent
- **Name**: LoadingSpinnerComponent
- **Library Path**: `libs/ui-components/src/lib/loading-spinner`
- **Customization**: None, standard loading indicator

## 3. Data Models

```typescript
interface Course {
  id: string;
  title: string;
  description?: string;
  thumbnailUrl: string;
  duration: number; // in minutes
  level: CourseLevel;
  topic: CourseTopic;
  popularity?: number;
  enrollmentCount?: number;
  rating?: number;
  instructor?: string;
  createdAt: Date;
  updatedAt: Date;
  isEnrolled?: boolean;
  progress?: number; // 0-100 percentage
}

interface CourseTopic {
  id: string;
  name: string;
  description?: string;
  color?: string;
}

interface CourseLevel {
  id: string;
  name: string;
  description?: string;
  order: number;
}

interface CourseFilter {
  topicId?: string;
  levelId?: string;
  searchQuery?: string;
  sortBy?: 'title' | 'duration' | 'popularity' | 'created';
  sortOrder?: 'asc' | 'desc';
}

interface CoursesPageState {
  availableCourses: Course[];
  popularCourses: Course[];
  topics: CourseTopic[];
  levels: CourseLevel[];
  filters: CourseFilter;
  viewMode: 'grid' | 'list';
  loading: {
    availableCourses: boolean;
    popularCourses: boolean;
    topics: boolean;
    levels: boolean;
  };
  pagination: {
    availableCourses: PaginationState;
    popularCourses: PaginationState;
  };
  error?: string;
}

interface PaginationState {
  currentPage: number;
  pageSize: number;
  totalItems: number;
  hasMore: boolean;
}
```

## 4. State Management

### 4.1 NgRx Store Structure
```typescript
// courses.state.ts
export interface CoursesState {
  courses: EntityState<Course>;
  topics: CourseTopic[];
  levels: CourseLevel[];
  filters: CourseFilter;
  viewMode: 'grid' | 'list';
  loading: LoadingState;
  pagination: PaginationState;
  error: string | null;
}

// courses.actions.ts
export const CoursesActions = createActionGroup({
  source: 'Courses',
  events: {
    'Load Available Courses': props<{ filters?: CourseFilter; page?: number }>(),
    'Load Available Courses Success': props<{ courses: Course[]; pagination: PaginationState }>(),
    'Load Available Courses Failure': props<{ error: string }>(),
    
    'Load Popular Courses': props<{ page?: number }>(),
    'Load Popular Courses Success': props<{ courses: Course[]; pagination: PaginationState }>(),
    'Load Popular Courses Failure': props<{ error: string }>(),
    
    'Load Filter Options': emptyProps(),
    'Load Filter Options Success': props<{ topics: CourseTopic[]; levels: CourseLevel[] }>(),
    'Load Filter Options Failure': props<{ error: string }>(),
    
    'Update Filters': props<{ filters: Partial<CourseFilter> }>(),
    'Update View Mode': props<{ viewMode: 'grid' | 'list' }>(),
    'Clear Filters': emptyProps(),
    
    'Select Course': props<{ course: Course }>(),
  }
});
```

### 4.2 Facade Pattern
```typescript
@Injectable()
export class CoursesFacade {
  // Selectors
  availableCourses$ = this.store.select(selectAvailableCourses);
  popularCourses$ = this.store.select(selectPopularCourses);
  topics$ = this.store.select(selectTopics);
  levels$ = this.store.select(selectLevels);
  filters$ = this.store.select(selectFilters);
  viewMode$ = this.store.select(selectViewMode);
  loading$ = this.store.select(selectLoading);
  pagination$ = this.store.select(selectPagination);
  
  constructor(private store: Store) {}
  
  // Actions
  loadAvailableCourses(filters?: CourseFilter, page?: number) {
    this.store.dispatch(CoursesActions.loadAvailableCourses({ filters, page }));
  }
  
  loadPopularCourses(page?: number) {
    this.store.dispatch(CoursesActions.loadPopularCourses({ page }));
  }
  
  updateFilters(filters: Partial<CourseFilter>) {
    this.store.dispatch(CoursesActions.updateFilters({ filters }));
  }
  
  updateViewMode(viewMode: 'grid' | 'list') {
    this.store.dispatch(CoursesActions.updateViewMode({ viewMode }));
  }
  
  selectCourse(course: Course) {
    this.store.dispatch(CoursesActions.selectCourse({ course }));
  }
}
```

## 5. Routing Configuration

```typescript
// courses-routing.module.ts
const routes: Routes = [
  {
    path: '',
    component: CoursesPageComponent,
    data: {
      title: 'Courses',
      breadcrumb: 'Courses'
    },
    children: [
      {
        path: '',
        redirectTo: 'browse',
        pathMatch: 'full'
      },
      {
        path: 'browse',
        component: CoursesBrowseComponent,
        data: {
          breadcrumb: 'Browse'
        }
      },
      {
        path: 'search',
        component: CoursesSearchComponent,
        data: {
          breadcrumb: 'Search Results'
        }
      }
    ]
  }
];
```

## 6. Responsive Design Considerations

### 6.1 Breakpoint Strategy
- **Desktop (≥1200px)**: 4-column grid layout with full filter controls
- **Tablet (768px - 1199px)**: 2-3 column grid with condensed filters
- **Mobile (≤767px)**: Single column with collapsible filters

### 6.2 Component Adaptations
- **Filter Controls**: 
  - Desktop: Horizontal layout with dropdowns and search
  - Mobile: Collapsible filter panel with full-width controls
- **Course Cards**: 
  - Desktop: Fixed aspect ratio with hover effects
  - Mobile: Full-width cards with touch-optimized interactions
- **View Toggle**: 
  - Desktop: Always visible toggle buttons
  - Mobile: Hidden, defaults to list view for better mobile experience

## 7. Accessibility Considerations

### 7.1 ARIA Implementation
- **Course Cards**: `role="button"`, `aria-label` with course details
- **Filter Controls**: Proper labeling and `aria-describedby` for instructions
- **Loading States**: `aria-live="polite"` for status updates
- **Pagination**: `aria-label` for "Load more" buttons with context

### 7.2 Keyboard Navigation
- **Tab Order**: Logical flow through filters, view toggle, and course cards
- **Focus Management**: Clear focus indicators and focus trapping in modals
- **Shortcuts**: Consider keyboard shortcuts for common actions (search focus, view toggle)

### 7.3 Screen Reader Support
- **Semantic HTML**: Proper heading hierarchy and landmark roles
- **Alternative Text**: Descriptive alt text for course thumbnails
- **Status Updates**: Announce filter changes and loading states

## 8. Performance Considerations

### 8.1 Optimization Strategies
- **Virtual Scrolling**: For large course lists (consider CDK Virtual Scrolling)
- **Image Lazy Loading**: Implement lazy loading for course thumbnails
- **OnPush Change Detection**: Use OnPush strategy for all presentation components
- **Pagination**: Server-side pagination with "Load more" functionality

### 8.2 Caching Strategy
- **Course Data**: Cache course lists with appropriate TTL
- **Filter Options**: Cache topics and levels as they change infrequently
- **User Preferences**: Persist view mode and filter preferences locally

## 9. Implementation Guidelines

### 9.1 Component File Structure
```
src/app/feature-modules/courses/
├── pages/
│   └── courses-page/
│       ├── courses-page.component.ts
│       ├── courses-page.component.html
│       ├── courses-page.component.scss
│       └── courses-page.component.spec.ts
├── containers/
│   ├── courses-page-container/
│   ├── available-courses-container/
│   └── popular-courses-container/
├── components/
│   ├── course-filters/
│   ├── course-grid/
│   ├── course-card/
│   └── course-section/
├── services/
│   └── courses.service.ts
├── state/
│   ├── courses.actions.ts
│   ├── courses.reducer.ts
│   ├── courses.selectors.ts
│   ├── courses.effects.ts
│   └── courses.facade.ts
└── courses.module.ts
```

### 9.2 Development Priorities
1. **Phase 1**: Basic page structure and course display
2. **Phase 2**: Filter and search functionality
3. **Phase 3**: View mode toggle and responsive design
4. **Phase 4**: Performance optimization and accessibility enhancements
5. **Phase 5**: Advanced features (sorting, advanced filters)

### 9.3 Testing Strategy
- **Unit Tests**: All components, services, and state management
- **Integration Tests**: Component interactions and data flow
- **E2E Tests**: Complete user workflows (search, filter, course selection)
- **Accessibility Tests**: Automated and manual accessibility testing

// ... existing code ... 