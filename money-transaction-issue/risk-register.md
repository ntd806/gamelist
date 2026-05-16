**Risk Register cho hệ thống giao dịch tiền bằng SQL**, có **phân loại + trọng số quan trọng + mức ưu tiên triển khai**.

---

# TÀI LIỆU RISK REGISTER

## Hệ thống giao dịch tiền / ví / game / betting / payment với SQL

---

# 1. Cách chấm trọng số

Mỗi rủi ro được chấm theo thang **1–5**:

```text
5 = Cực kỳ nghiêm trọng, có thể mất tiền ngay, cộng tiền ảo, trừ sai tiền, hoặc bị exploit trực tiếp.
4 = Rất nghiêm trọng, có thể gây lệch tiền, double payout, audit fail, hoặc rủi ro vận hành lớn.
3 = Nghiêm trọng vừa, thường gây lỗi đối soát, dispute, pending treo, khó debug.
2 = Trung bình, ảnh hưởng vận hành, báo cáo, UX, support.
1 = Thấp, nên có để hệ thống hoàn thiện nhưng không phải ưu tiên đầu.
```

Mức ưu tiên triển khai:

```text
P0 = Bắt buộc có trước khi chạy tiền thật
P1 = Cần có trước khi scale hoặc mở nhiều user
P2 = Cần có để vận hành ổn định, audit, fraud, đối soát
P3 = Tối ưu nâng cao
```

---

# 2. Tổng quan mức ưu tiên

| Nhóm | Nội dung                                | Trọng số trung bình | Ưu tiên |
| ---- | --------------------------------------- | ------------------: | ------- |
| A    | Core Money Safety                       |                   5 | P0      |
| B    | Idempotency & Concurrency               |                   5 | P0      |
| C    | Deposit Flow                            |                 4–5 | P0–P1   |
| D    | Withdraw Flow                           |                   5 | P0      |
| E    | Game / Betting Settlement               |                   5 | P0      |
| F    | Callback / Provider                     |                 4–5 | P0–P1   |
| G    | Ledger / Audit / Reconciliation         |                 4–5 | P0–P2   |
| H    | Bonus / Jackpot / Promotion             |                   4 | P1      |
| I    | Fraud / Risk / KYC                      |                 3–4 | P1–P2   |
| J    | Admin Operation                         |                 4–5 | P1      |
| K    | Distributed System / Worker / Queue     |                   4 | P1–P2   |
| L    | Reporting / Time / Currency             |                   3 | P2      |
| M    | Infrastructure / Deployment / Migration |                 4–5 | P1–P2   |
| N    | UX / Frontend Safety                    |                 2–3 | P2      |
| O    | Advanced Governance                     |                 2–3 | P3      |

---

# 3. P0 — Nhóm bắt buộc có trước khi chạy tiền thật

Đây là nhóm **không nên compromise**. Nếu thiếu các mục này, hệ thống có thể mất tiền ngay.

---

## A. Core Money Safety

| #   | Rủi ro                                                 | Trọng số | Ưu tiên | Ghi chú xử lý                                             |
| --- | ------------------------------------------------------ | -------: | ------- | --------------------------------------------------------- |
| A1  | Backend tin dữ liệu tiền từ frontend                   |        5 | P0      | Backend phải tự tính balance, win, payout, bonus, jackpot |
| A2  | Không dùng atomic update khi trừ tiền                  |        5 | P0      | Dùng `UPDATE ... WHERE balance >= amount`                 |
| A3  | Không dùng DB transaction cho wallet + ledger + status |        5 | P0      | Tiền và ledger phải commit/rollback cùng nhau             |
| A4  | Dùng `FLOAT` / `DOUBLE` cho tiền                       |        5 | P0      | Dùng `BIGINT` hoặc `DECIMAL`, ưu tiên `BIGINT`            |
| A5  | Không validate amount                                  |        5 | P0      | Chặn `amount <= 0`, `NaN`, null, quá lớn                  |
| A6  | Lấy `user_id` từ request body thay vì auth context     |        5 | P0      | User phải lấy từ token/session                            |
| A7  | Status `SUCCESS` nhưng wallet chưa update              |        5 | P0      | SUCCESS chỉ sau khi hiệu ứng tiền hoàn tất                |
| A8  | Balance thay đổi nhưng không có ledger                 |        5 | P0      | Không có ledger là không audit được                       |
| A9  | Cho sửa/xóa transaction history                        |        5 | P0      | Ledger phải bất biến, sai thì tạo reversal                |
| A10 | Admin sửa balance trực tiếp                            |        5 | P0      | Admin adjustment cũng phải qua ledger                     |

---

## B. Idempotency & Concurrency

