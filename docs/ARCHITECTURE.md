# Architecture Overview

## System Design

The Buildables Neu Todo app follows a clean architecture pattern with offline-first principles.

### Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │   Screens   │ │   Widgets   │ │  Controllers │          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Business Logic                         │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │    Models   │ │ Controllers │ │ Repository  │          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │Local (Drift)│ │   Supabase  │ │File Service │          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### TaskRepository
- Manages data synchronization between local and remote storage
- Implements offline-first strategy
- Handles conflict resolution

### EnhancedFileService
- Manages file attachments with offline support
- Queues uploads when offline
- Handles file deletion and cleanup

### Controllers
- **TaskController**: Manages task CRUD operations and real-time updates
- **AuthController**: Handles user authentication and session management

### Local Database (Drift)
- Type-safe SQL operations
- Offline data persistence
- Migration support

## Data Flow

### Creating a Task (Offline)
1. User creates task in UI
2. Task saved to local Drift database
3. Marked as "unsynced"
4. When online, synced to Supabase
5. Local record marked as "synced"

### Real-time Updates
1. Supabase sends real-time updates
2. Local database updated
3. UI automatically refreshes via controllers

### File Attachments
1. File selected by user
2. Stored locally immediately
3. If online: uploaded to Supabase storage
4. If offline: queued for upload
5. Local metadata tracks sync status

## Offline-First Strategy

The app prioritizes local data and functionality:

- ✅ Create, read, update, delete tasks offline
- ✅ View and manage file attachments offline
- ✅ Queue operations for later sync
- ✅ Conflict resolution on reconnection
- ✅ Seamless transition between online/offline modes

## Real-time Collaboration

- Uses Supabase real-time subscriptions
- Automatic UI updates when tasks are shared
- Conflict resolution for simultaneous edits
- User presence and activity tracking