
USE DataBridge;

-- =========================================
-- FUNCTION 1: VALIDATE EMAIL
-- =========================================

DROP FUNCTION IF EXISTS fn_is_valid_email;

DELIMITER //

CREATE FUNCTION fn_is_valid_email(
    p_email VARCHAR(255)
)
RETURNS TINYINT
DETERMINISTIC
NO SQL
BEGIN
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        RETURN 0;
    ELSEIF TRIM(p_email) REGEXP
        '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}$'
    THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END //

DELIMITER ;


-- =========================================
-- FUNCTION 2: CLEAN CUSTOMER NAME
-- =========================================

DROP FUNCTION IF EXISTS fn_clean_name;

DELIMITER //

CREATE FUNCTION fn_clean_name(
    p_name VARCHAR(255)
)
RETURNS VARCHAR(255)
DETERMINISTIC
NO SQL
BEGIN
    IF p_name IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN TRIM(
        REPLACE(
            REPLACE(
                REPLACE(p_name, '  ', ' '),
                '  ', ' '
            ),
            '  ', ' '
        )
    );
END //

DELIMITER ;


-- =========================================
-- FUNCTION 3: CALCULATE MIGRATION SUCCESS RATE
-- =========================================

DROP FUNCTION IF EXISTS fn_success_rate;

DELIMITER //

CREATE FUNCTION fn_success_rate(
    p_job_id INT
)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_successful INT DEFAULT 0;

    SELECT
        total_records,
        successful_records
    INTO
        v_total,
        v_successful
    FROM migration_jobs
    WHERE job_id = p_job_id;

    IF v_total = 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND(
        (v_successful / v_total) * 100,
        2
    );
END //

DELIMITER ;


-- =========================================
-- TEST ALL THREE FUNCTIONS
-- =========================================

SELECT fn_is_valid_email('test@gmail.com')
AS valid_email;

SELECT fn_is_valid_email('wrong-email')
AS invalid_email;

SELECT fn_clean_name('  Rahul   Sharma  ')
AS cleaned_name;

SELECT fn_success_rate(1)
AS migration_success_percentage;

SELECT fn_success_rate(2)
AS migration_success_percentage;
