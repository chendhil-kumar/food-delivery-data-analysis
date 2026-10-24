# Step 1 & 2 - Dataset and Excel Data Cleaning Guide

## 1. About the dataset (public vs synthetic - be honest in interviews)

| Item | Detail |
|---|---|
| Type | **SYNTHETIC (practice) data** generated for this project. It is **not** real Swiggy/Zomato data. |
| Why synthetic? | Public Swiggy/Zomato datasets on Kaggle (for example the "Swiggy Restaurants Dataset") list *restaurants* (ratings, cost for two, cuisine). They do **not** contain *order-level* rows (order ID, customer, payment, delivery time, cancellations), which this project needs. Real companies do not publish such data. |
| Realism | Indian cities, rupee prices, meal-time peaks, festive-season uplift, higher cancellation for Cash on Delivery. Average order value (about Rs 435) is calibrated to what Swiggy and Zomato publicly report (about Rs 428 in FY24). |
| Restaurant names | Fictional. Using real brand names with made-up numbers would be misleading. |
| Raw file | `data/raw_food_delivery_orders.csv` - **3,057 rows**, deliberately messy |
| Cleaned file | `data/cleaned_food_delivery_orders.csv` - **2,937 rows** |
| Extra tables | `dim_restaurants.csv` (32 restaurants), `dim_city.csv` (8 cities) for JOINs |

**Say this in an interview:** *"The data is synthetic because order-level food-delivery data is not public. I built it with realistic business patterns and deliberately injected real-world data problems so I could practise the full cleaning workflow."*

**Optional extension:** download the public Kaggle "Swiggy Restaurants Dataset" and do a second mini-project on restaurant ratings/cost/cuisine. Always label which project uses which data.

## 2. Column explanations (simple English)

| Column | Meaning | Rule used |
|---|---|---|
| order_id | Unique ID for one order (ORD10001) | Must be unique |
| order_date | Day order was placed (2025) | Must be a real date |
| order_time | Time of order, 24-hour (HH:MM) | For peak-hour analysis |
| customer_id | Customer's ID (C0001) | Links repeat orders |
| restaurant_name | Restaurant that cooked it | Standard spelling |
| city | Delivery city (8 cities) | Standard spelling |
| cuisine | Type of food | 9 types |
| quantity | Items in the order | 1 to 10 |
| unit_price | Price of one item in Rs | Rs 1 to Rs 1,500 |
| discount_amount | Total Rs discount on the order | Cannot exceed quantity x price |
| net_amount (cleaned file only) | quantity x unit_price - discount_amount | What customer pays for food |
| payment_method | UPI, Credit Card, Debit Card, Cash on Delivery, Wallet, Net Banking, Unknown | Standard spelling |
| order_status | Delivered or Cancelled | 2 values only |
| delivery_time_min | Minutes to deliver | 5 to 180; blank if cancelled |
| customer_rating | Stars 1-5 | Blank if cancelled / not rated |

**Business rule (memorise):** Sales = `net_amount` of **Delivered** orders only. Cancelled orders are not revenue.

## 3. The Excel workbook (`excel/Food_Delivery_Cleaning_Workbook.xlsx`)

Open it and look at the tabs in this order: **README > Data_Dictionary > Raw_Data > Map_Tables > Cleaned_Data > Cleaning_Log > Outlier_Check > Summary > Formula_Lab.**
In `Raw_Data`, columns A-N are the raw data. The **green columns O-AH are helper formulas** that find and fix the problems. Everything is formula-driven, so you can click any cell and read how it works.

> **Golden rule of cleaning:** never edit the raw data. Keep it untouched, do the work on a copy or in helper columns, and keep a log.

### Before you start: opening the CSV safely
Excel may silently convert dates. Use **Data > From Text/CSV**, click **Transform/Edit** (or "Do not detect data types"), and keep `order_date` as **Text**. Then your raw dates stay as they were (2025-03-27, 27/03/2025, 27-Mar-2025) and you can fix them yourself - that is the exercise.

### Task 1 - Identify missing values
**Goal:** know where data is blank.
- Count blanks in a column: `=COUNTBLANK(Raw_Data!A2:A3058)` (see `Cleaning_Log` section C).
- Count blanks in one row: `=COUNTBLANK(A2:N2)` (column Q in `Raw_Data`).
- Highlight them: select A2:L3058 > Home > Conditional Formatting > New Rule > *Use a formula* > `=ISBLANK(A2)` > pick red fill.
- Quick look: Ctrl+G > Special > Blanks.

**Result in this data:** order_id 8, customer_id 7, restaurant_name 5, city 18, payment_method 27, delivery_time 203, rating 463.
**Important thinking:** blank delivery time/rating on a **Cancelled** order is normal (nothing was delivered). Only blanks on **Delivered** orders are real gaps. That is why the orange rule uses `AND(ISBLANK(M2), LEFT(LOWER(TRIM($L2)),6)<>"cancel")`.

