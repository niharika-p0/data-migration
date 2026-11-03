
USE DataBridge;

-- =========================================
-- TRIGGER 1: CLEAN CUSTOMER NAME
-- =========================================

DROP TRIGGER IF EXISTS trg_clean_customer_name;

DELIMITER //

CREATE TRIGGER trg_clean_customer_name
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    SET NEW.customer_name = TRIM(NEW.customer_name);

    IF NEW.customer_name IS NULL
       OR NEW.customer_name = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Customer name cannot be empty';
    END IF;
END //

DELIMITER ;


-- =========================================
-- TRIGGER 2: AUDIT STAGING STATUS CHANGES
-- =========================================

DROP TRIGGER IF EXISTS trg_audit_staging_status;

DELIMITER //

CREATE TRIGGER trg_audit_staging_status
AFTER UPDATE ON staging_records
FOR EACH ROW
BEGIN
    DECLARE v_business_id INT;
    DECLARE v_job_id INT;

    IF OLD.record_status <> NEW.record_status THEN

        SELECT
            mj.business_id,
            sf.job_id
        INTO
            v_business_id,
            v_job_id
        FROM source_files sf
        JOIN migration_jobs mj
            ON sf.job_id = mj.job_id
        WHERE sf.file_id = NEW.file_id;

        INSERT INTO audit_logs (
            business_id,
            job_id,
            action_type,
            table_name,
            record_id,
            old_values,
            new_values,
            action_description
        )
        VALUES (
            v_business_id,
            v_job_id,
            'STATUS_CHANGED',
            'staging_records',
            NEW.staging_id,
            JSON_OBJECT(
                'record_status', OLD.record_status
            ),
            JSON_OBJECT(
                'record_status', NEW.record_status
            ),
            CONCAT(
                'Staging record ',
                NEW.staging_id,
                ' status changed from ',
                OLD.record_status,
                ' to ',
                NEW.record_status
            )
        );

    END IF;
END //

DELIMITER ;


-- =========================================
-- VERIFY CREATED TRIGGERS
-- =========================================

SHOW TRIGGERS;
