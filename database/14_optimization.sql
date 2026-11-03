
USE DataBridge;

-- =========================================
-- INDEX 1: CUSTOMER NAME
-- =========================================

CREATE INDEX idx_customer_name
ON customers(customer_name);


-- =========================================
-- INDEX 2: PRODUCT NAME
-- =========================================

CREATE INDEX idx_product_name
ON products(product_name);


-- =========================================
-- INDEX 3: MIGRATION JOB STATUS
-- =========================================

CREATE INDEX idx_job_status
ON migration_jobs(migration_status);


-- =========================================
-- INDEX 4: STAGING RECORD STATUS
-- =========================================

CREATE INDEX idx_staging_status
ON staging_records(record_status);


-- =========================================
-- INDEX 5: AUDIT LOG ACTION TYPE
-- =========================================

CREATE INDEX idx_audit_action
ON audit_logs(action_type);


-- =========================================
-- TEST INDEXES
-- =========================================

SHOW INDEX FROM customers;

SHOW INDEX FROM products;

SHOW INDEX FROM migration_jobs;

SHOW INDEX FROM staging_records;

SHOW INDEX FROM audit_logs;


-- =========================================
-- QUERY OPTIMIZATION USING EXPLAIN
-- =========================================

EXPLAIN
SELECT *
FROM customers
WHERE customer_name = 'Amit Sharma';

EXPLAIN
SELECT *
FROM products
WHERE product_name = 'Paracetamol';

EXPLAIN
SELECT *
FROM migration_jobs
WHERE migration_status = 'COMPLETED';

EXPLAIN
SELECT *
FROM staging_records
WHERE record_status = 'REJECTED';