### Task 2 - Find and remove duplicate rows (exact copies)
- **Find (formula):** make a key by joining all columns: `=A2&"|"&B2&"|"&C2&...&N2` (column O). Then `=IF(COUNTIF($O$2:O2,O2)>1,"DUP","OK")` (column P). The **expanding range** `$O$2:O2` means row 1's copy is "OK" and later copies are "DUP".
- **Remove (tool):** copy Raw_Data to a new sheet > select data > **Data > Remove Duplicates** > keep all columns ticked > OK. Excel tells you "45 duplicate values found and removed".
- **Result:** 45 exact duplicate rows.

### Task 3 - Duplicate Order IDs: should they be removed?
Not automatically! Two different cases:
1. **Exact copy** (everything the same) - safe to delete (Task 2).
2. **Same Order ID, different details** - an order can exist only once, but you must decide which row is right. Here the second row had the **customer rating filled in** (a later update). Rule used: **keep the row with fewer blanks** (more complete) and drop the other.
- Formula (column R): `=IF(A2="",0,COUNTIFS($A$2:$A$3058,A2,$P$2:$P$3058,"OK"))` = how many non-duplicate rows share this ID.
- Formula (column S): `=IF(OR(A2="",P2="DUP",R2<2),"",IF(Q2=MINIFS($Q$2:$Q$3058,$A$2:$A$3058,A2,$P$2:$P$3058,"OK"),"KEEP","DROP"))`
- **Result:** 12 rows. In real jobs, ask the data owner which record is correct, and **write your rule down**.

### Task 4 - Standardise city, restaurant and payment names
Problem: "bangalore", "Bangalore", "BLR", "Bengaluru " all mean Bengaluru. If you do not fix this, Power BI shows 4 different cities.
**Step 1 - TRIM** removes extra spaces: `=TRIM(F2)`.
**Step 2 - lookup table** (`Map_Tables`): list every spelling next to the correct name.
**Step 3 - lookup formula** (works in all Excel versions):
`=IFERROR(INDEX(Map_Tables!$B$4:$B$18, MATCH(TRIM(F2), Map_Tables!$A$4:$A$18, 0)), "CHECK")`
- MATCH finds the row number of the spelling; INDEX returns the correct name from that row; `0` = exact match (not case-sensitive, so "MUMBAI" = "Mumbai").
- IFERROR shows "CHECK" for a spelling you forgot to add - a safety net.
**Excel 365 version with XLOOKUP:** `=XLOOKUP(TRIM(F2), Map_Tables!A4:A18, Map_Tables!B4:B18, "CHECK")`
**Same idea** for restaurants (column AE), payment (column AF; blank becomes "Unknown": `=IF(TRIM(K2)="","Unknown",...)`) and status (column AG: `=IF(LEFT(LOWER(TRIM(L2)),6)="cancel","Cancelled","Delivered")`).
**Quick alternative for case only:** `=PROPER(TRIM(G2))` turns "NORTH INDIAN" into "North Indian" (used for cuisine).

### Task 5 - Correct date formats and data types
Raw dates come in 3 styles. In Raw_Data column AH:
```
=IF(ISNUMBER(SEARCH("/",B2)),
    DATE(VALUE(RIGHT(B2,4)),VALUE(MID(B2,4,2)),VALUE(LEFT(B2,2))),          <- 27/03/2025 (DD/MM/YYYY)
 IF(MID(B2,5,1)="-",
    DATE(VALUE(LEFT(B2,4)),VALUE(MID(B2,6,2)),VALUE(RIGHT(B2,2))),          <- 2025-03-27
    DATE(VALUE(RIGHT(B2,4)),MATCH(MID(B2,4,3),{"Jan","Feb",...,"Dec"},0),VALUE(LEFT(B2,2)))))  <- 27-Mar-2025
```
LEFT/MID/RIGHT cut the text into day, month, year; DATE() builds a real date. Format the column as `dd-mmm-yyyy`. **Never guess** DD/MM vs MM/DD - in India it is DD/MM/YYYY. Check: a real date is right-aligned and `=ISNUMBER(AH2)` is TRUE.
**Data types:** quantity/price/discount = numbers, order_id/customer_id = text, rating = whole number.

### Task 6 - Identify invalid prices, quantities and ratings
Decide valid ranges first (business rules), then flag:
- Quantity: `=IF(OR(H2<1,H2>10),1,0)` -> 20 rows (0, -1, 25, 40, 60)
- Price: `=IF(OR(I2<=0,I2>1500),1,0)` -> 18 rows (negative, 0, Rs 5,000+)
- Discount: `=IF(J2>H2*I2,1,0)` -> 5 rows (discount bigger than the order)
- Rating: `=IF(AND(N2<>"",OR(N2<1,N2>5)),1,0)` -> 6 rows (0, 6, 7, 9, 10)
- Delivery time: `=IF(AND(M2<>"",OR(M2<5,M2>180)),1,0)` -> 6 rows (negative, 350, 480, 999)
**Decision:** rows with impossible quantity/price/discount are **removed** (we cannot know the true value). Impossible rating / delivery time only invalidate that one field, so the order is **kept** and the field is blanked.

