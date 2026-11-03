
-- =====================================================
-- DATABRIDGE
-- STEP 05: SMART DATA CLEANING
-- MYSQL 8.0+
-- =====================================================

USE DataBridge;

-- 1. DETECT DUPLICATE CUSTOMER LEGACY IDS

SELECT
    JSON_UNQUOTE(
        JSON_EXTRACT(raw_data, '$."Customer ID"')
    ) AS legacy_customer_id,
    COUNT(*) AS duplicate_count
FROM staging_records
WHERE target_entity = 'CUSTOMERS'
GROUP BY legacy_customer_id
HAVING COUNT(*) > 1;


-- 2. DETECT DUPLICATE CUSTOMER NAMES

SELECT
    LOWER(TRIM(
        JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$.Name'))
    )) AS normalized_name,
    COUNT(*) AS duplicate_count
FROM staging_records
WHERE target_entity = 'CUSTOMERS'
AND JSON_EXTRACT(raw_data, '$.Name') IS NOT NULL
GROUP BY normalized_name
HAVING COUNT(*) > 1;


-- 3. DETECT MISSING CUSTOMER NAMES

SELECT
    staging_id,
    source_row_number,
    raw_data
FROM staging_records
WHERE target_entity = 'CUSTOMERS'
AND (
    JSON_EXTRACT(raw_data, '$.Name') IS NULL
    OR TRIM(
        JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$.Name'))
    ) = ''
);


-- 4. DETECT MISSING EMAIL ADDRESSES

SELECT
    staging_id,
    raw_data
FROM staging_records
WHERE target_entity = 'CUSTOMERS'
AND (
    JSON_EXTRACT(raw_data, '$."Email Address"') IS NULL
    OR TRIM(
        JSON_UNQUOTE(
            JSON_EXTRACT(raw_data, '$."Email Address"')
        )
    ) = ''
);


-- 5. PREVIEW CLEANED CUSTOMER NAMES AND EMAILS

SELECT
    staging_id,
    TRIM(
        JSON_UNQUOTE(JSON_EXTRACT(raw_data, '$.Name'))
    ) AS cleaned_name,
    LOWER(
        TRIM(
            JSON_UNQUOTE(
                JSON_EXTRACT(raw_data, '$."Email Address"')
            )
        )
    ) AS cleaned_email
FROM staging_records
WHERE target_entity = 'CUSTOMERS';


-- 6. DETECT INVALID EMAIL FORMATS

SELECT
    staging_id,
    JSON_UNQUOTE(
        JSON_EXTRACT(raw_data, '$."Email Address"')
    ) AS email
FROM staging_records
WHERE target_entity = 'CUSTOMERS'
AND JSON_UNQUOTE(
    JSON_EXTRACT(raw_data, '$."Email Address"')
) IS NOT NULL
AND TRIM(
    JSON_UNQUOTE(
        JSON_EXTRACT(raw_data, '$."Email Address"')
    )
) <> ''
AND TRIM(
    JSON_UNQUOTE(
        JSON_EXTRACT(raw_data, '$."Email Address"')
    )
) NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}$';


-- 7. DETECT INVALID PHONE NUMBERS

SELECT
    staging_id,
    JSON_UNQUOTE(
        JSON_EXTRACT(raw_data, '$."Phone Number"')
    ) AS phone
FROM staging_records
WHERE target_entity = 'CUSTOMERS'
AND JSON_UNQUOTE(
    JSON_EXTRACT(raw_data, '$."Phone Number"')
) IS NOT NULL
AND TRIM(
    JSON_UNQUOTE(
        JSON_EXTRACT(raw_data, '$."Phone Number"')
    )
) <> ''
AND TRIM(
    JSON_UNQUOTE(
        JSON_EXTRACT(raw_data, '$."Phone Number"')
    )
) NOT REGEXP '^[0-9]{10}$';


-- 8. DETECT NEGATIVE PRODUCT PRICES

SELECT
    staging_id,
    JSON_UNQUOTE(
        JSON_EXTRACT(raw_data, '$."Price"')
    ) AS product_price
FROM staging_records
WHERE target_entity = 'PRODUCTS'
AND JSON_UNQUOTE(
    JSON_EXTRACT(raw_data, '$."Price"')
) REGEXP '^-';


-- 9. DETECT NEGATIVE PRODUCT QUANTITIES

SELECT
    staging_id,
    JSON_UNQUOTE(
        JSON_EXTRACT(raw_data, '$."Quantity"')
    ) AS product_quantity
FROM staging_records
WHERE target_entity = 'PRODUCTS'
AND JSON_UNQUOTE(
    JSON_EXTRACT(raw_data, '$."Quantity"')
) REGEXP '^-';


-- 10. CLEAN VALID CUSTOMER MAPPED DATA

UPDATE staging_records
SET mapped_data = JSON_SET(
    mapped_data,
    '$.customer_name',
    TRIM(
        JSON_UNQUOTE(
            JSON_EXTRACT(mapped_data, '$.customer_name')
        )
    ),
    '$.email',
    LOWER(
        TRIM(
            JSON_UNQUOTE(
                JSON_EXTRACT(mapped_data, '$.email')
            )
        )
    )
)
WHERE target_entity = 'CUSTOMERS'
AND record_status IN ('VALID', 'MIGRATED')
AND mapped_data IS NOT NULL;


-- 11. CLEAN VALID PRODUCT MAPPED DATA

UPDATE staging_records
SET mapped_data = JSON_SET(
    mapped_data,
    '$.product_name',
    TRIM(
        JSON_UNQUOTE(
            JSON_EXTRACT(mapped_data, '$.product_name')
        )
    )
)
WHERE target_entity = 'PRODUCTS'
AND record_status IN ('VALID', 'MIGRATED')
AND mapped_data IS NOT NULL;


-- 12. FINAL CLEANING SUMMARY

SELECT
    record_status,
    target_entity,
    COUNT(*) AS total_records
FROM staging_records
GROUP BY target_entity, record_status
ORDER BY target_entity, record_status;
