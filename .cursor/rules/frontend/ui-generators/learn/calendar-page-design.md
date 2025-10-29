# Calendar UI Design Document

## 1. Visual Analysis

### 1.1 Overview
The Calendar feature in the Learn app provides users with a time-based view of scheduled events, classes, and deadlines. It offers multiple view options (day, week, work week, month, agenda) and allows users to create and manage calendar events.

### 1.2 Layout Structure
- **Main Content Area**: Displays a time-grid calendar view with hours of the day (1:00 PM to 9:00 PM visible in the design)
- **Top Navigation Bar**: Contains breadcrumb navigation, date selector, and view type options
- **Calendar Header**: Shows the current date and day (Tuesday, 20) at the top of the time grid
- **Time Slots**: Vertical layout of hourly time slots with event positioning
- **Modal Dialog**: "New Event" modal appears centered on screen when creating a new event

### 1.3 Visual Elements
- **Color Scheme**: 
  - Primary app color for active elements and highlights
  - Light gray backgrounds for the calendar grid
  - Pink/purple line indicators for current time or selected periods
- **Typography**:
  - Regular sans-serif font for most text elements
  - Varied font weights to indicate hierarchy (bold for headers, regular for content)
- **Calendar Grid**:
  - Horizontal lines separate hourly time slots
  - Vertical lines separate days in multi-day views
- **Event Indicators**:
  - Colored blocks or bars represent scheduled events
  - Shaded areas might indicate busy or blocked times

### 1.4 Interaction Points
- **Date Navigation**: Previous/next buttons (< >) for moving between time periods
- **Date Selector**: Dropdown to select specific dates
- **View Type Buttons**: TODAY, DAY, WEEK, WORK WEEK, MONTH, AGENDA options
- **Time Grid**: Clickable to create new events at specific times
- **New Event Modal**:
  - Title field (required)
  - Location field
  - Start date/time selector with calendar and clock pickers
  - End date/time selector with calendar and clock pickers
  - "All day" checkbox
  - "Timezone" checkbox
  - Repeat dropdown (set to "Never" in the design)
  - Description text area
  - SAVE and CANCEL buttons

## 2. Component Architecture

### 2.1 Page Component
- **Name**: CalendarHomeComponent
- **Route**: '/calendar'
- **Responsibilities**: 
  - Main container for the calendar feature
  - Manages the overall calendar state
  - Handles view type switching
  - Coordinates date navigation
  - Manages event creation/editing modal visibility

### 2.2 Container Components

- **Name**: CalendarViewContainerComponent
- **Responsibilities**: 
  - Manages the active calendar view (day, week, work week, month, agenda)
  - Handles view switching logic
  - Controls date navigation
- **Data Requirements**: 
  - Current view type
  - Selected date range
  - Calendar events for the visible period
- **Service Dependencies**: 
  - CalendarService (for fetching events)
  - DateUtilsService (for date manipulation)
- **State Management**: 
  - Local state for view preferences
  - NgRx store for event data

- **Name**: EventFormContainerComponent
- **Responsibilities**: 
  - Manages the event creation/editing form
  - Handles form validation and submission
  - Processes date/time inputs
- **Data Requirements**: 
  - Event model (for editing existing events)
  - Available locations (optional)
  - User timezone settings
- **Service Dependencies**: 
  - EventService (for saving events)
  - ValidationService (for form validation)
- **State Management**: 
  - Reactive form state
  - NgRx actions for creating/updating events

### 2.3 Presentation Components

- **Name**: CalendarDayViewComponent
- **Inputs**: 
  - selectedDate: Date
  - events: CalendarEvent[]
  - dayStartHour: number
  - dayEndHour: number
- **Outputs**: 
  - timeSlotClicked: EventEmitter<{time: Date}>
  - eventClicked: EventEmitter<{event: CalendarEvent}>
- **Rendering Responsibilities**: 
  - Renders a single day view with hourly time slots
  - Displays events at the correct times
  - Shows current time indicator
- **Styling Requirements**: 
  - Hourly grid layout
  - Event positioning based on start/end times
  - Responsive time slot heights

- **Name**: CalendarWeekViewComponent
- **Inputs**: 
  - weekStartDate: Date
  - events: CalendarEvent[]
  - includeWeekend: boolean
- **Outputs**: 
  - dayClicked: EventEmitter<{date: Date}>
  - eventClicked: EventEmitter<{event: CalendarEvent}>
- **Rendering Responsibilities**: 
  - Renders a 7-day (or 5-day for work week) grid
  - Shows events across multiple days
- **Styling Requirements**: 
  - Day column layout
  - Proper event spanning across days

- **Name**: CalendarMonthViewComponent
- **Inputs**: 
  - monthDate: Date
  - events: CalendarEvent[]
- **Outputs**: 
  - dayClicked: EventEmitter<{date: Date}>
  - eventClicked: EventEmitter<{event: CalendarEvent}>
- **Rendering Responsibilities**: 
  - Renders a month grid with dates
  - Shows event indicators for days with events
- **Styling Requirements**: 
  - Month grid layout
  - Event count or preview indicators

- **Name**: CalendarAgendaViewComponent
- **Inputs**: 
  - startDate: Date
  - endDate: Date
  - events: CalendarEvent[]
- **Outputs**: 
  - eventClicked: EventEmitter<{event: CalendarEvent}>
- **Rendering Responsibilities**: 
  - Renders a list view of upcoming events
  - Groups events by date
- **Styling Requirements**: 
  - List layout with date separators
  - Event detail presentation

- **Name**: EventFormComponent
- **Inputs**: 
  - eventModel: CalendarEvent (optional)
  - defaultDate: Date
  - defaultDuration: number (in minutes)
- **Outputs**: 
  - save: EventEmitter<CalendarEvent>
  - cancel: EventEmitter<void>
- **Rendering Responsibilities**: 
  - Renders the event creation/editing form
  - Displays date/time pickers
  - Shows form fields for title, location, description
  - Provides repeat options
- **Styling Requirements**: 
  - Modal form layout
  - Field validation styles
  - Responsive form layout

### 2.4 Shared Components

- **Name**: DatePickerComponent
- **Library Path**: libs/ui-components/src/lib/components/data/date-picker
- **Customization**: Configure to show both date and time selectors

- **Name**: ButtonComponent
- **Library Path**: libs/ui-components/src/lib/components/action/button
- **Customization**: Use primary style for SAVE, secondary for CANCEL

- **Name**: CheckboxComponent
- **Library Path**: libs/ui-components/src/lib/components/data/checkbox
- **Customization**: Standard implementation

- **Name**: TextFieldComponent
- **Library Path**: libs/ui-components/src/lib/components/data/text-field
- **Customization**: Standard implementation

- **Name**: TextAreaComponent
- **Library Path**: libs/ui-components/src/lib/components/data/text-area
- **Customization**: Standard implementation

- **Name**: DropdownSelectComponent
- **Library Path**: libs/ui-components/src/lib/components/data/dropdown-select
- **Customization**: Configure with repeat options

- **Name**: ModalComponent
- **Library Path**: libs/ui-components/src/lib/components/containers/modal
- **Customization**: Standard implementation with appropriate sizing 