---
name: Data Analysis
description: "Transforms structured data into quantitative findings, trends, and insights. Activates when the user wants to analyze data, find trends, calculate metrics, compare groups, detect outliers, or asks 'what does this data tell us?' Covers descriptive statistics, time-series trends, correlation analysis, outlier detection, and data quality assessment."
globs:
  - "teams/agents/analysis-agent.md"
---

## Overview

Transform structured data received from the Research Agent into quantitative findings, trends, and actionable insights. Operate on tabular data (rows and columns extracted from CSV, JSON, or Notion databases) and produce a structured JSON payload that the Writing Agent consumes to generate report prose. Follow this analytical sequence: validate data quality first, compute descriptive statistics, detect trends, perform comparative analysis, identify outliers, assess correlations, and assemble the output schema. Never skip the data quality step -- downstream agents depend on knowing which fields are reliable. Treat every dataset as potentially messy: expect missing values, mixed types, and inconsistent formatting.

## Descriptive Statistics

Compute the following measures for every numeric column in the dataset. Skip non-numeric columns for statistical calculations but still report their cardinality and mode.

### Core Measures

- **Count**: Total number of non-null values in the column. Report null count separately.
- **Sum**: Arithmetic total. Use only for additive measures (revenue, units, hours). Never sum ratios, percentages, or scores without explicit context.
- **Mean**: Arithmetic average. Report to two decimal places. Flag when the mean is heavily influenced by outliers (difference between mean and median exceeds 20% of the mean).
- **Median**: Middle value when sorted. Prefer median over mean for skewed distributions. Always report both so the Writing Agent can choose the appropriate measure.
- **Mode**: Most frequently occurring value. Report for both numeric and categorical columns. When multiple modes exist (multimodal distribution), report all modes up to a maximum of three. For continuous numeric data with no repeated values, report mode as "N/A -- continuous distribution."
- **Standard Deviation**: Measure of spread around the mean. Use population standard deviation (N) for complete datasets and sample standard deviation (N-1) when the data represents a sample. Default to sample standard deviation unless the dataset is explicitly described as a complete population.
- **Min / Max**: Smallest and largest values. Report the actual data points, not theoretical bounds.
- **Percentiles**: Compute the 25th (Q1), 50th (Q2/median), 75th (Q3), 90th, and 95th percentiles. Use linear interpolation when the percentile falls between two data points. Percentiles are essential for understanding distribution shape and feeding into outlier detection.

### Non-Numeric Fields

For text, date, and categorical columns:
- Report distinct value count (cardinality).
- Report the mode (most common value) and its frequency as a percentage of total rows.
- For date columns, report the earliest date, latest date, and date range span in days.
- For text columns with low cardinality (fewer than 20 distinct values), treat as categorical and produce a frequency table sorted by count descending.

### When to Use Each Measure

- Use **mean** for normally distributed data without extreme outliers (e.g., average deal size across a balanced portfolio).
- Use **median** when distribution is skewed or outliers are present (e.g., median response time when a few tickets took weeks).
- Use **mode** for categorical analysis or to identify the most common scenario (e.g., most frequent expense category).
- Use **sum** for totals that stakeholders need to see in aggregate (e.g., total revenue, total hours logged).
- Use **standard deviation** to communicate variability and risk (e.g., revenue volatility across months).
- Use **percentiles** to define thresholds and SLA targets (e.g., 95th percentile response time).

## Trend Analysis

Detect patterns over time. Require a date or timestamp column to perform trend analysis. When no time column is present, skip this section and note "No temporal dimension available" in the output.

### Time-Series Detection

1. Identify the time column by scanning for date, datetime, timestamp, or epoch-formatted fields. When multiple time columns exist, prefer the one labeled "date", "created_at", "timestamp", or "period."
2. Sort all rows by the time column ascending.
3. Determine the natural granularity of the data: daily, weekly, monthly, quarterly, or yearly. Use the median interval between consecutive data points to infer granularity.

### Period-over-Period Comparison

Compute the following comparisons when sufficient data exists:

- **Month-over-Month (MoM)**: Percentage change from the previous month. Require at least 2 months of data.
- **Quarter-over-Quarter (QoQ)**: Percentage change from the previous quarter. Require at least 2 quarters of data.
- **Year-over-Year (YoY)**: Percentage change from the same period in the prior year. Require at least 13 months of data.

Calculate percentage change as: `((current - previous) / |previous|) * 100`. When the previous period value is zero, report the change as "N/A -- division by zero" rather than infinity.

### Growth Rates

