
-- =====================================================
-- DATABRIDGE
-- STEP 04: SAMPLE DATA INSERTION
-- MYSQL 8.0+
-- RUN ONCE ON A CLEAN DATABASE
-- =====================================================

USE DataBridge;

-- 1. USERS
INSERT INTO users
(user_id, full_name, email, password_hash, role)
VALUES
(1, 'Admin User', 'admin@databridge.com', 'DEMO_HASH_ADMIN', 'ADMIN'),
(2, 'Rahul Sharma', 'rahul@databridge.com', 'DEMO_HASH_RAHUL', 'MANAGER'),
(3, 'Priya Verma', 'priya@databridge.com', 'DEMO_HASH_PRIYA', 'OPERATOR');


-- 2. BUSINESSES
INSERT INTO businesses
(business_id, business_name, business_type,
 contact_email, contact_phone, address, created_by)
VALUES
(1, 'City Care Pharmacy', 'PHARMACY',
 'citycare@example.com', '9876543210',
 'Pune, Maharashtra', 1),

(2, 'Fresh Mart Store', 'RETAIL',
 'freshmart@example.com', '9876501234',
 'Pune, Maharashtra', 2);


-- 3. MIGRATION JOBS
INSERT INTO migration_jobs
(job_id, business_id, created_by, job_name, target_entity,
 migration_status, total_records, successful_records,
 rejected_records)
VALUES
(1, 1, 2, 'Pharmacy Customer Migration', 'CUSTOMERS',
 'COMPLETED', 3, 2, 1),

(2, 1, 2, 'Pharmacy Product Migration', 'PRODUCTS',
 'COMPLETED', 3, 2, 1),

(3, 2, 3, 'Retail Customer Migration', 'CUSTOMERS',
 'PENDING', 2, 0, 0);


-- 4. SOURCE FILES
INSERT INTO source_files
(file_id, job_id, file_name, file_type, file_size_bytes)
VALUES
(1, 1, 'pharmacy_customers.xlsx', 'XLSX', 20480),
(2, 2, 'pharmacy_products.csv', 'CSV', 10240),
(3, 3, 'retail_customers.xlsx', 'XLSX', 15360);


-- 5. COLUMN MAPPINGS
INSERT INTO column_mappings
(file_id, source_column, target_column,
 target_entity, target_data_type, is_required)
VALUES
(1, 'Customer ID', 'legacy_customer_id',
 'CUSTOMERS', 'VARCHAR', TRUE),

(1, 'Name', 'customer_name',
 'CUSTOMERS', 'VARCHAR', TRUE),

(1, 'Email Address', 'email',
 'CUSTOMERS', 'VARCHAR', FALSE),

(1, 'Phone Number', 'phone',
 'CUSTOMERS', 'VARCHAR', FALSE),

(2, 'Product ID', 'legacy_product_id',
 'PRODUCTS', 'VARCHAR', TRUE),

(2, 'Product Name', 'product_name',
 'PRODUCTS', 'VARCHAR', TRUE),

(2, 'Price', 'price',
 'PRODUCTS', 'DECIMAL', TRUE),

(2, 'Quantity', 'quantity',
 'PRODUCTS', 'INT', FALSE);


-- 6. STAGING RECORDS
INSERT INTO staging_records
(staging_id, file_id, source_row_number,
 raw_data, mapped_data, target_entity, record_status)
VALUES

(1, 1, 2,
 '{"Customer ID":"CUST-101","Name":"Amit Sharma","Email Address":"amit@example.com","Phone Number":"9876543210"}',
 '{"legacy_customer_id":"CUST-101","customer_name":"Amit Sharma","email":"amit@example.com","phone":"9876543210"}',
 'CUSTOMERS', 'MIGRATED'),

(2, 1, 3,
 '{"Customer ID":"CUST-102","Name":"Neha Verma","Email Address":"","Phone Number":"9876543211"}',
 '{"legacy_customer_id":"CUST-102","customer_name":"Neha Verma","email":null,"phone":"9876543211"}',
 'CUSTOMERS', 'MIGRATED'),

