# Laundry App Frontend Architecture

## Overview

Laundry App frontend consists of three applications:
1. **Admin Panel** - React-based web application for mart administration
2. **Customer App** - Flutter mobile app for customers to place orders
3. **Delivery Partner App** - Flutter mobile app for delivery staff

---

## 1. Admin Panel (React)

### Technology Stack

| Component              | Technology/Tool                     |
| ---------------------- | ----------------------------------- |
| Framework              | React 18                            |
| Language               | JavaScript/TypeScript               |
| UI Library             | Material-UI (MUI) or Ant Design     |
| State Management       | Context API / Redux Toolkit/Zustand |
| Routing                | React Router v6                     |
| HTTP Client            | Axios                               |
| Forms                  | React Hook Form / Formik            |
| Data Visualization     | Chart.js / Recharts                 |
| Date Handling          | date-fns / Day.js                   |
| Build Tool             | Vite or Create React App            |
| CSS Solution           | CSS Modules / Styled Components     |
| Testing                | Jest + React Testing Library        |

### Project Structure
```
admin-panel/
├── public/
│   ├── index.html
│   └── assets/
├── src/
│   ├── components/
│   │   ├── common/        # Generic UI components
│   │   ├── layout/        # Layout components
│   │   └── features/      # Feature-specific components
│   ├── pages/             # Page-level components
│   │   ├── Dashboard/
│   │   ├── Orders/
│   │   ├── Customers/
│   │   ├── Delivery/
│   │   ├── Services/
│   │   └── Reports/
│   ├── hooks/             # Custom React hooks
│   ├── services/          # API client services
│   ├── store/             # State management
│   ├── utils/             # Utility functions
│   ├── types/             # TypeScript types
│   ├── constants/         # Constants
│   ├── routes/            # Route configuration
│   ├── assets/            # Static assets
│   ├── styles/            # Global styles
│   ├── App.tsx
│   └── index.tsx
├── package.json
└── tsconfig.json
```

### Component Architecture

#### Smart/Container Components (Pages)
- Located in `pages/` directory
- Manage state and data fetching
- Handle business logic
- Coordinate multiple dumb components
- Connect to API services and state management

**Example:**
```tsx
// pages/Orders/OrdersListPage.tsx
export const OrdersListPage: React.FC = () => {
  const { orders, loading, error, fetchOrders } = useOrders();
  
  useEffect(() => {
    fetchOrders({ status: 'in_process' });
  }, []);

  return (
    <div>
      <OrdersFilters onFilterChange={handleFilter} />
      <OrdersList orders={orders} loading={loading} />
    </div>
  );
};
```

#### Dumb/Presentational Components
- Located in `components/` directory
- Receive data via props
- Emit events via callbacks
- No business logic
- Reusable across features

**Example:**
```tsx
// components/features/orders/OrderCard.tsx
interface OrderCardProps {
  order: Order;
  onViewDetails: (id: string) => void;
}

export const OrderCard: React.FC<OrderCardProps> = ({ order, onViewDetails }) => {
  return (
    <Card>
      <h3>{order.orderId}</h3>
      <Button onClick={() => onViewDetails(order.orderId)}>View</Button>
    </Card>
  );
};
```

### State Management Patterns

#### Option 1: Context API (Simple State)
```tsx
// store/context/AuthContext.tsx
export const AuthProvider: React.FC = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  
  const login = async (email, password) => {
    const user = await authService.login(email, password);
    setUser(user);
  };

  return (
    <AuthContext.Provider value={{ user, login }}>
      {children}
    </AuthContext.Provider>
  );
};
```

#### Option 2: Redux Toolkit (Complex State)
```typescript
// store/slices/ordersSlice.ts
export const ordersSlice = createSlice({
  name: 'orders',
  initialState,
  reducers: {
    setFilters: (state, action) => {
      state.filters = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(fetchOrders.fulfilled, (state, action) => {
      state.orders = action.payload;
    });
  },
});
```

### API Integration

```typescript
// services/api.service.ts
class ApiService {
  private axiosInstance: AxiosInstance;

  constructor() {
    this.axiosInstance = axios.create({
      baseURL: process.env.REACT_APP_API_BASE_URL,
    });

    // Request interceptor for auth token
    this.axiosInstance.interceptors.request.use(config => {
      const token = localStorage.getItem('authToken');
      if (token) config.headers.Authorization = `Bearer ${token}`;
      return config;
    });
  }

  async get<T>(url: string) {
    return this.axiosInstance.get<T>(url);
  }
}
```

### Routing Structure

```tsx
// routes/AppRoutes.tsx
export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      
      <Route element={<PrivateRoute />}>
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/orders" element={<OrdersListPage />} />
        <Route path="/orders/:id" element={<OrderDetailsPage />} />
        <Route path="/customers" element={<CustomersPage />} />
      </Route>
    </Routes>
  );
};
```

---

## 2. Mobile Apps (Flutter)

### Technology Stack

| Component           | Technology/Tool               |
| ------------------- | ----------------------------- |
| Framework           | Flutter 3.x                   |
| Language            | Dart                          |
| State Management    | Provider / Riverpod / Bloc    |
| Navigation          | Flutter Navigator 2.0         |
| HTTP Client         | dio / http package            |
| Maps                | google_maps_flutter           |
| Location            | geolocator / location         |
| Camera              | camera / image_picker         |
| Push Notifications  | firebase_messaging            |
| Local Storage       | shared_preferences / hive     |
| Image Caching       | cached_network_image          |
| Forms               | flutter_form_builder          |
| Testing             | flutter_test / integration_test |

