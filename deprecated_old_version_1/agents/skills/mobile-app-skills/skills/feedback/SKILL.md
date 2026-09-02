---
name: feedback
description: User feedback submission via email or Feedback Nest API
---

# Feedback

## Overview

Feedback allows users to submit app feedback. Supports two modes: email (default) or Feedback Nest API. Configured during starter kit initialization.

## Implementation

### Setup

```dart
await StarterKit.initialize(
  supportEmail: 'support@yourapp.com',
  // OR use Feedback Nest API:
  feedbackNestApiKey: 'YOUR_API_KEY',
);
```

### Submit Feedback

```dart
final feedbackRepo = StarterKit.sl<FeedbackRepository>();
final result = await feedbackRepo.submitFeedback(
  'This app is amazing!',
  email: 'user@example.com',
);
result.fold(
  (failure) => showError(failure.message),
  (_) => showSuccess('Feedback sent!'),
);
```

## Interaction Map

- **Settings** → Feedback tile triggers feedback screen
- **Analytics** → Log `feedback_submitted` event

## Checklist

- [ ] Support email or Feedback Nest API key configured
- [ ] Feedback submission UI created
- [ ] Success/error feedback shown to user
