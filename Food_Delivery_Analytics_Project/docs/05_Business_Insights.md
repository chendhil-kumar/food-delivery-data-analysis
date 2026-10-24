# Step 6 - Business Insights

> **Every number below was calculated from the cleaned dataset** (SQL queries 3-25 and a pandas cross-check). The dataset is **synthetic**, so these are findings about this practice dataset, not real Swiggy/Zomato facts. Some patterns (e.g. Cash on Delivery cancellations, dinner delays) were built into the simulation to make analysis realistic - on real data, validate each finding before acting.

## Headline numbers
| Metric | Value |
|---|---|
| Total orders | 2,937 |
| Completed (Delivered) | 2,759 |
| Cancelled | 178 (**6.06%**) |
| Total sales (delivered) | **Rs 11,99,696** |
| Average order value | **Rs 434.83** |
| Customers | 1,258 |
| Total discount given | Rs 91,834 (7.1% of gross sales Rs 12,91,530) |
| Avg delivery time | 38.3 min |
| Avg rating | 3.91 / 5 |

## Answers to the seven questions
**1. Which city generates the highest sales?** **Mumbai**: Rs 2,79,810 (23.3% of sales). Interesting: **Bengaluru has more orders** (595 vs 551) but lower sales because Mumbai's average order is higher (Rs 508 vs Rs 404). Delhi is third (Rs 2,14,330, 17.9%). Kolkata is smallest (Rs 52,534, 4.4%).

**2. Which restaurant performs best?** Depends on the measure - say which one you mean:
- *Sales:* **Mumbai Pizza Co** - Rs 97,665 from only 132 orders (Rs 740 per order). Next: Tandoor Tales (Delhi, Rs 93,205) and Curry Leaf Kitchen (Mumbai, Rs 88,581).
- *Orders:* Burger Barn (181), then Curry Leaf Kitchen and Dosa Darbar (180 each).
- *Rating (min 30 ratings):* **Nawabi Biryani House**, 4.32 - the only top-5 sales restaurant with an excellent rating.
- *Concern:* the two biggest Mumbai earners have the weakest ratings (Curry Leaf Kitchen 3.48, Mumbai Pizza Co 3.56) - revenue at risk.

**3. Which cuisine is most popular?** **North Indian**: 622 orders and Rs 3,06,832 sales. Biryani is second by orders (369). **Pizza** has the highest order value (Rs 683) and is third in sales despite fewer orders. South Indian and Street Food are popular but low value (Rs 269 and Rs 252 per order).

**4. Which month has the highest sales?** **November 2025**: Rs 1,21,839, closely followed by October (Rs 1,20,076). Lowest: **June** (Rs 74,885). October-December together bring 28.9% of annual sales (festive season) against 25% if months were equal.

**5. What percentage of orders are cancelled?** **6.06%** (178 of 2,937). Big difference by payment method: **Cash on Delivery 10.45%** vs Debit Card 3.81%, Credit Card 4.74%, UPI 5.13%. By city: highest Pune (8.04%), Delhi (7.90%), Chennai (7.18%); lowest Ahmedabad (3.12%).

**6. Which cities have longer delivery times?** Overall average is 38.3 min. Above average: **Mumbai 43.1**, **Bengaluru 40.4**, **Delhi 39.5** - also the three largest cities by orders. Fastest: Ahmedabad 30.5, Pune 33.2. **Dinner** (19-22h) is the slowest slot (40.0 min vs 36.3 at breakfast).

**7. What actions could improve sales and satisfaction?** See below.

## Other findings
- **Peak hours:** 8 pm (375 orders), 7 pm (360), 12 noon (340). Lunch + Dinner slots = 72% of completed orders.
- **Speed affects ratings:** orders delivered in 30 min or less average **4.03** stars; 31-45 min = 3.93; over 45 min = **3.72**. (The overall correlation is weak at -0.12, so speed is one driver among several.)
- **Repeat customers:** 62.2% of customers with a delivered order ordered more than once (763 of 1,226).
- **Cloud kitchens vs dine-in:** cloud kitchens have a higher average order (Rs 485 vs Rs 390) and slightly faster delivery (37.9 vs 38.7 min).
- **Discounts:** 49% of delivered orders used a discount. Discounted orders average Rs 413 vs Rs 456 without. Caution: this shows association only; in this simulated data discounts were not assigned based on behaviour, so do not claim discounts "reduce" order value.
- **Day of week:** fairly flat (Sunday and Saturday ~410 orders, Tuesday lowest at 378) - no strong weekend effect.

## Recommendations (each tied to a finding)
1. **Reduce Cash on Delivery cancellations (10.45%).** Offer a small prepaid discount or UPI cashback; confirm COD orders by call/OTP for high-value baskets. If COD fell to the UPI rate (5.1%) roughly 26 fewer orders would be lost in this dataset (488 COD orders x 5.3 points).
2. **Fix delivery speed at dinner and in Mumbai/Bengaluru/Delhi.** Add rider capacity from 7-10 pm; set realistic ETAs; target below 40 min. Orders over 45 minutes score about 0.2-0.3 stars lower.
3. **Protect high-revenue, low-rating restaurants** (Curry Leaf Kitchen, Mumbai Pizza Co): audit food quality and packaging, share rating feedback with partners, and consider reduced visibility if ratings stay below 3.6.
4. **Grow high-value cuisines.** Promote Pizza, Biryani and Healthy Food (AOV Rs 545-683) with combo offers; bundle add-ons (drinks/desserts) with low-value Street Food and South Indian orders to lift AOV.
5. **Plan for festive demand.** Stock partner capacity and run campaigns in Oct-Nov; use a June/monsoon-type slump for targeted discounts rather than blanket offers.
6. **Loyalty programme** for the 62% repeat customers: tiered rewards for the top 5% (they place 14% of orders).
7. **Grow smaller cities carefully:** Kolkata and Chennai have low sales but good ratings (4.04 Kolkata) - add more restaurant partners rather than discounts.

## How to present an insight in an interview (SCR format)
**Situation** - 6.06% of orders are cancelled. **Cause** - COD cancels at 10.45%, double the card rate. **Recommendation** - prepaid incentives; expected benefit about 26 saved orders per 2,937 orders. Always: number + comparison + action.
