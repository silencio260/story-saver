---
name: ide-optimization
description: How to exclude directories from Dart analysis and IDE indexing to improve performance and remove error noise.
---

# IDE Optimization (Excluding Directories)

## Overview

In Flutter projects, some directories (like `/templates`, `/build`, or external packages) can cause "red" error highlights or clutter the IDE's search and indexing. This skill provides the standard way to tell both the Dart Analyzer and the IDE to ignore these directories.

## 1. Excluding from Dart Analyzer

To stop the IDE from showing lint errors or code issues in specific folders, update the `analysis_options.yaml` file in the project root.

### Example: Ignoring a `/templates` folder

```yaml
# analysis_options.yaml
analyzer:
  exclude:
    - "templates/**"
    - "path/to/other/folder/**"
```

> **Note**: The `**` ensures all subdirectories and files within that folder are ignored.

## 2. Excluded from Android Studio / IntelliJ

To prevent the IDE from indexing files (which speeds up search and reduces CPU usage), you can mark a directory as **Excluded**.

### Method A: UI (Recommended)
1. Right-click the folder in the **Project** view.
2. Select **Mark Directory as** -> **Excluded**.

### Method B: Manual Configuration (`.iml` file)
Edit the project's `.iml` file (e.g., `note_ai.iml`) to include an `<excludeFolder>` tag:

```xml
<content url="file://$MODULE_DIR$">
  <excludeFolder url="file://$MODULE_DIR$/templates" />
</content>
```

## 3. Excluding from VS Code

If you use VS Code, you can hide the directory from the file explorer and search results.

### `.vscode/settings.json`
```json
{
  "files.exclude": {
    "templates/": true
  },
  "search.exclude": {
    "templates/": true
  }
}
```

## 4. Excluding from Git

Always ensure excluded directories are also in your `.gitignore` if they shouldn't be tracked.

```text
/templates/
/build/
```

## Best Practices

1. **Only exclude non-source code**: Don't exclude your `/lib` or `/test` folders.
2. **Exclude generated code**: Typically, folders like `.dart_tool/`, `build/`, and `.pub/` are already excluded by default.
3. **Use for templates**: If your project contains template files that don't follow the current project's linting rules, excluding them is the best way to keep your IDE "clean".
