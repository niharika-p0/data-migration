
USE DataBridge;

DROP PROCEDURE IF EXISTS sp_process_rejected_cursor;

DELIMITER //

CREATE PROCEDURE sp_process_rejected_cursor()
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_staging_id BIGINT;
    DECLARE v_target_entity VARCHAR(20);
    DECLARE v_rejection_reason TEXT;

    DECLARE rejected_cursor CURSOR FOR
        SELECT
            s.staging_id,
            s.target_entity,
            COALESCE(d.rejection_reason, 'No rejection reason recorded')
        FROM staging_records s
        LEFT JOIN migration_diary d
            ON s.staging_id = d.staging_id
        WHERE s.record_status = 'REJECTED';

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_done = 1;

    DROP TEMPORARY TABLE IF EXISTS cursor_results;

    CREATE TEMPORARY TABLE cursor_results (
        staging_id BIGINT,
        target_entity VARCHAR(20),
        rejection_reason TEXT
    );

    OPEN rejected_cursor;

    read_loop: LOOP

        FETCH rejected_cursor
        INTO v_staging_id, v_target_entity, v_rejection_reason;

        IF v_done = 1 THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO cursor_results
        VALUES (
            v_staging_id,
            v_target_entity,
            v_rejection_reason
        );

    END LOOP;

    CLOSE rejected_cursor;

    SELECT * FROM cursor_results
    ORDER BY staging_id;

END //

DELIMITER ;

-- TEST CURSOR PROCEDURE

CALL sp_process_rejected_cursor();
