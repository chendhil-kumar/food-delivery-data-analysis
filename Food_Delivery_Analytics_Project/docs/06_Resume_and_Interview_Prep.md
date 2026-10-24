# Step 7 - Resume Description and Interview Preparation

## Resume project description (pick one version)
**Short (2 lines):**
> **Food Delivery Data Analysis | Excel, MySQL, Power BI** - Cleaned a 3,057-row order dataset (removed 120 duplicate/invalid rows), wrote 25 SQL queries, and built a 3-page Power BI dashboard with DAX measures. Found that Cash on Delivery orders cancel at 10.5% vs 5% for UPI, and that orders slower than 45 minutes score about 0.3 stars lower.

**Detailed (bullets):**
- Built an end-to-end analytics project on a synthetic Swiggy/Zomato-style dataset (Indian cities, Rs) covering 2,937 clean orders, 8 cities, 32 restaurants and 1,258 customers.
- **Excel:** Standardised city/restaurant/payment values with TRIM + INDEX-MATCH lookups, converted 3 mixed date formats, flagged invalid prices/quantities/ratings, and documented every cleaning decision in a log with before/after row counts.
- **MySQL:** Wrote 25 queries (GROUP BY, HAVING, CASE WHEN, JOINs, subqueries, window functions) for sales, AOV, cancellations, repeat customers and peak hours.
- **Power BI:** Designed a star-schema model and 3 interactive dashboards with 9 DAX measures and slicers; applied a clear business rule (sales = delivered orders only).
- Delivered recommendations: prepaid incentives for COD, dinner-hour rider capacity, and quality audits for high-revenue/low-rated restaurants.

**Skills line:** Excel (XLOOKUP/INDEX-MATCH, COUNTIFS, SUMIFS, PivotTables, Conditional Formatting), MySQL, Power BI, DAX, data cleaning, data storytelling.

## 5 interview questions with model answers

**Q1. Walk me through your project in 60 seconds.**
"I built an end-to-end analysis of food-delivery orders. The data is synthetic because order-level Swiggy/Zomato data is not public, but I modelled it on real patterns and injected real-world problems. In Excel I cleaned 3,057 rows to 2,937 - removing 45 duplicates and 75 invalid or unidentifiable rows, standardising names and dates. I loaded the clean data into MySQL and wrote 25 queries, then built a three-page Power BI dashboard on a star schema with DAX measures. Key findings: sales were Rs 12 lakh with an average order value of Rs 435; Mumbai had the highest sales; 6% of orders were cancelled, and Cash on Delivery was double the card rate. I recommended prepaid incentives and more dinner-time rider capacity."

**Q2. How did you handle duplicates, and are duplicate Order IDs always removed?**
"I separated two cases. Exact duplicate rows - 45 - were safe to delete. Duplicate Order IDs with different details - 12 - needed a rule, because an order must exist once but I had to choose which record is correct. In my data the later row had the rating filled in, so I kept the more complete row and logged the rule. In a real job I would confirm with the data owner. I also checked afterwards that Order IDs are unique, in Excel and in SQL, so counts and sales are not double-counted."

**Q3. How do you define sales and average order value, and why?**
"Sales is quantity times price minus discount, summed over Delivered orders only, because cancelled orders earn no money. AOV is that sales figure divided by delivered orders, giving Rs 434.83. Cancellation rate is cancelled divided by all orders, 6.06%. Including cancelled orders would have overstated sales by about Rs 70,000 (Rs 12.7 lakh versus Rs 12.0 lakh). I wrote the rule once and used it identically in Excel SUMIFS, SQL WHERE and DAX CALCULATE, and my totals matched across all three."

**Q4. What is the difference between WHERE and HAVING, and between a measure and a calculated column?**
"WHERE filters rows before grouping; HAVING filters groups after aggregation - for example, in my query for best-rated restaurants I used HAVING COUNT(customer_rating) >= 30 so restaurants with few ratings are excluded. In Power BI a calculated column is computed per row when data loads and is stored - I used it for the Is Delivered flag and Time of Day. A measure is calculated on the fly in the current filter context - I used measures for Total Sales and Cancellation Rate, so they change with slicers."

**Q5. What was your most interesting insight and what would you recommend?**
"Cancellations. Overall 6.06%, but Cash on Delivery was 10.45% against 3.81% for debit cards and 5.13% for UPI. COD orders have no prepayment, so customers cancel more easily. I recommended small prepaid incentives and confirmation for high-value COD orders; closing the gap to the UPI rate would save roughly 26 orders in this data. I would test it with an A/B experiment before rolling out, and I would validate the pattern on real data since mine is synthetic."

## Extra questions to be ready for
- *Why synthetic data?* Order-level data is not public; I was transparent and used realistic benchmarks (AOV near Rs 428).
- *How did you treat missing delivery time?* Kept NULL, not 0, because 0 would reduce the average; AVG/AVERAGE ignore blanks.
- *INNER vs LEFT JOIN?* Inner keeps only matches; left keeps all rows of the left table even without a match.
- *What is a star schema?* One fact table (Orders) surrounded by dimension tables (Date, City, Restaurants); relationships are one-to-many; it prevents double counting.
- *What would you improve?* Add delivery distance, rider data, menu items and customer sign-up dates for cohort and retention analysis; use real data.
- *How did you validate results?* Cross-checked Excel formulas vs a Python recalculation (0 row mismatches), and SQL vs Power BI totals using the self-check table.

## Tips for sounding confident
1. Know your 9 headline numbers by heart (see `docs/05_Business_Insights.md`).
2. Always state the business rule before the number.
3. When unsure, say how you would check it ("I would run a GROUP BY to verify").
4. Admit limitations (synthetic data, one year only, no delivery fees/taxes).
