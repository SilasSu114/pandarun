# 0001 - Preserve Demo as Hidden Legacy Scene

## Status

Accepted

## Context

The tutorial demo was built and verified, but the project is now moving into its formal phase. The team wants to keep the demo as a discoverable easter egg without letting it interfere with the formal levels.

## Decision

Copy the verified Demo into `projects/godot-gravity-main` as a hidden legacy scene. The formal project will be self-contained and will not reference the original Demo folder. The main menu will expose it through a low-key `OLD_SCAN.EXE` desktop entry.

## Consequences

- The formal project can be packaged and shared independently.
- The Demo remains playable as a hidden reward.
- Any future changes to the original Demo folder do not accidentally affect the formal project.
- Some Demo scripts are duplicated inside the formal project, so later changes must be made carefully.
