# DAG Resolution Algorithm Reference

## Overview

Resolve step execution order using Kahn's topological sort algorithm. Detect cycles, identify parallel execution batches, and handle diamond dependency patterns.

## Kahn's Topological Sort

### Algorithm

```
1. Compute in-degree for each step (count of depends_on entries)
2. Initialize queue with all steps where in-degree = 0 (root nodes)
3. Initialize execution_order = []
4. While queue is not empty:
   a. Remove a step from queue -> current
   b. Append current to execution_order
   c. For each step that depends on current:
      - Decrease its in-degree by 1
      - If in-degree reaches 0, add to queue
5. If len(execution_order) < total_steps:
   - Cycle detected! Steps not in execution_order form the cycle.
6. Return execution_order
```

### Cycle Detection

After the sort completes, compare the length of execution_order against the total step count. If they differ, a cycle exists. Identify the cycle by collecting all steps NOT present in execution_order -- these form the cyclic subgraph.

Report cycle errors with the step IDs involved:

```
Error: Circular dependency detected among steps: [step-a, step-b, step-c]
Fix: Remove one dependency to break the cycle.
```

### Parallel Batch Identification

Group steps that could execute concurrently (same topological level):

```
1. Assign level 0 to all root nodes (in-degree = 0)
2. For each step, level = max(level of dependencies) + 1
3. Steps sharing the same level form a parallel batch
```

Note: Claude executes steps sequentially within each batch. Batch grouping is for display purposes (showing which steps are independent) and potential future parallel execution.

## Worked Examples

### Example 1: Linear Pipeline

```
A -> B -> C -> D
```

In-degrees: A=0, B=1, C=1, D=1
Execution order: [A, B, C, D]
Batches: [[A], [B], [C], [D]]

### Example 2: Parallel Roots

```
A ---\
      +--- C -> D
B ---/
```

In-degrees: A=0, B=0, C=2, D=1
Execution order: [A, B, C, D] or [B, A, C, D]
Batches: [[A, B], [C], [D]]

### Example 3: Diamond Pattern

```
    A
   / \
  B   C
   \ /
    D
```

In-degrees: A=0, B=1, C=1, D=2
Execution order: [A, B, C, D] or [A, C, B, D]
Batches: [[A], [B, C], [D]]

### Example 4: Cycle (Error)

```
A -> B -> C -> A
```

In-degrees: A=1, B=1, C=1
No root nodes (no step with in-degree 0)
Queue starts empty -> execution_order = []
Cycle detected: [A, B, C]

### Example 5: Complex DAG

```
    A
   / \
  B   C
  |   |
  D   E
   \ / \
    F   G
```

In-degrees: A=0, B=1, C=1, D=1, E=1, F=2, G=1
Execution order: [A, B, C, D, E, F, G]
Batches: [[A], [B, C], [D, E], [F, G]]

## Handling Failed Dependencies

When a step fails and stop_on_error applies:

- All steps that transitively depend on the failed step are marked as "skipped"
- Compute the transitive closure of the dependency graph from the failed step
- Steps in independent branches (no path from failed step) continue execution if stop_on_error=false at workflow level
