USE DataBridge;

-- 1. DATABASE TABLES
SHOW TABLES;

-- 2. PROCEDURES
SHOW PROCEDURE STATUS
WHERE Db = 'DataBridge';

-- 3. FUNCTIONS
SHOW FUNCTION STATUS
WHERE Db = 'DataBridge';

-- 4. TRIGGERS
SHOW TRIGGERS;

-- 5. VIEWS
SHOW FULL TABLES
WHERE Table_type = 'VIEW';

-- 6. MIGRATION DASHBOARD
SELECT * FROM vw_migration_dashboard;

-- 7. CUSTOMER DETAILS
SELECT * FROM vw_customer_details;

-- 8. PRODUCT INVENTORY
SELECT * FROM vw_product_inventory;

-- 9. REJECTED RECORDS
SELECT * FROM vw_rejected_records;

-- 10. MIGRATION DIARY
SELECT * FROM migration_diary;

-- 11. AUDIT HISTORY
SELECT * FROM audit_logs
ORDER BY audit_id DESC;

-- 12. DATABASE TABLE COUNTS
SELECT
    (SELECT COUNT(*) FROM users) AS users,
    (SELECT COUNT(*) FROM businesses) AS businesses,
    (SELECT COUNT(*) FROM migration_jobs) AS migration_jobs,
    (SELECT COUNT(*) FROM customers) AS customers,
    (SELECT COUNT(*) FROM products) AS products,
    (SELECT COUNT(*) FROM staging_records) AS staging_records,
    (SELECT COUNT(*) FROM validation_issues) AS validation_issues,
    (SELECT COUNT(*) FROM migration_diary) AS diary_records,
    (SELECT COUNT(*) FROM audit_logs) AS audit_records;