(3, 1, 4,
 '{"Customer ID":"CUST-103","Name":"","Email Address":"invalid-email","Phone Number":"98765"}',
 NULL,
 'CUSTOMERS', 'REJECTED'),

(4, 2, 2,
 '{"Product ID":"PROD-101","Product Name":"Paracetamol","Price":"25.50","Quantity":"100"}',
 '{"legacy_product_id":"PROD-101","product_name":"Paracetamol","price":25.50,"quantity":100}',
 'PRODUCTS', 'MIGRATED'),

(5, 2, 3,
 '{"Product ID":"PROD-102","Product Name":"Vitamin C","Price":"-50","Quantity":"20"}',
 NULL,
 'PRODUCTS', 'REJECTED');


-- 7. VALIDATION ISSUES
INSERT INTO validation_issues
(staging_id, column_name, issue_type,
 issue_description, severity)
VALUES
(3, 'Name', 'MISSING_VALUE',
 'Customer name is missing', 'HIGH'),

(3, 'Email Address', 'INVALID_FORMAT',
 'Email address format is invalid', 'MEDIUM'),

(5, 'Price', 'INVALID_DATA',
 'Product price cannot be negative', 'HIGH');


-- 8. CUSTOMERS
INSERT INTO customers
(customer_id, business_id, legacy_customer_id,
 customer_name, email, phone, address)
VALUES
(1, 1, 'CUST-101', 'Amit Sharma',
 'amit@example.com', '9876543210', 'Pune'),

(2, 1, 'CUST-102', 'Neha Verma',
 NULL, '9876543211', 'Pune');


-- 9. PRODUCTS
INSERT INTO products
(product_id, business_id, legacy_product_id,
 product_name, category, quantity, price)
VALUES
(1, 1, 'PROD-101', 'Paracetamol',
 'Medicine', 100, 25.50),

(2, 1, 'PROD-103', 'Vitamin D',
 'Medicine', 50, 120.00),

(3, 2, 'PROD-201', 'Rice 5kg',
 'Grocery', 30, 350.00);


-- 10. MIGRATION DIARY
INSERT INTO migration_diary
(staging_id, rejected_data, rejection_reason)
VALUES
(3,
 '{"Customer ID":"CUST-103","Name":"","Email Address":"invalid-email"}',
 'Missing customer name and invalid email'),

(5,
 '{"Product ID":"PROD-102","Product Name":"Vitamin C","Price":"-50"}',
 'Negative product price');


-- 11. AUDIT LOGS
INSERT INTO audit_logs
(business_id, user_id, job_id, action_type,
 table_name, record_id, action_description)
VALUES
(1, 1, 1, 'MIGRATION_CREATED',
 'migration_jobs', '1',
 'Customer migration job created'),

(1, 2, 1, 'MIGRATION_COMPLETED',
 'customers', '1',
 'Two customer records migrated successfully'),

(1, 2, 2, 'RECORD_REJECTED',
 'staging_records', '5',
 'Invalid product price rejected');


-- FINAL VERIFICATION
SELECT 'USERS' AS Table_Name, COUNT(*) AS Total FROM users
UNION ALL
SELECT 'BUSINESSES', COUNT(*) FROM businesses
UNION ALL
SELECT 'MIGRATION_JOBS', COUNT(*) FROM migration_jobs
UNION ALL
SELECT 'SOURCE_FILES', COUNT(*) FROM source_files
UNION ALL
SELECT 'COLUMN_MAPPINGS', COUNT(*) FROM column_mappings
UNION ALL
SELECT 'STAGING_RECORDS', COUNT(*) FROM staging_records
UNION ALL
SELECT 'VALIDATION_ISSUES', COUNT(*) FROM validation_issues
UNION ALL
SELECT 'CUSTOMERS', COUNT(*) FROM customers
UNION ALL
SELECT 'PRODUCTS', COUNT(*) FROM products
UNION ALL
SELECT 'MIGRATION_DIARY', COUNT(*) FROM migration_diary
UNION ALL
SELECT 'AUDIT_LOGS', COUNT(*) FROM audit_logs;
