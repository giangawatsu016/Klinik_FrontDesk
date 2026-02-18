# UI Guidelines & Visual Standards

## 1. Design Philosophy
*Summarize the core visual principles (e.g., Clean, Optimistic, Minimalist).*

## 2. Color Palette (Tailwind)

### Primary Colors
| Name | Class | Hex | Usage |
| :--- | :--- | :--- | :--- |
| Primary | `bg-indigo-600` | `#4F46E5` | Main Buttons, Active States |
| Secondary | `bg-slate-900` | `#0F172A` | Headings, Strong Borders |

### Functional Colors
| Name | Class | Usage |
| :--- | :--- | :--- |
| Success | `text-emerald-600` | Completed actions |
| Error | `text-rose-600` | Critical failures |
| Warning | `text-amber-500` | Non-blocking alerts |

## 3. Typography
**Font Family**: Inter (Sans-serif)

| Style | Classes | Usage |
| :--- | :--- | :--- |
| H1 | `text-4xl font-bold tracking-tight text-slate-900` | Page Titles |
| H2 | `text-2xl font-semibold text-slate-800` | Section Headers |
| Body | `text-base text-slate-600 leading-relaxed` | Standard Text |
| Small | `text-sm text-slate-500` | Metadata, Hints |

## 4. Components

### Buttons
- **Primary**: `rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600`
- **Secondary**: `rounded-md bg-white px-3.5 py-2.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50`

### Inputs
- **Default**: `block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6`
