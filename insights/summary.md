# E-Commerce Sales Insights
**Dataset:** UCI Online Retail II | **Period:** December 2009 to December 2011 | **Tool:** MySQL


## Overview

The dataset contains 40,077 valid invoices from 5,878 registered customers across 43 countries, generating a total gross revenue of $41.9M over two years. The United Kingdom accounts for 85% of all revenue, making it by far the dominant market. The remaining 15% is spread across Europe, with Ireland (3.2%), Netherlands (2.6%), Germany (2.1%), and France (1.7%) as the next largest contributors.

Cancellations represent 15.5% of all invoices, which is worth monitoring as it has a direct impact on net revenue. About 16% of transactions were placed by guest users with no customer ID recorded.


## Sales Trends

Revenue consistently peaks in Q4 each year, driven by the holiday shopping season. November is the strongest single month in both 2010 and 2011. Tuesdays and Thursdays generate the highest revenue among weekdays, and Saturday transactions are nearly negligible since the business operates primarily on weekdays. Peak ordering hours fall between 10 AM and 2 PM.


## Top Products

The top five products by revenue are all home decor and gift items, reflecting the store's core customer base.

| Rank | Product | Revenue |
|------|---------|---------|
| 1 | REGENCY CAKESTAND 3 TIER | $689,127 |
| 2 | WHITE HANGING HEART T-LIGHT HOLDER | $533,847 |
| 3 | PAPER CRAFT, LITTLE BIRDIE | $336,939 |
| 4 | JUMBO BAG RED RETROSPOT | $301,871 |
| 5 | PARTY BUNTING | $298,374 |


## Customer Behavior

72% of customers made more than one purchase, which indicates solid repeat purchase rates for a wholesale-oriented retailer. The breakdown is as follows: 28% made only one purchase, 42% placed 2 to 5 orders, and the remaining 30% were high-frequency buyers with 6 or more orders.


## RFM Segmentation

Customers were scored on Recency, Frequency, and Monetary value using a 1 to 5 quintile scale, then grouped into eight segments.

| Segment | Customers | Share | Total Revenue | Avg LTV |
|---------|-----------|-------|---------------|---------|
| Champions | 1,345 | 22.9% | $24.4M | $18,162 |
| Loyal Customers | 1,473 | 25.1% | $5.8M | $3,918 |
| At Risk | 203 | 3.5% | $1.9M | $9,558 |
| Cant Lose Them | 505 | 8.6% | $1.2M | $2,352 |
| Need Attention | 584 | 9.9% | $938K | $1,607 |
| Lost | 1,362 | 23.2% | $719K | $528 |
| Recent Customers | 287 | 4.9% | $228K | $795 |
| Potential Loyalists | 119 | 2.0% | $275K | $2,311 |

Champions make up only 23% of the customer base but generate 58% of total revenue. The At Risk segment is particularly worth attention: these 203 customers each spent nearly $10K on average but have not purchased recently, making them strong candidates for reactivation campaigns. The Lost segment (23% of customers, only $528 average LTV) likely represents price-sensitive or one-time buyers who churned early.


## Key Takeaways

Revenue is heavily concentrated in the UK and in a small group of high-value customers. Retaining Champions and reactivating At Risk customers would have the highest revenue impact. Expanding the non-UK share of revenue, particularly in Germany and France where order values are relatively healthy, could reduce market concentration risk.
