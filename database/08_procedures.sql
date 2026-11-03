
USE DataBridge;

-- =========================================
-- PROCEDURE 1: GET MIGRATION JOB SUMMARY
-- =========================================

DROP PROCEDURE IF EXISTS sp_get_job_summary;

DELIMITER //

CREATE PROCEDURE sp_get_job_summary(
    IN p_job_id INT
)
BEGIN
    SELECT
        job_id,
        job_name,
        target_entity,
        migration_status,
        total_records,
        successful_records,
        rejected_records,
        created_at,
        completed_at
    FROM migration_jobs
    WHERE job_id = p_job_id;
END //

DELIMITER ;


-- =========================================
-- PROCEDURE 2: GET REJECTED RECORDS
-- =========================================

DROP PROCEDURE IF EXISTS sp_get_rejected_records;

DELIMITER //

CREATE PROCEDURE sp_get_rejected_records(
    IN p_job_id INT
)
BEGIN
    SELECT
        s.staging_id,
        s.target_entity,
        s.raw_data,
        s.record_status,
        d.rejection_reason,
        d.resolution_status
    FROM staging_records s
    JOIN source_files f
        ON s.file_id = f.file_id
    LEFT JOIN migration_diary d
        ON s.staging_id = d.staging_id
    WHERE f.job_id = p_job_id
      AND s.record_status = 'REJECTED';
END //

DELIMITER ;


-- =========================================
-- PROCEDURE 3: GET BUSINESS MIGRATION HISTORY
-- =========================================

DROP PROCEDURE IF EXISTS sp_get_business_history;

DELIMITER //

CREATE PROCEDURE sp_get_business_history(
    IN p_business_id INT
)
BEGIN
    SELECT
        job_id,
        job_name,
        target_entity,
        migration_status,
        total_records,
        successful_records,
        rejected_records,
        created_at
    FROM migration_jobs
    WHERE business_id = p_business_id
    ORDER BY created_at DESC;
END //

DELIMITER ;


-- =========================================
-- TEST ALL THREE PROCEDURES
-- =========================================

CALL sp_get_job_summary(1);

CALL sp_get_rejected_records(1);

CALL sp_get_business_history(1);
