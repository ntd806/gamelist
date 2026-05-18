-- =========================================================
-- VinPlay Wallet + Seamless API Schema
-- Version: V1.0
-- Purpose:
--   Add USD/USDT wallet module using BIGINT minor-unit.
--   Support Seamless API: balance, bet, win, refund, settle.
--   Keep legacy users.vin/users.xu untouched.
-- =========================================================

USE vinplay;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. Currency scale config
-- =========================================================

CREATE TABLE IF NOT EXISTS wallet_currency (
    currency_code VARCHAR(16) NOT NULL,

    currency_name VARCHAR(64) NOT NULL,
    currency_type VARCHAR(16) NOT NULL COMMENT 'FIAT, CRYPTO, GAME',

    scale_digits TINYINT NOT NULL COMMENT 'VND=0, USD=2, USDT=6',

    is_active TINYINT NOT NULL DEFAULT 1 COMMENT '1=ACTIVE,0=INACTIVE',

    min_deposit_minor BIGINT NOT NULL DEFAULT 0,
    min_withdraw_minor BIGINT NOT NULL DEFAULT 0,
    withdraw_fee_minor BIGINT NOT NULL DEFAULT 0,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (currency_code),
    KEY idx_currency_type (currency_type),
    KEY idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO wallet_currency (
    currency_code,
    currency_name,
    currency_type,
    scale_digits,
    is_active,
    min_deposit_minor,
    min_withdraw_minor,
    withdraw_fee_minor
)
VALUES
('USD', 'US Dollar', 'FIAT', 2, 1, 100, 1000, 0),
('USDT', 'Tether USD', 'CRYPTO', 6, 1, 1000000, 10000000, 1000000)
ON DUPLICATE KEY UPDATE
    currency_name = VALUES(currency_name),
    currency_type = VALUES(currency_type),
    scale_digits = VALUES(scale_digits),
    is_active = VALUES(is_active),
    min_deposit_minor = VALUES(min_deposit_minor),
    min_withdraw_minor = VALUES(min_withdraw_minor),
    withdraw_fee_minor = VALUES(withdraw_fee_minor),
    updated_at = CURRENT_TIMESTAMP;

-- =========================================================
-- 2. Wallet account: current balance source of truth for USD/USDT
-- =========================================================

CREATE TABLE IF NOT EXISTS wallet_account (
    id BIGINT NOT NULL AUTO_INCREMENT,

    account_id VARCHAR(64) NOT NULL COMMENT 'Internal wallet account id, e.g. WALLET_USER_1001',

    user_id BIGINT NOT NULL,
    nick_name VARCHAR(50) NOT NULL,

    currency_code VARCHAR(16) NOT NULL,
    wallet_type VARCHAR(30) NOT NULL DEFAULT 'MAIN' COMMENT 'MAIN, BONUS, PROMO',

    available_balance_minor BIGINT NOT NULL DEFAULT 0,
    frozen_balance_minor BIGINT NOT NULL DEFAULT 0,

    total_deposit_minor BIGINT NOT NULL DEFAULT 0,
    total_withdraw_minor BIGINT NOT NULL DEFAULT 0,
    total_bet_minor BIGINT NOT NULL DEFAULT 0,
    total_win_minor BIGINT NOT NULL DEFAULT 0,

    version BIGINT NOT NULL DEFAULT 0,

    status TINYINT NOT NULL DEFAULT 1 COMMENT '1=ACTIVE,0=LOCKED,2=SUSPENDED',

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_account_currency_wallet (
        account_id,
        currency_code,
        wallet_type
    ),

    UNIQUE KEY uk_user_currency_wallet (
        user_id,
        currency_code,
        wallet_type
    ),

    KEY idx_user_id (user_id),
    KEY idx_nick_name (nick_name),
    KEY idx_currency_code (currency_code),
    KEY idx_status (status),
    KEY idx_updated_at (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 3. Wallet transaction: business transaction record
-- =========================================================

CREATE TABLE IF NOT EXISTS wallet_transaction (
    id BIGINT NOT NULL AUTO_INCREMENT,

    transaction_no VARCHAR(64) NOT NULL COMMENT 'Internal transaction id',
    request_id VARCHAR(128) NOT NULL COMMENT 'Idempotency key / external request id',
    business_key VARCHAR(191) NOT NULL COMMENT 'Global unique business key: BET:OP:BET_ID, WIN:OP:WIN_ID, DEPOSIT:NETWORK:TX:EVENT',

    account_id VARCHAR(64) NOT NULL,

    user_id BIGINT NOT NULL,
    nick_name VARCHAR(50) NOT NULL,

    transaction_type VARCHAR(50) NOT NULL COMMENT 'DEPOSIT, WITHDRAW, ADMIN_ADJUST, EXCHANGE, GAME_BET, GAME_WIN, GAME_REFUND, BONUS, FEE',
    currency_code VARCHAR(16) NOT NULL,

    amount_minor BIGINT NOT NULL COMMENT 'Main transaction amount in minor-unit',
    fee_minor BIGINT NOT NULL DEFAULT 0,
    net_amount_minor BIGINT NOT NULL,

    status TINYINT NOT NULL DEFAULT 0 COMMENT '0=PENDING,1=SUCCESS,2=FAILED,3=CANCELLED,4=PROCESSING,5=REFUNDED,6=REVERSED',

    -- Seamless/game metadata
    operator_code VARCHAR(64) DEFAULT NULL,
    provider_code VARCHAR(64) DEFAULT NULL,
    game_code VARCHAR(64) DEFAULT NULL,
    round_id VARCHAR(128) DEFAULT NULL,
    bet_id VARCHAR(128) DEFAULT NULL,
    win_id VARCHAR(128) DEFAULT NULL,
    refund_id VARCHAR(128) DEFAULT NULL,
    original_transaction_no VARCHAR(64) DEFAULT NULL,
    bet_type VARCHAR(50) DEFAULT NULL COMMENT 'NORMAL, FREE_SPIN, BONUS',

    -- Payment/crypto metadata
    provider VARCHAR(50) DEFAULT NULL COMMENT 'Payment provider / blockchain provider',
    network VARCHAR(50) DEFAULT NULL COMMENT 'TRC20, ERC20, BEP20, BANK, INTERNAL',
    tx_hash VARCHAR(150) DEFAULT NULL COMMENT 'Blockchain transaction hash',
    event_index VARCHAR(64) DEFAULT NULL COMMENT 'Token event/log index if applicable',
    confirmations INT DEFAULT NULL,
    required_confirmations INT DEFAULT NULL,

    from_address VARCHAR(255) DEFAULT NULL,
    to_address VARCHAR(255) DEFAULT NULL,

    bank_code VARCHAR(50) DEFAULT NULL,
    bank_account VARCHAR(100) DEFAULT NULL,
    account_name VARCHAR(100) DEFAULT NULL,

    -- Exchange metadata
    rate_id VARCHAR(128) DEFAULT NULL,
    source_currency VARCHAR(16) DEFAULT NULL,
    source_amount_minor BIGINT DEFAULT NULL,
    target_currency VARCHAR(16) DEFAULT NULL,
    target_amount_minor BIGINT DEFAULT NULL,

    -- Admin/audit metadata
    created_by VARCHAR(64) DEFAULT NULL,
    approved_by VARCHAR(64) DEFAULT NULL,

    request_payload JSON DEFAULT NULL,
    response_payload JSON DEFAULT NULL,
    callback_payload JSON DEFAULT NULL,

    note VARCHAR(255) DEFAULT NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    completed_at DATETIME DEFAULT NULL,

    PRIMARY KEY (id),

    UNIQUE KEY uk_transaction_no (transaction_no),
    UNIQUE KEY uk_business_key (business_key),

    -- request_id may overlap between different operators; operator_code can be NULL for non-seamless ops.
    -- business_key is the stronger universal dedupe guard.
    KEY idx_request_id (request_id),
    KEY idx_operator_request (operator_code, request_id),

    UNIQUE KEY uk_network_tx_event (network, tx_hash, event_index),

    KEY idx_account_currency (account_id, currency_code),
    KEY idx_user_currency (user_id, currency_code),
    KEY idx_transaction_type (transaction_type),
    KEY idx_status (status),
    KEY idx_provider (provider),
    KEY idx_provider_code (provider_code),
    KEY idx_operator_round (operator_code, round_id),
    KEY idx_game_round (game_code, round_id),
    KEY idx_bet_id (bet_id),
    KEY idx_win_id (win_id),
    KEY idx_refund_id (refund_id),
    KEY idx_original_transaction_no (original_transaction_no),
    KEY idx_network_tx (network, tx_hash),
    KEY idx_rate_id (rate_id),
    KEY idx_created_at (created_at),
    KEY idx_completed_at (completed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 4. Wallet ledger: append-only balance movement audit
-- =========================================================

CREATE TABLE IF NOT EXISTS wallet_ledger (
    id BIGINT NOT NULL AUTO_INCREMENT,

    ledger_no VARCHAR(64) NOT NULL COMMENT 'Internal ledger id',
    request_id VARCHAR(128) NOT NULL COMMENT 'Idempotency key / external request id',
    ledger_entry_key VARCHAR(191) NOT NULL COMMENT 'Unique ledger entry key: BET:OP:BET_ID, WITHDRAW_HOLD:WD_1',

    account_id VARCHAR(64) NOT NULL,

    user_id BIGINT NOT NULL,
    nick_name VARCHAR(50) NOT NULL,

    currency_code VARCHAR(16) NOT NULL,
    wallet_type VARCHAR(30) NOT NULL DEFAULT 'MAIN',

    action_type VARCHAR(50) NOT NULL COMMENT 'DEPOSIT, WITHDRAW_HOLD, WITHDRAW_SUCCESS, WITHDRAW_REFUND, ADMIN_ADD, ADMIN_SUB, BET, WIN, REFUND, EXCHANGE_IN, EXCHANGE_OUT, FEE, BONUS, FREEZE, UNFREEZE, REVERSAL',

    amount_minor BIGINT NOT NULL COMMENT 'Business amount in minor-unit, usually positive',

    available_delta_minor BIGINT NOT NULL DEFAULT 0,
    frozen_delta_minor BIGINT NOT NULL DEFAULT 0,

    available_before_minor BIGINT NOT NULL,
    available_after_minor BIGINT NOT NULL,

    frozen_before_minor BIGINT NOT NULL DEFAULT 0,
    frozen_after_minor BIGINT NOT NULL DEFAULT 0,

    reference_type VARCHAR(50) NOT NULL COMMENT 'WALLET_TRANSACTION, GAME_ROUND, ADMIN_ACTION, EXCHANGE',
    reference_id VARCHAR(100) NOT NULL,

    -- Seamless/game metadata
    operator_code VARCHAR(64) DEFAULT NULL,
    provider_code VARCHAR(64) DEFAULT NULL,
    game_code VARCHAR(64) DEFAULT NULL,
    round_id VARCHAR(128) DEFAULT NULL,
    bet_id VARCHAR(128) DEFAULT NULL,
    win_id VARCHAR(128) DEFAULT NULL,
    refund_id VARCHAR(128) DEFAULT NULL,

    -- Exchange metadata
    rate_id VARCHAR(128) DEFAULT NULL,
    source_currency VARCHAR(16) DEFAULT NULL,
    source_amount_minor BIGINT DEFAULT NULL,
    target_currency VARCHAR(16) DEFAULT NULL,
    target_amount_minor BIGINT DEFAULT NULL,

    status TINYINT NOT NULL DEFAULT 1 COMMENT '1=SUCCESS,0=PENDING,2=FAILED,3=REVERSED',

    reversed_ledger_no VARCHAR(64) DEFAULT NULL,
    reversal_reason VARCHAR(255) DEFAULT NULL,

    description VARCHAR(255) DEFAULT NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_ledger_no (ledger_no),
    UNIQUE KEY uk_ledger_entry_key (ledger_entry_key),

    KEY idx_request_id (request_id),
    KEY idx_account_currency (account_id, currency_code),
    KEY idx_user_currency (user_id, currency_code),
    KEY idx_reference (reference_type, reference_id),
    KEY idx_action_type (action_type),
    KEY idx_operator_round (operator_code, round_id),
    KEY idx_game_round (game_code, round_id),
    KEY idx_bet_id (bet_id),
    KEY idx_win_id (win_id),
    KEY idx_refund_id (refund_id),
    KEY idx_rate_id (rate_id),
    KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 5. Wallet address for crypto deposits
-- =========================================================

CREATE TABLE IF NOT EXISTS wallet_address (
    id BIGINT NOT NULL AUTO_INCREMENT,

    account_id VARCHAR(64) NOT NULL,

    user_id BIGINT NOT NULL,
    nick_name VARCHAR(50) NOT NULL,

    currency_code VARCHAR(16) NOT NULL,
    network VARCHAR(50) NOT NULL COMMENT 'TRC20, ERC20, BEP20',

    address VARCHAR(255) NOT NULL,
    address_tag VARCHAR(100) DEFAULT NULL COMMENT 'Memo/tag if chain requires it',

    status TINYINT NOT NULL DEFAULT 1 COMMENT '1=ACTIVE,0=INACTIVE,2=LOCKED',

    last_used_at DATETIME DEFAULT NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_currency_network_address (
        currency_code,
        network,
        address
    ),

    KEY idx_account_currency_network (
        account_id,
        currency_code,
        network
    ),

    KEY idx_user_currency_network (
        user_id,
        currency_code,
        network
    ),

    KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 6. Exchange rate snapshot
-- =========================================================

CREATE TABLE IF NOT EXISTS exchange_rate_snapshot (
    rate_id VARCHAR(128) NOT NULL,

    from_currency VARCHAR(16) NOT NULL,
    to_currency VARCHAR(16) NOT NULL,

    rate DECIMAL(38,18) NOT NULL,

    provider VARCHAR(50) DEFAULT NULL,
    source VARCHAR(100) DEFAULT NULL COMMENT 'Rate source',
    note VARCHAR(255) DEFAULT NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (rate_id),

    KEY idx_currency_pair (
        from_currency,
        to_currency
    ),

    KEY idx_provider (provider),
    KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 7. Daily wallet snapshot for reconciliation
-- =========================================================

CREATE TABLE IF NOT EXISTS wallet_daily_snapshot (
    id BIGINT NOT NULL AUTO_INCREMENT,

    snapshot_date DATE NOT NULL,

    account_id VARCHAR(64) NOT NULL,
    user_id BIGINT NOT NULL,
    nick_name VARCHAR(50) NOT NULL,

    currency_code VARCHAR(16) NOT NULL,
    wallet_type VARCHAR(30) NOT NULL DEFAULT 'MAIN',

    available_balance_minor BIGINT NOT NULL,
    frozen_balance_minor BIGINT NOT NULL,

    total_deposit_minor BIGINT NOT NULL,
    total_withdraw_minor BIGINT NOT NULL,
    total_bet_minor BIGINT NOT NULL,
    total_win_minor BIGINT NOT NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_snapshot_account_currency (
        snapshot_date,
        account_id,
        currency_code,
        wallet_type
    ),

    KEY idx_snapshot_date (snapshot_date),
    KEY idx_user_currency (user_id, currency_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 8. Seamless provider/operator config
-- =========================================================

CREATE TABLE IF NOT EXISTS seamless_game_provider (
    id BIGINT NOT NULL AUTO_INCREMENT,

    provider_code VARCHAR(64) NOT NULL,
    provider_name VARCHAR(128) NOT NULL,

    status TINYINT NOT NULL DEFAULT 1 COMMENT '1=ACTIVE,0=INACTIVE',

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_provider_code (provider_code),
    KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS seamless_operator (
    id BIGINT NOT NULL AUTO_INCREMENT,

    operator_code VARCHAR(64) NOT NULL,
    operator_name VARCHAR(128) NOT NULL,

    provider_code VARCHAR(64) DEFAULT NULL,

    api_key VARCHAR(128) NOT NULL,
    secret_key VARCHAR(255) NOT NULL COMMENT 'Store encrypted or KMS-managed secret, not plain text in production',

    status TINYINT NOT NULL DEFAULT 1 COMMENT '1=ACTIVE,0=INACTIVE,2=LOCKED',

    allowed_ips VARCHAR(1000) DEFAULT NULL COMMENT 'Comma-separated IP allowlist, also enforce in gateway/firewall',

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_operator_code (operator_code),
    UNIQUE KEY uk_api_key (api_key),

    KEY idx_provider_code (provider_code),
    KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 9. Seamless API nonce for replay protection
-- =========================================================

CREATE TABLE IF NOT EXISTS seamless_api_nonce (
    id BIGINT NOT NULL AUTO_INCREMENT,

    operator_code VARCHAR(64) NOT NULL,
    nonce VARCHAR(128) NOT NULL,
    request_timestamp BIGINT NOT NULL COMMENT 'Unix timestamp from request',

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_operator_nonce (operator_code, nonce),
    KEY idx_created_at (created_at),
    KEY idx_operator_created_at (operator_code, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 10. Seamless API request/response log
-- =========================================================

CREATE TABLE IF NOT EXISTS seamless_api_request_log (
    id BIGINT NOT NULL AUTO_INCREMENT,

    request_id VARCHAR(128) NOT NULL,
    operator_code VARCHAR(64) NOT NULL,

    api_action VARCHAR(50) NOT NULL COMMENT 'BALANCE, BET, WIN, REFUND, CANCEL, SETTLE',
    business_key VARCHAR(191) DEFAULT NULL,

    user_id BIGINT DEFAULT NULL,
    nick_name VARCHAR(50) DEFAULT NULL,

    currency_code VARCHAR(16) DEFAULT NULL,
    amount_minor BIGINT DEFAULT NULL,

    provider_code VARCHAR(64) DEFAULT NULL,
    game_code VARCHAR(64) DEFAULT NULL,
    round_id VARCHAR(128) DEFAULT NULL,
    bet_id VARCHAR(128) DEFAULT NULL,
    win_id VARCHAR(128) DEFAULT NULL,
    refund_id VARCHAR(128) DEFAULT NULL,

    request_hash VARCHAR(128) DEFAULT NULL COMMENT 'Hash of canonical payload. Same request_id with different hash must be rejected.',
    nonce VARCHAR(128) DEFAULT NULL,
    request_timestamp BIGINT DEFAULT NULL,

    request_payload JSON DEFAULT NULL,
    response_payload JSON DEFAULT NULL,

    status TINYINT NOT NULL DEFAULT 0 COMMENT '0=PENDING,1=SUCCESS,2=FAILED,3=DUPLICATE,4=PAYLOAD_MISMATCH',

    error_code VARCHAR(64) DEFAULT NULL,
    error_message VARCHAR(255) DEFAULT NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_operator_request (
        operator_code,
        request_id
    ),

    KEY idx_business_key (business_key),
    KEY idx_operator_action (operator_code, api_action),
    KEY idx_user_currency (user_id, currency_code),
    KEY idx_round_id (round_id),
    KEY idx_bet_id (bet_id),
    KEY idx_win_id (win_id),
    KEY idx_refund_id (refund_id),
    KEY idx_status (status),
    KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 11. Seamless game round state
-- =========================================================

CREATE TABLE IF NOT EXISTS seamless_game_round (
    id BIGINT NOT NULL AUTO_INCREMENT,

    operator_code VARCHAR(64) NOT NULL,
    provider_code VARCHAR(64) DEFAULT NULL,

    game_code VARCHAR(64) NOT NULL,
    round_id VARCHAR(128) NOT NULL,

    user_id BIGINT NOT NULL,
    nick_name VARCHAR(50) NOT NULL,

    currency_code VARCHAR(16) NOT NULL,

    total_bet_minor BIGINT NOT NULL DEFAULT 0,
    total_win_minor BIGINT NOT NULL DEFAULT 0,
    total_refund_minor BIGINT NOT NULL DEFAULT 0,

    round_status TINYINT NOT NULL DEFAULT 0 COMMENT '0=OPEN,1=SETTLED,2=CANCELLED,3=REFUNDED',

    opened_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    settled_at DATETIME DEFAULT NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_operator_round_user (
        operator_code,
        round_id,
        user_id
    ),

    KEY idx_user_currency (user_id, currency_code),
    KEY idx_provider_code (provider_code),
    KEY idx_game_code (game_code),
    KEY idx_round_status (round_status),
    KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 12. Optional admin adjust request for maker-checker workflow
-- =========================================================

CREATE TABLE IF NOT EXISTS wallet_admin_adjust_request (
    id BIGINT NOT NULL AUTO_INCREMENT,

    adjust_no VARCHAR(64) NOT NULL,
    request_id VARCHAR(128) NOT NULL,

    account_id VARCHAR(64) NOT NULL,
    user_id BIGINT NOT NULL,
    nick_name VARCHAR(50) NOT NULL,

    currency_code VARCHAR(16) NOT NULL,
    adjust_type VARCHAR(20) NOT NULL COMMENT 'ADD,SUB',
    amount_minor BIGINT NOT NULL,

    reason VARCHAR(255) NOT NULL,

    status TINYINT NOT NULL DEFAULT 0 COMMENT '0=PENDING_APPROVAL,1=APPROVED,2=REJECTED,3=SUCCESS,4=FAILED,5=CANCELLED',

    created_by VARCHAR(64) NOT NULL,
    approved_by VARCHAR(64) DEFAULT NULL,

    wallet_transaction_no VARCHAR(64) DEFAULT NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME DEFAULT NULL,
    completed_at DATETIME DEFAULT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_adjust_no (adjust_no),
    UNIQUE KEY uk_request_id (request_id),

    KEY idx_user_currency (user_id, currency_code),
    KEY idx_status (status),
    KEY idx_created_by (created_by),
    KEY idx_approved_by (approved_by),
    KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- Operational notes / required backend rules
-- =========================================================
-- 1. Legacy VIN/XU remain in vinplay.users. USD/USDT source of truth is wallet_account.
-- 2. Core money uses BIGINT minor-unit only. API/UI must send decimal string, never JSON number.
-- 3. Convert decimal string to minor-unit using wallet_currency.scale_digits. Reject input exceeding scale. Never auto-round.
-- 4. Do not use FLOAT/DOUBLE for money anywhere.
-- 5. Every balance change must be in one DB transaction:
--      lock or atomic update wallet_account
--      insert wallet_transaction
--      insert wallet_ledger
--      update seamless_api_request_log response
--      commit
-- 6. wallet_ledger is append-only. Do not update/delete ledger rows. Use REVERSAL entries for corrections.
-- 7. Seamless API must verify HMAC signature, timestamp, nonce and IP allowlist.
-- 8. Same operator_code + request_id with same payload returns old response. Same request_id with different request_hash is rejected.
-- 9. BET debits balance immediately. WIN credits balance immediately. REFUND reverses a successful BET. SETTLE only closes round and must not change balance.
-- 10. Crypto deposit should only credit after required confirmations. Use network + tx_hash + event_index to prevent duplicate credit.
