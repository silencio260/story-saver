---
name: image-generation
description: AI image studio with generation, variations, history, and Cloud Function backend
---

# Image Generation

## Overview

The image generation feature provides an AI image studio where users create images from prompts, generate variations, and browse generation history. Backend uses Genkit Cloud Functions.

## Architecture

```
features/image_generation/   # (or within chat feature)
├── data/
│   ├── datasources/remote/
│   │   └── image_gen_remote_data_source.dart
│   ├── models/
│   │   └── generated_image_model.dart
│   └── repositories/
│       └── image_gen_repo.dart
├── domain/
│   ├── entities/
│   │   └── generated_image_entity.dart
│   ├── repositories/
│   │   └── image_gen_base_repo.dart
│   └── usecases/
│       ├── generate_image_usecase.dart
│       └── get_image_history_usecase.dart
└── presentation/
    ├── bloc/image_gen_bloc/
    ├── screens/
    │   ├── image_generator_screen.dart
    │   └── history_screen.dart
    └── widgets/
        ├── style_selector.dart
        ├── ratio_selector.dart
        └── image_preview.dart
```

## Firebase / Cloud

- **Cloud Functions:** `image-generate.flow.ts` — Takes prompt, style, ratio → returns image URL
- **Cloud Storage:** `images/generated/{userId}/{imageId}.png`
- **Firestore:** `images/{imageId}` — Generation metadata

## Interaction Map

- **Firebase** → Cloud Functions for generation, Storage for images, Firestore for metadata
- **Quota** → Rate-limit generations for free users
- **Content Locking** → Gate styles/features behind subscription
- **Analytics** → Log generation events, styles used
- **Offline/Caching** → Cache generated images locally

## Checklist

- [ ] Image generation feature structure created
- [ ] Cloud Function endpoint for generation
- [ ] Style and ratio selectors implemented
- [ ] History screen with cached images
- [ ] Variation generation support
- [ ] Quota checks before generation