### Task 7 - Handle missing values appropriately
| Field | Decision | Reason |
|---|---|---|
| order_id, customer_id, restaurant_name | Remove row | Cannot be recovered or attributed |
| city | **Recover** from restaurant (each restaurant works in one city) | Reliable, not a guess |
| payment_method | Fill "Unknown" | Do not invent a payment method |
| delivery_time (delivered orders) | Keep blank | Never use 0 - it would pull the average down |
| rating | Keep blank | Never invent ratings; AVERAGE ignores blanks |
Rule of thumb: **fix what you can prove, flag what you cannot, never invent.**

### Task 8 - Unusual values and outliers (`Outlier_Check`)
IQR rule: `Q1 = QUARTILE(range,1)`, `Q3 = QUARTILE(range,3)`, `IQR = Q3 - Q1`, lower fence `= Q1 - 1.5*IQR`, upper fence `= Q3 + 1.5*IQR`. Count outliers with `=COUNTIF(range,">"&fence)`.
**Judgement:** a large order (party of 5 pizzas) is valid but unusual - **keep, but note it**. An order of quantity 60 or price Rs 12,000 is an error - **remove**. Outliers are *investigated*, not blindly deleted.

### Task 9 - Create the separate cleaned dataset
The `Cleaned_Data` sheet holds only rows where `keep_or_drop = KEEP`, with the standardised values from columns AD-AH. Steps in Excel: filter column AC = KEEP > copy visible cells > Paste Special **Values** into a new sheet > copy the clean columns (AD city, AE restaurant, AF payment, AG status, AH date) over the raw ones > add `net_amount` = `=H2*I2-J2`. Save as CSV (UTF-8) for MySQL and Power BI.

### Task 10 - Row counts before and after
| | Rows |
|---|---|
| Before cleaning | **3,057** |
| Exact duplicates removed | 45 |
| Missing order ID | 8 |
| Duplicate order ID (less complete) | 12 |
| Missing customer ID | 7 |
| Missing restaurant | 5 |
| Invalid quantity | 20 |
| Invalid price | 18 |
| Discount > order value | 5 |
| **After cleaning** | **2,937** (120 removed = 3.9%) |
Live version with formulas and a self-check (`OK - matches`) is on the `Cleaning_Log` sheet.

## 4. Formulas you must be able to explain
| Formula | One-line explanation | Example in this project |
|---|---|---|
| IF | Decide: result A if true, else B | `=IF(L2="Delivered","Sale","No sale")` |
| IFERROR | Replace an error with a friendly value | `=IFERROR(INDEX(...),"CHECK")` |
| COUNTIF | Count rows meeting one condition | `=COUNTIF(F:F,"Mumbai")` |
| COUNTIFS | Count with many conditions | `=COUNTIFS(F:F,"Mumbai",M:M,"Delivered")` |
| SUMIF | Add up when one condition is met | `=SUMIF(F:F,"Delhi",K:K)` |
| SUMIFS | Add up with many conditions (the correct sales formula) | `=SUMIFS(K:K,F:F,"Delhi",M:M,"Delivered")` |
| INDEX+MATCH / XLOOKUP | Look up a value from another table | see Task 4 |
| TRIM | Remove stray spaces | `=TRIM(F2)` |
| AVERAGEIFS | Average with conditions | `=AVERAGEIFS(N:N,F:F,"Pune")` |
Every one has a working live example on the `Formula_Lab` sheet.

## 5. PivotTable practice (build these by hand - 10 minutes each)
Click inside `Cleaned_Data` > **Insert > PivotTable > New Worksheet**.
1. **Sales by city:** Rows = city; Values = Sum of net_amount; Filters = order_status > Delivered. Compare with `Summary` sheet.
2. **Monthly trend:** Rows = order_date (right-click > Group > Months); Values = Sum of net_amount; filter Delivered.
3. **Cancellation by payment method:** Rows = payment_method; Columns = order_status; Values = Count of order_id; Show Values As > % of Row Total.
4. **Cuisine vs city:** Rows = cuisine; Columns = city; Values = Sum of net_amount. Add Conditional Formatting > Color Scales.
Add a **Slicer** (PivotTable Analyze > Insert Slicer > city). That is the same idea as Power BI slicers.

## 6. Conditional Formatting recap
Home > Conditional Formatting. Used here: red = missing/duplicate/drop; orange = missing delivery time on delivered orders; yellow = invalid values; colour scale on delivery time; data bars on net amount.
