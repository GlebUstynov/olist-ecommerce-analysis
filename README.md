# Brazilian E-Commerce Analysis (Olist)

I'm using the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) to practice SQL, Python, Excel and Power BI. The work started with basic exploratory analysis and has gradually moved into data checks, joins, reporting and time-series analysis.

## Tools

- Python: Pandas, Jupyter Notebook
- PostgreSQL and DBeaver: SQL queries and data checks
- Excel and Power Query: combining monthly exports, PivotTables and reporting
- Power BI: data model, relationships and order trends
- Git and GitHub: version control

## What's in the repository

| Files | Work |
| --- | --- |
| `olist_analysis.ipynb` | Initial exploration of the Olist tables |
| `week_03_sql_olist.ipynb`, `week3_joins.sql`, `week3_pandas_quality.ipynb` | Key checks, joins, missing values, duplicates and merge validation |
| `week4OLIST/` | Monthly SQL exports, Pandas validation, Excel / Power Query report and April checks |
| `week5OLIST/` | CTEs, subqueries, `EXISTS`, window functions, `EXPLAIN` and Pandas practice |
| `week6OLIST/` | SQL grain and revenue checks, Pandas time series and a Power BI report |

## A few things I checked

- Olist has 99,441 orders in the full orders table
- 775 orders have no matching rows in `order_items`
- Joining order-level totals back to individual items can double-count revenue, so I aggregate items before joining when I need one row per order
- For January–August 2018, my SQL and Pandas checks returned 53,991 orders and BRL 7,385,905.80 in item revenue

The revenue figures here use item prices, excluding freight, unless stated otherwise. Different exercises use different date ranges and order-status filters.

## Data

The original dataset is available on [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Some exercises use monthly CSV exports generated from PostgreSQL; these intermediate files are not included in the repository.

This is an ongoing learning project, so the notebooks contain both exercises and analysis rather than one finished application.