- **Simple growth rate**: Percentage change between first and last period.
- **Compound growth rate (CAGR)**: Use the formula `(end_value / start_value)^(1/n_periods) - 1` for annualized growth over multiple periods. Require at least 3 periods for CAGR to be meaningful.

### Moving Averages

Compute a simple moving average (SMA) using a window appropriate to the data granularity:
- Daily data: 7-day and 30-day SMA.
- Weekly data: 4-week SMA.
- Monthly data: 3-month and 12-month SMA.
- Quarterly data: 4-quarter SMA.

Use moving averages to smooth noise and reveal underlying trends. Report both the raw values and the smoothed values so downstream agents can choose the appropriate representation for charts.

### Seasonal Patterns

Detect recurring patterns at regular intervals. Compare each period to the same period in prior cycles (e.g., January to January, Q1 to Q1). Flag seasonal effects when the same directional change occurs in the same period across at least 2 cycles. Report seasonal patterns as: "Metric X shows a recurring [increase/decrease] in [period], observed across [N] cycles."

### Trend Direction Classification

Classify each metric's overall trend using the slope of a linear regression fit:
- **Increasing**: Positive slope with R-squared >= 0.3.
- **Declining**: Negative slope with R-squared >= 0.3.
- **Stable**: Absolute slope near zero or R-squared < 0.3 (no meaningful linear relationship).
- **Volatile**: Standard deviation of period-over-period changes exceeds 50% of the mean absolute change.

Report the classification, the slope value, and the R-squared value for transparency.

## Comparative Analysis

Compare groups, segments, or categories within the data. Require at least one categorical column to perform comparative analysis.

### Cross-Group Comparisons

1. Identify categorical columns suitable for grouping (cardinality between 2 and 50).
2. For each numeric metric, compute the mean, median, sum, and count per group.
3. Calculate each group's share of the total (percentage breakdown).
4. Rank groups by each metric, highest to lowest.

### Top-N and Bottom-N

- Report the top 5 and bottom 5 entries for each key metric.
- When the dataset has fewer than 10 entries, report all entries ranked.
- Include the actual value and the percentage of total for each entry.

### Relative Performance Metrics

- **Index to average**: Express each group's value as a percentage of the overall average (100 = average, 150 = 50% above average).
- **Rank percentile**: Express each group's position as a percentile within the full set.
- **Gap analysis**: Calculate the difference between the top performer and the median performer, and between the median and the bottom performer. Express gaps in both absolute and percentage terms.

## Aggregation & Grouping

Perform structured aggregation operations to produce summary tables suitable for report consumption.

### Group-By Operations

- Group by single columns and compute aggregate functions (sum, mean, median, count, min, max) for all numeric columns.
- When multiple categorical dimensions exist, produce cross-tabulations (pivot-style) for the two most analytically interesting dimensions. Select dimensions by highest variance in the resulting aggregates.

### Multi-Level Aggregation

- Support hierarchical grouping (e.g., Region > Country > City) when the data contains nested categorical columns.
- Compute subtotals at each level and a grand total.
- Report the contribution of each sub-group to its parent group as a percentage.

### Weighted Averages

- When a weight column is specified or identifiable (e.g., "count", "volume", "weight"), compute weighted averages instead of simple averages.
- Always report whether an average is weighted or unweighted.
- Common use case: computing average price weighted by transaction volume, or average score weighted by response count.

## Outlier Detection

Identify data points that deviate significantly from the expected pattern. Apply two complementary methods and flag a point as an outlier only when at least one method triggers.

### Z-Score Method

1. Compute the mean and standard deviation for each numeric column.
2. Calculate the Z-score for each value: `Z = (value - mean) / standard_deviation`.
3. Flag values with `|Z| > 3` as strong outliers and `|Z| > 2` as mild outliers.
4. Do not apply the Z-score method to columns with fewer than 30 data points -- sample sizes below 30 produce unreliable Z-scores.

### IQR Method

1. Compute Q1 (25th percentile) and Q3 (75th percentile).
2. Calculate the interquartile range: `IQR = Q3 - Q1`.
3. Define fences: lower fence = `Q1 - 1.5 * IQR`, upper fence = `Q3 + 1.5 * IQR`.
4. Flag values outside the fences as outliers. Values beyond `Q1 - 3 * IQR` or `Q3 + 3 * IQR` are extreme outliers.
5. Prefer the IQR method for small datasets (fewer than 30 points) and for skewed distributions.

### Contextual Outliers

Not all statistical outliers are anomalies. Apply domain context before flagging:
- A December revenue spike may be seasonal, not anomalous.
- A single large invoice in a dataset of small invoices may be legitimate.
- Report all statistical outliers but annotate them with context: "Flagged by [method]. May be [seasonal / legitimate large transaction / data entry error]. Recommend manual review."

