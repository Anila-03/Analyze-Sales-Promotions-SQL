## Request 1
## Provide a list of products with a base price greater than 500 and that are featured in promo type of 'BOGOF' (Buy One Get One Free). 
## This information will help us identify high-value products that are currently being heavily discounted, 
## which can be useful for evaluating our pricing and promotion strategies.

SELECT DISTINCT product_code, p.product_name, e.base_price, e.promo_type
FROM dim_products p
JOIN fact_events e
USING (product_code)
WHERE base_price > 500 AND promo_type = 'BOGOF'
ORDER BY base_price DESC;

## Request 2
## Generate a report that provides an overview of the number of stores in each city. 
## The results will be sorted in descending order of store counts, allowing us to identify the cities with the highest store presence. 
## The report includes two essential fields: city and store count, which will assist in optimizing our retail operations.

SELECT city, count(store_id) as no_of_stores
FROM dim_stores
GROUP BY city
ORDER BY no_of_stores DESC;

## Request 3
## Generate a report that displays each campaign along with the total revenue generated before and after the campaign? 
## The report includes three key fields: campaign_name, total_revenue(before_promotion), total_revenue(after_promotion). 
## This report should help in evaluating the financial impact of our promotional campaigns. (Display the values in millions)

SELECT  campaign_name,
		concat(round(sum(base_price * `quantity_sold(before_promo)`)/1000000,2)," M") as total_revenue_before_promotion,
        concat(round(sum(
        CASE
			WHEN promo_type = "50% off" then base_price * 0.5 * `quantity_sold(after_promo)`
            WHEN promo_type = "25% off" then base_price * 0.75 * `quantity_sold(after_promo)`
            WHEN promo_type = "33% off" then base_price * 0.67 * `quantity_sold(after_promo)`
            WHEN promo_type = "BOGOF" then base_price * 0.5 * (2 * `quantity_sold(after_promo)`)
            WHEN promo_type = "500 cashback" then (base_price - 500) * `quantity_sold(after_promo)`
		END)/1000000,2), " M") as  total_revenue_after_promotion
FROM fact_events 
JOIN dim_campaigns 
USING (campaign_id)
group by campaign_name;

## Request 4
## Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign. 
## Additionally, provide rankings for the categories based on their ISU%. 
## The report will include three key fields: category, isu%, and rank order. 
## This information will assist in assessing the category-wise success and impact of the Diwali campaign on incremental sales.
with diwali_sales as 
	(
			SELECT category, 
					round(sum((
					case
					when promo_type = 'BOGOF' then `quantity_sold(after_promo)` *2
					else `quantity_sold(after_promo)`
					end 
						- `quantity_sold(before_promo)`)*100) / sum(`quantity_sold(before_promo)`),2) as `ISU%`
			FROM fact_events e
			JOIN dim_campaigns c on c.campaign_id = e.campaign_id
			JOIN dim_products p on p.product_code = e.product_code
			WHERE campaign_name = 'Diwali'
			GROUP BY category
	)
			SELECT category, `ISU%` , rank() over( order by `ISU%` desc ) as rank_order 
            FROM diwali_sales;
            
## Request 5         
## 5. Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. 
## The report will provide essential information including product name, category, and ir%.
## This analysis helps identify the most successful products in terms of incremental revenue across our campaigns, assisting in product optimization.
		SELECT product_name, category, 
            ROUND((sum(case
					WHEN promo_type = "50% off" then base_price * 0.5 * `quantity_sold(after_promo)`
					WHEN promo_type = "25% off" then base_price * 0.75 * `quantity_sold(after_promo)`
					WHEN promo_type = "33% off" then base_price * 0.67 * `quantity_sold(after_promo)`
					WHEN promo_type = "BOGOF" then base_price * 0.5 * (2 * `quantity_sold(after_promo)`)
					WHEN promo_type = "500 cashback" then (base_price - 500) * `quantity_sold(after_promo)`                   
				ELSE 0
                END) - SUM(base_price * `quantity_sold(before_promo)`)) / sum(base_price * `quantity_sold(before_promo)`) * 100,2) as `IR%`
		FROM fact_events e
		JOIN dim_products p on e.product_code = p.product_code
        GROUP BY product_name, category
        ORDER BY `IR%` desc
        LIMIT 5;
            
