
USE DataBridge;

-- =========================================
-- TEST 1: TRANSACTION WITH COMMIT
-- =========================================

START TRANSACTION;

INSERT INTO audit_logs (
    business_id,
    user_id,
    action_type,
    table_name,
    action_description
)
VALUES (
    1,
    1,
    'TRANSACTION_TEST',
    'audit_logs',
    'Transaction committed successfully'
);

COMMIT;


-- =========================================
-- TEST 2: TRANSACTION WITH ROLLBACK
-- =========================================

START TRANSACTION;

INSERT INTO audit_logs (
    business_id,
    user_id,
    action_type,
    table_name,
    action_description
)
VALUES (
    1,
    1,
    'ROLLBACK_TEST',
    'audit_logs',
    'This record should be rolled back'
);

ROLLBACK;


-- =========================================
-- TEST 3: SAVEPOINT
-- =========================================

START TRANSACTION;

INSERT INTO audit_logs (
    business_id,
    user_id,
    action_type,
    table_name,
    action_description
)
VALUES (
    1,
    1,
    'SAVEPOINT_TEST_1',
    'audit_logs',
    'First savepoint test record'
);

SAVEPOINT sp_first;

INSERT INTO audit_logs (
    business_id,
    user_id,
    action_type,
    table_name,
    action_description
)
VALUES (
    1,
    1,
    'SAVEPOINT_TEST_2',
    'audit_logs',
    'Second savepoint test record'
);

ROLLBACK TO SAVEPOINT sp_first;

COMMIT;


-- =========================================
-- VERIFY TRANSACTION RESULTS
-- =========================================

SELECT
    audit_id,
    action_type,
    action_description
FROM audit_logs
WHERE action_type IN (
    'TRANSACTION_TEST',
    'ROLLBACK_TEST',
    'SAVEPOINT_TEST_1',
    'SAVEPOINT_TEST_2'
)
ORDER BY audit_id;
