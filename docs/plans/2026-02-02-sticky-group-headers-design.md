# Sticky Group Headers on Home Page

Date: 2026-02-02

## Context
The home page renders clipboard items grouped by time (e.g., today, yesterday, older). The list is built with a `CustomScrollView` that interleaves a group header and a `SliverGrid` per group. The request is to make only the group headers stick to the top while content continues to scroll normally.

## Goals
- Keep time grouping as-is.
- Make the current group header stick at the top and be replaced by the next header when it reaches the top.
- Provide an opaque header background so scrolling content is not visible underneath.

## Non-goals
- No changes to grouping logic, data sources, or persistence.
- No custom scroll math or overlay-based stickiness.

## Recommended Approach
Use Flutter's native sliver pinning:
- Replace each `SliverToBoxAdapter` header with `SliverPersistentHeader(pinned: true)`.
- Provide a small `SliverPersistentHeaderDelegate` that returns a fixed-height header widget.
- Use a solid background color (theme surface) plus a subtle bottom divider.

This keeps the existing sliver-based architecture and avoids manual scroll handling.

## UI Structure
For each group:
1. `SliverPersistentHeader` (pinned) with fixed height.
2. `SliverGrid` containing the group's items.

The existing top padding under the custom app bar remains unchanged, so pinned headers sit just below it.

## Data Flow
No changes. `PboardProvider` still produces `groupedItems`, and `PasteboardGridView` iterates `groups.entries` to build slivers. Dart map insertion order preserves the group order as generated.

## Styling
- Header height: fixed (e.g., 36-44 px).
- Horizontal padding: align with grid (`spec.gridPadding` plus existing spacing).
- Background: opaque surface color (theme-based) to mask underlying content.
- Optional divider: 1 px with low alpha to hint separation when pinned.

## Error Handling
None required beyond existing error states. If a group is empty (unlikely), the header still renders safely. Unknown dates already map to a safe label (e.g., "Unknown").

## Testing
Manual verification:
1. Scroll: header sticks to top while its group is visible.
2. Next header replaces current at the top.
3. No overlap with the app bar (padding preserved).
4. Light/dark themes show a proper opaque header background.

(Optional) Add a widget test that pumps two groups, scrolls, and asserts the pinned header text at the top of the viewport.
