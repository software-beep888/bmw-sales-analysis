-- ========================================================================
-- BMW VEHICLE SALES DATABASE - COMPLETE ANALYSIS SCRIPT (FIXED VERSION)
-- Author: Senior Data Engineer
-- Date: 2024
-- Description: Production-ready PostgreSQL analysis for BMW sales data
-- Note: Fixed ambiguous column reference and all other issues
-- ========================================================================

-- SECTION 1: CLEANUP AND PREPARATION
-- ========================================================================

-- Drop existing objects to ensure clean environment
DROP TABLE IF EXISTS bmw_sales CASCADE;
DROP VIEW IF EXISTS executive_dashboard CASCADE;
DROP VIEW IF EXISTS regional_performance CASCADE;
DROP VIEW IF EXISTS model_analytics CASCADE;
DROP VIEW IF EXISTS year_over_year_trends CASCADE;
DROP VIEW IF EXISTS fuel_type_trends CASCADE;
DROP FUNCTION IF EXISTS calculate_sales_growth CASCADE;

-- SECTION 2: TABLE CREATION WITH CONSTRAINTS (FIXED)
-- ========================================================================

CREATE TABLE bmw_sales (
    id SERIAL PRIMARY KEY,
    model VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL CHECK (year BETWEEN 2010 AND 2024),
    region VARCHAR(50) NOT NULL,
    color VARCHAR(20),
    fuel_type VARCHAR(20) NOT NULL CHECK (fuel_type IN ('Petrol', 'Diesel', 'Hybrid', 'Electric')),
    transmission VARCHAR(20) NOT NULL CHECK (transmission IN ('Manual', 'Automatic')),
    
    -- FIXED: Engine size can be NULL for Electric vehicles, valid range for non-NULL values
    engine_size_l NUMERIC(3,1),
    mileage_km INTEGER CHECK (mileage_km >= 0),
    price_usd NUMERIC(10,2) CHECK (price_usd > 0),
    sales_volume INTEGER NOT NULL CHECK (sales_volume > 0),
    
    -- Sales classification thresholds (High >= 7000, Medium 3000-6999, Low < 3000)
    sales_classification VARCHAR(10) GENERATED ALWAYS AS (
        CASE 
            WHEN sales_volume >= 7000 THEN 'High'
            WHEN sales_volume >= 3000 THEN 'Medium'
            ELSE 'Low'
        END
    ) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- FIXED: Engine size constraint allows NULL for Electric vehicles
    CONSTRAINT valid_engine_size CHECK (
        engine_size_l IS NULL OR (engine_size_l BETWEEN 1.0 AND 6.0)
    ),
    CONSTRAINT valid_mileage CHECK (mileage_km <= 200000)
);

COMMENT ON TABLE bmw_sales IS 'BMW vehicle sales data (2010-2024)';
COMMENT ON COLUMN bmw_sales.engine_size_l IS 'Engine size in liters (NULL for Electric vehicles)';
COMMENT ON COLUMN bmw_sales.sales_classification IS 'Generated column: High(≥7000), Medium(3000-6999), Low(<3000)';

-- SECTION 3: INSERT REALISTIC SAMPLE DATA (2020-2024) WITH FIXED EV DATA
-- ========================================================================

INSERT INTO bmw_sales (model, year, region, color, fuel_type, transmission, engine_size_l, mileage_km, price_usd, sales_volume)
SELECT 
    Model,
    Year,
    Region,
    Color,
    Fuel_Type,
    Transmission,
    -- FIXED: Set engine_size_l to NULL for Electric vehicles
    CASE 
        WHEN Fuel_Type = 'Electric' THEN NULL
        ELSE Engine_Size_L
    END as engine_size_l,
    Mileage_KM,
    Price_USD,
    Sales_Volume
