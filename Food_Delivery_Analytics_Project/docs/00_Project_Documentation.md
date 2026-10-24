# Project Documentation - Food Delivery Data Analysis

## 1. Problem statement
A food-delivery platform wants to understand where sales come from, how restaurants and cities perform, why orders get cancelled, and how delivery speed affects customer satisfaction - so it can grow sales and improve service.

## 2. Objectives
1. Clean a messy order dataset and document every decision.
2. Answer business questions with SQL.
3. Present KPIs in an interactive Power BI dashboard.
4. Recommend actions backed by numbers.

## 3. Tools
Microsoft Excel (cleaning, formulas, PivotTables) | MySQL 8 (analysis) | Power BI Desktop + DAX (dashboard) | GitHub (portfolio). Python was used only behind the scenes to generate the synthetic dataset and double-check results; you do not need it.

## 4. Data
Synthetic, 2025, 8 cities, 32 fictional restaurants, 9 cuisines. Raw 3,057 rows with injected problems: 45 exact duplicates, 12 conflicting duplicate IDs, mixed city/restaurant/payment spellings, 3 date formats, missing values, impossible prices/quantities/ratings/delivery times. See `01_Dataset_and_Excel_Cleaning_Guide.md`.

## 5. Business rules
| Rule | Definition |
|---|---|
| Net amount | quantity x unit_price - discount_amount |
| Completed order | order_status = Delivered |
| Sales | Sum of net_amount for Delivered orders only |
| AOV | Sales / Completed orders |
| Cancellation rate | Cancelled orders / All orders |
| Valid ranges | quantity 1-10; price Rs 1-1,500; rating 1-5; delivery 5-180 min; discount <= quantity x price |
| Dates | Slash dates are DD/MM/YYYY |

## 6. Method
Raw data > Excel cleaning (flags, lookups, log) > Cleaned CSV > MySQL (3 tables) > Power BI star schema + DAX > Insights > Recommendations.

## 7. Cleaning result
3,057 rows -> 2,937 rows (120 removed). Full table in `01_Dataset_and_Excel_Cleaning_Guide.md` and the workbook `Cleaning_Log` sheet.

## 8. Validation
- Excel helper formulas vs independent Python logic: **0 mismatches across 3,057 rows**.
- SQL results re-run on a live MySQL-compatible database and cross-checked with pandas.
- Order IDs unique in cleaned data (checked in Excel and SQL).
- Excel `Summary` sheet totals = SQL = Power BI self-check values.

## 9. Limitations
Synthetic data (patterns are simulated); one year; no delivery fees, taxes, distance, rider or menu-item data; ratings come from delivered orders only; customer behaviour is simplified.

## 10. Future work
Cohort and retention analysis, delivery-distance analysis, forecasting, A/B test design for COD incentives, repeat on a real public dataset.
