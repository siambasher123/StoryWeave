# StoryWeave

An interactive branching story iOS app built with SwiftUI and Firebase.

## Overview

StoryWeave lets users register, browse a library of interactive stories, and play through branching narratives with multiple endings. Progress is saved in real time so users can resume from where they left off.

## Tech Stack

- Swift + SwiftUI
- Firebase Authentication
- Firebase Firestore
- JSONBin.io REST API
- URLSession + Codable
- MVVM architecture

## Lab Criteria Coverage

| Criterion                        | Implementation                                                                              |
| -------------------------------- | ------------------------------------------------------------------------------------------- |
| Swift Language                   | All models, ViewModels, services, and logic                                                 |
| Simple iOS Interface Using Swift | All screens built in SwiftUI                                                                |
| Firebase Integration + Database  | Auth (register/login/logout) + Firestore CRUD across 3 collections                          |
| JSON Parsing + REST API          | URLSession fetches story JSON from JSONBin, decoded with Codable                            |
| `@State`                         | Local UI state in LoginView, RegisterView, StoryLibraryView                                 |
| `@Binding`                       | CategoryFilterView receives selected category from StoryLibraryView                         |
| `@ObservedObject`                | StoryCardView and ChoiceButtonView observe ViewModels from parent                           |
| `@StateObject`                   | StoryLibraryView, StoryPlayerView, ProfileView own their ViewModels                         |
| `@EnvironmentObject`             | AppSession injected at root, consumed across StoryPlayerView, ChoiceButtonView, ProfileView |

## Firestore CRUD Operations

All four operations are explicitly user-triggered:

| Operation | Triggered By |
| | |
| Create | Registering an account creates a user document. Starting a new story creates a session document. |
| Read | Opening the Library tab reads the stories collection. Opening the Profile tab reads all user sessions. |
| Update | Tapping a choice during playthrough merges the updated session back to Firestore. |
| Delete | Swiping left on a story in the Profile progress list deletes that session document. |

## Firestore Collections

**users/{uid}**

```
Fields:
- email
- createdAt
```

**stories/{storyId}**

```
Fields:
- storyId
- title
- category
- description
- storyJsonURL
```

**sessions/{userId_storyId}**

```
Fields:
- userId
- storyId
- currentSceneId
- visitedSceneIds
- isCompleted
- updatedAt
```

## Story Data

Story content is hosted on JSONBin.io as JSON files. Each Firestore story document holds the URL to its corresponding bin. The app fetches and decodes the JSON at playthrough start using URLSession and Swift Codable.

Each story JSON contains a scene tree where each scene has text and a list of choices. Each choice points to the next scene by ID. A scene with no choices is an ending.

## Setup

1. Clone the repository
2. Open `story-weave.xcodeproj` in Xcode
3. Add your own `GoogleService-Info.plist` from Firebase Console
4. Add your JSONBin API key in `StoryAPIService.swift`
5. Populate Firestore with story documents pointing to your JSONBin bins
6. Build and run on iOS 16 or later