FROM (VALUES
    -- 2024 Models
    ('X3', 2024, 'Middle East', 'Blue', 'Petrol', 'Automatic', 1.7, 27255, 60971, 4047),
    ('i3', 2024, 'Middle East', 'Red', 'Petrol', 'Automatic', 3.5, 135958, 69578, 173),
    ('5 Series', 2024, 'Asia', 'Blue', 'Electric', 'Manual', NULL, 157789, 86855, 648),
    ('X6', 2023, 'Africa', 'White', 'Hybrid', 'Automatic', 2.8, 84367, 112542, 7933),
    ('i8', 2023, 'Europe', 'Blue', 'Diesel', 'Automatic', 3.8, 78573, 118317, 7168),
    
    -- 2023 Models
    ('5 Series', 2023, 'North America', 'Blue', 'Petrol', 'Automatic', 1.9, 139301, 85255, 4180),
    ('X5', 2023, 'South America', 'Black', 'Diesel', 'Manual', 4.4, 183143, 86846, 5598),
    ('3 Series', 2023, 'Europe', 'Black', 'Electric', 'Manual', NULL, 128295, 86402, 4266),
    ('7 Series', 2023, 'North America', 'Grey', 'Diesel', 'Automatic', 4.8, 64153, 117121, 4823),
    
    -- 2022 Models
    ('5 Series', 2022, 'North America', 'Blue', 'Petrol', 'Automatic', 4.5, 10991, 113265, 6994),
    ('i8', 2022, 'Europe', 'White', 'Diesel', 'Manual', 1.8, 196741, 55064, 7949),
    ('X3', 2022, 'Middle East', 'Grey', 'Petrol', 'Manual', 3.5, 52217, 78144, 9420),
    ('M5', 2022, 'North America', 'Black', 'Petrol', 'Automatic', 3.5, 56293, 58700, 249),
    
    -- 2021 Models
    ('X5', 2021, 'South America', 'Red', 'Diesel', 'Manual', 2.2, 184981, 47527, 6273),
    ('M5', 2021, 'Asia', 'Red', 'Hybrid', 'Automatic', 3.0, 105162, 32076, 9469),
    ('i8', 2021, 'South America', 'Silver', 'Diesel', 'Manual', 4.8, 3188, 64577, 448),
    ('X3', 2021, 'Asia', 'Silver', 'Hybrid', 'Automatic', 3.8, 57759, 119692, 6782),
    
    -- 2020 Models
    ('7 Series', 2020, 'South America', 'Black', 'Diesel', 'Manual', 2.1, 122131, 49898, 3080),
    ('5 Series', 2020, 'Africa', 'White', 'Electric', 'Manual', NULL, 163444, 119486, 4668),
    ('7 Series', 2020, 'North America', 'Silver', 'Diesel', 'Automatic', 3.8, 27403, 100015, 8111),
    ('M3', 2020, 'Africa', 'Black', 'Petrol', 'Manual', 3.6, 82668, 86748, 3929)
) AS sample_data(Model, Year, Region, Color, Fuel_Type, Transmission, Engine_Size_L, Mileage_KM, Price_USD, Sales_Volume);

-- SECTION 4: PERFORMANCE INDEXES
-- ========================================================================

-- Primary index already created via PRIMARY KEY constraint

-- Foreign key simulation indexes
CREATE INDEX idx_bmw_sales_year ON bmw_sales(year);
CREATE INDEX idx_bmw_sales_region ON bmw_sales(region);
CREATE INDEX idx_bmw_sales_model ON bmw_sales(model);
CREATE INDEX idx_bmw_sales_fuel_type ON bmw_sales(fuel_type);
CREATE INDEX idx_bmw_sales_classification ON bmw_sales(sales_classification);
CREATE INDEX idx_bmw_sales_price ON bmw_sales(price_usd);
CREATE INDEX idx_bmw_sales_volume ON bmw_sales(sales_volume);

-- Composite indexes for common query patterns
CREATE INDEX idx_bmw_sales_year_region ON bmw_sales(year, region);
CREATE INDEX idx_bmw_sales_model_year ON bmw_sales(model, year);
CREATE INDEX idx_bmw_sales_fuel_year ON bmw_sales(fuel_type, year);

-- Partial index for EVs (since engine_size_l is NULL for them)
CREATE INDEX idx_bmw_sales_ev ON bmw_sales(fuel_type) WHERE fuel_type = 'Electric';

-- SECTION 5: ANALYTICAL VIEWS
-- ========================================================================

