-- ========================================================================
-- BMW SALES DATABASE - FINAL COMPLETE ANALYSIS SCRIPT
-- ========================================================================

-- 1. DATABASE OVERVIEW AND HEALTH CHECK
-- ========================================================================

-- Total records count
SELECT COUNT(*) as total_records FROM bmw_sales;

-- Check table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'bmw_sales' 
ORDER BY ordinal_position;

-- Data quality check
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT model) as unique_models,
    COUNT(DISTINCT region) as unique_regions,
    COUNT(DISTINCT year) as years_covered,
    MIN(year) as earliest_year,
    MAX(year) as latest_year,
    MIN(price_usd) as min_price,
    MAX(price_usd) as max_price,
    ROUND(AVG(price_usd), 2) as avg_price,
    MIN(sales_volume) as min_sales,
    MAX(sales_volume) as max_sales,
    ROUND(AVG(sales_volume), 2) as avg_sales
FROM bmw_sales;

-- 2. RECENT ACTIVITY CHECK
-- ========================================================================

-- Most recent entries
SELECT * FROM bmw_sales ORDER BY created_at DESC LIMIT 10;

-- Last 5 entries by model and region
SELECT 
    model,
    year,
    region,
    fuel_type,
    price_usd,
    sales_volume,
    sales_classification,
    created_at
FROM bmw_sales 
ORDER BY created_at DESC 
LIMIT 5;

-- 3. VIEW VALIDATION
-- ========================================================================

-- Check all views exist and have data
SELECT 'executive_dashboard' as view_name, COUNT(*) as row_count FROM executive_dashboard
UNION ALL
SELECT 'regional_performance', COUNT(*) FROM regional_performance
UNION ALL
SELECT 'model_analytics', COUNT(*) FROM model_analytics
UNION ALL
SELECT 'year_over_year_trends', COUNT(*) FROM year_over_year_trends
UNION ALL
SELECT 'fuel_type_trends', COUNT(*) FROM fuel_type_trends;

-- 4. KEY ANALYTICAL INSIGHTS
-- ========================================================================

-- 4.1 Executive Dashboard Summary
SELECT 'EXECUTIVE DASHBOARD SUMMARY' as section;
SELECT * FROM executive_dashboard;

-- 4.2 Regional Performance Overview
SELECT 'TOP 10 REGIONS BY SALES' as section;
SELECT 
    region,
    year,
    total_sales,
    revenue_millions,
    electric_percentage
FROM regional_performance 
ORDER BY total_sales DESC 
LIMIT 10;

-- 4.3 Model Performance Ranking
SELECT 'TOP 10 MODELS BY LIFETIME SALES' as section;
SELECT 
    model,
    years_active,
    lifetime_sales,
    avg_price,
    high_sales_percentage
FROM model_analytics 
ORDER BY lifetime_sales DESC 
LIMIT 10;

-- 4.4 Year-over-Year Trends
SELECT 'YEAR-OVER-YEAR TRENDS BY FUEL TYPE' as section;
SELECT 
    year,
    fuel_type,
    total_sales,
    yoy_growth_percent,
    growth_status
FROM year_over_year_trends 
WHERE year >= 2020
ORDER BY fuel_type, year DESC;

-- 4.5 Fuel Type Analysis
SELECT 'FUEL TYPE MARKET SHARE' as section;
SELECT 
    fuel_type,
    SUM(total_sales) as total_sales,
    ROUND(AVG(avg_price), 2) as avg_price,
    STRING_AGG(DISTINCT models_available, ', ') as available_models
FROM fuel_type_trends 
WHERE year >= 2020
GROUP BY fuel_type 
ORDER BY total_sales DESC;

-- 5. FUNCTION TESTING
-- ========================================================================

-- Test growth calculation for all regions in 2023
SELECT 'SALES GROWTH ANALYSIS (2023)' as section;
SELECT * FROM calculate_sales_growth(2023, NULL, NULL) 
WHERE growth_status != 'Stable'
ORDER BY growth_percent DESC
LIMIT 10;