| #   | Rủi ro                                             | Trọng số | Ưu tiên | Ghi chú xử lý                                          |
| --- | -------------------------------------------------- | -------: | ------- | ------------------------------------------------------ |
| B1  | Không có idempotency key                           |        5 | P0      | Chống retry / double submit                            |
| B2  | Idempotency key dùng timestamp frontend + user_id  |        5 | P0      | Dùng UUID v4/v7 hoặc random 128-bit                    |
| B3  | Retry cùng request nhưng tạo key mới               |        5 | P0      | Frontend phải reuse key cho cùng action                |
| B4  | Không có request hash                              |        4 | P0      | Cùng key khác payload phải trả `409 Conflict`          |
| B5  | Không có unique business key cho game round        |        5 | P0      | `user_id + game_id + round_id + action_type`           |
| B6  | Race condition khi nhiều request trừ tiền cùng lúc |        5 | P0      | Atomic update / lock / versioning                      |
| B7  | Multi-device / nhiều tab cùng thao tác             |        4 | P0      | Backend phải concurrent-safe, không tin disable button |
| B8  | Daily limit check bằng `SELECT SUM` không atomic   |        4 | P0/P1   | Dùng counter atomic hoặc lock                          |
| B9  | Read balance từ replica bị lag                     |        5 | P0      | Quyết định tiền phải đọc primary                       |
| B10 | Cache balance dùng để quyết định tiền              |        5 | P0      | Cache chỉ dùng để hiển thị                             |

---

## C. Ledger & Source of Truth

| #   | Rủi ro                                       | Trọng số | Ưu tiên               | Ghi chú xử lý                                                                 |
| --- | -------------------------------------------- | -------: | --------------------- | ----------------------------------------------------------------------------- |
| C1  | Chỉ lưu balance, không có ledger             |        5 | P0                    | Ledger là sự thật lịch sử                                                     |
| C2  | Ledger không replay được thành balance       |        5 | P0                    | Cần đủ amount, direction, balance type, status                                |
| C3  | Không có before/after balance                |        4 | P0/P1                 | Giúp audit và dispute                                                         |
| C4  | Không phân biệt real / bonus / locked        |        5 | P0                    | Tách ví theo bản chất tiền                                                    |
| C5  | Không có immutable transaction history       |        5 | P0                    | Không update/delete lịch sử                                                   |
| C6  | Không tách internal ID và external reference |        4 | P0/P1                 | Tách `internal_transaction_id`, `provider_ref`, `round_id`, `idempotency_key` |
| C7  | Không có currency trong transaction          |        5 | P0 nếu multi-currency | Amount không có currency là dữ liệu thiếu                                     |
| C8  | Không có transaction status rõ               |        4 | P0                    | `PENDING`, `PROCESSING`, `SUCCESS`, `FAILED`, `UNKNOWN`                       |
| C9  | Không có reference tới nghiệp vụ gốc         |        4 | P0                    | Bet, deposit, withdraw, jackpot đều phải trace được                           |
| C10 | Không có constraint balance không âm         |        4 | P0/P1                 | DB nên có rào chắn                                                            |

---

# 4. P0/P1 — Nhóm nạp tiền

Nạp tiền nguy hiểm nhất ở điểm: **cộng tiền ảo, callback giả, callback trùng, amount mismatch, hoặc user nạp thật nhưng không được cộng**.

---

## D. Deposit Flow

| #   | Rủi ro                                               | Trọng số | Ưu tiên | Ghi chú xử lý                                          |
| --- | ---------------------------------------------------- | -------: | ------- | ------------------------------------------------------ |
| D1  | Cộng tiền dựa trên frontend báo đã thanh toán        |        5 | P0      | Chỉ cộng sau provider/bank xác nhận                    |
| D2  | Không verify callback signature                      |        5 | P0      | HMAC/raw body/timestamp/nonce                          |
| D3  | Callback success bị xử lý nhiều lần                  |        5 | P0      | Unique `provider_reference_id`                         |
| D4  | Không check amount/currency từ callback              |        5 | P0      | Amount mismatch phải manual review                     |
| D5  | Callback không match deposit request nhưng bị bỏ qua |        4 | P1      | Lưu raw callback, đưa unmatched queue                  |
| D6  | Deposit expired nhưng tiền về sau                    |        4 | P1      | `LATE_PAYMENT`, manual review                          |
| D7  | User chuyển sai nội dung / thiếu mã nạp              |        4 | P1      | Manual matching, không auto đoán mù                    |
| D8  | User upload biên lai giả                             |        4 | P1      | Biên lai chỉ là bằng chứng, không là trigger cộng tiền |
| D9  | Chargeback/refund sau khi đã cộng ví                 |        5 | P1      | Cần reversal/negative balance/freeze policy            |
| D10 | Bonus nạp tiền bị cộng nhiều lần                     |        4 | P1      | Bonus cũng phải idempotent                             |
| D11 | Nạp nhiều khoản nhỏ để né limit                      |        3 | P2      | Rolling limit / velocity check                         |
| D12 | Một bank sender nạp cho nhiều user                   |        3 | P2      | Risk score / manual review                             |
| D13 | Import sao kê trùng dòng                             |        4 | P1      | Bank statement fingerprint                             |
| D14 | Bank statement không có ref duy nhất                 |        3 | P2      | Ambiguous thì manual review                            |
| D15 | Deposit pending treo vô hạn                          |        3 | P2      | Expiry/re-query job                                    |