-- View 1: Executive Dashboard KPIs
CREATE OR REPLACE VIEW executive_dashboard AS
WITH yearly_stats AS (
    SELECT 
        year,
        COUNT(*) as total_records,
        SUM(sales_volume) as total_sales,
        AVG(price_usd) as avg_price,
        AVG(sales_volume) as avg_sales_per_model,
        SUM(sales_volume * price_usd) / 1000000 as revenue_millions
    FROM bmw_sales
    GROUP BY year
),
current_year_stats AS (
    SELECT * FROM yearly_stats WHERE year = (SELECT MAX(year) FROM bmw_sales)
),
previous_year_stats AS (
    SELECT * FROM yearly_stats WHERE year = (SELECT MAX(year)-1 FROM bmw_sales)
)
SELECT 
    cy.year as current_year,
    cy.total_sales as current_year_sales,
    py.total_sales as previous_year_sales,
    ROUND(
        (cy.total_sales - COALESCE(py.total_sales, cy.total_sales)) / 
        NULLIF(COALESCE(py.total_sales, cy.total_sales), 0) * 100, 2
    ) as yoy_growth_percent,
    ROUND(cy.avg_price, 2) as avg_price,
    ROUND(cy.avg_sales_per_model, 2) as avg_sales_per_model,
    ROUND(cy.revenue_millions, 2) as revenue_millions,
    (SELECT COUNT(DISTINCT model) FROM bmw_sales WHERE year = cy.year) as unique_models,
    (SELECT COUNT(DISTINCT region) FROM bmw_sales WHERE year = cy.year) as regions_covered
FROM current_year_stats cy
LEFT JOIN previous_year_stats py ON 1=1;

-- View 2: Regional Performance
CREATE OR REPLACE VIEW regional_performance AS
SELECT 
    region,
    year,
    COUNT(*) as models_offered,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    ROUND(AVG(mileage_km), 2) as avg_mileage,
    ROUND(SUM(sales_volume * price_usd) / 1000000, 2) as revenue_millions,
    ROUND(
        SUM(CASE WHEN fuel_type = 'Electric' THEN sales_volume ELSE 0 END) * 100.0 / 
        NULLIF(SUM(sales_volume), 0), 2
    ) as electric_percentage,
    STRING_AGG(DISTINCT model, ', ' ORDER BY model) as available_models
FROM bmw_sales
GROUP BY region, year
ORDER BY region, year DESC;

-- View 3: Model Analytics
CREATE OR REPLACE VIEW model_analytics AS
SELECT 
    model,
    COUNT(DISTINCT year) as years_active,
    MIN(year) as first_year,
    MAX(year) as last_year,
    SUM(sales_volume) as lifetime_sales,
    ROUND(AVG(sales_volume), 2) as avg_yearly_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    ROUND(AVG(engine_size_l), 2) as avg_engine_size,
    STRING_AGG(DISTINCT fuel_type, ', ' ORDER BY fuel_type) as fuel_types_offered,
    STRING_AGG(DISTINCT region, ', ' ORDER BY region) as regions_available,
    ROUND(
        SUM(CASE WHEN sales_classification = 'High' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(*), 0), 2
    ) as high_sales_percentage
FROM bmw_sales
GROUP BY model
ORDER BY lifetime_sales DESC;

-- View 4: Year-over-Year Trends
CREATE OR REPLACE VIEW year_over_year_trends AS
WITH yearly_aggregates AS (
    SELECT 
        year,
        fuel_type,
        SUM(sales_volume) as total_sales,
        COUNT(DISTINCT model) as models_count,
        AVG(price_usd) as avg_price
    FROM bmw_sales
    GROUP BY year, fuel_type
),
yoy_calculation AS (
    SELECT 
        year,
        fuel_type,
        total_sales,
        LAG(total_sales) OVER (PARTITION BY fuel_type ORDER BY year) as prev_year_sales,
        models_count,
        avg_price,
        ROUND(
            (total_sales - LAG(total_sales) OVER (PARTITION BY fuel_type ORDER BY year)) * 100.0 / 
            NULLIF(LAG(total_sales) OVER (PARTITION BY fuel_type ORDER BY year), 0), 2
        ) as yoy_growth_percent
    FROM yearly_aggregates
)
SELECT 
    year,
    fuel_type,
    total_sales,
    prev_year_sales,
    models_count,
    ROUND(avg_price, 2) as avg_price,
    yoy_growth_percent,
    CASE 
        WHEN yoy_growth_percent > 10 THEN 'Strong Growth'
        WHEN yoy_growth_percent > 0 THEN 'Moderate Growth'
        WHEN yoy_growth_percent < -10 THEN 'Significant Decline'
        WHEN yoy_growth_percent < 0 THEN 'Moderate Decline'
        ELSE 'Stable'
    END as growth_status