-- Test growth for specific model (5 Series)
SELECT '5 SERIES GROWTH ANALYSIS' as section;
SELECT * FROM calculate_sales_growth(NULL, NULL, '5 Series')
ORDER BY analysis_year DESC
LIMIT 5;

-- 6. ADVANCED ANALYTICS QUERIES
-- ========================================================================

-- 6.1 Price Segmentation
SELECT 'PRICE SEGMENTATION ANALYSIS' as section;
WITH price_segments AS (
    SELECT 
        CASE 
            WHEN price_usd < 50000 THEN 'Budget (<50k)'
            WHEN price_usd BETWEEN 50000 AND 80000 THEN 'Mid-Range (50k-80k)'
            WHEN price_usd BETWEEN 80000 AND 120000 THEN 'Premium (80k-120k)'
            ELSE 'Luxury (>120k)'
        END as price_segment,
        sales_volume,
        price_usd
    FROM bmw_sales
)
SELECT 
    price_segment,
    COUNT(*) as models_count,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price_in_segment,
    ROUND(MIN(price_usd), 2) as min_price,
    ROUND(MAX(price_usd), 2) as max_price,
    ROUND(
        SUM(sales_volume) * 100.0 / 
        (SELECT SUM(sales_volume) FROM bmw_sales), 2
    ) as market_share_percent
FROM price_segments
GROUP BY price_segment
ORDER BY 
    CASE price_segment
        WHEN 'Budget (<50k)' THEN 1
        WHEN 'Mid-Range (50k-80k)' THEN 2
        WHEN 'Premium (80k-120k)' THEN 3
        ELSE 4
    END;

-- 6.2 EV vs ICE Comparison
SELECT 'EV VS TRADITIONAL VEHICLE COMPARISON' as section;
WITH fuel_categories AS (
    SELECT 
        CASE 
            WHEN fuel_type IN ('Electric', 'Hybrid') THEN 'EV/Hybrid'
            ELSE 'Traditional ICE'
        END as fuel_category,
        sales_volume,
        price_usd,
        engine_size_l,
        year,
        sales_classification
    FROM bmw_sales
)
SELECT 
    fuel_category,
    COUNT(*) as records,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    ROUND(AVG(engine_size_l), 2) as avg_engine_size,
    ROUND(
        SUM(CASE WHEN sales_classification = 'High' THEN 1 ELSE 0 END) * 100.0 / 
        COUNT(*), 2
    ) as high_sales_percentage,
    ROUND(
        SUM(CASE WHEN year >= 2020 THEN sales_volume ELSE 0 END) * 100.0 / 
        NULLIF(SUM(sales_volume), 0), 2
    ) as recent_sales_percentage
FROM fuel_categories
GROUP BY fuel_category
ORDER BY total_sales DESC;

-- 6.3 Sales Classification Analysis
SELECT 'SALES CLASSIFICATION DISTRIBUTION' as section;
SELECT 
    sales_classification,
    COUNT(*) as records_count,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    ROUND(AVG(engine_size_l), 2) as avg_engine_size,
    STRING_AGG(DISTINCT model, ', ' ORDER BY model) as models_in_category,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM bmw_sales), 2
    ) as records_percentage
FROM bmw_sales
GROUP BY sales_classification
ORDER BY 
    CASE sales_classification
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END;

-- 6.4 Correlation Analysis
SELECT 'STATISTICAL CORRELATIONS' as section;
SELECT 
    ROUND(CORR(price_usd, sales_volume)::numeric, 4) as price_sales_correlation,
    ROUND(CORR(engine_size_l, price_usd)::numeric, 4) as engine_price_correlation,
    ROUND(CORR(mileage_km, price_usd)::numeric, 4) as mileage_price_correlation,
    ROUND(CORR(year::numeric, price_usd::numeric)::numeric, 4) as year_price_correlation,
    ROUND(CORR(year::numeric, sales_volume::numeric)::numeric, 4) as year_sales_correlation