---

# 5. P0/P1 — Nhóm rút tiền

Rút tiền là flow nguy hiểm nhất vì liên quan đến **tiền thật rời khỏi hệ thống**.

---

## E. Withdraw Flow

| #   | Rủi ro                                         | Trọng số | Ưu tiên | Ghi chú xử lý                                       |
| --- | ---------------------------------------------- | -------: | ------- | --------------------------------------------------- |
| E1  | Không tách available_balance và locked_balance |        5 | P0      | Rút tiền phải lock trước                            |
| E2  | User vừa rút vừa chơi                          |        5 | P0      | Lock tiền trước khi gửi provider                    |
| E3  | Release tiền khi provider timeout              |        5 | P0      | Timeout = UNKNOWN, không phải FAILED                |
| E4  | Late success callback sau khi đã release tiền  |        5 | P0      | `LATE_SUCCESS_CALLBACK`, manual review              |
| E5  | Cho user cancel khi đã PROCESSING              |        5 | P0      | Chỉ cancel khi chưa gửi provider                    |
| E6  | Không check withdrawable balance               |        5 | P0      | Không phải total balance nào cũng rút được          |
| E7  | Không check bonus turnover trước khi rút       |        4 | P1      | Chặn rút tiền chưa đủ điều kiện                     |
| E8  | Provider success nhưng amount thực trả khác    |        4 | P1      | Check `gross`, `fee`, `net`, `provider_paid_amount` |
| E9  | Provider balance không đủ                      |        4 | P1      | `WAITING_PROVIDER_FUNDS`, không auto fail           |
| E10 | Fallback provider khi attempt cũ UNKNOWN       |        5 | P0/P1   | Có thể double payout                                |
| E11 | Rút về bank account chưa verify                |        4 | P1      | Bank/KYC verification                               |
| E12 | Bank account bị sửa sau khi tạo withdraw       |        4 | P1      | Lưu snapshot bank tại thời điểm request             |
| E13 | Nhiều user rút về cùng bank account            |        4 | P2      | Fraud / mule account detection                      |
| E14 | Rút nhiều khoản nhỏ né review                  |        4 | P2      | Rolling threshold                                   |
| E15 | Rút khi còn open game round                    |        4 | P1      | Check open exposure                                 |

---

# 6. P0/P1 — Nhóm game / betting / settlement

Với game hoặc betting, rủi ro không chỉ là wallet, mà còn nằm ở **round lifecycle, result calculation, payout table, bonus, jackpot**.

---

## F. Game / Betting

| #   | Rủi ro                                              | Trọng số | Ưu tiên | Ghi chú xử lý                                  |
| --- | --------------------------------------------------- | -------: | ------- | ---------------------------------------------- |
| F1  | Frontend quyết định kết quả thắng/thua              |        5 | P0      | RNG, payout, result phải ở backend             |
| F2  | Frontend tự tạo round_id không kiểm soát            |        5 | P0      | Backend tạo round                              |
| F3  | Không có state machine cho game round               |        5 | P0      | `CREATED -> BET_PLACED -> SETTLED`             |
| F4  | BET một round bị xử lý nhiều lần                    |        5 | P0      | Unique game action                             |
| F5  | SETTLE/WIN bị xử lý nhiều lần                       |        5 | P0      | State condition + unique                       |
| F6  | ROLLBACK sau khi đã SETTLED                         |        5 | P0      | Chặn theo state                                |
| F7  | Rollback nhiều lần                                  |        5 | P0      | Một original transaction chỉ rollback một lần  |
| F8  | Rollback trả nhầm ví                                |        4 | P1      | Refund đúng nguồn real/bonus đã trừ            |
| F9  | Settle game không atomic với wallet                 |        5 | P0      | Game result + wallet + ledger cùng transaction |
| F10 | Payout table thay đổi nhưng round cũ chưa settle    |        4 | P1      | Lưu rule/config version                        |
| F11 | Payout table lệch giữa các server                   |        4 | P1      | Centralized config + version                   |
| F12 | Blue/green deploy khiến 2 logic tiền chạy song song |        4 | P1      | Feature flag + effective_from                  |
| F13 | Không có finality policy cho settlement             |        3 | P2      | Quy định dispute/void window                   |
| F14 | Game config client cache bản cũ                     |        3 | P2      | Client chỉ display, backend là nguồn tính      |
| F15 | RNG yếu / đoán được                                 |        4 | P1      | Backend RNG, audit seed nếu cần                |

---

# 7. P1 — Nhóm bonus / jackpot / promotion

Bonus và jackpot bản chất cũng là tiền, nên phải xử lý như tiền thật nhưng có thêm điều kiện.

---

## G. Bonus / Jackpot / Promotion

