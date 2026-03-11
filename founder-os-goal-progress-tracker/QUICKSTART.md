# Quick Start

## Create Your First Goal

```
/goal:create "Launch MVP by Q2" --target=2026-06-30 --category=Product --milestones="Design,Build,Test,Ship"
```

## Track Progress

Complete a milestone:
```
/goal:update "Launch MVP" --done="Design" --note="Client approved mockups"
```

Add a new milestone:
```
/goal:update "Launch MVP" --add="Beta testing"
```

For goals without milestones, set progress manually:
```
/goal:update "Reach 50K MRR" --progress=40
```

## Check Status

Quick look at one goal:
```
/goal:check "Launch MVP"
```

Overview of all goals:
```
/goal:check
```

## Generate Reports

Full dashboard with Gantt chart:
```
/goal:report
```

Filter to at-risk goals:
```
/goal:report --status=red
```

Save report to file:
```
/goal:report --output=file --path=monthly-goals.md
```

## Close Goals

Complete a goal:
```
/goal:close "Launch MVP" --note="Shipped to 50 beta users"
```

Archive an old goal:
```
/goal:close "Old initiative" --archive
```

## Understanding RAG Status

| Emoji | Status | Meaning |
|-------|--------|---------|
| 🟢 | Green | On track (progress within 10% of expected) |
| 🟡 | Yellow | At risk (10-25% behind expected) |
| 🔴 | Red | Behind (>25% behind or past deadline) |
| ⚪ | Not Started | No progress data yet |
