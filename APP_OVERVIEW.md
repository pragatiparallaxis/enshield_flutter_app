# Enshield Flutter App - Complete Overview & User Guide

## Table of Contents
1. [App Overview](#app-overview)
2. [Architecture & Technology Stack](#architecture--technology-stack)
3. [User Roles & Access Control](#user-roles--access-control)
4. [Authentication Flow](#authentication-flow)
5. [Admin Features (APP_ADMIN)](#admin-features-app_admin)
6. [Worker Features (APP_USER)](#worker-features-app_user)
7. [Work Order Management Flow](#work-order-management-flow)
8. [Inventory Management Flow](#inventory-management-flow)
9. [Worker Assignment Flow](#worker-assignment-flow)
10. [API Integration](#api-integration)
11. [Navigation & Routes](#navigation--routes)
12. [Key Features & Modals](#key-features--modals)
13. [Data Models](#data-models)
14. [Error Handling](#error-handling)
15. [Local Storage](#local-storage)
16. [UI/UX Features](#uiux-features)
17. [Best Practices](#best-practices)

---

## App Overview

The Enshield Flutter App is a production management system for manufacturing operations. It supports:
- Work order creation and tracking
- Inventory management
- Worker assignment and task management
- Production stage tracking
- Material allocation and tracking
- Worker submissions and approvals

---

## Architecture & Technology Stack

### Framework & State Management
- **Flutter** (Dart programming language)
- **GetX** for state management and navigation
- **GetStorage** for local storage

### Key Libraries
- `http` package for API calls
- `get_storage` for persistent storage
- `get` package for state management, routing, and dependency injection

### Project Structure
```
lib/
├── core/              # Theme configuration
├── models/            # Data models
├── services/          # API and auth services
├── views/             # UI screens
├── viewmodels/        # Business logic controllers
├── widgets/           # Reusable UI components
├── routes.dart        # Navigation configuration
└── main.dart          # App entry point
```

---

## User Roles & Access Control

### APP_ADMIN (Administrator)
- Full access to all features
- Can create and manage work orders
- Can assign workers to stages
- Can manage inventory
- Can approve/reject worker submissions
- Can create and manage workers
- Can manage outsourced parties

### APP_USER (Worker)
- Limited access
- Can view assigned tasks
- Can submit work with output quantities
- Can return inventory items
- Cannot access admin features

### Role-Based Routing
- On login, users are redirected based on role:
  - `APP_ADMIN` → Dashboard
  - `APP_USER` → Worker Assignments screen

---

## Authentication Flow

### 1. Splash Screen (`/`)
- First screen on app launch
- Checks for existing authentication token
- Auto-redirects:
  - If token exists → Dashboard (admin) or Worker Assignments (worker)
  - If no token → Sign In screen

### 2. Sign In (`/signin`)
- Email and password fields
- "Remember Me" option
- Password visibility toggle
- On success:
  - Stores token and user data in GetStorage
  - Sets global API token
  - Redirects based on role

### 3. Sign Up (`/signup`)
- User registration
- Creates new app user account

### 4. Logout
- Clears all stored data (token, user info)
- Redirects to Sign In screen

---

## Admin Features (APP_ADMIN)

### Dashboard (`/dashboard`)
- Main landing page for admins
- Shows production statistics
- Quick access to:
  - Work Orders
  - Inventory
  - Workers
  - Outsourced Parties

### Work Order Management

#### Create Work Order (`/create-work-order`)
- Create new work orders
- Fields:
  - Work Order Code
  - Title
  - Client Name
  - Planned Quantity
  - Order Date
  - Notes
- Add work order items (category, color, size, quantity)

#### View Work Order (`/view-work-order/:id`)
- Detailed view of a work order
- Shows:
  - Work order details
  - Stages and their status
  - Inventory allocations
  - Worker assignments
- Actions:
  - **Allocate Materials** - Allocate fabric/materials to work order
  - **Assign Workers to Stages** - Assign workers with inventory
  - **Edit Allocations** - Modify existing material allocations
  - **Return Layers** - Return unused layers and recalculate
  - **Complete Stages** - Mark stages as complete
  - **Review & Finalize** - Review worker submissions and approve/reject

#### Work Order Stages
- Each work order has multiple stages
- Stage statuses: `pending`, `assigned`, `in_progress`, `submitted`, `approved`, `completed`
- Stages can be created dynamically when assigning workers

### Inventory Management (`/inventory`)

#### View Inventory
- List of all inventory items
- Shows:
  - Item name
  - Fabric, Color, Unit
  - Total quantity
  - Available quantity
  - Taken quantity

#### Add Inventory (Inward)
- Add new inventory items or increase quantity
- Fields:
  - Inventory ID (optional, for existing items)
  - Name
  - Fabric
  - Color
  - Unit
  - Quantity
  - Supplier
  - Purchase Order
  - Notes

### Worker Management

#### Create Worker (`/create-worker`)
- Create new worker accounts
- Fields:
  - Name
  - Email
  - Phone
  - Type (APP_USER or APP_ADMIN)
  - Password (default: "User@123")
  - Active status
  - Outsourced status
- Creates app user account and links to worker

#### Worker List (`/workers`)
- View all workers
- Edit worker details
- Filter by active/inactive

#### Edit Worker (`/edit-worker/:id`)
- Update worker information
- Change active status

### Outsourced Party Management

#### Outsourced Party List (`/outsourced-parties`)
- View all outsourced parties
- Create new outsourced parties

#### Create Outsourced Party (`/create-outsourced-party`)
- Add new outsourced party
- Fields: Name, Contact, Address, etc.

---

## Worker Features (APP_USER)

### Worker Assignments (`/worker-assignments`)
- Main screen for workers
- Shows all assigned tasks
- Displays:
  - Work Order Code and Title
  - Stage Name
  - Item Name
  - Assigned Quantity
  - Status (Assigned, Submitted, Approved)
  - Output Quantity (if submitted)
  - Approved Quantity (if approved)

### Submit Work
- Tap on an assignment to submit work
- Dialog includes:
  - **Output Quantity** (required)
  - **Rejected Quantity** (optional)
  - **Notes** (optional)
  - **Inventory Return Section**:
    - List of allocated inventory items
    - Returned quantity
    - Broken/Lost quantity
- On submit:
  - Submits work assignment
  - Submits inventory returns (if any)
  - Updates assignment status to "submitted"

---

## Work Order Management Flow

### Step 1: Create Work Order
1. Admin navigates to Dashboard
2. Clicks "Create Work Order"
3. Fills in work order details
4. Adds work order items (category, color, size, quantity)
5. Saves work order

### Step 2: Allocate Materials
1. Open work order details
2. Click "Allocate Materials"
3. Select inventory item
4. Enter:
   - Total Meters
   - Table Length
   - Layers Used
   - Pairs Per Layer
   - Fabric, Color
5. System calculates:
   - Meters Used = Layers Used × Table Length
   - Item quantities based on pairs per layer
6. Inventory is deducted (only meters used)

### Step 3: Assign Workers to Stage
1. Click "Assign Workers" on a stage
2. Add workers and assign quantities
3. Optionally allocate inventory items to each worker:
   - Select inventory item
   - Enter quantity provided
4. Submit:
   - Creates worker assignments
   - Allocates inventory to workers
   - Updates inventory quantities

### Step 4: Worker Completes Work
1. Worker views assignment
2. Clicks "Submit Work"
3. Enters output quantity
4. Returns inventory (if any)
5. Submits

### Step 5: Admin Reviews & Approves
1. Admin opens work order
2. Clicks "Review & Finalize" on submitted stage
3. Reviews worker submissions
4. Approves/rejects with quantities
5. Stage status updates to "approved"

### Step 6: Return Layers (Optional)
1. Admin can return unused layers
2. System recalculates:
   - Effective layers
   - Output quantities
   - Item quantities
3. Optionally restocks inventory

---

## Inventory Management Flow

### Inventory Allocation to Work Orders
1. Admin allocates materials to work order
2. System deducts from available quantity
3. Adds to taken quantity
4. Only meters used are deducted (not total meters)

### Inventory Allocation to Workers
1. Admin assigns workers to stage
2. Can allocate inventory items to each worker
3. System:
   - Creates `stage_worker_inventory_allocations` records
   - Deducts from main inventory
   - Tracks quantity provided to each worker

### Worker Returns Inventory
1. Worker submits work
2. Can return inventory items:
   - Quantity Returned
   - Quantity Broken/Lost
3. System updates allocation records
4. Admin can approve/reject returns
5. On approval, inventory is restocked

---

## Worker Assignment Flow

### Admin Side
1. Open work order details
2. Navigate to a stage
3. Click "Assign Workers"
4. Modal opens with:
   - Input quantity display
   - Remaining quantity tracker
   - Worker assignment list
   - Inventory allocation section (per worker)
5. Add workers:
   - Select worker from dropdown
   - Enter quantity
   - Add inventory items (optional)
6. Submit:
   - Creates worker assignments
   - Allocates inventory (if any)
   - Updates stage status

### Worker Side
1. Worker logs in
2. Sees "Worker Assignments" screen
3. Views all assigned tasks
4. Taps assignment to submit:
   - Enter output quantity
   - Return inventory (if allocated)
   - Add notes
5. Submits work

---

## API Integration

### Base URL
```
http://185.165.240.191:3056
```

### Authentication
- Bearer token authentication
- Token stored in GetStorage
- Automatically included in all API requests
- Auto-redirects to login on 401/403

### Key API Endpoints

#### Authentication
- `POST /api/auth/flutter-login` - Login
- `POST /api/auth/flutter-logout` - Logout

#### Work Orders
- `GET /api/production/work-orders` - List work orders
- `POST /api/production/work-orders` - Create work order
- `GET /api/production/work-orders/[id]` - Get work order details
- `POST /api/production/work-orders/[id]/allocate-materials` - Allocate materials
- `POST /api/production/work-orders/[id]/stages/[stageId]/assign-workers` - Assign workers
- `PUT /api/production/work-orders/[id]/update-allocation/[inventoryId]` - Edit allocation
- `POST /api/production/work-orders/inventory/[inventoryId]/return-layers` - Return layers

#### Inventory
- `GET /api/inventory` - List inventory items
- `POST /api/inventory/inward` - Add inventory
- `POST /api/production/work-orders/[id]/stages/[stageId]/allocate-inventory` - Allocate to workers
- `GET /api/production/work-orders/[id]/stages/[stageId]/allocate-inventory` - Get allocations
- `POST /api/production/inventory-allocations/[allocationId]/return` - Return inventory
- `POST /api/production/inventory-allocations/[allocationId]/approve` - Approve return

#### Workers
- `GET /api/production/workers` - List workers
- `POST /api/production/workers` - Create worker
- `GET /api/production/workers/my-assignments` - Get worker assignments
- `POST /api/production/assignments/[assignmentId]/submit` - Submit work

---

## Navigation & Routes

### Route Constants
```dart
Routes.splash              → '/'
Routes.signin              → '/signin'
Routes.signup              → '/signup'
Routes.dashboard           → '/dashboard'
Routes.inventory           → '/inventory'
Routes.workOrder           → '/work-order'
Routes.createWorkOrder     → '/create-work-order'
Routes.viewWorkOrder       → '/view-work-order'
Routes.workerList          → '/workers'
Routes.createWorker        → '/create-worker'
Routes.editWorker          → '/edit-worker'
Routes.workerAssignments   → '/worker-assignments'
Routes.outsourcedPartyList → '/outsourced-parties'
Routes.createOutsourcedParty → '/create-outsourced-party'
```

### Navigation Methods
- `Get.toNamed(Routes.dashboard)` - Navigate to route
- `Get.offAllNamed(Routes.signin)` - Navigate and clear stack
- `Get.back()` - Go back

---

## Key Features & Modals

### Allocate Materials Modal
- Allocate fabric/materials to work order
- Calculate item quantities
- Deduct inventory

### Assign Workers Modal
- Assign workers to stages
- Allocate inventory to workers
- Track remaining quantity

### Edit Allocation Modal
- Edit existing material allocation
- Update layers used, pairs per layer
- Recalculate quantities

### Return Layers Modal
- Return unused layers
- Recalculate quantities
- Optionally restock inventory

### Submit Work Dialog
- Worker submits work
- Enter output/rejected quantities
- Return inventory items

---

## Data Models

### WorkOrder
- id, work_order_code, title, planned_quantity
- client_name, order_date, status, notes
- work_order_items, stages, inventory

### WorkOrderStage
- id, stage_name, stage_order
- input_quantity, output_quantity, rejected_quantity
- status, worker_assignments

### WorkerAssignment
- work_order_stages_id, workers_id
- quantity, status
- worker_output_quantity, admin_approved_quantity

### InventoryItem
- id, name, fabric, color, unit
- total, available, taken_quantity

---

## Error Handling

### Authentication Errors
- Auto-redirects to login on 401/403
- Clears stored token
- Shows error message

### API Errors
- Displays error messages via Snackbar
- Logs errors for debugging
- Graceful fallbacks

### Validation
- Form validation before submission
- Quantity validation (remaining quantity checks)
- Required field validation

---

## Local Storage

### Stored Data
- `auth_token` - JWT token
- `user_id` - User ID
- `user_email` - User email
- `user_role` - User role (APP_ADMIN/APP_USER)
- `user_firstName` - First name
- `user_lastName` - Last name

### Storage Methods
- `GetStorage().write(key, value)` - Write
- `GetStorage().read(key)` - Read
- `GetStorage().remove(key)` - Delete

---

## UI/UX Features

### Theme
- Dark theme (primary: #0F111A, accent: #FF9800)
- Consistent color scheme
- Material Design components

### Loading States
- Circular progress indicators
- Loading overlays
- Skeleton screens

### Feedback
- Snackbar notifications (success/error)
- Confirmation dialogs
- Form validation messages

---

## Best Practices

1. Always check authentication before API calls
2. Handle network errors gracefully
3. Validate user input before submission
4. Show loading states during async operations
5. Provide clear error messages
6. Use role-based access control
7. Dispose controllers properly
8. Handle null values safely

---

## File Structure Reference

### Views (Screens)
- `splash_view.dart` - Splash screen
- `signin_view.dart` - Sign in screen
- `signup_view.dart` - Sign up screen
- `dashboard_view.dart` - Admin dashboard
- `work_order_create.dart` - Create work order
- `work_order_view.dart` - View work order details
- `worker_assignments_view.dart` - Worker assignments
- `inventory_view.dart` - Inventory management
- `worker_list.dart` - Worker list
- `worker_create.dart` - Create worker
- `worker_edit.dart` - Edit worker
- `outsourced_party_list.dart` - Outsourced parties list
- `outsourced_party_create.dart` - Create outsourced party
- `stage_submissions_view.dart` - Review submissions

### ViewModels (Controllers)
- `splash_viewmodel.dart` - Splash logic
- `signin_viewmodel.dart` - Sign in logic
- `signup_viewmodel.dart` - Sign up logic
- `dashboard_viewmodel.dart` - Dashboard logic
- `work_order_viewmodel.dart` - Work order logic
- `work_order_create_viewmodel.dart` - Create work order logic
- `inventory_viewmodel.dart` - Inventory logic
- `worker_create_viewmodel.dart` - Create worker logic
- `worker_list_viewmodel.dart` - Worker list logic
- `worker_edit_viewmodel.dart` - Edit worker logic

### Widgets (Reusable Components)
- `assign_workers_modal.dart` - Assign workers modal
- `allocate_materials_work_order_modal.dart` - Allocate materials modal
- `edit_allocation_modal.dart` - Edit allocation modal
- `return_layers_modal.dart` - Return layers modal
- `complete_stage_modal.dart` - Complete stage modal
- `centered_progress.dart` - Loading indicator

### Services
- `api_service.dart` - API communication
- `auth_service.dart` - Authentication service

### Models
- `work_order_model.dart` - Work order data models
- `app_user_model.dart` - User models
- `inventory_item_model.dart` - Inventory models
- `worker_model.dart` - Worker models

---

## Development Notes

### State Management
- Uses GetX for reactive state management
- ViewModels extend `GetxController`
- Observable variables use `.obs`
- UI updates automatically with `Obx()` or `GetBuilder()`

### API Service
- Centralized API service in `api_service.dart`
- Automatic token injection
- Error handling and redirects
- Base URL configuration

### Navigation
- GetX routing system
- Named routes in `routes.dart`
- Route parameters support
- Deep linking support

### Storage
- GetStorage for local persistence
- Stores authentication tokens
- Stores user preferences
- Cleared on logout

---

## Troubleshooting

### Common Issues

1. **Token Expired**
   - App automatically redirects to login
   - Clear storage and re-login

2. **API Connection Errors**
   - Check base URL configuration
   - Verify network connectivity
   - Check server status

3. **Navigation Issues**
   - Ensure routes are registered in `routes.dart`
   - Check route names match exactly
   - Verify bindings are set up

4. **State Not Updating**
   - Ensure using `Obx()` or `GetBuilder()`
   - Check if variable is `.obs`
   - Verify ViewModel is properly initialized

---

## Version Information

- **Framework**: Flutter
- **State Management**: GetX
- **Storage**: GetStorage
- **HTTP Client**: http package
- **API Base URL**: http://185.165.240.191:3056

---

## Support & Contact

For issues, questions, or feature requests, please contact the development team.

---

**Last Updated**: 2025
**Document Version**: 1.0

