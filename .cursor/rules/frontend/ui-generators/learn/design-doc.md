# Help Page UI Design Document

## Overview
The Help page provides users with access to support resources, FAQs, and assistance options within the Learn application. It serves as a central hub for users to find answers to common questions and access support when needed.

## Page Location
- **App**: Learn
- **Route**: `/help`
- **Module**: feature-help (already set up)

## UI Components Breakdown

### Layout Structure
- **Page Container**: Keep the container same as Courses Page with responsive padding
- **Content Layout**: Two-column layout on desktop, single column on mobile
  - Left column (2/3 width): Main content area
  - Right column (1/3 width): Support contact information and resources

### Main Components

#### 1. Help Header Section
- **Title**: "Help Center" with h1 styling
- **Subtitle**: Brief description of available help resources
- **Search Bar**: Use existing searchbox component from UI components library with placeholder "Search for help topics"

#### 2. Category Cards Section
- **Section Title**: "Browse by Category"
- **Cards Container**: Responsive grid layout (3 cards per row on desktop, 2 on tablet, 1 on mobile)
- **Category Cards** (6 total):
  - Use existing CourseCard component from UI components library
  - Each card contains:
    - Icon representing the category
    - Category title
    - Brief description
    - "View Topics" link
  - Categories include:
    - Getting Started
    - Courses & Learning Paths
    - Assessments & Quizzes
    - Certificates & Achievements
    - Account Settings
    - Technical Issues

#### 3. Popular Articles Section
- **Section Title**: "Popular Articles"
- **Articles List**: Vertical list of 5-7 most frequently accessed help articles
- **Article Items**:
  - Article title
  - Brief excerpt/description
  - Icon indicating article type
  - "Read More" link

#### 4. FAQ Accordion
- **Section Title**: "Frequently Asked Questions"
- **Accordion Component**: Expandable/collapsible question panels
- **FAQ Items**: 5-8 common questions with expandable answers
- **View All FAQs Link**: Link to comprehensive FAQ page

#### 5. Support Sidebar
- **Contact Card**:
  - "Need More Help?" heading
  - Support hours information
  - Contact options:
    - Email support button/link
    - Live chat button (with availability indicator)
    - Phone support information
- **Resources Card**:
  - "Additional Resources" heading
  - Links to:
    - Video tutorials
    - User guide PDF
    - Community forum
    - Knowledge base

### UI Elements & Styling

#### Colors
- Use primary theme colors from the Learn application
- Background: Light neutral background
- Cards: White with subtle shadow
- Accents: Primary brand color for interactive elements

#### Typography
- Follow the existing typography system from the UI component library
- Heading sizes should follow the established hierarchy
- Body text should use the standard text style

#### Iconography
- Use consistent icons from the application's icon library
- Category icons should be visually distinctive
- Interactive icons should follow the established patterns

#### Responsive Behavior
- Desktop: Two-column layout with 3 category cards per row
- Tablet: Two-column layout with 2 category cards per row
- Mobile: Single column layout with 1 card per row
- Support sidebar moves to bottom of page on mobile

## Component Architecture

### Angular Components

#### Page Component
```typescript
// help-page.component.ts
@Component({
  selector: 'app-help-page',
  templateUrl: './help-page.component.html',
  styleUrls: ['./help-page.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class HelpPageComponent implements OnInit {
  searchQuery = '';
  categories: HelpCategory[] = [];
  popularArticles: HelpArticle[] = [];
  faqs: Faq[] = [];
  
  constructor() {}
  
  ngOnInit(): void {
    // Initialize with mock data
    this.loadMockData();
  }
  
  searchHelp(): void {
    // Implement search functionality with mock data
  }
  
  private loadMockData(): void {
    // Load mock data for categories, articles and FAQs
    this.categories = MOCK_CATEGORIES;
    this.popularArticles = MOCK_ARTICLES;
    this.faqs = MOCK_FAQS;
  }
}
```

#### Child Components
1. Use existing searchbox component from UI components library
2. Use existing CourseCard component from UI components library for category cards
3. **ArticleListItemComponent**: Displays individual article list items
4. **FaqAccordionComponent**: Handles the FAQ accordion
5. **SupportSidebarComponent**: Displays support options and resources

### Models
```typescript
// help.models.ts
export interface HelpCategory {
  id: string;
  title: string;
  description: string;
  iconName: string;
  topicCount: number;
}

export interface HelpArticle {
  id: string;
  title: string;
  excerpt: string;
  type: 'article' | 'video' | 'guide';
  readTime: number;
  viewCount: number;
  categoryId: string;
}

export interface Faq {
  id: string;
  question: string;
  answer: string;
  category: string;
}

// Mock data constants
export const MOCK_CATEGORIES: HelpCategory[] = [
  // Mock category data
];

export const MOCK_ARTICLES: HelpArticle[] = [
  // Mock article data
];

export const MOCK_FAQS: Faq[] = [
  // Mock FAQ data
];
```

## State Management

### NgRx Store Integration
- Create a help feature state in the NgRx store
- Define actions, reducers, and selectors for help data using mock data

```typescript
// help.actions.ts
export const loadCategories = createAction('[Help] Load Categories');
export const loadCategoriesSuccess = createAction(
  '[Help] Load Categories Success',
  props<{ categories: HelpCategory[] }>()
);

// Similar actions for articles, FAQs, and search
```

## Routing Configuration
```typescript
// help-routing.module.ts
const routes: Routes = [
  {
    path: '',
    component: HelpPageComponent,
  },
  {
    path: 'category/:id',
    component: HelpCategoryDetailComponent,
  },
  {
    path: 'article/:id',
    component: HelpArticleDetailComponent,
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class HelpRoutingModule { }
```

## Implementation Plan
1. Develop the main page component and layout
2. Integrate existing searchbox component
3. Implement category cards section using existing CourseCard component
4. Create ArticleListItemComponent
5. Implement FaqAccordionComponent
6. Create SupportSidebarComponent
7. Add responsive styling
8. Perform manual testing of all UI components and structure
9. Upon user confirmation, set up NgRx state management with mock data 