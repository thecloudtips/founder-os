---
name: intelligence-learning
description: Learning cycle for the Adaptive Intelligence Engine. Implements the Observe-Retrieve-Judge-Distill-Consolidate-Apply cycle for detecting and applying user preference patterns.
---

## Overview

The learning system detects patterns in user behavior and plugin outcomes, then injects learned preferences into future plugin runs. It operates in three tiers shipped sequentially:

1. **Taste Learning** (Tier 1) — output preference detection
2. **Workflow Optimization** (Tier 2) — plugin chain detection
3. **Confidence-Gated Autonomy** (Tier 3) — graduated trust

## The Cycle

```
OBSERVE → RETRIEVE → JUDGE → DISTILL → CONSOLIDATE → APPLY
   ↑                                                    │
   └────────────────── feedback ─────────────────────────┘
```

| Stage | What Happens | When |
|---|---|---|
| **Observe** | Hooks capture events | During command run |
| **Retrieve** | Pull relevant past patterns | Before next run |
| **Judge** | Compare outcome to patterns | After post_command |
| **Distill** | Extract generalizable insight | After 3+ observations |
| **Consolidate** | Store with confidence score | After distillation |
| **Apply** | Inject as instruction | Before next matching run |

## Confidence Mechanics

- Formula: `confirmations / max(1, confirmations + rejections * 2)`
- New patterns start at confidence 0.0 (candidate)
- Applied when confidence >= threshold AND observations >= 3
- Rejections weigh double to prevent bad patterns from persisting

## Pattern Lifecycle

```
candidate (conf < 0.5) → active (conf >= 0.5, auto-applied with notice)
                       → approved (user /intel:approve, conf locked at 1.0)
                       → rejected (user rejected or conf < 0.3)
```

## Applying Patterns

When a plugin command runs:
1. Query patterns table for matching plugin + command (or cross-plugin patterns)
2. Filter to status IN ('active', 'approved')
3. For each matching pattern, inject its `instruction` text into the command context
4. Notify user: `[Intel] Applying learned preference: "{description}"`

## Cross-Plugin Promotion

Patterns referencing a Company or Contact are promoted to the Memory Engine:
- taste + company → Memory Engine category `preference`
- workflow → Memory Engine category `workflow`
- Confidence conversion: `round(confidence * 100)`