### Project Structure (Customer App & Delivery App)
```
customer-app/  (or delivery-app/)
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── screens/           # Full-screen pages
│   │   ├── auth/
│   │   ├── home/
│   │   ├── orders/
│   │   └── profile/
│   ├── widgets/           # Reusable widgets
│   │   ├── common/
│   │   └── features/
│   ├── providers/         # State management
│   ├── models/            # Data models
│   ├── services/          # API services
│   ├── utils/             # Utilities
│   ├── constants/         # Constants
│   ├── routes/            # Routes
│   └── theme/             # Theme config
├── assets/
│   ├── images/
│   ├── fonts/
│   └── icons/
├── android/
├── ios/
└── pubspec.yaml
```

### Widget Architecture

#### Screens (Smart Widgets)
```dart
// screens/orders/orders_list_screen.dart
class OrdersListScreen extends StatefulWidget {
  @override
  _OrdersListScreenState createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<OrderProvider>(context, listen: false).fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Orders')),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.loading) {
            return Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: orderProvider.orders.length,
            itemBuilder: (context, index) {
              return OrderCard(order: orderProvider.orders[index]);
            },
          );
        },
      ),
    );
  }
}
```

#### Widgets (Presentational)
```dart
// widgets/orders/order_card.dart
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({Key? key, required this.order, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(order.orderId),
        subtitle: Text('₹${order.totalAmount}'),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
```

### State Management (Provider Pattern)

```dart
// providers/order_provider.dart
class OrderProvider with ChangeNotifier {
  final OrderService _orderService;
  
  List<Order> _orders = [];
  bool _loading = false;

  List<Order> get orders => _orders;
  bool get loading => _loading;

  OrderProvider(this._orderService);

  Future<void> fetchOrders() async {
    _loading = true;
    notifyListeners();

    try {
      _orders = await _orderService.getOrders();
    } catch (e) {
      // Handle error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
```

### API Integration

```dart
// services/api_service.dart
class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseURL: 'https://api.laundryapp.com/api/v1',
      connectTimeout: Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await Storage.getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Response> get(String path) => _dio.get(path);
  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);
}
```

### Navigation

```dart
// routes/app_routes.dart
class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String orderDetails = '/order-details';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case orders:
        return MaterialPageRoute(builder: (_) => OrdersListScreen());
      default:
        return MaterialPageRoute(builder: (_) => NotFoundScreen());
    }
  }
}
```

---

## 3. Cross-Platform Integration

### Authentication Flow
```
1. User logs in (Mobile/Web)
2. Backend validates credentials
3. Returns JWT token
4. Store token (localStorage/SharedPreferences)
5. Include in all API requests
6. Refresh token before expiry
```

### API Communication
- Base URL: `https://api.laundryapp.com/api/v1`
- Authentication: Bearer token in headers
- Request/Response: JSON format
- Error handling: Standardized error codes

---

## 4. Design Patterns

### Admin Panel (React)
1. **Component Composition**: Build complex UIs from simple components
2. **Custom Hooks**: Extract reusable logic
3. **Render Props/Compound Components**: Share logic between components
4. **Higher-Order Components**: Cross-cutting concerns
5. **Context + Hooks**: Global state without prop drilling

### Mobile Apps (Flutter)
1. **Widget Composition**: Build complex UIs from simple widgets
2. **Provider Pattern**: Predictable state management
3. **Repository Pattern**: Abstract data sources
4. **Factory Pattern**: Create objects
5. **Singleton Pattern**: Shared instances (API service)

---

## 5. Performance Optimization

### React Admin Panel
- **Code Splitting**: React.lazy + Suspense for routes
- **Memoization**: React.memo, useMemo, useCallback
- **Virtual Scrolling**: For long lists
- **Image Optimization**: Lazy loading, WebP format
- **Bundle Analysis**: Identify large dependencies

### Flutter Mobile Apps
- **Const Constructors**: Reduce widget rebuilds
- **ListView.builder**: Efficient list rendering
- **Cached Images**: cached_network_image
- **Keys**: Optimize widget tree updates
- **Lazy Loading**: Load data on demand

---

## 6. Testing Strategy

### React (Jest + React Testing Library)
```tsx
describe('OrderCard', () => {
  it('renders order information', () => {
    render(<OrderCard order={mockOrder} />);
    expect(screen.getByText(mockOrder.orderId)).toBeInTheDocument();
  });

  it('calls onViewDetails when clicked', () => {
    const handleClick = jest.fn();
    render(<OrderCard order={mockOrder} onViewDetails={handleClick} />);
    fireEvent.click(screen.getByText('View'));
    expect(handleClick).toHaveBeenCalled();
  });
});
```

### Flutter (Widget Tests)
```dart
testWidgets('OrderCard displays order info', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: OrderCard(order: mockOrder),
  ));

  expect(find.text(mockOrder.orderId), findsOneWidget);
  expect(find.text('₹${mockOrder.totalAmount}'), findsOneWidget);
});
```

---

## 7. Development Standards

### React Coding Conventions
- Functional components with hooks
- TypeScript for type safety
- Props destructuring
- Consistent file naming (PascalCase.tsx)
- CSS Modules or styled-components

### Flutter Coding Conventions
- Stateless widgets where possible
- Const constructors
- Strong typing (avoid dynamic)
- File naming (snake_case.dart)
- Material Design guidelines

---

## Related Documentation

- React Standards: `.cursor/rules/frontend/react-coding-standards.mdc`
- Flutter Standards: `.cursor/rules/frontend/flutter-coding-standards.mdc`
- Review Checklist: `.cursor/rules/frontend/frontend-review-checklist.mdc`

---

**Last Updated**: October 29, 2025
