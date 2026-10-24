# Step 5 - Basic DAX Measures

Full code: `powerbi/dax_measures.dax`. **Measure** = a calculation that recalculates every time a slicer or visual changes (unlike a normal column, which is fixed per row).

## Business rules (the contract)
1. `Orders` has **one row per order** (`order_id` unique), so counting distinct IDs can never double-count an order.
2. **Sales = net_amount of Delivered orders only.** `net_amount = quantity x unit_price - discount_amount`.
3. AOV = Sales / Completed Orders. Cancellation Rate = Cancelled / **all** orders.
4. Blank delivery times and ratings are ignored in averages (never treated as 0).

## Helper column first
```DAX
Is Delivered = IF ( Orders[order_status] = "Delivered", 1, 0 )
```
Creates a 1/0 flag on every row (Modeling > New column). It makes the measures short and easy to read. Because it is a *different column* from `order_status`, the Order Status slicer and the measures work together (choose "Cancelled" and Total Sales correctly shows blank).

## The 9 measures
| # | Measure | DAX | Simple English | Use it in |
|---|---|---|---|---|
| 1 | Total Orders | `DISTINCTCOUNT ( Orders[order_id] )` | Count each different Order ID once | Card; Orders by payment method |
| 2 | Completed Orders | `CALCULATE ( [Total Orders], Orders[Is Delivered] = 1 )` | Total Orders, but only delivered ones | Card; Orders by restaurant |
| 3 | Cancelled Orders | `CALCULATE ( [Total Orders], Orders[Is Delivered] = 0 )` | Total Orders, but only cancelled ones | Card; Completed vs Cancelled |
| 4 | Total Sales | `CALCULATE ( SUM ( Orders[net_amount] ), Orders[Is Delivered] = 1 )` | Add up net amount, delivered orders only | Card; line chart; city/cuisine bars |
| 5 | Average Order Value | `DIVIDE ( [Total Sales], [Completed Orders], 0 )` | Sales divided by delivered orders; shows 0 instead of an error if there are none | Card; cuisine comparison |
| 6 | Total Customers | `DISTINCTCOUNT ( Orders[customer_id] )` | Number of different customers who ordered | Card |
| 7 | Average Delivery Time | `CALCULATE ( AVERAGE ( Orders[delivery_time_min] ), Orders[Is Delivered] = 1 )` | Average minutes for delivered orders; blanks skipped | Card; city bar; time-of-day |
| 8 | Average Customer Rating | `AVERAGE ( Orders[customer_rating] )` | Average stars; blanks skipped | Card; restaurant bar |
| 9 | Cancellation Rate | `DIVIDE ( [Cancelled Orders], [Total Orders], 0 )` | Share of all orders that were cancelled | Card; payment-method bar |

### Key ideas explained
- **CALCULATE** = "calculate this, but change the filter". `CALCULATE([Total Orders], Orders[Is Delivered]=1)` means "count orders, but only where Is Delivered is 1". It is the most important DAX function.
- **DISTINCTCOUNT vs COUNT:** `COUNT` counts rows; `DISTINCTCOUNT` counts different values. For orders they are equal here, but DISTINCTCOUNT stays safe if duplicates ever sneak in.
- **DIVIDE** is safer than `/`: handles divide-by-zero.
- **Context:** a measure adapts to where it is placed. Put `Total Sales` in a visual with City on the axis and it is calculated once per city. Same formula, different answer per row. This is *filter context*.
- **Measure vs calculated column:** column = computed per row when data loads (use for flags and categories); measure = computed on the fly for totals and ratios (use for numbers you show in visuals).

## Test every measure
Create a Table visual with `order_status`, Total Orders, Total Sales, AOV. Compare with SQL/Excel:
| Measure | Expected (no slicers) |
|---|---|
| Total Orders | 2,937 |
| Completed Orders | 2,759 |
| Cancelled Orders | 178 |
| Total Sales | Rs 11,99,696 |
| Average Order Value | Rs 434.83 |
| Total Customers | 1,258 |
| Average Delivery Time | 38.3 min |
| Average Customer Rating | 3.91 |
| Cancellation Rate | 6.06% |

## Common beginner mistakes
- Using SUM on `net_amount` without the Delivered filter -> sales inflated by cancelled orders (Rs 12.0 L becomes about Rs 12.7 L).
- Replacing blank delivery times with 0 -> average falls and is wrong.
- Dividing cancelled orders by completed orders instead of by all orders.
- Using the text column from the CSV as a date instead of a proper Date table, which breaks month sorting.