| #   | Rủi ro                                                      | Trọng số | Ưu tiên | Ghi chú xử lý                             |
| --- | ----------------------------------------------------------- | -------: | ------- | ----------------------------------------- |
| G1  | Không tách real_balance và bonus_balance                    |        5 | P0/P1   | Dễ cho rút sai bonus                      |
| G2  | Bonus cộng nhiều lần do callback trùng                      |        4 | P1      | Unique `deposit_request_id + campaign_id` |
| G3  | Không check turnover trước khi withdraw                     |        4 | P1      | `turnover_required`, `turnover_completed` |
| G4  | Win từ bonus không rõ vào ví nào                            |        4 | P1      | Rule rõ: real/bonus/locked                |
| G5  | Bet split real + bonus nhưng rollback sai                   |        4 | P1      | Rollback theo original split detail       |
| G6  | Thứ tự trừ real/bonus không rõ                              |        4 | P1      | `BONUS_FIRST`, `REAL_FIRST`, proportional |
| G7  | Bonus expired khi có open bet                               |        3 | P2      | Lưu policy snapshot tại thời điểm bet     |
| G8  | Rule promotion thay đổi giữa chừng                          |        3 | P2      | Campaign versioning                       |
| G9  | Jackpot không có pool/nguồn tiền rõ                         |        4 | P1      | Jackpot pool ledger                       |
| G10 | Jackpot payout không idempotent                             |        5 | P0/P1   | Unique jackpot payout event               |
| G11 | Cashback tính trên bet đã rollback                          |        4 | P1      | Chỉ tính eligible settled bets            |
| G12 | Commission affiliate không đảo khi transaction gốc rollback |        4 | P1      | `COMMISSION_REVERSED`                     |

---

# 8. P0/P1 — Nhóm callback / provider / external system

Provider có thể gửi trùng, gửi trễ, gửi sai thứ tự, gửi thiếu dữ liệu, hoặc chính provider cũng lỗi.

---

## H. Callback & Provider

| #   | Rủi ro                                   | Trọng số | Ưu tiên | Ghi chú xử lý                                  |
| --- | ---------------------------------------- | -------: | ------- | ---------------------------------------------- |
| H1  | Callback không verify signature          |        5 | P0      | HMAC/raw body/timestamp/nonce                  |
| H2  | Không lưu raw callback                   |        4 | P1      | Lưu payload/header/signature status            |
| H3  | Callback trùng xử lý nhiều lần           |        5 | P0      | Unique provider ref                            |
| H4  | Callback về sai thứ tự                   |        4 | P1      | State machine + event version                  |
| H5  | Callback success sau failed/released     |        5 | P0      | Manual review                                  |
| H6  | Callback failed sau success              |        4 | P1      | Không tự rollback, đưa conflict review         |
| H7  | Provider status mapping sai              |        5 | P0/P1   | Mapping table rõ `is_final`, `requires_action` |
| H8  | Provider ref bị trùng do provider lỗi    |        4 | P1      | Provider conflict review                       |
| H9  | Callback thiếu amount/currency           |        4 | P1      | Query provider lại, không tự xử lý             |
| H10 | Provider reversal sau success            |        4 | P1      | `PROVIDER_REVERSAL` transaction                |
| H11 | Provider maintenance nhưng vẫn nhận lệnh |        3 | P2      | Channel status                                 |
| H12 | Multi-provider payout gây double payout  |        5 | P0/P1   | Không fallback khi attempt cũ UNKNOWN          |
| H13 | Không đối soát provider balance          |        4 | P1/P2   | Provider settlement reconciliation             |
| H14 | Request replay attack                    |        4 | P1      | Signature + nonce + timestamp                  |
| H15 | Dùng chung API key cho nhiều service     |        4 | P1      | Scope permission theo service                  |

---

# 9. P1/P2 — Nhóm worker / queue / event-driven

Nếu hệ thống dùng queue, worker, event, outbox, cần đảm bảo **consumer cũng idempotent**.

---

## I. Worker / Queue / Event

| #   | Rủi ro                                       | Trọng số | Ưu tiên | Ghi chú xử lý                         |
| --- | -------------------------------------------- | -------: | ------- | ------------------------------------- |
| I1  | Nhiều worker xử lý cùng một job              |        5 | P0/P1   | Atomic claim job                      |
| I2  | Worker chết giữa PROCESSING                  |        4 | P1      | Lease timeout + retry policy          |
| I3  | Retry không phân biệt lỗi tạm thời/vĩnh viễn |        3 | P2      | Error taxonomy                        |
| I4  | Retry sau nhiều giờ nhưng state đã đổi       |        4 | P1      | Mỗi retry phải re-check current state |
| I5  | Publish event trước khi DB commit            |        5 | P0/P1   | Outbox pattern                        |
| I6  | Outbox event gửi trùng                       |        4 | P1      | Consumer idempotency                  |
| I7  | Consumer xử lý event sai thứ tự              |        4 | P1      | Event version / state check           |
| I8  | Settlement batch chạy lại cộng trùng         |        4 | P1      | Unique batch item key                 |
| I9  | Partial batch success                        |        4 | P1      | Item-level status                     |
| I10 | Audit log không nhất quán với transaction    |        3 | P2      | Audit trong transaction hoặc outbox   |
| I11 | Event không có correlation_id                |        3 | P2      | Trace toàn hệ thống                   |
| I12 | Job PROCESSING treo vô hạn                   |        4 | P1      | Scanner + alert                       |

