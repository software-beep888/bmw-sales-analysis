-- BASIC COUNT QUERIES
SELECT COUNT(*) as total_records FROM bmw_sales;

-- Recent entries
SELECT * FROM bmw_sales ORDER BY created_at DESC LIMIT 5;

-- Check by year
SELECT year, COUNT(*) as count FROM bmw_sales GROUP BY year ORDER BY year DESC;

-- Check by region
SELECT region, COUNT(*) as count FROM bmw_sales GROUP BY region ORDER BY count DESC;

-- Check by model
SELECT model, COUNT(*) as count FROM bmw_sales GROUP BY model ORDER BY count DESC;

-- Check by fuel type
SELECT fuel_type, COUNT(*) as count FROM bmw_sales GROUP BY fuel_type ORDER BY count DESC;

-- Check sales classification distribution
SELECT sales_classification, COUNT(*) as count FROM bmw_sales GROUP BY sales_classification;

-- Check price ranges
SELECT 
    MIN(price_usd) as min_price,
    MAX(price_usd) as max_price,
    AVG(price_usd) as avg_price
FROM bmw_sales;

-- Check sales volume ranges
SELECT 
    MIN(sales_volume) as min_sales,
    MAX(sales_volume) as max_sales,
    AVG(sales_volume) as avg_sales
FROM bmw_sales;

-- Quick view of the first 5 records
SELECT * FROM bmw_sales LIMIT 5;

-- Check for any NULL values in key columns
SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN model IS NULL THEN 1 END) as null_models,
    COUNT(CASE WHEN year IS NULL THEN 1 END) as null_years,
    COUNT(CASE WHEN region IS NULL THEN 1 END) as null_regions,
    COUNT(CASE WHEN price_usd IS NULL THEN 1 END) as null_prices
FROM bmw_sales;

-- View counts
SELECT 'executive_dashboard' as view_name, COUNT(*) as row_count FROM executive_dashboard
UNION ALL
SELECT 'regional_performance', COUNT(*) FROM regional_performance
UNION ALL
SELECT 'model_analytics', COUNT(*) FROM model_analytics
UNION ALL
SELECT 'year_over_year_trends', COUNT(*) FROM year_over_year_trends
UNION ALL
SELECT 'fuel_type_trends', COUNT(*) FROM fuel_type_trends;

-- Test the function with no parameters
SELECT * FROM calculate_sales_growth() LIMIT 3;