# Reports Page UI Design Document

## 1. Visual Analysis

### 1.1 Overview
The Reports page in the Learn app provides users with the ability to search, filter, and view various reports. It features a filterable data table with pagination, allowing users to manage and access relevant reporting information efficiently.

### 1.2 Layout Structure
- **Main content area**: Full-width container with padding
- **Filter section**: Horizontal bar at the top with multiple filter controls
- **Action bar**: Row between filters and table with view toggle, action dropdown, and search
- **Results section**: Data table displaying filtered records
- **Pagination**: Located at the bottom of the page

### 1.3 Visual Elements
- **Page title**: "Reports" text in large heading typography
- **Filter controls**: Category dropdown, Name dropdown, Date range inputs, and Go button
- **Records counter**: Shows "10 Records Found" text
- **Search input**: Right-aligned search field above the table
- **View controls**: Display options for table view (list/grid)
- **Action dropdown**: Options menu for performing actions on selected entries
- **Data table**: Multi-column table with sortable headers and selectable rows
- **Pagination controls**: Previous/Next buttons with page numbers

### 1.4 Interaction Points
- **Dropdown filters**: Category and Name dropdowns for filtering reports
- **Date range pickers**: From and To date inputs for date-based filtering
- **Go button**: Primary button to apply the selected filters
- **Search field**: Text input for searching within results
- **Records per page**: Dropdown to control pagination size
- **Sort controls**: Column headers with sorting indicators
- **View toggle**: Buttons to switch between list and grid views
- **Action dropdown**: Menu for bulk actions on selected items
- **Checkboxes**: Row selectors for bulk operations
- **Pagination**: Controls to navigate between pages of results

## 2. Component Architecture

### 2.1 Page Component
- **Name**: ReportsPageComponent ----- already inplace
- **Route**: '/reports'          ------ already inplace
- **Responsibilities**: 
  - Main container for the Reports feature
  - Managing route parameters and filter state
  - Handling pagination and search

### 2.2 Container Components
- **Name**: ReportsFilterContainerComponent
- **Responsibilities**: Managing all filter selections and search criteria
- **Data Requirements**: Category list, Report names, Date range
- **Service Dependencies**: ReportsService
- **State Management**: Local component state, emitting filter changes to parent

- **Name**: ReportsActionBarContainerComponent
- **Responsibilities**: Managing view mode, actions, and search functionality
- **Data Requirements**: Selected records, available actions
- **Service Dependencies**: ReportsService
- **State Management**: Local component state for view mode and search criteria

### 2.3 Presentation Components
- **Name**: ReportsFilterComponent
- **Inputs**: 
  - categories: Category[]
  - names: ReportName[]
  - dateRange: {from: Date, to: Date}
- **Outputs**: 
  - filterChange: EventEmitter<FilterCriteria>
- **Rendering Responsibilities**: Renders filter controls
- **Styling Requirements**: Horizontally aligned filter controls with proper spacing

- **Name**: ReportsActionBarComponent
- **Inputs**: 
  - recordsCount: number
  - selectedRecords: any[]
  - actionItems: ActionItem[]
  - viewOptions: ViewOption[]
  - currentView: string
- **Outputs**: 
  - viewChange: EventEmitter<string>
  - actionSelected: EventEmitter<{action: string, items: any[]}>
  - searchChange: EventEmitter<string>
- **Rendering Responsibilities**: Renders action bar with view toggle, actions dropdown, records count, and search
- **Styling Requirements**: Horizontally aligned controls with proper spacing and alignment

### 2.4 Shared Components
- **Name**: GridViewComponent
- **Library Path**: libs/ui-components/data/grid-view
- **Customization**: 
  - Custom column configuration
  - Selection mode enabled
  - Sortable headers
  - Custom cell rendering
  - Integrated pagination controls
  - Records count display

- **Inputs**:
  - data: any[]
  - columns: ColumnConfig[]
  - pagination: PaginationState
  - selectable: boolean
- **Outputs**:
  - pageChange: EventEmitter<number>
  - pageSizeChange: EventEmitter<number>
  - selectionChange: EventEmitter<any[]>
  - sortChange: EventEmitter<SortConfig>

- **Name**: DropdownComponent - do not create, reuse from the sahred lib -libs/ui-components/data
- **Library Path**: libs/ui-components/data
- **Customization**: Styling to match design, with custom placeholder text

- **Name**: DatePickerComponent
- **Library Path**: libs/ui-components/form-controls/date-picker
- **Customization**: Date format matching mm/dd/yyyy

- **Name**: ButtonComponent ---- do not create, reuse from the sahred lib -libs/ui-components/action/button
- **Library Path**: libs/ui-components/button
- **Customization**: Primary button style for "Go" button

- **Name**: SearchInputComponent - do not create, reuse from the sahred lib -libs/ui-components/data/searchbox
- **Library Path**: libs/ui-components/form-controls/search-input
- **Customization**: Right-aligned with search icon

- **Name**: ViewToggleComponent 
- **Library Path**: libs/ui-components/view-toggle - do not create, reuse from the sahred lib -libs/ui-components/data/viewtoggle
- **Customization**: List/grid view icons as per design

- **Name**: ActionMenuComponent
- **Library Path**: libs/ui-components/action/action-menu
- **Customization**: Styling to match design with dropdown menu
