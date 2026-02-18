# Application Structure & Wireframes

**Version:** 1.0
**Last Updated:** YYYY-MM-DD

## 1. Global Navigation (Sitemap)

| Page Name | Route Path | Layout Type | Access |
| :--- | :--- | :--- | :--- |
| **Login** | `/login` | Auth Layout (Centered) | Public |
| **Dashboard** | `/dashboard` | Sidebar Layout | Private |
| **Chat** | `/chat/:id` | Sidebar Layout | Private |
| **Settings** | `/settings` | Sidebar Layout | Private |

## 2. Layout Definitions

### A. Sidebar Layout
*Fixed sidebar on the left, scrollable content on the right.*
- **Sidebar (Width: 250px)**:
  - Logo (Top)
  - Navigation Links (Middle): Dashboard, Documents, Chat.
  - User Profile (Bottom): Avatar + Name.
- **Main Content**:
  - `max-w-7xl mx-auto p-4` container.
- **Mobile Behavior**: Sidebar becomes a hamburger menu drawer.

## 3. Page Specifications (Wireframes)

### Page: Dashboard (`/dashboard`)

#### Zone 1: Header
- **Title**: "Welcome back, {User}" (H1)
- **Action**: "New Project" Button (Primary, Right-aligned)

#### Zone 2: Stats Grid (3 Cols)
- **Card 1**: "Total Documents" (Icon + Number)
- **Card 2**: "AI Credits Left" (Icon + Number + Progress Bar)

#### Zone 3: Recent Activity Table
- **Columns**: Filename, Date, Status (Badge).
- **Row Action**: Click -> Navigate to `/documents/:id`
- **Empty State**: Illustration + "Upload your first document" button.

### Page: Chat Interface (`/chat/:id`)

#### Zone 1: Chat Area (Scrollable, Flex-Grow)
- **Component**: `MessageList`
- **Behavior**: Auto-scroll to bottom on new message.

#### Zone 2: Input Area (Sticky Bottom)
- **Component**: `ChatInput`
  - Textarea (Auto-resize)
  - "Attach File" Icon Button
  - "Send" Button (Disabled if empty)
- **Loading State**: When AI is thinking, show "Thinking..." pulsing indicator above input.

## 4. Interaction Rules
- **Modals**: Use `Dialog` component (Headless UI) for "Delete Confirmation".
- **Toasts**: Show "Success" toast (Top-Right) after Form Submission.
- **Transitions**: Use `Framer Motion` for page transitions (fade-in).
