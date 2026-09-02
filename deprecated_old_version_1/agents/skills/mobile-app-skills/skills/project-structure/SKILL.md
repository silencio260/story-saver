---
name: project-structure
description: Preferred Flutter project structure — no src/ folder, feature-based organization under lib/features/ following Clean Architecture layers
---

# Project Structure Skill

## Overview
This skill defines the preferred project structure for the Flutter application, ensuring consistency and adherence to architectural preferences.

## Critical Rules
1. **NO `src/` FOLDER**: Do NOT use a `src/` folder inside `lib/`. All main source code components (`core/`, `features/`, `config/`, etc.) MUST reside directly under `lib/`.
2. **Feature-Based Organization**: Group code by features under `lib/features/`, following Clean Architecture layers (presentation, domain, data).
3. **Core components**: Shared utilities and base classes MUST be in `lib/core/`.
4. **No Code Generation**: Avoid using `build_runner` or similar tools unless absolutely necessary. Prefer manual implementations (e.g., Hive adapters).
5. **API vs Network Separation**: Always separate high-level business protocol from low-level network plumbing:
    - `lib/core/api/`: Centralized endpoints (`api_endpoints.dart`) and response modeling (`api_response.dart`).
    - `lib/core/network/`: Low-level infrastructure (Dio instances, Interceptors, Connectivity checks).

## Import Conventions
- Prefer `package:note_ai/...` imports over relative imports when crossing feature boundaries.
- Never use `import 'src/...'`.