FROM yoy_calculation
ORDER BY fuel_type, year DESC;

-- View 5: Fuel Type Trends
CREATE OR REPLACE VIEW fuel_type_trends AS
SELECT 
    fuel_type,
    year,
    COUNT(*) as records,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    ROUND(AVG(engine_size_l), 2) as avg_engine_size,
    ROUND(
        SUM(CASE WHEN transmission = 'Automatic' THEN sales_volume ELSE 0 END) * 100.0 / 
        NULLIF(SUM(sales_volume), 0), 2
    ) as automatic_percentage,
    STRING_AGG(DISTINCT model, ', ' ORDER BY model) as models_available
FROM bmw_sales
GROUP BY fuel_type, year
ORDER BY fuel_type, year DESC;

-- SECTION 6: POSTGRESQL FUNCTIONS (FIXED AMBIGUOUS COLUMN REFERENCE)
-- ========================================================================

-- Function 1: Sales Growth Analysis
CREATE OR REPLACE FUNCTION calculate_sales_growth(
    p_year INTEGER DEFAULT NULL,
    p_region VARCHAR DEFAULT NULL,
    p_model VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    analysis_year INTEGER,
    analysis_region VARCHAR,
    analysis_model VARCHAR,
    current_sales BIGINT,
    previous_sales BIGINT,
    sales_change BIGINT,
    growth_percent NUMERIC(10,2),
    growth_status VARCHAR(20)
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH current_data AS (
        SELECT 
            bs.year as data_year,
            COALESCE(p_region, bs.region) as data_region,
            COALESCE(p_model, bs.model) as data_model,
            SUM(bs.sales_volume) as data_sales
        FROM bmw_sales bs
        WHERE 
            (p_year IS NULL OR bs.year = p_year) AND
            (p_region IS NULL OR bs.region = p_region) AND
            (p_model IS NULL OR bs.model = p_model)
        GROUP BY bs.year, bs.region, bs.model
    ),
    comparison_data AS (
        SELECT 
            cd.*,
            LAG(cd.data_sales) OVER (PARTITION BY cd.data_region, cd.data_model ORDER BY cd.data_year) as prev_sales
        FROM current_data cd
    )
    SELECT 
        cd.data_year::INTEGER as analysis_year,
        cd.data_region::VARCHAR as analysis_region,
        cd.data_model::VARCHAR as analysis_model,
        cd.data_sales::BIGINT as current_sales,
        cd.prev_sales::BIGINT as previous_sales,
        (cd.data_sales - cd.prev_sales)::BIGINT as sales_change,
        ROUND(
            (cd.data_sales - cd.prev_sales) * 100.0 / 
            NULLIF(cd.prev_sales, 0), 2
        ) as growth_percent,
        CASE 
            WHEN (cd.data_sales - cd.prev_sales) * 100.0 / NULLIF(cd.prev_sales, 0) > 15 THEN 'Rapid Growth'
            WHEN (cd.data_sales - cd.prev_sales) * 100.0 / NULLIF(cd.prev_sales, 0) > 5 THEN 'Steady Growth'
            WHEN (cd.data_sales - cd.prev_sales) * 100.0 / NULLIF(cd.prev_sales, 0) < -15 THEN 'Sharp Decline'
            WHEN (cd.data_sales - cd.prev_sales) * 100.0 / NULLIF(cd.prev_sales, 0) < -5 THEN 'Moderate Decline'
            ELSE 'Stable'
        END::VARCHAR(20) as growth_status
    FROM comparison_data cd
    WHERE cd.prev_sales IS NOT NULL
    ORDER BY cd.data_year DESC, growth_percent DESC;
END;
$$;

-- SECTION 7: ADVANCED ANALYTICS QUERIES
-- ========================================================================

-- Query 1: Overall Summary Statistics
SELECT 
    'Overall Summary' as metric,
    COUNT(*) as total_records,
    COUNT(DISTINCT model) as unique_models,
    COUNT(DISTINCT region) as regions_covered,
    COUNT(DISTINCT year) as years_covered,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    ROUND(AVG(engine_size_l), 2) as avg_engine_size,
    ROUND(AVG(mileage_km), 2) as avg_mileage
FROM bmw_sales;

-- Query 2: Model Performance Analysis
WITH model_stats AS (
    SELECT 
        model,
        SUM(sales_volume) as total_sales,
        AVG(price_usd) as avg_price,
        AVG(sales_volume) as avg_yearly_sales,
        COUNT(DISTINCT year) as years_active
    FROM bmw_sales
    GROUP BY model
)
SELECT 
    model,
    total_sales,
    ROUND(avg_price, 2) as avg_price,
    ROUND(avg_yearly_sales, 2) as avg_yearly_sales,
    years_active,
    RANK() OVER (ORDER BY total_sales DESC) as sales_rank,
    RANK() OVER (ORDER BY avg_price DESC) as price_rank,
    CASE 
        WHEN total_sales > (SELECT AVG(total_sales) * 1.5 FROM model_stats) THEN 'Top Performer'
        WHEN total_sales < (SELECT AVG(total_sales) * 0.5 FROM model_stats) THEN 'Low Performer'
        ELSE 'Average Performer'
    END as performance_category
FROM model_stats
ORDER BY total_sales DESC;

-- Query 3: Regional Analysis with Market Share
WITH regional_totals AS (
    SELECT 
        region,
        SUM(sales_volume) as region_sales,
        AVG(price_usd) as avg_price
    FROM bmw_sales
    GROUP BY region
),
grand_total AS (
    SELECT SUM(sales_volume) as total_sales FROM bmw_sales
)
SELECT 
    rt.region,
    rt.region_sales,
    ROUND(rt.region_sales * 100.0 / gt.total_sales, 2) as market_share_percent,
    ROUND(rt.avg_price, 2) as avg_price,
    (SELECT COUNT(DISTINCT model) FROM bmw_sales bs WHERE bs.region = rt.region) as models_available,
    (SELECT STRING_AGG(DISTINCT fuel_type, ', ') FROM bmw_sales bs WHERE bs.region = rt.region) as fuel_types
FROM regional_totals rt, grand_total gt
ORDER BY region_sales DESC;

-- Query 4: Year-over-Year Growth Analysis
WITH yearly_sales AS (
    SELECT 
        year,
        SUM(sales_volume) as total_sales,
        LAG(SUM(sales_volume)) OVER (ORDER BY year) as prev_year_sales
    FROM bmw_sales
    GROUP BY year
)
SELECT 
    year,
    total_sales,
    prev_year_sales,
    (total_sales - prev_year_sales) as absolute_change,
    ROUND(
        (total_sales - prev_year_sales) * 100.0 / 
        NULLIF(prev_year_sales, 0), 2
    ) as percent_change,
    CASE 
        WHEN total_sales > prev_year_sales THEN 'Growth'
        WHEN total_sales < prev_year_sales THEN 'Decline'
        ELSE 'No Change'
    END as trend
FROM yearly_sales
ORDER BY year DESC;

-- Query 5: Fuel Type Analysis
SELECT 
    fuel_type,
    COUNT(*) as records,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    ROUND(AVG(engine_size_l), 2) as avg_engine_size,
    ROUND(AVG(mileage_km), 2) as avg_mileage,
    ROUND(
        SUM(CASE WHEN transmission = 'Automatic' THEN sales_volume ELSE 0 END) * 100.0 / 
        NULLIF(SUM(sales_volume), 0), 2
    ) as automatic_percentage,
    ROUND(
        SUM(CASE WHEN year >= 2020 THEN sales_volume ELSE 0 END) * 100.0 / 
        NULLIF(SUM(sales_volume), 0), 2
    ) as recent_sales_percentage
FROM bmw_sales
GROUP BY fuel_type
ORDER BY total_sales DESC;

-- Query 6: Price Segmentation Analysis
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
    ) as sales_percentage
