# Step 4 - Power BI Dashboard Guide (build it yourself, step by step)

> I cannot create a `.pbix` file from here, so this is a click-by-click build guide. Files you need: `data/cleaned_food_delivery_orders.csv`, `data/dim_restaurants.csv`, `data/dim_city.csv`, `powerbi/dax_measures.dax`, `powerbi/food_delivery_theme.json`. Preview images of the target look are in `screenshots/`. Install **Power BI Desktop** (free, Windows).

## A. Load the data
1. Home > **Get data > Text/CSV** > choose `cleaned_food_delivery_orders.csv` > **Transform Data**.
2. In Power Query check data types: `order_date` = Date, `order_time` = Time, numeric columns = Whole Number, `delivery_time_min` and `customer_rating` = Whole Number (blanks stay blank - do not replace with 0), text columns = Text. Rename the query to **Orders**. **Close & Apply**.
3. Repeat for `dim_restaurants.csv` and `dim_city.csv`.

## B. Build the data model (star schema)
Model view (third icon on the left). Create these relationships (drag column to column):
| From (one side) | To (many side) | Cardinality |
|---|---|---|
| Date[Date] | Orders[order_date] | One-to-many |
| dim_city[city] | Orders[city] | One-to-many |
| dim_restaurants[restaurant_name] | Orders[restaurant_name] | One-to-many |
Make **Date** table with DAX (see `dax_measures.dax` section 1), sort *Month* by *Month No*, and **Mark as date table**. Hide the join columns in dim tables ("Hide in report view") to avoid confusion.
**Why:** Orders is the *fact* table (one row per order); the others are *dimension* tables. Filters flow from dimension to fact. This stops double counting.

## C. Create columns and measures
Follow `dax_measures.dax`: calculated columns `Is Delivered`, `Order Hour`, `Time of Day`; then the 9 core measures. Put measures in a separate empty table (Home > Enter data > name it `_Measures`) to keep them tidy. Format: Total Sales and AOV = Currency, Indian Rupee (Measure tools > Currency > English India); Cancellation Rate = Percentage, 1 decimal.

## D. Apply the theme
View > Themes > **Browse for themes** > `food_delivery_theme.json`. Page background: Format page > Canvas background light grey (#F3F2F1).

## E. Dashboard 1 - Sales Overview (page name: "Sales Overview")
| Visual | How to build |
|---|---|
| **Card x4**: Total Orders, Total Sales, Average Order Value, Total Customers | Insert Card; drag the measure into Fields. Place in a row at the top. |
| **Line chart - Monthly Sales Trend** | Line chart; X-axis = Date[Month] (sorted by Month No); Y-axis = Total Sales. Turn on data labels. |
| **Bar chart - Sales by City** | Clustered bar; Y = Orders[city]; X = Total Sales; sort descending by Total Sales (... menu > Sort axis). |
| **Bar/Donut - Sales by Cuisine** | Clustered bar; Y = cuisine; X = Total Sales. (Prefer bar over donut: 9 slices are hard to read.) |
| **Slicers** | Date: Slicer on Date[Date] set to *Between*. City: dim_city[city] (Dropdown). Cuisine: Orders[cuisine]. Restaurant: dim_restaurants[restaurant_name] (dropdown + search). Order Status: Orders[order_status] (buttons). |
**Sync the slicers to every page:** View > Sync slicers > tick all three pages for each slicer.

## F. Dashboard 2 - Restaurant Performance
| Visual | How to build |
|---|---|
| **Top 10 Restaurants by Sales** | Bar chart; Y = restaurant_name; X = Total Sales. In Filters pane on the visual: restaurant_name > Filter type **Top N** > Top 10 > By value Total Sales > Apply. |
| **Orders by Restaurant** | Bar chart; Y = restaurant_name; X = Completed Orders; Top N 10 by Completed Orders. |
| **Average Restaurant Rating** | Clustered bar or table: restaurant_name + Average Customer Rating. Add visual filter `Rated Orders >= 30` so tiny samples are hidden. Add **Conditional formatting** (field > data bars). |
| **Restaurant Sales Comparison** | Scatter chart: X = Average Customer Rating; Y = Total Sales; Size = Completed Orders; Details = restaurant_name; Legend = dim_restaurants[restaurant_type]. Shows who is both popular and liked. |
| Card | Average Customer Rating |
Tip: add a **Table** visual with restaurant, city, orders, sales, AOV, rating for drill-down.

## G. Dashboard 3 - Order and Delivery Analysis
| Visual | How to build |
|---|---|
| **Completed vs Cancelled** | Donut or column chart; Legend/Axis = order_status; Values = Total Orders. Cards: Completed Orders, Cancelled Orders, Cancellation Rate. |
| **Average Delivery Time** | Card = Average Delivery Time. Add a **Gauge** if you like (target 35 min is your assumption - write it in the notes). |
| **Orders by Payment Method** | Bar chart; Y = payment_method; X = Total Orders. Second visual: X = Cancellation Rate to expose Cash on Delivery. |
| **Orders by Time of Day** | Column chart; X = Orders[Time of Day]; Y = Total Orders. Optional: line on same chart for Average Delivery Time (Line and clustered column chart). |
| **Delivery Performance by City** | Bar chart; Y = city; X = Average Delivery Time; add a **constant line** (Analytics pane) at the overall average. |
**Interaction tip:** the Order Status slicer should not hide the Completed-vs-Cancelled chart. Select the slicer > Format > **Edit interactions** > click the "none" icon on that chart.

## H. Polish checklist (what recruiters notice)
- Page title + short subtitle on every page. Consistent colours (theme). Aligned visuals (Format > Align).
- Every visual has a clear title with units (Rs, minutes).
- Rename pages; add a **navigation bar** (Insert > Buttons > Navigator > Page navigator).
- Turn on tooltips; avoid more than 7 visuals per page.
- Add a text box "Data: synthetic practice dataset, 2025" in the footer.
- Save as `Food_Delivery_Dashboard.pbix`. Export screenshots: File > Export > PDF, or Win+Shift+S for each page; save into `screenshots/` as `dashboard1_sales_overview.png`, etc.

## I. Self-check numbers (your dashboard must match)
Total Orders 2,937 | Completed 2,759 | Cancelled 178 | Total Sales Rs 11,99,696 | AOV Rs 434.83 | Customers 1,258 | Cancellation Rate 6.06% | Avg Delivery 38.3 min | Avg Rating 3.91. With no slicer selected. If a number differs, check relationships and the `Is Delivered` column first.