---

# 10. P1/P2 — Nhóm admin / manual operation

Admin là nơi dễ gây lỗi tiền nếu không có maker-checker, audit và phân quyền.

---

## J. Admin Operation

| #   | Rủi ro                                        | Trọng số | Ưu tiên | Ghi chú xử lý                    |
| --- | --------------------------------------------- | -------: | ------- | -------------------------------- |
| J1  | Admin sửa balance trực tiếp                   |        5 | P0      | Cấm update balance tay           |
| J2  | Manual adjustment không qua ledger            |        5 | P0      | Adjustment là transaction riêng  |
| J3  | Không có maker-checker cho adjustment lớn     |        4 | P1      | Người tạo khác người duyệt       |
| J4  | Không log admin action                        |        4 | P1      | Admin audit log                  |
| J5  | Admin xử lý nhầm user                         |        4 | P1      | Confirmation UI                  |
| J6  | Admin action race với provider callback       |        5 | P0/P1   | State-safe update                |
| J7  | Không có quyền theo số tiền                   |        4 | P1      | Approval tier                    |
| J8  | Export report không audit                     |        3 | P2      | Log export                       |
| J9  | Phân quyền đọc dữ liệu tiền quá rộng          |        3 | P2      | RBAC + masking                   |
| J10 | Manual review không có reason code            |        3 | P2      | `review_reason_code`, risk rule  |
| J11 | Manual review không có SLA                    |        3 | P2      | Alert quá hạn                    |
| J12 | Admin xử lý transaction UNKNOWN bằng cảm tính |        4 | P1      | Re-query/provider evidence trước |

---

# 11. P1/P2 — Nhóm fraud / risk / KYC

Nhóm này không chỉ bảo vệ hệ thống khỏi bug, mà còn khỏi người dùng cố tình abuse.

---

## K. Fraud / Risk / KYC

| #   | Rủi ro                                           | Trọng số | Ưu tiên | Ghi chú xử lý                 |
| --- | ------------------------------------------------ | -------: | ------- | ----------------------------- |
| K1  | Rút tiền ngay sau khi nạp nguồn rủi ro           |        4 | P1      | Risk hold / cleared deposit   |
| K2  | Rút toàn bộ sau khi thắng lớn                    |        3 | P2      | Manual review threshold       |
| K3  | Nhiều user cùng bank account                     |        4 | P1/P2   | Multi-account risk            |
| K4  | Nhiều user cùng device/IP                        |        3 | P2      | Risk scoring                  |
| K5  | User đổi bank liên tục                           |        3 | P2      | Hold account mới              |
| K6  | KYC không match bank account                     |        4 | P1      | Name matching                 |
| K7  | Account bị khóa trong lúc có pending transaction |        4 | P1      | Policy theo từng flow         |
| K8  | User bị ban sau khi thắng nhưng trước payout     |        4 | P1      | `PAYOUT_HOLD`, `FRAUD_REVIEW` |
| K9  | Negative balance không có policy                 |        4 | P1      | Freeze/debt/recovery rule     |
| K10 | Không có reserve/risk hold                       |        3 | P2      | Hold theo nguồn tiền          |
| K11 | KYC thay đổi sau giao dịch                       |        3 | P2      | Snapshot KYC lúc request      |
| K12 | Transaction từ blacklisted bank/account          |        4 | P1      | Blacklist screening           |

---

# 12. P2 — Nhóm reporting / reconciliation / time

Đây là nhóm giúp hệ thống **không lệch âm thầm**.

---

## L. Reconciliation / Reporting / Time

| #   | Rủi ro                                        | Trọng số | Ưu tiên | Ghi chú xử lý                                    |
| --- | --------------------------------------------- | -------: | ------- | ------------------------------------------------ |
| L1  | Không có reconciliation hằng ngày             |        5 | P1      | Đối soát wallet/ledger/provider                  |
| L2  | Counter daily/monthly lệch ledger             |        3 | P2      | Counter reconciliation                           |
| L3  | Không có business_date                        |        3 | P2      | Dùng cho report và settlement                    |
| L4  | Timezone làm sai daily limit                  |        3 | P2      | Business timezone rõ                             |
| L5  | Giao dịch đúng lúc đổi ngày                   |        2 | P2      | Quy định tính theo created/settled/business date |
| L6  | Không phân biệt created_at/paid_at/settled_at |        3 | P2      | Mỗi mốc có ý nghĩa riêng                         |
| L7  | Không có effective_at                         |        3 | P2      | Adjustment/chargeback cần effective date         |
| L8  | Query report nặng làm chậm production         |        3 | P2      | Replica/materialized summary                     |
| L9  | Provider balance không khớp ví nội bộ         |        4 | P1/P2   | Provider settlement report                       |
| L10 | Không có alert lệch tiền                      |        4 | P1      | Alert reconciliation mismatch                    |
| L11 | Không có alert pending quá lâu                |        3 | P2      | SLA alert                                        |
| L12 | Không có taxonomy error_code                  |        3 | P2      | Support/debug/report                             |