FROM price_segments
GROUP BY price_segment
ORDER BY 
    CASE price_segment
        WHEN 'Budget (<50k)' THEN 1
        WHEN 'Mid-Range (50k-80k)' THEN 2
        WHEN 'Premium (80k-120k)' THEN 3
        ELSE 4
    END;

-- Query 7: Sales Classification Analysis
SELECT 
    sales_classification,
    COUNT(*) as records_count,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    ROUND(AVG(engine_size_l), 2) as avg_engine_size,
    ROUND(AVG(mileage_km), 2) as avg_mileage,
    STRING_AGG(DISTINCT model, ', ' ORDER BY model) as models_in_category,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM bmw_sales), 2
    ) as percentage_of_total
FROM bmw_sales
GROUP BY sales_classification
ORDER BY 
    CASE sales_classification
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END;

-- Query 8: EV vs ICE Analysis
WITH fuel_categories AS (
    SELECT 
        CASE 
            WHEN fuel_type IN ('Electric', 'Hybrid') THEN 'EV/Hybrid'
            ELSE 'Traditional ICE'
        END as fuel_category,
        sales_volume,
        price_usd,
        engine_size_l,
        year
    FROM bmw_sales
)
SELECT 
    fuel_category,
    COUNT(*) as records,
    SUM(sales_volume) as total_sales,
    ROUND(AVG(price_usd), 2) as avg_price,
    ROUND(AVG(engine_size_l), 2) as avg_engine_size,
    ROUND(
        SUM(CASE WHEN year >= 2020 THEN sales_volume ELSE 0 END) * 100.0 / 
        NULLIF(SUM(sales_volume), 0), 2
    ) as recent_sales_percentage
