
USE DataBridge;

-- =========================================
-- TEST 1: DATABASE TABLES
-- =========================================

SHOW TABLES;


-- =========================================
-- TEST 2: TABLE RECORD COUNTS
-- =========================================

SELECT 'users' AS table_name, COUNT(*) AS total FROM users
UNION ALL
SELECT 'businesses', COUNT(*) FROM businesses
UNION ALL
SELECT 'migration_jobs', COUNT(*) FROM migration_jobs
UNION ALL
SELECT 'source_files', COUNT(*) FROM source_files
UNION ALL
SELECT 'column_mappings', COUNT(*) FROM column_mappings
UNION ALL
SELECT 'staging_records', COUNT(*) FROM staging_records
UNION ALL
SELECT 'validation_issues', COUNT(*) FROM validation_issues
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'migration_diary', COUNT(*) FROM migration_diary
UNION ALL
SELECT 'audit_logs', COUNT(*) FROM audit_logs;


-- =========================================
-- TEST 3: MIGRATION DASHBOARD
-- =========================================

SELECT * FROM vw_migration_dashboard;


-- =========================================
-- TEST 4: PROCEDURES
-- =========================================

CALL sp_get_job_summary(1);

CALL sp_get_rejected_records(1);


-- =========================================
-- TEST 5: FUNCTIONS
-- =========================================

SELECT fn_is_valid_email('hello@gmail.com');

SELECT fn_clean_name('  DataBridge   Project  ');

SELECT fn_success_rate(1);


-- =========================================
-- TEST 6: TRIGGERS
-- =========================================

SHOW TRIGGERS;


-- =========================================
-- TEST 7: INDEXES
-- =========================================

SHOW INDEX FROM customers;

SHOW INDEX FROM products;


-- =========================================
-- TEST 8: AUDIT LOGS
-- =========================================

SELECT * FROM audit_logs
ORDER BY audit_id DESC
LIMIT 10;