### Anomaly Flagging

For each outlier, produce a record containing:
- The column name and row identifier.
- The outlier value and the expected range (mean +/- 2 SD, or IQR fences).
- The detection method that triggered the flag.
- A severity label: "mild" (2 < |Z| <= 3 or outside 1.5x IQR) or "strong" (|Z| > 3 or outside 3x IQR).

## Data Quality Assessment

Evaluate the dataset's fitness for analysis before computing any metrics. Report quality findings in the `data_quality` section of the output schema.

### Completeness Check

- For each column, count the number of null, empty, or missing values.
- Calculate the completeness percentage: `(non_null_count / total_rows) * 100`.
- Flag columns with completeness below 80% as having significant gaps.
- Flag columns with completeness below 50% as unreliable -- exclude them from trend and correlation analysis but still report their descriptive statistics with a warning.

### Consistency Check

- Verify format uniformity within each column. Detect mixed formats: dates in multiple formats (MM/DD vs DD/MM), numbers stored as strings alongside actual numbers, inconsistent casing in categorical values.
- Report the number and percentage of inconsistent entries per column.
- Suggest normalization actions: "Column 'date' contains 3 format variations; recommend standardizing to ISO 8601."

### Validity Check

- Identify values that fall outside expected ranges. Detect negative values in columns that should be positive (revenue, count), dates in the future for historical data, percentages outside 0-100.
- Report the count and examples of invalid entries.
- Exclude invalid entries from statistical calculations and note the exclusion.

### Uniqueness Check

- Identify potential duplicate rows by comparing all columns or a specified key column.
- Report the total number of duplicates and the duplication rate as a percentage.
- When duplicates exist, flag them but do not remove them automatically. Note: "Dataset contains [N] potential duplicate rows ([X]% duplication rate). Metrics computed on full dataset including duplicates."

## Correlation Analysis

Identify relationships between numeric metrics. Require at least 2 numeric columns and at least 10 data points.

### Identifying Related Metrics

- Compute the Pearson correlation coefficient between all pairs of numeric columns.
- Report correlations with `|r| >= 0.5` as notable and `|r| >= 0.7` as strong.
- Present correlations in a ranked list from strongest to weakest, including the direction (positive or negative).

### Co-Movement Patterns

- When time-series data is available, identify metrics that move together over time.
- Compute rolling correlations (window = 50% of time periods, minimum 5 periods) to detect whether correlations are stable or shifting.
- Report metrics whose correlation has changed direction over the analysis period as having an "unstable relationship."

### Leading and Lagging Indicators

- For each pair of correlated metrics, test whether one leads the other by shifting one series forward by 1, 2, and 3 periods and recomputing correlation.
- If a shifted correlation is stronger than the unshifted correlation, report the leading metric, the lagging metric, and the optimal lag period.
- Use case: marketing spend in month N may correlate with revenue in month N+2.

## Output Schema

Assemble all analysis results into the following JSON structure. The Writing Agent consumes this schema to generate report prose. Every field is required; use empty arrays or null values when a section has no findings.

```json
{
  "key_findings": [
    {
      "finding": "string -- one-sentence summary of the insight",
      "metric": "string -- the metric or column name involved",
      "value": "number or string -- the key data point",
      "significance": "high | medium | low",
      "evidence": "string -- supporting data points or calculation"
    }
  ],
  "trends": [
    {
      "metric": "string -- column name",
      "direction": "increasing | declining | stable | volatile",
      "period": "string -- time range analyzed",
      "growth_rate": "number -- percentage change over period",
      "details": "string -- additional context (MoM, QoQ, seasonality)"
    }
  ],
  "metrics": {
    "<column_name>": {
      "count": "number",
      "sum": "number | null",
      "mean": "number | null",
      "median": "number | null",
      "mode": "value | null",
      "std_dev": "number | null",
      "min": "number | null",
      "max": "number | null",
      "percentiles": { "p25": "number", "p50": "number", "p75": "number", "p90": "number", "p95": "number" }
    }
  },
  "comparisons": [
    {
      "dimension": "string -- categorical column used for grouping",
      "groups": [
        {
          "name": "string -- group label",
          "metrics": { "<metric_name>": "number" },
          "rank": "number",
          "share_pct": "number"
        }
      ],
      "top_performers": ["string -- group names"],
      "bottom_performers": ["string -- group names"],
      "gap_analysis": {
        "top_vs_median": "number -- percentage difference",
        "median_vs_bottom": "number -- percentage difference"
      }
    }
  ],
  "correlations": [
    {
      "metric_a": "string",
      "metric_b": "string",
      "coefficient": "number -- Pearson r",
      "strength": "strong | notable | weak",
      "direction": "positive | negative",
      "lead_lag": "string | null -- e.g., 'metric_a leads by 2 periods'"
    }
  ],
  "outliers": [
    {
      "column": "string",
      "row_id": "string or number",
      "value": "number",
      "expected_range": "string -- e.g., '45.2 - 102.8'",
      "method": "z-score | iqr",
      "severity": "mild | strong",
      "context": "string -- annotation"
    }
  ],
  "data_quality": {
    "total_rows": "number",
    "total_columns": "number",
    "completeness": {
      "<column_name>": { "non_null": "number", "total": "number", "pct": "number" }
    },
    "consistency_issues": [
      { "column": "string", "issue": "string", "count": "number" }
    ],
    "validity_issues": [
      { "column": "string", "issue": "string", "count": "number", "examples": ["value"] }
    ],
    "duplicates": { "count": "number", "pct": "number" }
  }
}
```