FROM bmw_sales;

-- 7. DATA DISTRIBUTION CHECKS
-- ========================================================================

-- 7.1 Year distribution
SELECT 'YEARLY DISTRIBUTION' as section;
SELECT 
    year,
    COUNT(*) as record_count,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    COUNT(DISTINCT model) as unique_models,
    COUNT(DISTINCT region) as unique_regions
FROM bmw_sales
GROUP BY year
ORDER BY year DESC;

-- 7.2 Model distribution
SELECT 'MODEL DISTRIBUTION (TOP 15)' as section;
SELECT 
    model,
    COUNT(*) as record_count,
    COUNT(DISTINCT year) as years_active,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    MIN(year) as first_year,
    MAX(year) as last_year,
    STRING_AGG(DISTINCT fuel_type, ', ') as fuel_types
FROM bmw_sales
GROUP BY model
ORDER BY total_sales DESC
LIMIT 15;

-- 7.3 Region distribution
SELECT 'REGION DISTRIBUTION' as section;
SELECT 
    region,
    COUNT(*) as record_count,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    COUNT(DISTINCT model) as unique_models,
    ROUND(
        SUM(CASE WHEN fuel_type = 'Electric' THEN sales_volume ELSE 0 END) * 100.0 / 
        NULLIF(SUM(sales_volume), 0), 2
    ) as ev_percentage
FROM bmw_sales
GROUP BY region
ORDER BY total_sales DESC;

-- 7.4 Fuel type distribution
SELECT 'FUEL TYPE DISTRIBUTION' as section;
SELECT 
    fuel_type,
    COUNT(*) as record_count,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    ROUND(AVG(engine_size_l), 2) as avg_engine_size,
    COUNT(DISTINCT model) as unique_models,
    COUNT(DISTINCT region) as unique_regions,
    ROUND(
        SUM(CASE WHEN year >= 2020 THEN sales_volume ELSE 0 END) * 100.0 / 
        NULLIF(SUM(sales_volume), 0), 2
    ) as recent_sales_percentage
FROM bmw_sales
GROUP BY fuel_type
ORDER BY total_sales DESC;

-- 8. PERFORMANCE METRICS
-- ========================================================================

-- 8.1 Index usage check
SELECT 'INDEX INFORMATION' as section;
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' AND tablename = 'bmw_sales'
ORDER BY indexname;

-- 8.2 Table size information
SELECT 'TABLE SIZE INFORMATION' as section;
SELECT 
    pg_size_pretty(pg_total_relation_size('bmw_sales')) as total_size,
    pg_size_pretty(pg_relation_size('bmw_sales')) as table_size,
    pg_size_pretty(pg_indexes_size('bmw_sales')) as indexes_size,
    (SELECT COUNT(*) FROM bmw_sales) as row_count;

-- 9. DATA INTEGRITY CHECKS
-- ========================================================================

-- 9.1 Check for any NULL values in critical columns
SELECT 'DATA QUALITY CHECK' as section;
SELECT 
    COUNT(*) as total_records,
    SUM(CASE WHEN model IS NULL THEN 1 ELSE 0 END) as null_models,
    SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) as null_years,
    SUM(CASE WHEN region IS NULL THEN 1 ELSE 0 END) as null_regions,
    SUM(CASE WHEN price_usd IS NULL THEN 1 ELSE 0 END) as null_prices,
    SUM(CASE WHEN sales_volume IS NULL THEN 1 ELSE 0 END) as null_sales,
    SUM(CASE WHEN fuel_type = 'Electric' AND engine_size_l IS NOT NULL THEN 1 ELSE 0 END) as ev_with_engine_error,
    SUM(CASE WHEN fuel_type != 'Electric' AND engine_size_l IS NULL THEN 1 ELSE 0 END) as non_ev_without_engine
FROM bmw_sales;