---

# 13. P1/P2 — Nhóm currency / fee / rounding

Nếu hệ thống chỉ dùng VND thì nhóm này nhẹ hơn. Nếu có THB/USD/USDT thì trọng số tăng.

---

## M. Currency / Fee / Rounding

| #   | Rủi ro                                        | Trọng số | Ưu tiên               | Ghi chú xử lý                                |
| --- | --------------------------------------------- | -------: | --------------------- | -------------------------------------------- |
| M1  | Amount không có currency                      |        5 | P0 nếu multi-currency | Mọi transaction phải có currency             |
| M2  | Cộng sai currency vào ví                      |        5 | P0/P1                 | Không cộng VND vào ví THB                    |
| M3  | Exchange rate thay đổi giữa request và settle |        4 | P1                    | Rate quote/version/expiry                    |
| M4  | Không lưu rate source/timestamp               |        3 | P2                    | Audit conversion                             |
| M5  | Rounding fee/bonus sai                        |        4 | P1                    | Rounding policy chính thức                   |
| M6  | Fee bị tính hai lần                           |        4 | P1                    | Tách gross/fee/net                           |
| M7  | Fee không có ledger riêng                     |        3 | P2                    | Fee là transaction detail                    |
| M8  | Provider trả net khác gross                   |        4 | P1                    | Match `provider_paid_amount`                 |
| M9  | Chia jackpot/commission rounding lệch         |        3 | P2                    | Rounding diff ledger                         |
| M10 | Currency scale sai                            |        4 | P1                    | VND 0 decimal, USD cents, crypto scale riêng |

---

# 14. P1/P2 — Nhóm infrastructure / migration / deployment

Nhóm này thường bị xem nhẹ, nhưng khi lỗi thì ảnh hưởng toàn hệ thống.

---

## N. Infrastructure / Deployment / Migration

| #   | Rủi ro                                                | Trọng số | Ưu tiên | Ghi chú xử lý                          |
| --- | ----------------------------------------------------- | -------: | ------- | -------------------------------------- |
| N1  | Migration dữ liệu tiền không có plan                  |        5 | P0/P1   | Backup, dry run, checksum, rollback    |
| N2  | Backfill ledger từ balance hiện tại không có approval |        4 | P1      | `OPENING_BALANCE` có phê duyệt         |
| N3  | Không có backup/PITR                                  |        5 | P0/P1   | Point-in-time recovery                 |
| N4  | Backup chưa test restore                              |        4 | P1      | Test restore định kỳ                   |
| N5  | Clock lệch giữa server                                |        3 | P2      | NTP / DB timestamp                     |
| N6  | Blue/green deploy chạy song song 2 logic tiền         |        4 | P1      | Rule versioning                        |
| N7  | Config tiền lệch giữa server                          |        4 | P1      | Central config                         |
| N8  | Không có kill switch                                  |        4 | P1      | Disable deposit/withdraw/provider/game |
| N9  | Provider maintenance không được phản ánh              |        3 | P2      | Channel status                         |
| N10 | Test gọi nhầm production provider                     |        4 | P1      | Env guard / sandbox key                |
| N11 | Test data lẫn production report                       |        2 | P3      | `is_test_transaction`                  |
| N12 | Archive ledger làm mất audit trail                    |        3 | P2      | Read-only archive/checksum             |

---

# 15. P2 — Nhóm frontend / UX safety

Frontend không phải lớp bảo mật chính, nhưng frontend tốt giúp giảm retry sai, khiếu nại và thao tác trùng.

---

## O. Frontend / UX Safety

| #   | Rủi ro                                          | Trọng số | Ưu tiên | Ghi chú xử lý                    |
| --- | ----------------------------------------------- | -------: | ------- | -------------------------------- |
| O1  | Frontend không giữ idempotency key khi retry    |        4 | P1      | Retry phải reuse key             |
| O2  | User bấm lại vì UI không có pending state       |        3 | P2      | Disable button + loading/pending |
| O3  | App refresh làm mất pending request             |        3 | P2      | Fetch lại status từ backend      |
| O4  | Không có endpoint query transaction status      |        4 | P1/P2   | `GET /transaction/status`        |
| O5  | API response retry không nhất quán              |        3 | P2      | Idempotent response standard     |
| O6  | UI không hiển thị locked/bonus/withdrawable     |        2 | P2      | Giảm hiểu nhầm                   |
| O7  | UI hiển thị payout table cũ                     |        3 | P2      | Config version                   |
| O8  | User không biết withdraw đang review            |        2 | P2      | Status rõ                        |
| O9  | User upload proof nhưng tưởng đã được cộng tiền |        2 | P2      | Copy trạng thái rõ               |
| O10 | Error message không có mã chuẩn                 |        2 | P2      | Error code + message             |

---

# 16. Bảng ưu tiên triển khai theo phase

---

## Phase 0 — Không có thì không nên chạy tiền thật