### Key Findings Priority

Populate `key_findings` with the most impactful insights, ordered by significance. Derive key findings from:
1. Strongest trends (highest absolute growth rates or most consistent direction).
2. Largest outliers or anomalies.
3. Strongest correlations, especially those with lead-lag relationships.
4. Significant data quality issues that could affect report conclusions.
5. Largest gaps in comparative analysis (top vs. bottom performers).

Limit key findings to a maximum of 10 entries. Each finding must be self-contained -- the Writing Agent should be able to construct a paragraph from a single key finding without needing to cross-reference other sections.

## Edge Cases

### Single Data Point

When a column or the entire dataset contains only one row:
- Report count as 1. Set mean, median, min, and max to the single value. Set standard deviation to 0. Set all percentiles to the single value.
- Skip trend analysis entirely -- a single point cannot define a trend.
- Skip correlation analysis -- at least 10 data points are required.
- Skip outlier detection -- a single point cannot be classified as an outlier relative to itself.
- Note in data quality: "Dataset contains a single observation. Statistical measures are descriptive only; no inferential analysis is possible."

### All Identical Values

When every value in a numeric column is the same:
- Report standard deviation as 0. Report IQR as 0.
- Skip outlier detection for this column -- all values are identical, so no value deviates.
- Skip correlation analysis involving this column -- a constant cannot correlate with anything.
- Report trend direction as "stable" with a note: "All values are identical ([value]). No variance detected."
- Flag in key findings only if the uniformity is unexpected given the metric's nature (e.g., all clients with identical revenue warrants attention).

### Mixed Types in Columns

When a column contains a mix of numeric and non-numeric values:
- Attempt type coercion: convert string representations of numbers ("100", "1,234.56") to numeric values.
- After coercion, report the count of successfully converted values and the count of unconvertible values.
- Compute statistics only on the successfully converted numeric values.
- Flag the column in data quality: "Column '[name]' contains mixed types: [N] numeric, [M] non-numeric. Statistics computed on numeric values only."
- When more than 50% of values are non-numeric after coercion, reclassify the column as categorical and apply non-numeric field analysis instead.

### Extremely Skewed Distributions

When the skewness of a distribution is extreme (ratio of mean to median exceeds 2:1 or falls below 1:2):
- Prefer median over mean as the central tendency measure in key findings.
- Report both mean and median with a note: "Distribution is heavily skewed ([direction]). Median ([value]) is more representative than mean ([value])."
- Use the IQR method instead of the Z-score method for outlier detection on skewed columns -- Z-scores assume approximate normality and produce unreliable results on skewed data.
- Consider reporting the geometric mean as an alternative central measure when all values are positive.
- Highlight the skewness in the data quality section so the Writing Agent can contextualize any summary statistics it presents.

### Empty Dataset

When the Research Agent passes an empty dataset (zero rows):
- Populate `data_quality.total_rows` as 0.
- Set all metric values to null.
- Return a single key finding: "Dataset contains no records. Unable to perform analysis. Verify data source configuration and extraction criteria."
- Do not produce trends, comparisons, correlations, or outliers.

### Sparse Time Series

When time-series data has large gaps (missing periods exceed 30% of the expected periods):
- Note the gaps in data quality: "Time series has [N] missing periods out of [M] expected. Gap rate: [X]%."
- Compute moving averages only across available data points -- do not interpolate missing periods.
- Flag trend direction with reduced confidence: "Trend classification based on incomplete time series. [N] of [M] periods available."
- Avoid computing growth rates that span gaps. Instead, compute growth rates for continuous segments and report them separately.