FROM fuel_categories
GROUP BY fuel_category
ORDER BY total_sales DESC;

-- Query 9: Correlation Analysis
SELECT 
    'Statistical Correlations' as analysis,
    ROUND(CORR(price_usd, sales_volume)::numeric, 4) as price_sales_correlation,
    ROUND(CORR(engine_size_l, price_usd)::numeric, 4) as engine_price_correlation,
    ROUND(CORR(mileage_km, price_usd)::numeric, 4) as mileage_price_correlation,
    ROUND(CORR(engine_size_l, sales_volume)::numeric, 4) as engine_sales_correlation,
    ROUND(CORR(year::numeric, price_usd::numeric)::numeric, 4) as year_price_correlation
FROM bmw_sales;

-- Query 10: Top Performing Models by Region
WITH ranked_models AS (
    SELECT 
        region,
        model,
        SUM(sales_volume) as total_sales,
        AVG(price_usd) as avg_price,
        RANK() OVER (PARTITION BY region ORDER BY SUM(sales_volume) DESC) as sales_rank
    FROM bmw_sales
    GROUP BY region, model
)
SELECT 
    region,
    model,
    total_sales,
    ROUND(avg_price, 2) as avg_price,
    sales_rank
FROM ranked_models
WHERE sales_rank <= 3
ORDER BY region, sales_rank;

-- SECTION 8: VALIDATION AND SUMMARY
-- ========================================================================

-- Final validation query
SELECT 
    'Data Quality Check' as check_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT model) as unique_models,
    MIN(year) as earliest_year,
    MAX(year) as latest_year,
    SUM(CASE WHEN price_usd IS NULL THEN 1 ELSE 0 END) as null_prices,
    SUM(CASE WHEN sales_volume IS NULL THEN 1 ELSE 0 END) as null_sales
FROM bmw_sales
UNION ALL
SELECT 
    'EV Data Integrity',
    COUNT(*) as total_ev_records,
    COUNT(DISTINCT model) as unique_ev_models,
    SUM(CASE WHEN engine_size_l IS NULL THEN 1 ELSE 0 END) as ev_with_null_engine,
    SUM(CASE WHEN engine_size_l IS NOT NULL THEN 1 ELSE 0 END) as ev_with_engine_size,
    0,
    0
FROM bmw_sales
WHERE fuel_type = 'Electric';

-- Display table size information
SELECT 
    pg_size_pretty(pg_total_relation_size('bmw_sales')) as total_size,
    pg_size_pretty(pg_relation_size('bmw_sales')) as table_size,
    pg_size_pretty(pg_indexes_size('bmw_sales')) as indexes_size;

-- Test the growth function
SELECT * FROM calculate_sales_growth(2023, 'North America', '5 Series');

-- Quick summary of views
SELECT 
    'Executive Dashboard' as view_name,
    COUNT(*) as row_count
FROM executive_dashboard
UNION ALL
SELECT 
    'Regional Performance',
    COUNT(*) 
FROM regional_performance
UNION ALL
SELECT 
    'Model Analytics',
    COUNT(*) 
FROM model_analytics
UNION ALL
SELECT 
    'Year-over-Year Trends',
    COUNT(*) 
FROM year_over_year_trends
UNION ALL
SELECT 
    'Fuel Type Trends',
    COUNT(*) 
FROM fuel_type_trends;

-- ========================================================================
-- END OF SCRIPT
-- ========================================================================