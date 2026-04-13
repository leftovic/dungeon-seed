# Task 010 — Build core game loop orchestration

Complexity: 13
Dependencies: Tasks 6,7,8,9

Description:
Implement the central loop manager coordinating planting, growth tick processing, dispatch, run resolution, and loot harvesting. Ensure robustness across saves/loads and interruption.

Acceptance Criteria:
- Loop manager handling idle and active runs
- Correct state transitions and edge-case handling
- Integration tests for end-to-end loop
