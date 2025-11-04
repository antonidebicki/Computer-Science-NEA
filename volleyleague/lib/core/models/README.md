# VolleyLeague Data Models

This directory contains the Dart data models that represent the database schema for the VolleyLeague application.

## Overview

All models are immutable data classes with:
- `fromJson()` factory constructors for deserialization
- `toJson()` methods for serialization
- `copyWith()` methods for creating modified copies
- Proper equality operators and `hashCode` implementations
- Clear `toString()` representations

## Models

### Core Entities

- **`User`** - Represents users in the system (admins, coaches, players, referees)
- **`Team`** - Represents volleyball teams
- **`League`** - Represents volleyball leagues
- **`Season`** - Represents seasons within leagues

### Relationships

- **`TeamMember`** - Links users to teams with roles (player/coach)
- **`SeasonTeam`** - Links teams to seasons

### Match Management

- **`Match`** - Represents volleyball matches between two teams
- **`MatchReferee`** - Links referees to matches with their roles
- **`VolleyballSet`** - Represents individual sets within a match
- **`Substitution`** - Tracks player substitutions during sets
- **`Timeout`** - Tracks timeouts called during sets

### Analytics & Finance

- **`LeagueStanding`** - Stores team standings and statistics for a season
- **`Payment`** - Manages payments between entities (leagues, teams, users)

### Enums

- **`UserRole`** - ADMIN, COACH, PLAYER, REFEREE
- **`GameState`** - UNSCHEDULED, SCHEDULED, FINISHED, PROCESSED
- **`PaymentStatus`** - UNPAID, PAID, OVERDUE

## Usage

Import all models at once:

```dart
import 'package:volleyleague/core/models/models.dart';
```

Or import individual models:

```dart
import 'package:volleyleague/core/models/user.dart';
import 'package:volleyleague/core/models/team.dart';
```

## Example

```dart
// Creating a user from JSON
final user = User.fromJson({
  'user_id': 1,
  'username': 'john_doe',
  'email': 'john@example.com',
  'role': 'PLAYER',
  'hashed_password': 'hash',
  'created_at': '2024-01-01T00:00:00Z',
});

// Creating a modified copy
final updatedUser = user.copyWith(
  fullName: 'John Doe',
  email: 'john.doe@example.com',
);

// Converting to JSON
final json = updatedUser.toJson();
```

## Database Schema

These models correspond to the PostgreSQL database schema defined in `/database/schema.sql`.
