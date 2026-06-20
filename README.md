# Price Elasticity of Demand (PED) Analysis in E-Commerce

This project applies microeconomic theory and data engineering principles to Olist's public e-commerce dataset (Kaggle). The objective is to calculate and analyze consumer price sensitivity across different product categories over time.

## Dataset Information

The analysis is conducted using the **Brazilian E-Commerce Public Dataset by Olist**, a real, anonymized e-commerce marketplace dataset containing over 100,000 orders from 2016 to 2018. 

The project specifically orchestrates and queries the following relational tables:
* `olist_orders_dataset`: Captures order timestamps and tracking states.
* `olist_order_items_dataset`: Contains transactional data, including pricing, products, and freight.
* `olist_products_dataset`: Houses product attributes and raw category classifications.
* `olist_category_name_translation`: Used to map Portuguese category names into English.

## Tech Skills
* **Database:** PostgreSQL
* **SQL Client:** DBeaver
* **Core Concepts:** Common Table Expressions (CTEs), Window Functions (`LAG`), Complex Conditional Logic (`CASE WHEN`), Data Cleansing (`NULLIF`, `ABS`, `COALESCE`).

## How to Run

### Prerequisites
- PostgreSQL
- A SQL client
- The Olist dataset (downloaded from Kaggle)

### 1. Download the dataset
Download the **[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)** from Kaggle

Extract the CSV files. You'll need:
- `olist_orders_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_products_dataset.csv`
- `product_category_name_translation.csv`

### 2. Create the database
```sql
CREATE DATABASE olist_ecommerce;
```

### 3. Create the tables
Run `schema.sql` to set up the relational structure:
```sql
\i schema.sql
```
> In DBeaver, open `schema.sql` and execute it directly in the SQL editor.

### 4. Import the CSV files
Using `psql`:
```sql
\copy olist_orders_dataset FROM 'path/to/olist_orders_dataset.csv' DELIMITER ',' CSV HEADER;
\copy olist_order_items_dataset FROM 'path/to/olist_order_items_dataset.csv' DELIMITER ',' CSV HEADER;
\copy olist_products_dataset FROM 'path/to/olist_products_dataset.csv' DELIMITER ',' CSV HEADER;
\copy olist_category_name_translation FROM 'path/to/product_category_name_translation.csv' DELIMITER ',' CSV HEADER;
```
> In DBeaver, right-click each table → **Import Data** → select the corresponding CSV.

### 5. Run the analysis
```sql
\i analysis.sql
```
Or open `analysis.sql` in your SQL client and run it directly. The final query returns PED (Price Elasticity of Demand) results by category, ranked by sensitivity.

### Expected output

| month | product | order_count | avg_price | previous_order_count | previous_avg_price | ped | sensitivity |
|---|---|---|---|---|---|---|---|
| 2017-11-01 | health_beauty | ... | ... | ... | ... | 42.75 | elastic |
| 2018-03-01 | garden_tools | ... | ... | ... | ... | -28.66 | elastic |

## SQL Query Architecture
The analytical pipeline was built using sequentially linked CTEs to ensure clean data transformation:
1. **`olist` (Monthly Aggregation):** Extracts monthly order volumes and average prices per product.
2. **`product` (Categorization & Translation):** Normalizes product categories and maps them from Portuguese to English using `COALESCE` to handle missing descriptions as `'other / uncategorized'`.
3. **`prev` (Time-Series Mapping):** Uses the `LAG()` window function partitioned by product to fetch the previous month's metrics.
4. **`percent` (Delta Calculation):** Computes the percentage change in quantity demanded ($\% \Delta Q$) and price ($\% \Delta P$), safely handling division-by-zero risks with `NULLIF`.

## Economic Interpretation

### 1. Understanding Sensitivity Classifications
* **Elastic ($\text{PED} > 1$):** Highly price-sensitive products. Small price increases lead to sharp drops in order volume. *Strategy:* Highly responsive to promotions, discounts, and flash sales.
* **Inelastic ($\text{PED} < 1$):** Price-resilient products. Demand drops proportionally less than the price increase. *Strategy:* Ideal for profit margin optimization and gradual price adjustments.
* **Unit Elastic ($\text{PED} = 1$):** The percentage change in price matches the percentage change in quantity exactly. Revenue remains constant.

### 2. Handling Mathematical & Economic Nulls
Records resulting in `NULL` values for `ped` and `sensitivity` are normal behavioral outcomes handled by design:
* **Price Stability:** When the average price remains unchanged month-over-month, the price delta ($\% \Delta P$) is $0$. To prevent division-by-zero errors, the code uses `NULLIF()`, resulting in a `NULL` calculation. This means no price stimulus occurred to test consumer reaction.
* **Discontinuous History:** Products without consecutive monthly sales cannot establish a continuous historical baseline, which naturally limits time-series elasticity modeling.


## Key Insights

### 1. Empirical Findings
* **Highest Positive Elasticity:** The `health_beauty` category registered a peak PED of `42.75`. 
* **Highest Negative Elasticity:** The `garden_tools` category registered a peak PED of `-28.66`.

### 2. Negative vs. Positive Elasticity

While both metrics indicate extreme price sensitivity (high absolute variance), they reveal fundamentally different market dynamics:

* **Negative Elasticity (`garden_tools` / $\text{PED} = -28.66$):** This aligns perfectly with the law of demand. A high absolute negative value demonstrates an ultra-sensitive market segment. In online marketplaces, categories like garden tools often face fierce competition with low switching costs; a minor price drop triggers aggressive volume growth as consumers rapidly pivot to the cheapest available seller.
  
* **Positive Elasticity Paradox (`health_beauty` / $\text{PED} = 42.75$):** In economic theory, a positive price elasticity is attributed to **Giffen Goods** (inferior goods with no close substitutes where price hikes force consumers to buy more) or **Veblen Goods** (luxury items where higher prices increase prestige and demand). 
  
However, in a digital marketplace like Olist, this positive spike is an anomaly driven by **demand shocks and seasonality**. For health and beauty products, massive promotional campaigns (e.g., Black Friday, Mother's Day) or macroeconomic shifts often cause demand to skyrocket. Since the overall volume and market activity shift upward together during these periods, it creates an artificial positive elasticity effect where high demand bypasses traditional price barriers.

## Outlier Treatment

To prevent statistical noise, specific constraints were hardcoded into the final `WHERE` clause:

1. **`abs(percent_avg_price) > 0.02`:** Month-over-month price fluctuations of just a few cents yield percentage variations near zero ($\% \Delta P \approx 0$). When acting as the denominator in the PED formula ($\frac{\% \Delta Q}{\% \Delta P}$), it causes an artificial mathematical explosion, yielding false elasticities in the thousands. This filter forces a minimum 2% price change baseline.
   
2. **`previous_order_count >= 10`:** Long-tail or low-volume products moving from 1 isolated sale to a modest volume (e.g., 12 sales) register an astronomical 1,100% demand surge ($\% \Delta Q = 11.0$). Without this filter, the model would misinterpret normal early-stage product growth as extreme price responsiveness. Enforcing a baseline of at least 10 prior sales ensures empirical relevance.
