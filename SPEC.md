# SPEC.md - PlantCare App

## 1. Project Overview

**Project Name:** PlantCare  
**Project Type:** Flutter Mobile Application (Android)  
**Core Functionality:** A mobile application for managing plant care, providing plant information, notifications for watering/sun exposure, a plant catalog, and a plant identification quiz system.

---

## 2. Technology Stack & Choices

| Category | Choice |
|----------|--------|
| **Framework** | Flutter 3.x |
| **Language** | Dart 3.x |
| **State Management** | Provider + ChangeNotifier |
| **Local Database** | SQLite (sqflite) |
| **Notifications** | flutter_local_notifications |
| **Architecture** | Clean Architecture (Data / Domain / Presentation) |
| **Navigation** | GoRouter |
| **UI Components** | Material Design 3 |

### Key Dependencies
- `provider: ^6.1.1` - State management
- `sqflite: ^2.3.0` - Local database
- `path: ^1.8.3` - Path utilities
- `flutter_local_notifications: ^17.0.0` - Local notifications
- `go_router: ^14.0.0` - Navigation
- `intl: ^0.19.0` - Date/time formatting
- `uuid: ^4.2.1` - Unique ID generation

---

## 3. Feature List

### 3.1 Plant Registration
- Add new plants with name, species, photo (optional), location
- Edit existing plant details
- Delete plants from collection
- View list of all registered plants

### 3.2 Plant Information
- Detailed plant profile with:
  - Light requirements (low/medium/high/direct)
  - Watering needs (frequency, amount)
  - Temperature range (min/max)
  - Humidity requirements (low/medium/high)
  - Care tips and notes

### 3.3 Notification System
- Configurable watering reminders per plant
- Sun exposure alerts
- Custom notification schedules
- Enable/disable notifications per plant

### 3.4 Plant Catalog
- Pre-loaded database of common plants
- Search and filter functionality
- Basic and advanced information views
- Categories (indoor, outdoor, succulents, flowers, etc.)

### 3.5 Plant Identification Quiz
- Interactive quiz with visual questions
- Step-by-step identification process
- Results with matching plants from catalog
- Save results to personal collection

### 3.6 User Interface
- Bottom navigation (Home, Catalog, Quiz, My Plants, Settings)
- Plant cards with images and quick info
- Pull-to-refresh functionality
- Empty states with helpful messages

---

## 4. UI/UX Design Direction

### Visual Style
- **Design System:** Material Design 3
- **Theme:** Nature-inspired, fresh and clean
- **Primary Color:** Green (#4CAF50)
- **Secondary Color:** Earthy Brown (#8D6E63)
- **Accent Color:** Sunny Yellow (#FFC107)
- **Background:** Light cream/white

### Color Palette
| Role | Color | Hex |
|------|-------|-----|
| Primary | Green | #4CAF50 |
| Primary Container | Light Green | #C8E6C9 |
| Secondary | Brown | #8D6E63 |
| Secondary Container | Light Brown | #D7CCC8 |
| Tertiary | Yellow | #FFC107 |
| Background | Off-White | #FAFAFA |
| Surface | White | #FFFFFF |
| Error | Red | #F44336 |

### Layout Approach
- **Navigation:** Bottom Navigation Bar with 5 tabs
- **Home:** Dashboard with upcoming tasks and quick stats
- **Catalog:** Grid/List view with search bar
- **Quiz:** Step-by-step wizard flow
- **My Plants:** List view with plant cards
- **Settings:** Simple list with toggles

### Typography
- Headlines: Bold, green accent
- Body: Clean, readable
- Labels: Small, muted colors

### Iconography
- Custom plant-themed icons
- Material icons for standard actions
- Illustrated empty states

---

## 5. Data Models

### Plant (User's plant)
- id, name, species, imagePath, location
- lightRequirement, wateringFrequency, wateringAmount
- minTemp, maxTemp, humidityLevel
- lastWatered, nextWatering, lastSunExposure
- notificationsEnabled, createdAt

### CatalogPlant (Pre-loaded)
- id, name, scientificName, category
- description, lightRequirement, wateringFrequency
- minTemp, maxTemp, humidityLevel
- careTips, imageUrl

### Notification
- id, plantId, type (watering/sun), scheduledTime, enabled

---

## 6. Screen Flow

```
App Launch
    │
    ▼
Bottom Navigation
    ├── Home (Dashboard)
    │   └── Plant Details → Edit Plant
    ├── Catalog
    │   └── Plant Details (Catalog)
    ├── Quiz
    │   └── Quiz Questions (multiple)
    │   └── Quiz Results → Add to Collection
    ├── My Plants
    │   └── Plant Details → Edit Plant
    └── Settings
        └── Notification Preferences
```