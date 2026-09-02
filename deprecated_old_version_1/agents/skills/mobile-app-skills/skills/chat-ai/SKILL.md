---
name: chat-ai
description: Chat UI with AI streaming, message history, Firebase backend, and Genkit Cloud Functions
---

# Chat / AI

## Overview

The chat feature provides a conversational AI interface with real-time streaming responses. Messages are stored in Firestore. The backend uses Firebase Genkit Cloud Functions for AI processing.

## Architecture

```
features/chat/
├── chat_injector.dart
├── data/
│   ├── datasources/
│   │   └── remote/
│   │       └── chat_remote_data_source.dart    # Calls Cloud Functions
│   ├── models/
│   │   ├── message_model.dart
│   │   └── session_model.dart
│   └── repositories/
│       ├── chat_repo.dart
│       └── chat_history_repo.dart              # Firestore persistence
├── domain/
│   ├── entities/
│   │   ├── message_entity.dart
│   │   └── session_entity.dart
│   ├── repositories/
│   │   ├── chat_base_repo.dart
│   │   └── chat_history_base_repo.dart
│   └── usecases/
│       ├── send_message_usecase.dart
│       ├── get_chat_history_usecase.dart
│       └── create_session_usecase.dart
└── presentation/
    ├── bloc/
    │   └── chat_bloc/
    ├── screens/
    │   └── chat_screen.dart
    └── widgets/
        ├── message_bubble.dart
        ├── typing_indicator.dart
        └── chat_input.dart
```

## Firebase / Cloud

**Firestore collections:**
- `chats/{sessionId}` — Session metadata
- `chats/{sessionId}/messages/{messageId}` — Individual messages

**Cloud Functions (Genkit):**
- `chat.flow.ts` — Processes chat messages, returns AI responses
- `system-prompts.ts` — System prompt configuration

## Interaction Map

- **Firebase** → Firestore for persistence, Cloud Functions for AI
- **Auth** → Messages linked to authenticated user
- **Quota** → Rate-limit message sends for free users
- **Analytics** → Log chat sessions, message counts
- **Content Locking** → Gate advanced AI models behind subscription

## Checklist

- [ ] Chat feature folder structure with Clean Architecture
- [ ] Message and session entities/models
- [ ] Firestore persistence for chat history
- [ ] Cloud Function calls for AI responses
- [ ] Streaming response display
- [ ] Typing indicator during AI response
- [ ] Chat input with send button
- [ ] Chat history browsable
- [ ] Quota checks before sending
