
-- =====================================================
-- DATABRIDGE
-- STEP 07: ACTUAL DATA MIGRATION
-- MYSQL 8.0+
-- =====================================================

USE DataBridge;

-- PART A: ADD TWO NEW VALID RECORDS

INSERT INTO staging_records
(file_id, source_row_number, raw_data, mapped_data,
 target_entity, record_status)
VALUES
(
    1,
    5,
    '{"Customer ID":"CUST-104","Name":"Rohan Gupta","Email Address":"rohan@example.com","Phone Number":"9876543212"}',
    '{"legacy_customer_id":"CUST-104","customer_name":"Rohan Gupta","email":"rohan@example.com","phone":"9876543212"}',
    'CUSTOMERS',
    'VALID'
),
(
    2,
    4,
    '{"Product ID":"PROD-104","Product Name":"Hand Sanitizer","Price":"85.50","Quantity":"40"}',
    '{"legacy_product_id":"PROD-104","product_name":"Hand Sanitizer","category":"Personal Care","price":85.50,"quantity":40}',
    'PRODUCTS',
    'VALID'
);


-- PART B: CREATE MIGRATION PROCEDURE

DROP PROCEDURE IF EXISTS migrate_valid_records;

DELIMITER $$

CREATE PROCEDURE migrate_valid_records(IN p_job_id INT)
BEGIN

    DECLARE v_business_id INT;
    DECLARE v_user_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Get business and user details
    SELECT business_id, created_by
    INTO v_business_id, v_user_id
    FROM migration_jobs
    WHERE job_id = p_job_id
    FOR UPDATE;


    -- 1. MIGRATE CUSTOMERS

    INSERT INTO customers
    (
        business_id,
        legacy_customer_id,
        customer_name,
        email,
        phone
    )
    SELECT
        v_business_id,
        JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.legacy_customer_id')
        ),
        TRIM(JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.customer_name')
        )),
        NULLIF(JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.email')
        ), 'null'),
        NULLIF(JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.phone')
        ), 'null')
    FROM staging_records s
    JOIN source_files f ON s.file_id = f.file_id
    WHERE f.job_id = p_job_id
    AND s.target_entity = 'CUSTOMERS'
    AND s.record_status = 'VALID'
    AND s.mapped_data IS NOT NULL
    AND JSON_UNQUOTE(
        JSON_EXTRACT(s.mapped_data, '$.legacy_customer_id')
    ) IS NOT NULL
    AND JSON_UNQUOTE(
        JSON_EXTRACT(s.mapped_data, '$.customer_name')
    ) <> ''
    AND NOT EXISTS (
        SELECT 1
        FROM customers c
        WHERE c.business_id = v_business_id
        AND c.legacy_customer_id = JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.legacy_customer_id')
        )
    );


    -- 2. MIGRATE PRODUCTS

    INSERT INTO products
    (
        business_id,
        legacy_product_id,
        product_name,
        category,
        quantity,
        price
    )
    SELECT
        v_business_id,
        JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.legacy_product_id')
        ),
        TRIM(JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.product_name')
        )),
        JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.category')
        ),
        CAST(JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.quantity')
        ) AS UNSIGNED),
        CAST(JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.price')
        ) AS DECIMAL(10,2))
    FROM staging_records s
    JOIN source_files f ON s.file_id = f.file_id
    WHERE f.job_id = p_job_id
    AND s.target_entity = 'PRODUCTS'
    AND s.record_status = 'VALID'
    AND s.mapped_data IS NOT NULL
    AND JSON_UNQUOTE(
        JSON_EXTRACT(s.mapped_data, '$.legacy_product_id')
    ) IS NOT NULL
    AND JSON_UNQUOTE(
        JSON_EXTRACT(s.mapped_data, '$.product_name')
    ) <> ''
    AND JSON_UNQUOTE(
        JSON_EXTRACT(s.mapped_data, '$.price')
    ) REGEXP '^[0-9]+([.][0-9]{1,2})?$'
    AND JSON_UNQUOTE(
        JSON_EXTRACT(s.mapped_data, '$.quantity')
    ) REGEXP '^[0-9]+$'
    AND NOT EXISTS (
        SELECT 1
        FROM products p
        WHERE p.business_id = v_business_id
        AND p.legacy_product_id = JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.legacy_product_id')
        )
    );


    -- 3. UPDATE MIGRATED STATUS

    UPDATE staging_records s
    JOIN source_files f ON s.file_id = f.file_id
    LEFT JOIN customers c
        ON c.business_id = v_business_id
        AND c.legacy_customer_id = JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.legacy_customer_id')
        )
    LEFT JOIN products p
        ON p.business_id = v_business_id
        AND p.legacy_product_id = JSON_UNQUOTE(
            JSON_EXTRACT(s.mapped_data, '$.legacy_product_id')
        )
    SET s.record_status = 'MIGRATED'
    WHERE f.job_id = p_job_id
    AND s.record_status = 'VALID'
    AND (
        (s.target_entity = 'CUSTOMERS' AND c.customer_id IS NOT NULL)
        OR
        (s.target_entity = 'PRODUCTS' AND p.product_id IS NOT NULL)
    );


    -- 4. UPDATE MIGRATION JOB SUMMARY

    UPDATE migration_jobs j
    SET
        j.successful_records = (
            SELECT COUNT(*)
            FROM staging_records s
            JOIN source_files f ON s.file_id = f.file_id
            WHERE f.job_id = p_job_id
            AND s.record_status = 'MIGRATED'
        ),
        j.rejected_records = (
            SELECT COUNT(*)
            FROM staging_records s
            JOIN source_files f ON s.file_id = f.file_id
            WHERE f.job_id = p_job_id
            AND s.record_status = 'REJECTED'
        ),
        j.total_records = (
            SELECT COUNT(*)
            FROM staging_records s
            JOIN source_files f ON s.file_id = f.file_id
            WHERE f.job_id = p_job_id
        ),
        j.migration_status = CASE
            WHEN EXISTS (
                SELECT 1
                FROM staging_records s
                JOIN source_files f ON s.file_id = f.file_id
                WHERE f.job_id = p_job_id
                AND s.record_status IN ('PENDING', 'VALID')
            ) THEN 'PROCESSING'
            WHEN EXISTS (
                SELECT 1
                FROM staging_records s
                JOIN source_files f ON s.file_id = f.file_id
                WHERE f.job_id = p_job_id
                AND s.record_status = 'MIGRATED'
            ) THEN 'COMPLETED'
            ELSE 'FAILED'
        END,
        j.completed_at = NOW()
    WHERE j.job_id = p_job_id;


    -- 5. AUDIT LOG

    INSERT INTO audit_logs
    (business_id, user_id, job_id, action_type,
     table_name, action_description)
    VALUES
    (v_business_id, v_user_id, p_job_id,
     'DATA_MIGRATION',
     'customers/products',
     'Validated staging records processed by migration procedure');


    COMMIT;

END$$

DELIMITER ;


-- PART C: EXECUTE MIGRATION

CALL migrate_valid_records(1);
CALL migrate_valid_records(2);


-- PART D: VERIFY CUSTOMER MIGRATION

SELECT
    customer_id,
    business_id,
    legacy_customer_id,
    customer_name,
    email
FROM customers
ORDER BY customer_id;


-- PART E: VERIFY PRODUCT MIGRATION

SELECT
    product_id,
    business_id,
    legacy_product_id,
    product_name,
    price,
    quantity
FROM products
ORDER BY product_id;


-- PART F: VERIFY STAGING STATUS

SELECT
    staging_id,
    target_entity,
    record_status
FROM staging_records
ORDER BY staging_id;


-- PART G: VERIFY MIGRATION JOBS

SELECT
    job_id,
    job_name,
    migration_status,
    total_records,
    successful_records,
    rejected_records
FROM migration_jobs
ORDER BY job_id;


-- PART H: VERIFY AUDIT HISTORY

SELECT
    audit_id,
    action_type,
    action_description,
    action_time
FROM audit_logs
ORDER BY audit_id;
