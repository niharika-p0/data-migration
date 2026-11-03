
USE DataBridge;

-- =========================================
-- STEP 1: UPDATE EXISTING DIARY REASONS
-- =========================================

UPDATE migration_diary d
JOIN (
    SELECT
        staging_id,
        GROUP_CONCAT(
            CONCAT(column_name, ': ', issue_description)
            ORDER BY issue_id
            SEPARATOR '; '
        ) AS all_reasons
    FROM validation_issues
    GROUP BY staging_id
) v
ON d.staging_id = v.staging_id
SET d.rejection_reason = v.all_reasons;


-- =========================================
-- STEP 2: INSERT MISSING DIARY ENTRIES
-- =========================================

INSERT INTO migration_diary (
    staging_id,
    rejected_data,
    rejection_reason,
    resolution_status
)
SELECT
    s.staging_id,
    s.raw_data,
    COALESCE(
        GROUP_CONCAT(
            CONCAT(v.column_name, ': ', v.issue_description)
            ORDER BY v.issue_id
            SEPARATOR '; '
        ),
        'Record rejected during migration'
    ),
    'UNRESOLVED'
FROM staging_records s
LEFT JOIN validation_issues v
    ON s.staging_id = v.staging_id
WHERE s.record_status = 'REJECTED'
AND NOT EXISTS (
    SELECT 1
    FROM migration_diary d
    WHERE d.staging_id = s.staging_id
)
GROUP BY s.staging_id, s.raw_data;


-- =========================================
-- STEP 3: VERIFY COMPLETE MIGRATION DIARY
-- =========================================

SELECT
    d.diary_id,
    d.staging_id,
    s.target_entity,
    d.rejected_data,
    d.rejection_reason,
    d.resolution_status
FROM migration_diary d
JOIN staging_records s
    ON d.staging_id = s.staging_id
ORDER BY d.diary_id;
