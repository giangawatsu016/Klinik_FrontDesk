# Design System & Wireflows

**Feature:** [Feature Name]

## 1. Visual Tokens (Tailwind)
*Define the core look and feel for this feature.*

- **Layout**: (e.g. `max-w-4xl mx-auto`, `p-4`)
- **Typography Strategy**:
  - Headings: `text-2xl font-bold tracking-tight`
  - Body: `text-base text-slate-600 leading-relaxed`
- **Colors**:
  - Primary Action: `bg-indigo-600`
  - AI Output: `bg-slate-50 border-l-4 border-indigo-400`

## 2. Component Specifications

### A. [Component Name] (e.g. ChatBubble)
- **Props**: `message: string`, `is_user: boolean`, `status: 'sending' | 'sent' | 'error'`
- **States**:
  - *Default*: ...
  - *Hover*: ...
  - *Loading*: Show skeleton pulse `animate-pulse bg-slate-200`

## 3. Wireflow (Description)
*Describe the user journey through the UI elements.*

1. **Entry**: User lands on `/chat`.
2. **Action**: User types in `Textarea` (Sticky Bottom).
3. **Feedback**: 
   - Button turns to "Stop Generating".
   - `MessageList` auto-scrolls.
   - Streaming text appears in a new `ChatBubble`.
4. **Completion**: Feedback buttons (Thumbs Up-Down) appear below the message.