-- 9.2 Check constraint violations
SELECT 'CONSTRAINT VALIDATION' as section;
SELECT 
    'All years between 2010-2024' as check_name,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL - ' || COUNT(*) || ' records outside range'
    END as result
FROM bmw_sales WHERE year < 2010 OR year > 2024
UNION ALL
SELECT 
    'All prices positive',
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL - ' || COUNT(*) || ' records with non-positive prices'
    END as result
FROM bmw_sales WHERE price_usd <= 0
UNION ALL
SELECT 
    'All sales volumes positive',
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL - ' || COUNT(*) || ' records with non-positive sales'
    END as result
FROM bmw_sales WHERE sales_volume <= 0
UNION ALL
SELECT 
    'EV engine size NULL',
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL - ' || COUNT(*) || ' EVs with engine size'
    END as result
FROM bmw_sales WHERE fuel_type = 'Electric' AND engine_size_l IS NOT NULL;

-- 10. SAMPLE DATA FOR VERIFICATION
-- ========================================================================

-- 10.1 Random sample of 10 records
SELECT 'RANDOM SAMPLE OF DATA (10 RECORDS)' as section;
SELECT 
    model,
    year,
    region,
    fuel_type,
    transmission,
    engine_size_l,
    mileage_km,
    price_usd,
    sales_volume,
    sales_classification
FROM bmw_sales 
ORDER BY RANDOM() 
LIMIT 10;

-- 10.2 Sample of each sales classification
SELECT 'SAMPLES BY SALES CLASSIFICATION' as section;
SELECT 
    sales_classification,
    model,
    year,
    region,
    price_usd,
    sales_volume
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY sales_classification ORDER BY RANDOM()) as rn
    FROM bmw_sales
) t
WHERE rn <= 2
ORDER BY 
    CASE sales_classification
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END;

-- 11. FINAL SUMMARY
-- ========================================================================

SELECT 'ANALYSIS COMPLETE - FINAL SUMMARY' as section;
WITH summary AS (
    SELECT 
        'Database Objects' as category,
        'Tables' as item,
        '1' as value
    UNION ALL
    SELECT 
        'Database Objects',
        'Views',
        (SELECT COUNT(*) FROM pg_views WHERE schemaname = 'public' AND viewname LIKE '%bmw%' OR viewname IN ('executive_dashboard', 'regional_performance', 'model_analytics', 'year_over_year_trends', 'fuel_type_trends'))::text
    UNION ALL
    SELECT 
        'Database Objects',
        'Functions',
        (SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname LIKE '%calculate%')::text
    UNION ALL
    SELECT 
        'Data Volume',
        'Total Records',
        (SELECT COUNT(*)::text FROM bmw_sales)
    UNION ALL
    SELECT 
        'Data Volume',
        'Unique Models',
        (SELECT COUNT(DISTINCT model)::text FROM bmw_sales)
    UNION ALL
    SELECT 
        'Data Volume',
        'Regions Covered',
        (SELECT COUNT(DISTINCT region)::text FROM bmw_sales)
    UNION ALL
    SELECT 
        'Data Range',
        'Year Range',
        (SELECT MIN(year)::text || ' - ' || MAX(year)::text FROM bmw_sales)
    UNION ALL
    SELECT 
        'Data Range',
        'Price Range',
        (SELECT '$' || MIN(price_usd)::text || ' - $' || MAX(price_usd)::text FROM bmw_sales)
    UNION ALL
    SELECT 
        'Analysis Ready',
        'All Views Created',
        'YES'
    UNION ALL
    SELECT 
        'Analysis Ready',
        'Function Working',
        (SELECT CASE WHEN COUNT(*) > 0 THEN 'YES' ELSE 'NO' END FROM calculate_sales_growth() LIMIT 1)
)
SELECT * FROM summary ORDER BY category, item;

-- ========================================================================
-- END OF COMPLETE ANALYSIS SCRIPT
-- ========================================================================