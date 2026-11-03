
-- =====================================================
-- DATABRIDGE
-- STEP 06: DATA VALIDATION ENGINE
-- MYSQL 8.0+
-- =====================================================

USE DataBridge;

-- 1. VALIDATE CUSTOMER NAME

INSERT INTO validation_issues
(staging_id, column_name, issue_type, issue_description, severity)
SELECT
    staging_id,
    'Name',
    'MISSING_VALUE',
    'Customer name is missing',
    'HIGH'
FROM staging_records
WHERE target_entity = 'CUSTOMERS'
AND (
    JSON_EXTRACT(raw_data, '$.Name') IS NULL
    OR TRIM(JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$.Name'))) = ''
)
AND NOT EXISTS (
    SELECT 1 FROM validation_issues v
    WHERE v.staging_id = staging_records.staging_id
    AND v.issue_type = 'MISSING_VALUE'
    AND v.column_name = 'Name'
);


-- 2. VALIDATE CUSTOMER EMAIL

INSERT INTO validation_issues
(staging_id, column_name, issue_type, issue_description, severity)
SELECT
    staging_id,
    'Email Address',
    'INVALID_FORMAT',
    'Customer email format is invalid',
    'MEDIUM'
FROM staging_records
WHERE target_entity = 'CUSTOMERS'
AND TRIM(COALESCE(
    JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$."Email Address"')), ''
)) <> ''
AND TRIM(
    JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$."Email Address"'))
) NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}$'
AND NOT EXISTS (
    SELECT 1 FROM validation_issues v
    WHERE v.staging_id = staging_records.staging_id
    AND v.issue_type = 'INVALID_FORMAT'
    AND v.column_name = 'Email Address'
);


-- 3. VALIDATE CUSTOMER PHONE

INSERT INTO validation_issues
(staging_id, column_name, issue_type, issue_description, severity)
SELECT
    staging_id,
    'Phone Number',
    'INVALID_FORMAT',
    'Phone number must contain exactly 10 digits',
    'MEDIUM'
FROM staging_records
WHERE target_entity = 'CUSTOMERS'
AND TRIM(COALESCE(
    JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$."Phone Number"')), ''
)) <> ''
AND TRIM(
    JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$."Phone Number"'))
) NOT REGEXP '^[0-9]{10}$'
AND NOT EXISTS (
    SELECT 1 FROM validation_issues v
    WHERE v.staging_id = staging_records.staging_id
    AND v.issue_type = 'INVALID_FORMAT'
    AND v.column_name = 'Phone Number'
);


-- 4. VALIDATE PRODUCT PRICE

INSERT INTO validation_issues
(staging_id, column_name, issue_type, issue_description, severity)
SELECT
    staging_id,
    'Price',
    'INVALID_DATA',
    'Product price must be a non-negative number',
    'HIGH'
FROM staging_records
WHERE target_entity = 'PRODUCTS'
AND (
    TRIM(COALESCE(
        JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$.Price')), ''
    )) = ''
    OR TRIM(
        JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$.Price'))
    ) NOT REGEXP '^[0-9]+([.][0-9]{1,2})?$'
)
AND NOT EXISTS (
    SELECT 1 FROM validation_issues v
    WHERE v.staging_id = staging_records.staging_id
    AND v.issue_type = 'INVALID_DATA'
    AND v.column_name = 'Price'
);


-- 5. VALIDATE PRODUCT QUANTITY

INSERT INTO validation_issues
(staging_id, column_name, issue_type, issue_description, severity)
SELECT
    staging_id,
    'Quantity',
    'INVALID_DATA',
    'Product quantity must be a non-negative integer',
    'HIGH'
FROM staging_records
WHERE target_entity = 'PRODUCTS'
AND (
    TRIM(COALESCE(
        JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$.Quantity')), ''
    )) = ''
    OR TRIM(
        JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$.Quantity'))
    ) NOT REGEXP '^[0-9]+$'
)
AND NOT EXISTS (
    SELECT 1 FROM validation_issues v
    WHERE v.staging_id = staging_records.staging_id
    AND v.issue_type = 'INVALID_DATA'
    AND v.column_name = 'Quantity'
);


-- 6. MARK INVALID RECORDS AS REJECTED

UPDATE staging_records s
SET s.record_status = 'REJECTED'
WHERE s.record_status IN ('PENDING', 'VALID')
AND EXISTS (
    SELECT 1
    FROM validation_issues v
    WHERE v.staging_id = s.staging_id
);


-- 7. INSERT REJECTED RECORDS INTO MIGRATION DIARY

INSERT INTO migration_diary
(staging_id, rejected_data, rejection_reason)
SELECT
    s.staging_id,
    s.raw_data,
    CONCAT('Validation failed: ', GROUP_CONCAT(
        DISTINCT v.issue_description
        SEPARATOR '; '
    ))
FROM staging_records s
JOIN validation_issues v
    ON s.staging_id = v.staging_id
WHERE s.record_status = 'REJECTED'
AND NOT EXISTS (
    SELECT 1
    FROM migration_diary d
    WHERE d.staging_id = s.staging_id
)
GROUP BY s.staging_id, s.raw_data;


-- 8. DISPLAY ALL VALIDATION ISSUES

SELECT
    v.issue_id,
    v.staging_id,
    v.column_name,
    v.issue_type,
    v.issue_description,
    v.severity
FROM validation_issues v
ORDER BY v.staging_id, v.issue_id;


-- 9. DISPLAY REJECTED RECORDS

SELECT
    staging_id,
    target_entity,
    record_status,
    raw_data
FROM staging_records
WHERE record_status = 'REJECTED';


-- 10. DISPLAY MIGRATION DIARY

SELECT
    diary_id,
    staging_id,
    rejection_reason,
    resolution_status
FROM migration_diary;


-- 11. FINAL VALIDATION SUMMARY

SELECT
    target_entity,
    record_status,
    COUNT(*) AS total_records
FROM staging_records
GROUP BY target_entity, record_status
ORDER BY target_entity, record_status;