```text
1. Backend không tin tiền/result từ frontend
2. BIGINT/DECIMAL cho money, tuyệt đối không FLOAT/DOUBLE
3. Atomic debit với điều kiện balance >= amount
4. DB transaction cho wallet + ledger + business status
5. Ledger immutable
6. Idempotency key
7. Request hash
8. Unique business key cho game/deposit/withdraw/callback
9. Verify callback signature
10. Tách real_balance / bonus_balance / locked_balance
11. Withdraw lock available -> locked
12. Deposit chỉ cộng sau callback/bank verified
13. Game result/payout tính ở backend
14. State machine cho deposit/withdraw/game round
15. Không admin update balance trực tiếp
16. User_id lấy từ auth context
17. Primary DB cho quyết định tiền
18. Không dùng cache làm source of truth
19. Không fallback payout khi provider attempt đang UNKNOWN
20. Backup/PITR tối thiểu
```

---

## Phase 1 — Cần có trước khi mở rộng user hoặc volume

```text
1. Raw callback storage
2. Reconciliation hằng ngày
3. Alert balance âm / pending lâu / provider lỗi / duplicate callback
4. Worker atomic claim
5. Outbox pattern nếu dùng event
6. Consumer idempotency
7. Admin audit log
8. Maker-checker cho adjustment/rút tiền lớn
9. Bank account verification
10. Bonus turnover check
11. Jackpot pool ledger
12. Chargeback/reversal policy
13. Provider status mapping table
14. Manual review queue
15. Fraud rules cơ bản
16. Risk hold cho nguồn tiền rủi ro
17. Deadlock retry
18. Rate limit endpoint tiền
19. Migration checklist
20. Kill switch theo module
```

---

## Phase 2 — Cần có để vận hành bền vững

```text
1. Business_date / effective_at / paid_at / settled_at
2. Report không ảnh hưởng production
3. Provider settlement reconciliation
4. Rolling limit 24h/30d
5. Multi-account risk detection
6. Bank sender tracking
7. SLA cho manual review
8. Error code taxonomy
9. Correlation_id / trace_id
10. Counter reconciliation
11. Archive ledger có kiểm soát
12. RBAC cho dữ liệu tiền
13. Export audit log
14. UI hiển thị available/locked/bonus/withdrawable
15. Query transaction status API
16. Frontend pending state
17. Holiday / bank cutoff
18. Channel maintenance status
19. Rule/config versioning
20. Test data flag
```

---

## Phase 3 — Nâng cao

```text
1. Ledger hash chain / tamper detection
2. Advanced fraud scoring
3. Automated anomaly detection
4. Provably fair RNG nếu cần
5. Fine-grained permission by amount/risk
6. Cold storage archive
7. Advanced dispute management
8. Automated provider failover có kiểm soát
9. Risk-based withdrawal delay
10. Full financial observability dashboard
```

---

# 17. Top 30 rủi ro nghiêm trọng nhất

Nếu chỉ có thời gian review nhanh, hãy review 30 điểm này trước:

| Rank | Rủi ro                                              | Trọng số | Ưu tiên |
| ---: | --------------------------------------------------- | -------: | ------- |
|    1 | Backend tin dữ liệu tiền/result từ frontend         |        5 | P0      |
|    2 | Không dùng atomic update khi trừ tiền               |        5 | P0      |
|    3 | Không dùng DB transaction cho wallet + ledger       |        5 | P0      |
|    4 | Không có idempotency key                            |        5 | P0      |
|    5 | Không có unique business key cho game/action        |        5 | P0      |
|    6 | Không verify callback signature                     |        5 | P0      |
|    7 | Callback success xử lý nhiều lần                    |        5 | P0      |
|    8 | Deposit cộng tiền dựa trên frontend/proof           |        5 | P0      |
|    9 | Withdraw không lock available -> locked             |        5 | P0      |
|   10 | Provider timeout bị coi là failed và release tiền   |        5 | P0      |
|   11 | Late success callback sau khi đã release withdraw   |        5 | P0      |
|   12 | Fallback provider khi attempt trước UNKNOWN         |        5 | P0      |
|   13 | Game result/payout tính ở frontend                  |        5 | P0      |
|   14 | Game settle không atomic với wallet                 |        5 | P0      |
|   15 | Ledger bị sửa/xóa                                   |        5 | P0      |
|   16 | Chỉ lưu balance, không có ledger                    |        5 | P0      |
|   17 | Admin update balance trực tiếp                      |        5 | P0      |
|   18 | Dùng FLOAT/DOUBLE cho tiền                          |        5 | P0      |
|   19 | Không validate amount âm/null/NaN                   |        5 | P0      |
|   20 | Lấy user_id từ request body                         |        5 | P0      |
|   21 | Read balance từ replica/cache để quyết định tiền    |        5 | P0      |
|   22 | Worker xử lý trùng job tiền                         |        5 | P0/P1   |
|   23 | Publish event tiền trước khi DB commit              |        5 | P0/P1   |
|   24 | Migration dữ liệu tiền không có plan                |        5 | P0/P1   |
|   25 | Không có backup/PITR                                |        5 | P0/P1   |
|   26 | Chargeback/reversal không có policy                 |        5 | P1      |
|   27 | Amount/currency mismatch nhưng vẫn auto xử lý       |        5 | P0/P1   |
|   28 | Rút tiền khi chưa check withdrawable/bonus turnover |      4–5 | P1      |
|   29 | Không có state machine deposit/withdraw/game        |        5 | P0      |
|   30 | Manual review race với callback                     |        5 | P0/P1   |

