# Cron Syntax Reference

## Overview
Complete specification for 5-field cron expressions used in workflow scheduling.

## Field Specification

| Position | Field | Range | Special Characters |
|----------|-------|-------|-------------------|
| 1 | Minute | 0-59 | * , - / |
| 2 | Hour | 0-23 | * , - / |
| 3 | Day of Month | 1-31 | * , - / |
| 4 | Month | 1-12 or JAN-DEC | * , - / |
| 5 | Day of Week | 0-7 or SUN-SAT (0 and 7 = Sunday) | * , - / |

## Special Characters

| Character | Meaning | Example | Explanation |
|-----------|---------|---------|-------------|
| `*` | Any value | `* * * * *` | Every minute |
| `,` | Value list | `1,15 * * * *` | Minutes 1 and 15 |
| `-` | Range | `1-5 * * * *` | Minutes 1 through 5 |
| `/` | Step | `*/15 * * * *` | Every 15 minutes |

## Combination Rules
- Lists can contain ranges: `1-5,10-15 * * * *` (minutes 1-5 and 10-15)
- Steps apply to ranges: `0-30/10 * * * *` (minutes 0, 10, 20, 30)
- Steps apply to wildcards: `*/5 * * * *` (every 5 minutes)

## Named Values

### Months
JAN=1, FEB=2, MAR=3, APR=4, MAY=5, JUN=6, JUL=7, AUG=8, SEP=9, OCT=10, NOV=11, DEC=12

### Days of Week
SUN=0, MON=1, TUE=2, WED=3, THU=4, FRI=5, SAT=6 (SUN also = 7)

## Common Patterns

| Description | Expression | Next runs (from Mon 9 AM) |
|-------------|-----------|---------------------------|
| Every minute | `* * * * *` | 9:01, 9:02, 9:03 |
| Every 5 minutes | `*/5 * * * *` | 9:05, 9:10, 9:15 |
| Every 15 minutes | `*/15 * * * *` | 9:15, 9:30, 9:45 |
| Every 30 minutes | `*/30 * * * *` | 9:30, 10:00, 10:30 |
| Every hour | `0 * * * *` | 10:00, 11:00, 12:00 |
| Every 2 hours | `0 */2 * * *` | 10:00, 12:00, 14:00 |
| Daily at 9 AM | `0 9 * * *` | Tue 9:00, Wed 9:00 |
| Weekdays at 9 AM | `0 9 * * 1-5` | Tue 9:00, Wed 9:00 |
| Weekends at 10 AM | `0 10 * * 0,6` | Sat 10:00, Sun 10:00 |
| Monday at 8 AM | `0 8 * * 1` | Next Mon 8:00 |
| Mon, Wed, Fri at 9 AM | `0 9 * * 1,3,5` | Wed 9:00, Fri 9:00 |
| Twice daily (9 AM, 5 PM) | `0 9,17 * * *` | Mon 17:00, Tue 9:00 |
| First of month at 10 AM | `0 10 1 * *` | Apr 1 10:00 |
| Every quarter (1st of Jan/Apr/Jul/Oct) | `0 10 1 1,4,7,10 *` | Apr 1 10:00 |

## Validation Rules

### Field Count
- Must have exactly 5 space-separated fields
- 6 fields (with seconds): reject with message "Only 5-field cron format supported (no seconds)"
- Fewer than 5 fields: reject with message "Cron expression requires 5 fields"

### Range Validation
- Minute value > 59: reject
- Hour value > 23: reject
- Day of month value > 31 or < 1: reject
- Month value > 12 or < 1: reject
- Day of week value > 7: reject

### Step Validation
- Step value must be > 0: `*/0` is invalid
- Step value should not exceed field range: `*/60` in minute field is invalid

### Warning Conditions
- Interval < 5 minutes: warn "Schedule runs very frequently (every N minutes). This may be excessive."
- Day 29-31 with specific month: warn "This date doesn't exist in all months"
- `* * * * *` (every minute): warn "Running every minute is not recommended"

## Edge Cases

### February 29-31
- `0 9 29 2 *`: runs only in leap years on Feb 29
- `0 9 30 2 *`: never runs (Feb never has 30 days)
- `0 9 31 2 *`: never runs

### Day of Month + Day of Week
- When both day-of-month and day-of-week are specified (not *), most cron implementations use OR logic
- `0 9 15 * 1`: runs on the 15th of every month AND every Monday
- Recommend avoiding this combination for clarity

### DST Transitions
- Spring forward: 2 AM may not exist — cron job may skip or run at adjusted time
- Fall back: 2 AM may occur twice — cron job may run twice
- Recommend scheduling at times that avoid 2-3 AM in DST-observing timezones
