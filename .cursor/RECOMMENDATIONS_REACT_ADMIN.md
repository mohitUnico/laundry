# React + TypeScript Admin Panel Rules - Required Changes

## Priority 1: Critical Fixes

### 1. Environment Variables (Vite)
**File**: `.cursor/rules/frontend/frontend-architecture.mdc`
**Line**: ~384

**Change From**:
```typescript
baseURL: process.env.REACT_APP_API_BASE_URL,
```

**Change To**:
```typescript
baseURL: import.meta.env.VITE_API_BASE_URL,
```

**Also Update**: All environment variable references throughout frontend rules to use `import.meta.env.VITE_*` instead of `process.env.REACT_APP_*`

---

### 2. Testing Framework Standardization
**Files**: 
- `.cursor/rules/frontend/react-coding-standards.mdc` (lines 895, 903, 912)
- `.cursor/rules/core/tech-overview.mdc` (line 116)

**Change**: Replace Jest references with Vitest for Vite projects

**In react-coding-standards.mdc**:
```typescript
// Change from:
import { render, screen, fireEvent } from '@testing-library/react';
import { OrderCard } from './OrderCard';

// Change to:
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { OrderCard } from './OrderCard';

// Change jest.fn() to vi.fn()
const handleViewDetails = vi.fn();
```

**In tech-overview.mdc**:
Change "Testing: Jest, React Testing Library" to "Testing: Vitest, React Testing Library"

---

### 3. Remove DoorSync File
**File**: `.cursor/rules/frontend/user-experience.mdc`

**Action**: Delete this file OR mark as not applicable since it's DoorSync-specific, not Laundry App

---

### 4. Separate React-Only Rules
**Files**: 
- `.cursor/rules/frontend/frontend-architecture.mdc`
- `.cursor/rules/frontend/frontend-review-checklist.mdc`

**Action**: Add a clear section separator or note that Flutter sections don't apply to React admin panel. Consider creating React-specific versions of these files.

---

## Priority 2: Important Additions

### 5. Add TypeScript Configuration Section
**File**: `.cursor/rules/frontend/react-coding-standards.mdc`

**Add after "TypeScript Best Practices" section**:

```markdown
## TypeScript Configuration

### Required tsconfig.json Settings

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLib醸k": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": "src",
    "paths": {
      "@/*": ["*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

### Path Aliases Setup

**Vite Config (vite.config.ts)**:
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export引用 default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

**Usage**:
```typescript
// Instead of: import { Button } from '../../../components/common/Button';
// Use: import { Button } from '@/components/common/Button';
```

---

### 6. Add Vite-Specific Patterns
**File**: `.cursor/rules/frontend/frontend-architecture.mdc`

**Add new section after "Technology Stack"**:

```markdown
## Vite Build Tool Configuration

### Environment Variables
- Prefix all public env vars with `VITE_`
- Use `import.meta.env.VITE_*` to access in code
- Type-safe env vars: Create `src/env.d.ts`:

```typescript
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string;
  readonly VITE_APP_TITLE: string;
  // Add other env vars here
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

### Asset Handling
- Static assets in `public/` are served as-is
- Imported assets in `src/` are processed and hashed
- Use `?url` suffix for asset URLs: `import logoUrl from './logo.svg?url'`
- Use `?raw` for raw text: `import sql from './query.sql?raw'`

### Build Optimization
- Code splitting is automatic with dynamic imports
- CSS is automatically extracted and minified
- Images are optimized during build
- Tree-shaking removes unused code
```

---

### 7. Add ESLint/Prettier Standards
**File**: `.cursor/rules/frontend/react-coding-standards.mdc`

**Add new section**:

```markdown
## Code Quality Tools

### ESLint Configuration

Required plugins:
```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react-hooks/recommended",
    "plugin:react/recommended",
    "plugin:jsx-a11y/recommended"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "react/react-in-jsx-scope": "off", // Not needed in React 17+
    "react/prop-types": "off" // Using TypeScript instead
  }
}
```

### Prettier Configuration

```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false
}
```

---

### 8. Add React 18 Patterns
**File**: `.cursor/rules/frontend/react-coding-standards.mdc`

**Add after "Custom Hooks" section**:

```markdown
## React 18 Features

### useTransition for Non-Urgent Updates

```tsx
import { useTransition } from 'react';

const [isPending, startTransition] = useTransition();

const handleSearch = (value: string) => {
  startTransition(() => {
    setSearchQuery(value); // Non-urgent update
  });
};
```

### useDeferredValue for Deferring Expensive Values

```tsx
import { useDeferredValue } from 'react';

const deferredQuery = useDeferredValue(searchQuery);

// Use deferredQuery for expensive operations
const results = useMemo(() => 
  expensiveFilter(deferredQuery), 
  [deferredQuery]
);
```

### Automatic Batching
React 18 automatically batches all state updates, even in promises and timeouts.
```

---

### 9. Add Import/Export Conventions
**File**: `.cursor/rules/frontend/react-coding-standards.mdc`

**Add new section**:

```markdown
## Import and Export Conventions

### Use Named Exports for Components
```typescript
// ✅ Good: Named export
export const OrderCard: React.FC<OrderCardProps> = ({ ... }) => { ... };

// ❌ Avoid: Default export (harder to refactor)
export default OrderCard;
```

### Barrel Exports (index.ts)
```typescript
// components/common/index.ts
export { Button } from './Button';
export { Input } from './Input';
export { Modal } from './Modal';

// Usage
import { Button, Input, Modal } from '@/components/common';
```

### Import Order
1. React and external libraries
2. Internal utilities and hooks
3. Types and interfaces
4. Components
5. Styles

```typescript
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

import { formatDate } from '@/utils/date.utils';
import { useOrders } from '@/hooks/useOrders';

import type { Order } from '@/types/order.types';

import { OrderCard } from '@/components/features/orders/OrderCard';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';

import styles from './OrdersPage.module.css';
```
```

---

### 10. Update Component Generator Import Example
**File**: `.cursor/rules/commands/web/create-react-component.mdc`

**Update finalize section import example**:

```typescript
// ✅ Preferred: Use path alias
import { ${componentName} } from '@/components/${componentType}/${componentType === 'feature' ? featureModule + '/' : ''}${componentName}';
```

Remove the relative import alternative to enforce consistency.

---

## Summary Checklist

- [ ] Update `frontend-architecture.mdc` - Change env vars to Vite syntax
- [ ] Update `react-coding-standards.mdc` - Change Jest to Vitest, add sections 5-9
- [ ] Delete or disable `user-experience.mdc` 
- [ ] Update `tech-overview.mdc` - Change testing to Vitest
- [ ] Update `create-react-component.mdc` - Standardize imports
- [ ] Add clear React-only sections in frontend-architecture and review-checklist

---

## Files Modified (for reference)
1. `.cursor/rules/frontend/frontend-architecture.mdc`
2. `.cursor/rules/frontend/react-coding-standards.mdc`
3. `.cursor/rules/frontend/frontend-review-checklist.mdc`
4. `.cursor/rules/core/tech-overview.mdc`
5. `.cursor/rules/commands/web/create-react-component.mdc`
6. `.cursor/rules/frontend/user-experience.mdc` (delete/disable)