---

# 18. Checklist theo vai trò team

---

## Backend cần chịu trách nhiệm chính

```text
Atomic update
DB transaction
Idempotency
Request hash
State machine
Ledger
Wallet balance model
Deposit/withdraw request model
Callback verification
Provider mapping
Worker claim
Outbox/event idempotency
Reconciliation data
Admin audit
```

---

## Frontend cần chịu trách nhiệm chính

```text
Tạo UUID idempotency key
Reuse key khi retry cùng action
Không tự tính tiền thắng/thua
Không gửi balance/after_balance/win_amount làm nguồn quyết định
Hiển thị pending state
Không cho user spam click về mặt UX
Fetch transaction status sau timeout
Hiển thị available/locked/bonus/withdrawable rõ ràng
```

---

## QA cần test bắt buộc

```text
100 request bet cùng lúc
100 withdraw cùng lúc
100 callback success trùng
Retry sau timeout
Same idempotency key khác payload
Provider timeout rồi late success
Deposit amount mismatch
Expired deposit rồi tiền về
Admin action cùng lúc callback
Worker chết giữa PROCESSING
Batch settlement chạy lại
Bonus cộng trùng
Rollback nhiều lần
Read replica lag
Cache stale
Migration dry run
```

---

## DevOps / Infra cần chịu trách nhiệm

```text
Backup + restore test
PITR
Primary/replica routing
NTP/time sync
Monitoring DB lock/deadlock
Alert pending/failed/duplicate/reconciliation mismatch
Provider channel kill switch
Production/sandbox separation
Deployment rule versioning
Migration safety
```

---

## Product / Operation cần định nghĩa rule

```text
Min/max deposit
Min/max withdraw
Daily/monthly limit
Withdrawable balance definition
Bonus turnover
Bonus expiry
Win from bonus rule
Fee gross/net rule
Timeout policy
Manual review SLA
Chargeback policy
Negative balance policy
Bank account verification
KYC mismatch handling
Provider fallback policy
Game settlement finality
```

---

# 19. Cấu trúc phân loại cuối cùng

Có thể gom toàn bộ hệ thống thành 12 nhóm lớn:

```text
1. Core Money Safety
2. Idempotency & Concurrency
3. Wallet Balance Model
4. Ledger & Audit
5. Deposit Flow
6. Withdraw Flow
7. Game / Betting Settlement
8. Bonus / Jackpot / Promotion
9. Callback / Provider Integration
10. Worker / Queue / Event System
11. Admin / Manual Operation
12. Reconciliation / Fraud / Infrastructure
```

---

# 20. Bản trọng số ngắn gọn để đưa vào tài liệu

```text
Weight 5 — Must not fail
Các lỗi gây mất tiền ngay, cộng tiền ảo, double payout, trừ sai tiền, hoặc bị exploit trực tiếp.
Bắt buộc xử lý ở P0.

Weight 4 — High financial risk
Các lỗi gây lệch ledger, callback sai, manual review nguy hiểm, fraud lớn, hoặc vận hành không an toàn.
Xử lý ở P1.

Weight 3 — Operational risk
Các lỗi gây pending treo, dispute, report sai, support khó, hoặc fraud detection yếu.
Xử lý ở P2.

Weight 2 — UX / reporting quality
Các lỗi làm user hiểu nhầm, tăng ticket support, hoặc gây khó theo dõi.
Xử lý ở P2/P3.

Weight 1 — Optimization
Các cải tiến nâng cao, hữu ích khi scale lớn hoặc cần chuẩn tài chính cao.
Xử lý ở P3.
```

---

# 21. Kết luận ưu tiên

Nếu phải chọn **10 việc quan trọng nhất để làm trước**, hãy chọn:

```text
1. Backend tự tính toàn bộ tiền, không tin frontend
2. Atomic update + DB transaction
3. Ledger immutable
4. Idempotency key + request hash
5. Unique business key cho game/deposit/withdraw/callback
6. Verify callback signature + lưu raw callback
7. Tách real / bonus / locked / withdrawable balance
8. Withdraw lock tiền trước, timeout không release vội
9. State machine cho deposit / withdraw / game round
10. Reconciliation + alert + backup/PITR
```

Câu chốt cho tài liệu:

> Hệ thống tiền an toàn không phải là hệ thống “không bao giờ lỗi”. Hệ thống tiền an toàn là hệ thống mà khi lỗi xảy ra — retry, timeout, callback trùng, callback trễ, worker chết, admin xử lý tay, provider sai, user spam — tiền vẫn không bị mất, không bị cộng trùng, không bị trừ sai, và mọi thay đổi đều truy vết được bằng ledger.
