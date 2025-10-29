# Create Course Form UI Design Document

## 1. Visual Analysis

### 1.1 Overview
The Create Course form is a comprehensive course creation interface within the DoorSync Learn application. It allows instructors and administrators to create new courses by providing essential metadata including title, authors, description, topic, language, learning mode, level, pricing, and tags. The form features a clean, organized layout with logical grouping of related fields and an image upload area for course thumbnails.

### 1.2 Layout Structure
- **Main Content Area**: 
  - Page header with title "Create Course" 
  - Subtitle text "(All field are required unless specified optional)"
  - Form layout in two-column structure:
    - **Left Column (60% width)**: Form fields and controls
    - **Right Column (40% width)**: Image upload area
  - Form fields organized in logical sections:
    - Basic Information: Title, Author tags
    - Content Details: Description textarea
    - Categorization: Topic dropdown, Language dropdown
    - Learning Configuration: Learning Mode dropdown, Level dropdown
    - Pricing: Free/Paid radio buttons
    - Metadata: Tags with removable chips
    - Author Attribution: "Include Author Name" checkbox
  - Action buttons at bottom: "Create & Continue" (primary), "Cancel" (secondary)

### 1.3 Visual Elements
- **Color Scheme**: 
  - Primary background: Clean white/light theme
  - Accent color: Blue (#2563EB or similar) for primary actions and links
  - Form elements: Light gray borders with blue focus states
  - Text colors: Dark gray/black for labels, medium gray for placeholders
  - Tag chips: Light blue background with removable 'x' icons
- **Typography**:
  - Page title: Large, bold sans-serif font
  - Form labels: Medium-sized, semi-bold font
  - Field text: Regular weight, readable font size
  - Helper text: Smaller, muted color
  - Placeholder text: Light gray color
- **Form Elements**: 
  - Clean input fields with subtle borders and rounded corners
  - Dropdown selectors with arrow indicators
  - Multi-line textarea for description
  - Radio button groups with clear labeling
  - Tag input with removable chips
  - Checkbox with accompanying label
- **Image Upload Area**:
  - Large dashed border rectangle with upload icon
  - "Click to upload or drag and drop" text with blue link styling
  - Format specification: "Image Format: PNG, jpg, jpeg (max 2mb)"
- **Interactive Elements**:
  - Primary blue "Create & Continue" button
  - Secondary "Cancel" button
  - Hover states on all clickable elements
  - Focus indicators for accessibility

### 1.4 Interaction Points
- **Form Fields**:
  - Text input for course title
  - Author tag input with add/remove functionality
  - Multi-line textarea for course description
  - Dropdown selectors for Topic, Language, Learning Mode, Level
  - Radio button selection for Free/Paid pricing
  - Tag input field with chip creation and removal
  - Checkbox for author name inclusion
- **Image Upload**:
  - Click to browse files or drag-and-drop functionality
  - File format and size validation
  - Preview capability for uploaded images
- **Form Actions**:
  - "Create & Continue" button for form submission and navigation
  - "Cancel" button to abort course creation
- **Form Validation**:
  - Real-time validation for required fields
  - File format and size validation for image upload
  - Error state display for invalid inputs

## 2. Component Architecture

### 2.1 Page Component
- **Name**: CreateCoursePageComponent
- **Route**: '/courses/create'
- **Route Configuration**:
  ```typescript
  {
    path: 'courses/create',
    component: CreateCoursePageComponent,
    canActivate: [AuthGuard, InstructorGuard],
    data: { 
      title: 'Create Course',
      breadcrumb: 'Create Course'
    }
  }
  ```
- **Responsibilities**: 
  - Main container for the course creation workflow
  - Manages form state and validation
  - Handles form submission and navigation
  - Coordinates between form and upload components

### 2.2 Container Components

#### CreateCourseFormContainerComponent
- **Name**: CreateCourseFormContainerComponent  
- **Responsibilities**: 
  - Orchestrates course creation form logic
  - Manages form state and validation
  - Handles form submission and API calls
  - Manages reference data loading (topics, languages, levels)
- **Data Requirements**: 
  - Course creation form data
  - Reference data (topics, languages, learning modes, levels)
  - Form validation state
  - Loading and error states
- **Service Dependencies**: 
  - CourseService
  - ReferenceDataService
  - FileUploadService
- **State Management**: 
  - Uses CreateCourseFacade for NgRx state management
  - Manages form submission states and error handling

### 2.3 Presentation Components

#### CreateCourseFormComponent
- **Name**: CreateCourseFormComponent
- **Inputs**: 
  ```typescript
  @Input() initialData: CreateCourseFormData | null;
  @Input() topics: Topic[];
  @Input() languages: Language[];
  @Input() learningModes: LearningMode[];
  @Input() levels: Level[];
  @Input() loading: boolean;
  @Input() errors: FormErrors | null;
  ```
- **Outputs**: 
  ```typescript
  @Output() formSubmit = new EventEmitter<CreateCourseFormData>();
  @Output() formCancel = new EventEmitter<void>();
  @Output() imageUpload = new EventEmitter<File>();
  ```
- **Rendering Responsibilities**: 
  - Renders the complete course creation form
  - Handles form validation and error display
  - Manages reactive form controls and validation
- **Styling Requirements**: 
  - Two-column responsive layout
  - Consistent field spacing and alignment
  - Proper form validation styling

#### AuthorTagInputComponent
- **Name**: AuthorTagInputComponent  
- **Inputs**: 
  ```typescript
  @Input() authors: string[];
  @Input() placeholder: string = 'Add author';
  @Input() maxAuthors: number = 10;
  ```
- **Outputs**: 
  ```typescript
  @Output() authorsChange = new EventEmitter<string[]>();
  ```
- **Rendering Responsibilities**: 
  - Renders author input field with tag chips
  - Handles adding and removing author tags
  - Validates author input and prevents duplicates
- **Styling Requirements**: 
  - Clean tag chip design with remove buttons
  - Responsive wrapping of tag chips
  - Focus states for accessibility

#### TagInputComponent
- **Name**: TagInputComponent
- **Inputs**: 
  ```typescript
  @Input() tags: string[];
  @Input() placeholder: string = 'Add tag';
  @Input() maxTags: number = 10;
  @Input() suggestions: string[] = [];
  ```
- **Outputs**: 
  ```typescript
  @Output() tagsChange = new EventEmitter<string[]>();
  ```
- **Rendering Responsibilities**: 
  - Renders tag input field with removable chips
  - Provides tag suggestions and autocomplete
  - Handles tag creation and removal
- **Styling Requirements**: 
  - Consistent chip styling with the author tags
  - Autocomplete dropdown styling
  - Proper spacing and alignment

#### ImageUploadComponent
- **Name**: ImageUploadComponent
- **Inputs**: 
  ```typescript
  @Input() acceptedFormats: string[] = ['image/png', 'image/jpeg', 'image/jpg'];
  @Input() maxFileSize: number = 2 * 1024 * 1024; // 2MB
  @Input() previewUrl: string | null;
  ```
- **Outputs**: 
  ```typescript
  @Output() fileSelected = new EventEmitter<File>();
  @Output() fileRemoved = new EventEmitter<void>();
  ```
- **Rendering Responsibilities**: 
  - Renders file upload area with drag-and-drop
  - Displays file format and size requirements
  - Shows image preview when file is selected
  - Handles file validation and error display
- **Styling Requirements**: 
  - Dashed border upload area styling
  - Upload icon and instruction text
  - Preview image styling with remove option
  - Error state styling for invalid files

### 2.4 Shared Components

#### SelectDropdownComponent
- **Name**: SelectDropdownComponent
- **Library Path**: `libs/ui-components/src/lib/form-controls/select-dropdown`
- **Customization**: 
  - Used for Topic, Language, Learning Mode, and Level dropdowns
  - Custom styling to match form design
  - Placeholder text support

#### TextInputComponent
- **Name**: TextInputComponent
- **Library Path**: `libs/ui-components/src/lib/form-controls/text-input`
- **Customization**: 
  - Used for Title input field
  - Support for validation states and error messages

#### TextareaComponent
- **Name**: TextareaComponent
- **Library Path**: `libs/ui-components/src/lib/form-controls/textarea`
- **Customization**: 
  - Used for Description field
  - Auto-resize functionality
  - Character count display (optional)

#### RadioGroupComponent
- **Name**: RadioGroupComponent
- **Library Path**: `libs/ui-components/src/lib/form-controls/radio-group`
- **Customization**: 
  - Used for Free/Paid selection
  - Horizontal layout configuration

#### CheckboxComponent
- **Name**: CheckboxComponent
- **Library Path**: `libs/ui-components/src/lib/form-controls/checkbox`
- **Customization**: 
  - Used for "Include Author Name" option
  - Custom label styling

#### ButtonComponent
- **Name**: ButtonComponent
- **Library Path**: `libs/ui-components/src/lib/buttons/button`
- **Customization**: 
  - Primary variant for "Create & Continue"
  - Secondary variant for "Cancel"
  - Loading state support

## 3. Form Model and Validation

### 3.1 Form Data Interface
```typescript
interface CreateCourseFormData {
  title: string;
  authors: string[];
  description: string;
  topic: string;
  language: string;
  learningMode: string;
  level: string;
  pricing: 'free' | 'paid';
  tags: string[];
  includeAuthorName: boolean;
  courseImage?: File;
}
```

### 3.2 Validation Rules
- **Title**: Required, min 3 characters, max 100 characters
- **Authors**: Required, at least 1 author, max 10 authors
- **Description**: Required, min 10 characters, max 1000 characters
- **Topic**: Required, must be valid topic ID
- **Language**: Required, must be valid language code
- **Learning Mode**: Required, must be valid mode
- **Level**: Required, must be valid level
- **Tags**: Optional, max 10 tags, each tag max 30 characters
- **Course Image**: Optional, PNG/JPG/JPEG only, max 2MB

### 3.3 Error Handling
- Field-level validation with immediate feedback
- Form-level validation on submission
- API error handling with user-friendly messages
- File upload error handling with specific error types

## 4. Responsive Design Considerations

### 4.1 Desktop (1200px+)
- Two-column layout with form on left, image upload on right
- Full-width form fields with proper spacing
- Side-by-side action buttons

### 4.2 Tablet (768px - 1199px)
- Single column layout with image upload below form
- Maintained field widths with responsive spacing
- Stacked action buttons

### 4.3 Mobile (< 768px)
- Full-width single column layout
- Compact field spacing
- Full-width action buttons
- Simplified tag input interaction

## 5. Accessibility Requirements

### 5.1 Form Accessibility
- Proper form labels and ARIA attributes
- Keyboard navigation support
- Screen reader compatibility
- High contrast mode support

### 5.2 File Upload Accessibility
- Keyboard accessible file selection
- Alternative text for upload icons
- Clear error message announcements
- Progress indication for uploads

### 5.3 Interactive Elements
- Focus indicators for all interactive elements
- Proper color contrast ratios
- Support for screen readers
- Keyboard shortcuts for common actions 