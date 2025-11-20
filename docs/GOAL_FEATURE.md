# Goal Setting Feature

## Overview

The Goal Setting feature allows users to set and track progress towards specific rewards or point targets. The system calculates estimated completion time based on recent earning history and displays progress on both Home and Rewards tabs.

## Features

### 1. Goal Types

Users can set two types of goals:
- **Points Target**: Set a specific number of points as a goal
- **Reward Target**: Select a reward item from the reward store as a goal

### 2. Progress Tracking

- **Progress Bar**: Visual representation of progress towards goal
- **Current vs Target**: Shows current points, target points, and points needed
- **Estimated Days**: Calculates estimated days to reach goal based on last 5 days' average point earnings
- **Auto-completion**: Goals are automatically marked as completed when target is reached

### 3. User Interface

#### Home Tab
- Active goal card displays at the top (if a goal exists)
- Shows complete progress information including estimated completion time

#### Rewards Tab
- Active goal card at the top (if goal exists) with full progress details
- "Set Goal" button/card when no active goal exists
- One-tap access to create new goals

### 4. Goal Management

- **Create Goal**: Tap "Set Goal" button to open goal creation dialog
- **Select Target**: Choose between points or reward item
- **Delete Goal**: Remove active goal via the X button on goal card
- **Celebration**: Automatic celebration dialog when goal is achieved

## Technical Implementation

### Models

**GoalModel** (`lib/core/models/goal_model.dart`)
- `id`: Unique identifier
- `userId`: Owner of the goal
- `familyId`: Family association
- `targetType`: Points or reward (enum)
- `targetPoints`: Target point value
- `targetRewardId`, `targetRewardName`, `targetRewardCost`: For reward goals
- `createdAt`: Creation timestamp
- `completedAt`: Completion timestamp (null if active)
- `isActive`: Whether goal is currently active
- `startingPoints`: Points when goal was created

### Services

**GoalService** (`lib/core/services/goal_service.dart`)
- `createGoal()`: Create new goal
- `getActiveGoal()`: Get current active goal
- `watchActiveGoal()`: Stream of active goal updates
- `calculateAveragePointsPerDay()`: Calculate 5-day average
- `calculateDaysToGoal()`: Estimate days to completion
- `checkAndCompleteGoal()`: Auto-complete when target reached
- `deleteGoal()`: Remove goal

### UI Components

**SetGoalDialog** (`lib/features/rewards/presentation/widgets/set_goal_dialog.dart`)
- Dialog for creating/editing goals
- Segmented button to switch between points and reward targets
- Points input with validation
- Scrollable reward list with selection
- Current points display

**GoalProgressCard** (`lib/shared/widgets/goal_progress_card.dart`)
- Visual goal progress display
- Progress bar with percentage
- Stats: current, target, needed points
- Estimated days calculation
- Completion celebration badge

### Database

**Firestore Collection**: `goals`

**Security Rules**:
```
- Users can read/write their own goals
- Parents can read their children's goals
```

**Indexes**:
```json
{
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "isActive", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

## Usage

### Setting a Points Goal

1. Navigate to Rewards tab
2. Tap "Set Goal" button
3. Keep "Points Target" selected
4. Enter target points (must be higher than current points)
5. Tap "Set Goal"

### Setting a Reward Goal

1. Navigate to Rewards tab
2. Tap "Set Goal" button
3. Select "Reward Item" option
4. Scroll and tap desired reward from list
5. Tap "Set Goal"

### Viewing Progress

- Check Home tab or Rewards tab to see progress card
- Progress updates automatically as points change
- Estimated days refreshes based on recent activity

### Completing a Goal

- Goals automatically complete when target reached
- Celebration dialog appears on completion
- Set new goal to continue tracking progress

## Estimation Algorithm

The system estimates days to goal completion using:
1. Analyze last 5 days of earned transactions
2. Calculate average points per active day
3. Divide points needed by daily average
4. Display as estimated days

**Note**: If no recent activity (last 5 days), shows message to complete more tasks for estimate.

## Future Enhancements

Potential additions:
- Multiple active goals
- Goal categories/tags
- Shared family goals
- Milestone tracking
- Goal history view
- Weekly/monthly goals
- Reward suggestions based on progress
- Goal reminders/notifications
