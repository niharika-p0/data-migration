
USE DataBridge;

-- =========================================
-- VIEW 1: MIGRATION DASHBOARD
-- =========================================

CREATE OR REPLACE VIEW vw_migration_dashboard AS
SELECT
    mj.job_id,
    mj.job_name,
    b.business_name,
    mj.target_entity,
    mj.migration_status,
    mj.total_records,
    mj.successful_records,
    mj.rejected_records,
    CASE
        WHEN mj.total_records = 0 THEN 0
        ELSE ROUND(
            mj.successful_records * 100.0 /
            mj.total_records, 2
        )
    END AS success_percentage
FROM migration_jobs mj
JOIN businesses b
    ON mj.business_id = b.business_id;


-- =========================================
-- VIEW 2: REJECTED RECORDS
-- =========================================

CREATE OR REPLACE VIEW vw_rejected_records AS
SELECT
    s.staging_id,
    f.job_id,
    s.target_entity,
    s.source_row_number,
    s.raw_data,
    d.rejection_reason,
    d.resolution_status
FROM staging_records s
JOIN source_files f
    ON s.file_id = f.file_id
LEFT JOIN migration_diary d
    ON s.staging_id = d.staging_id
WHERE s.record_status = 'REJECTED';


-- =========================================
-- VIEW 3: CUSTOMER DETAILS
-- =========================================

CREATE OR REPLACE VIEW vw_customer_details AS
SELECT
    c.customer_id,
    c.legacy_customer_id,
    c.customer_name,
    c.email,
    c.phone,
    b.business_name
FROM customers c
JOIN businesses b
    ON c.business_id = b.business_id;


-- =========================================
-- VIEW 4: PRODUCT INVENTORY
-- =========================================

CREATE OR REPLACE VIEW vw_product_inventory AS
SELECT
    p.product_id,
    p.legacy_product_id,
    p.product_name,
    p.category,
    p.quantity,
    p.price,
    b.business_name
FROM products p
JOIN businesses b
    ON p.business_id = b.business_id;


-- =========================================
-- TEST ALL VIEWS
-- =========================================

SELECT * FROM vw_migration_dashboard;

SELECT * FROM vw_rejected_records;

SELECT * FROM vw_customer_details;

SELECT * FROM vw_product_inventory;
