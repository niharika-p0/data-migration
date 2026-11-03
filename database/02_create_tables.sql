
-- =====================================================
-- DATABRIDGE: COMPLETE TABLE CREATION
-- MYSQL 8.0+
-- =====================================================

CREATE DATABASE IF NOT EXISTS DataBridge;
USE DataBridge;

-- 1. USERS
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('ADMIN','MANAGER','OPERATOR') DEFAULT 'OPERATOR',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. BUSINESSES
CREATE TABLE businesses (
    business_id INT AUTO_INCREMENT PRIMARY KEY,
    business_name VARCHAR(150) NOT NULL,
    business_type ENUM('PHARMACY','RETAIL','GROCERY','OTHER') NOT NULL,
    contact_email VARCHAR(150),
    contact_phone VARCHAR(20),
    address VARCHAR(255),
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- 3. MIGRATION JOBS
CREATE TABLE migration_jobs (
    job_id INT AUTO_INCREMENT PRIMARY KEY,
    business_id INT NOT NULL,
    created_by INT NOT NULL,
    job_name VARCHAR(150) NOT NULL,
    target_entity ENUM('CUSTOMERS','PRODUCTS') NOT NULL,
    migration_status ENUM(
        'PENDING','PROCESSING','COMPLETED','FAILED'
    ) DEFAULT 'PENDING',
    total_records INT DEFAULT 0,
    successful_records INT DEFAULT 0,
    rejected_records INT DEFAULT 0,
    started_at DATETIME,
    completed_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES businesses(business_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    CHECK (
        total_records >= 0 AND
        successful_records >= 0 AND
        rejected_records >= 0
    )
) ENGINE=InnoDB;

-- 4. SOURCE FILES
CREATE TABLE source_files (
    file_id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_type ENUM('CSV','XLS','XLSX') NOT NULL,
    file_size_bytes BIGINT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_id) REFERENCES migration_jobs(job_id)
        ON DELETE CASCADE,
    CHECK (file_size_bytes IS NULL OR file_size_bytes >= 0)
) ENGINE=InnoDB;

-- 5. COLUMN MAPPINGS
CREATE TABLE column_mappings (
    mapping_id INT AUTO_INCREMENT PRIMARY KEY,
    file_id INT NOT NULL,
    source_column VARCHAR(150) NOT NULL,
    target_column VARCHAR(150) NOT NULL,
    target_entity ENUM('CUSTOMERS','PRODUCTS') NOT NULL,
    target_data_type VARCHAR(50),
    is_required BOOLEAN DEFAULT FALSE,
    transformation_rule VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (file_id) REFERENCES source_files(file_id)
        ON DELETE CASCADE,
    UNIQUE (file_id, source_column)
) ENGINE=InnoDB;

-- 6. STAGING RECORDS
CREATE TABLE staging_records (
    staging_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_id INT NOT NULL,
    source_row_number INT NOT NULL,
    raw_data JSON NOT NULL,
    mapped_data JSON,
    target_entity ENUM('CUSTOMERS','PRODUCTS') NOT NULL,
    record_status ENUM(
        'PENDING','VALID','INVALID','MIGRATED','REJECTED'
    ) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (file_id) REFERENCES source_files(file_id)
        ON DELETE CASCADE,
    UNIQUE (file_id, source_row_number),
    CHECK (source_row_number > 0)
) ENGINE=InnoDB;

-- 7. VALIDATION ISSUES
CREATE TABLE validation_issues (
    issue_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    staging_id BIGINT NOT NULL,
    column_name VARCHAR(150),
    issue_type ENUM(
        'MISSING_VALUE','DUPLICATE','INVALID_FORMAT',
        'INVALID_DATA','INCONSISTENT_VALUE'
    ) NOT NULL,
    issue_description VARCHAR(500) NOT NULL,
    severity ENUM('LOW','MEDIUM','HIGH') DEFAULT 'MEDIUM',
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staging_id) REFERENCES staging_records(staging_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- 8. CUSTOMERS
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    business_id INT NOT NULL,
    legacy_customer_id VARCHAR(50) NOT NULL,
    customer_name VARCHAR(150) NOT NULL,
    email VARCHAR(150),
    phone VARCHAR(20),
    address VARCHAR(255),
    migrated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES businesses(business_id),
    UNIQUE (business_id, legacy_customer_id)
) ENGINE=InnoDB;

-- 9. PRODUCTS
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    business_id INT NOT NULL,
    legacy_product_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(150) NOT NULL,
    category VARCHAR(100),
    quantity INT DEFAULT 0,
    price DECIMAL(10,2) NOT NULL,
    migrated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES businesses(business_id),
    UNIQUE (business_id, legacy_product_id),
    CHECK (quantity >= 0),
    CHECK (price >= 0)
) ENGINE=InnoDB;

-- 10. MIGRATION DIARY
CREATE TABLE migration_diary (
    diary_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    staging_id BIGINT NOT NULL,
    rejected_data JSON NOT NULL,
    rejection_reason VARCHAR(500) NOT NULL,
    resolution_status ENUM(
        'UNRESOLVED','CORRECTED','IGNORED'
    ) DEFAULT 'UNRESOLVED',
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staging_id) REFERENCES staging_records(staging_id)
) ENGINE=InnoDB;

-- 11. AUDIT LOGS
CREATE TABLE audit_logs (
    audit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    business_id INT NOT NULL,
    user_id INT,
    job_id INT,
    action_type VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id VARCHAR(100),
    old_values JSON,
    new_values JSON,
    action_description VARCHAR(500),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES businesses(business_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE SET NULL,
    FOREIGN KEY (job_id) REFERENCES migration_jobs(job_id)
        ON DELETE SET NULL
) ENGINE=InnoDB;

-- FINAL VERIFICATION
SHOW TABLES;
