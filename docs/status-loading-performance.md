# Status loading optimization

## Observed on the connected device

The captured log on September 12 shows:

- 18:27:47.133: status loading begins.
- 18:27:47.587: a second load begins before the first finishes.
- 18:27:51.860: directory listing returns.
- 18:27:52.116: caching finishes with 85 files (already cached in this run).

That is approximately five seconds to complete, dominated by directory enumeration. Overlapping requests prevent attributing the directory result to exactly one request. The log also reports skipped frames; it does not establish a single cause for every dropped frame.

DocMan's directory listing maps every DocumentFile through property getters. The replacement queries document ID, name, MIME type, size, and modification time together in one ContentResolver cursor on a worker thread.

## Changes

- Separate regular/business cache indexes publish valid cached paths before querying the provider.
- The fresh directory result reconciles removed or modified entries.
- New files are copied by at most three workers. The first completed copy is published immediately, then subsequent batches update the grid.
- Cached copies are keyed by source URI, modification time, and size, with atomic writes. Original filenames are preserved for saving/sharing and auto-save compatibility.
- Duplicate loads are coalesced. Source switches invalidate old UI results and schedule the next source after the previous load finishes.
- Analytics no longer delays publication of status results.
- Grid image decoding is capped at 600 pixels wide instead of decoding every source at full resolution.
- New cache files can be cleared with the existing cache-clear action; old unused versions are pruned.

## Verification remaining

Dart formatting and diff whitespace checks completed. A device build, tests, and new timing measurements have not been run. Repository rules prohibit builds/analyzer/test suites without an explicit command request.

The Android method channel requires a full rebuild (`flutter run`), not hot reload. Once rebuilt, compare `[statuses] cached_first_ms`, `directory_ms`, `first_batch_ms`, and `complete_ms` in logcat for cold and warm loads. These measure publication, not actual rendered-frame timing. Check regular/business switching, permission revocation, pull-to-refresh, and clearing the cache during a scan.

Warm-load publication should avoid the directory-query delay. A cold load still depends on the document provider and storage throughput; no sub-second device result has yet been measured. The first rebuilt run creates the new source-specific index.
