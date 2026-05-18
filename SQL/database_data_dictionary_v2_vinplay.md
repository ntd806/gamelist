# Database Data Dictionary V2 - VinPlay

> Bản V2 bổ sung: enum/status mapping suy luận, money field risk map, relationship map, backend flow map và QA checklist. Lưu ý: các giá trị enum dạng số cần xác minh thêm bằng source backend vì schema không có comment chính thức.

## 0. Phạm vi kiểm tra

| Database | Số bảng | Số field | Vai trò |
|---|---:|---:|---|
| `vinplay` | 59 | 513 | Core user/ví/nạp-rút/game log/operator |
| `vinplay_admin` | 14 | 112 | Admin/đại lý/phân quyền/log thao tác |
| `vinplay_minigame` | 14 | 90 | Mini game/Tài Xỉu/pot/fund |
| `vinplay_gamebai` | 11 | 95 | Game bài/tournament/free code/jackpot |

---

## 1. Executive Summary cho Backend / QA

### 1.1. Database quan trọng nhất
- `vinplay` là database core vì chứa `users.vin`, `users.xu`, `freeze_money`, `topup`, `withdraw`, `money_system`.
- `vinplay_minigame` chứa transaction và kết quả Tài Xỉu. Đây là database đối soát với ví chính trong `vinplay.users`.
- `vinplay_gamebai` chứa tournament, free code, jackpot game bài. Có liên quan thưởng/quỹ nhưng không phải ví chính.
- `vinplay_admin` chứa quyền admin, request rút, log thao tác admin/đại lý. Đây là vùng rủi ro thao tác thủ công.

### 1.2. Vấn đề thiết kế cần ưu tiên
1. **Thiếu wallet ledger trung tâm**: nhiều bảng có tiền nhưng chưa thấy bảng ledger chuẩn để đối soát before/after balance.
2. **Kiểu dữ liệu tiền không đồng nhất**: `bigint`, `int`, `varchar`, `float` cùng tồn tại.
3. **Enum/status thiếu mapping chính thức**: nhiều field `status`, `type`, `state`, `result`, `money_type` chỉ là số hoặc char.
4. **Thiếu unique idempotency ở flow tổng**: `topup`/`withdraw` tổng chưa thấy unique cho `order_no`, `transaction_code`.
5. **Cross-database settlement**: game transaction ở `vinplay_minigame`, ví ở `vinplay`, nếu không transaction atomic sẽ lệch tiền.

---
## 2. Enum / Status Mapping cần xác minh

### 2.1. Nguyên tắc đọc enum/status
Các field bên dưới **không nên tự gán nghĩa tuyệt đối từ schema**. Cách chuẩn là grep source backend theo tên bảng + tên field, ví dụ `withdraw.status`, `transaction_tai_xiu.money_type`, `poker_tour.tour_state`.

### 2.2. Danh sách field enum/status theo schema

| Database | Table | Field | Type | Mapping suy luận | Mức rủi ro |
|---|---|---|---|---|---|
| `vinplay` | `agent` | `game` | `varchar(255)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `agent` | `status` | `int` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `daily_event` | `event_type` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `daily_mission` | `mission_type` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `daily_mission` | `status` | `smallint` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `dealer` | `room_type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay` | `dealer` | `is_active` | `int` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay` | `event_vp_lucky` | `type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay` | `freeze_money` | `game_name` | `varchar(45)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay` | `freeze_money` | `money_type` | `varchar(5)` | Thường phân biệt loại tiền VIN/XU hoặc real/play money; không được đoán số. | High |
| `vinplay` | `freeze_money` | `status` | `int` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `games` | `status` | `int` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `idol` | `display_name` | `varchar(100)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `idol` | `status` | `tinyint` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `log_game_reference` | `result` | `int` | Kết quả game/ván; với Tài Xỉu có thể là Tài/Xỉu nhưng cần xác minh. | High |
| `vinplay` | `log_game_round` | `pot_result` | `varchar(100)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay` | `log_game_round` | `game_id` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `log_game_thau_vi` | `result` | `int` | Kết quả game/ván; với Tài Xỉu có thể là Tài/Xỉu nhưng cần xác minh. | High |
| `vinplay` | `log_tranfer_agent` | `transaction_no` | `varchar(45)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `log_tranfer_agent` | `status` | `int` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `log_tranfer_agent` | `process` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `log_tranfer_agent` | `is_freeze_money` | `int` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay` | `mission` | `type` | `smallint` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay` | `operator_activity_log` | `action` | `varchar(100)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `operator_activity_log` | `processing_time_ms` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `operator_activity_log_copy1` | `action` | `varchar(100)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `operator_activity_log_copy1` | `processing_time_ms` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `operator_api_keys` | `status` | `enum('ACTIVE','REVOKED','EXPIRED')` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `operator_api_keys` | `last_used_at` | `timestamp` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay` | `operator_api_keys_copy1` | `status` | `enum('ACTIVE','REVOKED','EXPIRED')` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `operator_api_keys_copy1` | `last_used_at` | `timestamp` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay` | `operator_audit_log` | `action` | `varchar(100)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `operator_audit_log` | `processing_time_ms` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `operator_audit_log_copy1` | `action` | `varchar(100)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `operator_audit_log_copy1` | `processing_time_ms` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `operator_database_config` | `pool_status` | `enum('INITIALIZING','ACTIVE','INACTIVE','ERROR')` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay` | `operator_database_config` | `health_status` | `varchar(50)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay` | `operator_database_config` | `is_active` | `tinyint(1)` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay` | `operators` | `status` | `enum('ACTIVE','INACTIVE','SUSPENDED')` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `product` | `type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay` | `product_user` | `is_active` | `int` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay` | `product_user` | `type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay` | `report_daily` | `game` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `report_money_daily` | `action_name` | `varchar(256)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `system_account` | `gameName` | `varchar(20)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `system_account` | `type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay` | `system_account` | `status` | `int` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `topup` | `transaction_code` | `varchar(20)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay` | `topup` | `status` | `tinyint` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `topup` | `type` | `tinyint` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | High |
| `vinplay` | `topup` | `bank_type` | `varchar(50)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay` | `topup_bank` | `status` | `tinyint(1)` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `topup_momo` | `type` | `tinyint` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | High |
| `vinplay` | `topup_zalopay` | `status` | `tinyint` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `user_gun` | `active` | `int` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay` | `users` | `dai_ly` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `users` | `status` | `int` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `users` | `is_bot` | `int` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay` | `users` | `is_idol` | `int` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay` | `users_in_game` | `game_id` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `users_vp_event` | `is_bot` | `int` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay` | `utm_campain` | `name_display` | `varchar(255)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `utm_medium` | `name_display` | `varchar(255)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `utm_source` | `name_display` | `varchar(255)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `videos` | `status` | `bit(1)` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `weekly_mission` | `mission_type` | `varchar(255)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay` | `weekly_mission` | `status` | `smallint` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `withdraw` | `transaction_code` | `varchar(20)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay` | `withdraw` | `admin_approve` | `varchar(100)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay` | `withdraw` | `status` | `tinyint` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay` | `withdraw` | `type` | `varchar(50)` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | High |
| `vinplay_admin` | `action_admin` | `action` | `varchar(255)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay_admin` | `groupuser` | `Type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay_admin` | `log_admin` | `action` | `varchar(255)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay_admin` | `log_admin` | `money_type` | `varchar(50)` | Thường phân biệt loại tiền VIN/XU hoặc real/play money; không được đoán số. | High |
| `vinplay_admin` | `log_admin` | `status` | `varchar(11)` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay_admin` | `log_loginadmin` | `status` | `int` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay_admin` | `log_loginadmin` | `action` | `varchar(255)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay_admin` | `menu` | `Status` | `char(1)` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay_admin` | `price_giftcode` | `money_type` | `int` | Thường phân biệt loại tiền VIN/XU hoặc real/play money; không được đoán số. | High |
| `vinplay_admin` | `rolemenu` | `Type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay_admin` | `source_giftcode` | `type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay_admin` | `source_giftcode` | `display` | `int` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay_admin` | `user` | `Status` | `char(2)` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay_admin` | `user` | `Active` | `int` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay_admin` | `useragent` | `status` | `varchar(2)` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay_admin` | `useragent` | `show` | `int` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay_admin` | `useragent` | `active` | `int` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay_admin` | `userrole` | `Type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay_minigame` | `game_result` | `game` | `int` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay_minigame` | `game_result` | `result` | `varchar(20)` | Kết quả game/ván; với Tài Xỉu có thể là Tài/Xỉu nhưng cần xác minh. | High |
| `vinplay_minigame` | `references` | `game_id` | `int` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay_minigame` | `result_tai_xiu` | `result` | `tinyint` | Kết quả game/ván; với Tài Xỉu có thể là Tài/Xỉu nhưng cần xác minh. | High |
| `vinplay_minigame` | `result_tai_xiu` | `money_type` | `tinyint` | Thường phân biệt loại tiền VIN/XU hoặc real/play money; không được đoán số. | High |
| `vinplay_minigame` | `rotate_slot_free` | `game_name` | `varchar(45)` | Cần đọc source để map giá trị cụ thể. | Medium |
| `vinplay_minigame` | `thanh_du` | `type` | `tinyint` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay_minigame` | `transaction_detail_tai_xiu` | `transaction_code` | `varchar(120)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay_minigame` | `transaction_detail_tai_xiu` | `bet_side` | `tinyint` | Cửa cược, ví dụ Tài/Xỉu hoặc side khác; cần map từ source. | High |
| `vinplay_minigame` | `transaction_detail_tai_xiu` | `money_type` | `tinyint` | Thường phân biệt loại tiền VIN/XU hoặc real/play money; không được đoán số. | High |
| `vinplay_minigame` | `transaction_tai_xiu` | `bet_side` | `tinyint` | Cửa cược, ví dụ Tài/Xỉu hoặc side khác; cần map từ source. | High |
| `vinplay_minigame` | `transaction_tai_xiu` | `money_type` | `tinyint` | Thường phân biệt loại tiền VIN/XU hoặc real/play money; không được đoán số. | High |
| `vinplay_gamebai` | `game_free_code_detail` | `game_name` | `varchar(45)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay_gamebai` | `game_free_code_detail` | `type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | High |
| `vinplay_gamebai` | `game_free_code_detail` | `status` | `int` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay_gamebai` | `game_free_code_package` | `game_name` | `varchar(45)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay_gamebai` | `game_free_code_package` | `type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | High |
| `vinplay_gamebai` | `game_tour_mark` | `game_name` | `varchar(45)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay_gamebai` | `game_tour_mark` | `status` | `int` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay_gamebai` | `game_tour_vip` | `game_name` | `varchar(45)` | Cần đọc source để map giá trị cụ thể. | High |
| `vinplay_gamebai` | `poker_free_ticket` | `tour_type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay_gamebai` | `poker_free_ticket` | `used` | `bit(1)` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | High |
| `vinplay_gamebai` | `poker_free_ticket` | `create_type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | Medium |
| `vinplay_gamebai` | `poker_free_ticket` | `is_bot` | `bit(1)` | Cờ bật/tắt hoặc boolean-like; kiểm tra 0/1 và bit/char. | Medium |
| `vinplay_gamebai` | `poker_tour` | `tour_state` | `int` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |
| `vinplay_gamebai` | `poker_tour` | `tour_type` | `int` | Loại nghiệp vụ/game/room/tour; cần enum từ source. | High |
| `vinplay_gamebai` | `xoc_dia_boss` | `status` | `int` | Trạng thái vòng đời: pending/running/success/failed/cancel/settled tùy bảng. | High |

### 2.3. Enum cần ưu tiên map trước khi sửa code
| Field/nhóm field | Vì sao ưu tiên |
|---|---|
| `vinplay.withdraw.status`, `admin_approve`, `type` | Liên quan rút tiền, hoàn tiền, duyệt admin. |
| `vinplay.topup.status`, `type`, `channel` | Liên quan nạp tiền và callback cổng thanh toán. |
| `vinplay.freeze_money.status`, `money_type` | Liên quan tiền bị giữ và hoàn/trừ khi game lỗi. |
| `vinplay_minigame.transaction_tai_xiu.money_type`, `bet_side` | Liên quan loại tiền và cửa cược. |
| `vinplay_minigame.result_tai_xiu.result`, `money_type` | Liên quan settle kết quả Tài Xỉu. |
| `vinplay_gamebai.poker_tour.tour_state`, `tour_type` | Liên quan vòng đời tournament và chia thưởng. |
| `vinplay_gamebai.game_free_code_detail.status`, `type` | Liên quan redeem code và chống dùng lại. |
| `vinplay_admin.log_admin.status`, `action`, `money_type` | Liên quan thao tác admin cộng/trừ tiền. |

---
## 3. Money Field Risk Map

### 3.1. Top field nguy hiểm nhất
| Field | Nghiệp vụ | Risk | Rule bắt buộc |
|---|---|---|---|
| vinplay.users.vin / xu / safe | Số dư chính của user | Rất cao | Mọi thay đổi phải có transaction + ledger + before/after. |
| vinplay.freeze_money.money | Tiền tạm giữ | Rất cao | Cần xử lý crash/disconnect/idempotency. |
| vinplay.withdraw.amount / previous_balance / balance_fluctuation | Rút tiền | Rất cao | Không được trừ/hoàn 2 lần; cần unique callback. |
| vinplay.topup.amount | Nạp tiền tổng | Rất cao | Không được cộng 2 lần khi callback retry. |
| vinplay.topup_bank/topup_momo/topup_vtpay/topup_zalopay amount/money/money_user | Nạp từng kênh | Rất cao | Đang dùng varchar ở nhiều bảng; cần chuẩn hóa/cast cẩn thận. |
| vinplay_minigame.transaction_tai_xiu.bet_value/prize/refund/exchange | Cược/thưởng Tài Xỉu | Rất cao | Phải settle đúng 1 lần theo reference_id. |
| vinplay_minigame.minigame_pots.value / minigame_funds.value | Hũ/quỹ mini game | Rất cao | Cần atomic update, chống nổ hũ 2 lần. |
| vinplay_gamebai.game_tour_jackpot.value / poker_tour.fund / poker_tour_user.prize | Tournament/jackpot | Cao | Cần trạng thái đã trả thưởng. |
| vinplay_admin.useragent.balance | Số dư đại lý/admin agent | Cao | Cần đối soát với agent/dealer/user core. |
| vinplay_admin.log_admin.money | Tiền admin thao tác | Cao | Log không thay thế ledger; cần reference đến giao dịch thật. |

### 3.2. Toàn bộ money-like fields phát hiện từ schema

| Database | Table | Field | Type | Nhận xét rủi ro |
|---|---|---|---|---|
| `vinplay` | `daily_event` | `money` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `freeze_money` | `money` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `freeze_money` | `money_type` | `varchar(5)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `log_game_reference` | `total_bet_odd` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_reference` | `total_bet_even` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_reference` | `total_buy_odd` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_reference` | `total_buy_even` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_reference` | `total_bet_4_black` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_reference` | `total_bet_4_white` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_reference` | `total_bet_3_black` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_reference` | `total_bet_3_white` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_reference` | `total_refund` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_reference` | `total_prize` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_reference` | `fee` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `log_game_result` | `total_received` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_result` | `total_bet` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_result` | `total_win` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_result` | `total_lose` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_result` | `total_fee` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_round` | `pot` | `varchar(100)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `log_game_round` | `money` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_round` | `pot_result` | `varchar(100)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `log_game_round` | `fee` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_round` | `total_money` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_thau_vi` | `total_bet_4_black` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_thau_vi` | `total_bet_4_white` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_thau_vi` | `total_bet_3_black` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_thau_vi` | `total_bet_3_white` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_thau_vi` | `total_prize` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_game_thau_vi` | `revenue` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `log_tranfer_agent` | `money_send` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_tranfer_agent` | `money_receive` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_tranfer_agent` | `fee` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `log_tranfer_agent` | `is_freeze_money` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `log_tranfer_agent` | `session_id_freeze_money` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `mission` | `money` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `money_system` | `money` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `product` | `price_usd` | `float` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `product` | `price_vnd` | `float` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `report_daily` | `totalBet` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `report_daily` | `totalPrize` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `report_daily` | `totalFee` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `report_daily` | `totalBetThauVi` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `report_daily` | `totalPayThauVi` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `report_daily` | `totalRevenueThauVi` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `report_daily` | `revenue` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `report_money_daily` | `money_win` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `report_money_daily` | `money_lost` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `report_money_daily` | `money_other` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `report_money_daily` | `fee` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `system_cashout` | `money` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `topup` | `amount` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `topup_bank` | `amount` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `topup_bank` | `money_user` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `topup_momo` | `money` | `varchar(20)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `topup_momo` | `money_user` | `varchar(20)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `topup_vtpay` | `money` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `topup_vtpay` | `money_user` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `topup_zalopay` | `amount` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `topup_zalopay` | `money_user` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay` | `users` | `vin` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `users` | `xu` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `users` | `vin_total` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `users` | `xu_total` | `bigint(20) unsigned zerofill` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `users` | `recharge_money` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `users` | `money_vp` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `users` | `total_level_1` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `users` | `total_level_2` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `users` | `money_affiliate` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `users` | `total_bet` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay` | `users_in_game` | `num_total` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `users_vp_event` | `vp_real` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `users_vp_event` | `vp_event` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `users_vp_event` | `vp_add` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `users_vp_event` | `vp_sub` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `withdraw` | `amount` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `withdraw` | `previous_balance` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay` | `withdraw` | `balance_fluctuation` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_admin` | `log_admin` | `money` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_admin` | `log_admin` | `money_type` | `varchar(50)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay_admin` | `price_giftcode` | `price` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_admin` | `price_giftcode` | `money_type` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_admin` | `request_withdraw` | `amount` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_admin` | `user` | `Balance` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_admin` | `useragent` | `percent_bonus_vincard` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_admin` | `useragent` | `balance` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `hu_game_bai` | `pot_name` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay_minigame` | `minigame_funds` | `fund_name` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay_minigame` | `minigame_pots` | `pot_name` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay_minigame` | `result_tai_xiu` | `total_tai` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `result_tai_xiu` | `total_xiu` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `result_tai_xiu` | `num_bet_tai` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_minigame` | `result_tai_xiu` | `num_bet_xiu` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_minigame` | `result_tai_xiu` | `total_prize` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `result_tai_xiu` | `total_refund_tai` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `result_tai_xiu` | `total_refund_xiu` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `result_tai_xiu` | `total_revenue` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `result_tai_xiu` | `money_type` | `tinyint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `thanh_du` | `total_betting` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `transaction_detail_tai_xiu` | `bet_value` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `transaction_detail_tai_xiu` | `bet_side` | `tinyint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `transaction_detail_tai_xiu` | `prize` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `transaction_detail_tai_xiu` | `refund` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `transaction_detail_tai_xiu` | `money_type` | `tinyint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `transaction_tai_xiu` | `bet_value` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `transaction_tai_xiu` | `bet_side` | `tinyint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `transaction_tai_xiu` | `total_prize` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `transaction_tai_xiu` | `total_refund` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `transaction_tai_xiu` | `total_exchange` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_minigame` | `transaction_tai_xiu` | `money_type` | `tinyint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_gamebai` | `game_free_code_detail` | `amount` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_gamebai` | `game_free_code_package` | `amount` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_gamebai` | `game_tour_mark` | `fee` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_gamebai` | `game_tour_mark` | `mark` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_gamebai` | `game_tour_mark` | `user_total` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_gamebai` | `game_tour_mark` | `prize` | `varchar(45)` | Cần chuẩn hóa/cast; không lý tưởng cho tiền. |
| `vinplay_gamebai` | `poker_free_ticket` | `ticket` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_gamebai` | `poker_tour` | `ticket` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_gamebai` | `poker_tour` | `fund` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_gamebai` | `poker_tour_user` | `current_chip` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_gamebai` | `poker_tour_user` | `ticket_count` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_gamebai` | `poker_tour_user` | `last_chip` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_gamebai` | `poker_tour_user` | `mark` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_gamebai` | `poker_tour_user` | `prize` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_gamebai` | `xoc_dia_boss` | `fund_initial` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |
| `vinplay_gamebai` | `xoc_dia_boss` | `fee` | `int` | Kiểm tra overflow nếu tiền lớn. |
| `vinplay_gamebai` | `xoc_dia_boss` | `revenue` | `bigint` | Cần transaction/ledger nếu field thay đổi số dư/quỹ. |

### 3.3. Money fields đang dùng kiểu dữ liệu rủi ro cao

| Database | Table | Field | Type | Vì sao cần chú ý |
|---|---|---|---|---|
| `vinplay` | `freeze_money` | `money_type` | `varchar(5)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `log_game_round` | `pot` | `varchar(100)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `log_game_round` | `pot_result` | `varchar(100)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `log_tranfer_agent` | `session_id_freeze_money` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `product` | `price_usd` | `float` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `product` | `price_vnd` | `float` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `system_cashout` | `money` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `topup_bank` | `amount` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `topup_bank` | `money_user` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `topup_momo` | `money` | `varchar(20)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `topup_momo` | `money_user` | `varchar(20)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `topup_vtpay` | `money` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `topup_vtpay` | `money_user` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `topup_zalopay` | `amount` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay` | `topup_zalopay` | `money_user` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay_admin` | `log_admin` | `money_type` | `varchar(50)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay_minigame` | `hu_game_bai` | `pot_name` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay_minigame` | `minigame_funds` | `fund_name` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay_minigame` | `minigame_pots` | `pot_name` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |
| `vinplay_gamebai` | `game_tour_mark` | `prize` | `varchar(45)` | varchar/float không phù hợp để tính tiền hoặc đối soát chính xác. |

---
## 4. Table Relationship Map

Schema hầu như không khai báo foreign key, trừ nhóm operator. Vì vậy relationship bên dưới là **logical relationship** cần xác minh bằng source code.

| Source | Target | Ý nghĩa |
|---|---|---|
| `vinplay.users.id` | `vinplay.freeze_money.user_id` | Ví user bị freeze theo phiên game |
| `vinplay.users.id` | `vinplay.withdraw.user_id` | User tạo yêu cầu rút tiền |
| `vinplay.users.id` | `vinplay.topup.user_id` | User được cộng tiền khi nạp |
| `vinplay.users.nick_name` | `vinplay_minigame.transaction_tai_xiu.user_name` | Giao dịch đặt cược Tài Xỉu theo nickname |
| `vinplay_minigame.references.id/value` | `vinplay_minigame.result_tai_xiu.reference_id` | Phiên/kỳ Tài Xỉu có kết quả |
| `vinplay_minigame.result_tai_xiu.reference_id` | `vinplay_minigame.transaction_tai_xiu.reference_id` | Settle giao dịch theo phiên kết quả |
| `vinplay_minigame.transaction_tai_xiu.reference_id` | `vinplay_minigame.transaction_detail_tai_xiu.reference_id` | Header/detail hoặc tổng/chi tiết bet Tài Xỉu |
| `vinplay.users.nick_name` | `vinplay_gamebai.poker_tour_user.nick_name` | User tham gia poker tournament |
| `vinplay_gamebai.poker_tour.id` | `vinplay_gamebai.poker_tour_user.tour_id` | Tournament và danh sách user trong tour |
| `vinplay_gamebai.game_free_code_package.id` | `vinplay_gamebai.game_free_code_detail.package_id` | Gói free code và từng mã code |
| `vinplay_admin.groupuser.Id` | `vinplay_admin.userrole.Group_ID / rolemenu.Group_ID` | Nhóm quyền admin |
| `vinplay_admin.user.ID` | `vinplay_admin.userrole.User_ID / access_link.User_ID` | Admin user và quyền truy cập |
| `vinplay_admin.menu.id` | `vinplay_admin.rolemenu.Menu_ID / access_link.Menu_ID` | Menu admin và phân quyền |
| `vinplay.operators.id` | `vinplay.operator_api_keys.operator_id` | Operator và API key; có FK thật |
| `vinplay.operators.id` | `vinplay.operator_audit_log.operator_id` | Audit log operator; có FK thật |
| `vinplay.operators.id` | `vinplay.operator_database_config.operator_id` | Config database riêng cho operator |

### 4.1. ERD text theo nghiệp vụ

```text
User wallet core
vinplay.users
  ├─ vinplay.freeze_money
  ├─ vinplay.topup / topup_bank / topup_momo / topup_vtpay / topup_zalopay
  ├─ vinplay.withdraw
  ├─ vinplay.log_game_result / log_game_round / log_game_reference
  ├─ vinplay_minigame.transaction_tai_xiu / transaction_detail_tai_xiu / result_tai_xiu
  └─ vinplay_gamebai.poker_tour_user / game_free_code_detail

Admin/permission
vinplay_admin.user
  ├─ userrole ─ groupuser
  ├─ rolemenu ─ menu
  ├─ access_link ─ menu
  └─ log_admin / log_loginadmin

Operator
vinplay.operators
  ├─ operator_api_keys
  ├─ operator_audit_log
  ├─ operator_activity_log
  └─ operator_database_config
```

---
## 5. Backend Flow Map

### 5.1. Flow Nạp tiền
1. Nhận request/callback từ kênh nạp.
2. Check idempotency bằng `request_id`, `momo_transId`, `vtp_transId`, `order_no` hoặc `transaction_code`.
3. Ghi bảng kênh: `topup_bank` / `topup_momo` / `topup_vtpay` / `topup_zalopay`.
4. Ghi/update `vinplay.topup` là bảng tổng.
5. Lock `vinplay.users` theo `user_id` hoặc `nick_name`.
6. Cộng `users.vin` hoặc `users.xu`.
7. Ghi ledger/balance log nếu có; hiện schema chưa thấy ledger chuẩn.
8. Commit; callback retry chỉ trả lại kết quả cũ, không cộng tiền lần nữa.

### 5.2. Flow Rút tiền
1. Tạo yêu cầu rút vào `vinplay.withdraw` hoặc `vinplay_admin.request_withdraw` tùy flow đang dùng.
2. Lock `vinplay.users`.
3. Kiểm tra số dư; trừ tạm hoặc freeze tiền.
4. Lưu `previous_balance`, `balance_fluctuation` nếu flow có dùng.
5. Admin/partner xử lý.
6. Nếu thành công: update withdraw success, không cộng lại tiền.
7. Nếu thất bại: hoàn tiền đúng 1 lần.
8. Callback retry phải idempotent theo `order_no`, `transaction_code`, `txId`, `momoTransId`.

### 5.3. Flow Đặt cược game / Tài Xỉu
1. Nhận bet request kèm idempotency_key.
2. Lock `vinplay.users`.
3. Kiểm tra số dư theo `money_type`.
4. Trừ tiền cược khỏi `users.vin/xu` hoặc ghi freeze tùy thiết kế.
5. Ghi `vinplay_minigame.transaction_tai_xiu` và/hoặc `transaction_detail_tai_xiu`.
6. Update pot/fund nếu bet đóng góp vào hũ/quỹ.
7. Commit cùng transaction nếu cùng DB instance; nếu tách connection cần cơ chế outbox/saga.

### 5.4. Flow Trả thưởng / settle game
1. Chốt kết quả trong `result_tai_xiu` hoặc bảng result tương ứng.
2. Lock transaction game theo `reference_id`.
3. Chỉ settle transaction chưa settle.
4. Lock `vinplay.users`.
5. Cộng prize/refund vào ví.
6. Update transaction status/settled marker; nếu schema chưa có field status cần kiểm tra source dùng cơ chế nào.
7. Ghi log result/reference.
8. Commit; service restart không được settle lại.

### 5.5. Flow Jackpot / Pot
1. Đọc pot/fund hiện tại bằng lock hoặc atomic update.
2. Tính phần đóng góp pot từ bet.
3. Khi nổ hũ, lock pot trước khi trả thưởng.
4. Chỉ cho một process claim jackpot thành công.
5. Cộng thưởng cho user qua ví core.
6. Reset/update pot.
7. Ghi log jackpot/reference để đối soát.

### 5.6. Flow Free code / Gift code
1. User nhập code.
2. Atomic update `game_free_code_detail` từ UNUSED → USED theo `code` và `status`.
3. Nếu update affected rows = 1 thì cộng thưởng.
4. Nếu = 0 thì code đã dùng/hết hạn/sai trạng thái.
5. Ghi log nhận thưởng và reference.

### 5.7. Flow Admin cộng/trừ/chỉnh tiền
1. Admin action phải kiểm tra role.
2. Ghi `log_admin` trước/sau hoặc cùng transaction.
3. Lock user/agent balance liên quan.
4. Update số dư.
5. Ghi reason, action, money_type, account_name.
6. Không cho sửa/xóa log admin bằng UI thường.

### 5.8. Flow Freeze/unfreeze tiền
1. Khi vào game/session cần giữ tiền: tạo `freeze_money` status FROZEN.
2. Kết thúc game: SETTLED nếu đã trừ/cộng thật.
3. Lỗi/disconnect: REFUNDED/EXPIRED tùy rule.
4. Job reconcile tìm freeze quá lâu chưa xử lý.
5. Không được vừa refund vừa settle cùng session.

---
## 6. QA Checklist theo nghiệp vụ

### 6.1. QA Checklist - Nạp tiền
- [ ] Callback cùng mã gửi 2-5 lần chỉ cộng tiền 1 lần.
- [ ] Callback success sau callback pending cập nhật đúng trạng thái.
- [ ] Callback failed không cộng tiền.
- [ ] Số tiền ở bảng channel khớp `topup.amount` và `users.vin` tăng đúng.
- [ ] Dữ liệu varchar money có dấu phẩy/ký tự lạ không làm sai tiền.
- [ ] User không tồn tại/khóa tài khoản xử lý đúng.

### 6.2. QA Checklist - Rút tiền
- [ ] User spam rút cùng lúc không làm số dư âm.
- [ ] Withdraw pending không bị trừ 2 lần.
- [ ] Partner callback success retry không trừ thêm.
- [ ] Partner callback failed sau success không hoàn sai.
- [ ] Hủy rút hoàn tiền đúng 1 lần.
- [ ] Đối chiếu `withdraw`, `users`, `request_withdraw` nếu cả 2 flow cùng tồn tại.

### 6.3. QA Checklist - Bet game
- [ ] Spam bet cùng request không ghi trùng.
- [ ] Bet vượt số dư bị từ chối.
- [ ] Bet sát số dư còn 0 không âm.
- [ ] Bet VIN/XU đúng money_type.
- [ ] Mất kết nối sau khi trừ tiền có log/freeze để reconcile.
- [ ] Transaction game khớp số dư thay đổi.

### 6.4. QA Checklist - Settle thắng/thua
- [ ] Một reference chỉ settle một lần.
- [ ] Service restart không trả thưởng lại.
- [ ] Refund đúng cửa/đúng user.
- [ ] Kết quả Tài/Xỉu map đúng dice total.
- [ ] Tổng bet/prize/refund khớp report.
- [ ] Không settle khi result chưa final.

### 6.5. QA Checklist - Jackpot/Pot/Fund
- [ ] Nhiều user cùng trúng chỉ một user claim nếu rule là single jackpot.
- [ ] Pot không bị lost update khi nhiều bet đồng thời.
- [ ] Sau nổ hũ pot reset đúng.
- [ ] Fund không âm.
- [ ] Log jackpot đủ reference/user/balance.

### 6.6. QA Checklist - Free code
- [ ] Một code chỉ dùng một lần.
- [ ] Code hết hạn không dùng được.
- [ ] Code package quantity khớp số detail.
- [ ] Spam redeem không cộng thưởng trùng.
- [ ] Bot/user bị khóa không nhận code nếu rule cấm.

### 6.7. QA Checklist - Admin/Agent
- [ ] Admin không đủ quyền không truy cập menu/action.
- [ ] Admin cộng/trừ tiền có log_admin.
- [ ] Log admin không mất reason/account/money_type.
- [ ] Agent transfer không tạo lệch giữa sender/receiver.
- [ ] Freeze money qua agent transfer được unfreeze đúng.

### 6.8. QA Checklist - Reconcile/report
- [ ] Tổng topup theo ngày khớp tăng ví.
- [ ] Tổng withdraw success khớp giảm ví.
- [ ] Tổng bet/win/refund theo game khớp report_daily.
- [ ] Freeze quá hạn được phát hiện.
- [ ] Money varchar convert không sai khi SUM.

---
## 7. Bảng chi tiết field theo từng table - V2 annotations

Phần này không thay thế Data Dictionary V1, nhưng bổ sung phân loại field: `MONEY/RISK`, `ENUM/STATUS`, `TIME`, `IDENTIFIER`, `DATA`.

## 7.x. Database `vinplay`
### `agent`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`code`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `code` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `game` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `start_date` | `datetime` | `DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `status` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `currency`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `code` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `toCurrency` | `float` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `toUsd` | `float` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `daily_event`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `money` | `int` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `create_date` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `event_type` | `int` | `DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `daily_mission`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `mission_type` | `int` | `DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `complete` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `status` | `smallint` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `update_time` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `user_name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |

### `dealer`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_id` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `nick_name` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `room_type` | `int` | `DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `is_active` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `event_vp`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `name` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `value` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `num` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `use` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `update_time` | `timestamp` | `NOT NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `event_vp_lucky`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`date_run`,`type`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `date_run` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `num_run` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `type` | `int` | `NOT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `update_time` | `timestamp` | `NOT NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `follows`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`follower_id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `follower_id` | `bigint` | `NOT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `idol_id` | `bigint` | `NOT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `freeze_money`
**Vai trò:** Tiền tạm giữ trong phiên game.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `user_id_index` (`user_id`) USING BTREE`
- `KEY `session_id_index` (`session_id`) USING BTREE`
- `KEY `game_name_index` (`game_name`) USING BTREE`
- `KEY `nick_name_index` (`nick_name`) USING BTREE`
- `KEY `money_type_index` (`money_type`) USING BTREE`
- `KEY `status_index` (`status`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `bigint` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `session_id` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `user_id` | `bigint` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `game_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `room_id` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `money` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `money_type` | `varchar(5)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | MONEY/RISK, ENUM/STATUS | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `create_time` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `update_time` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `status` | `int` | `DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `game_config`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `value` | `longtext` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `version` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `platform` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `game_config_xx`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `value` | `longtext` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `version` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `platform` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `games`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `url` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `status` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `idol`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`user_id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `user_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(50)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `display_name` | `varchar(100)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `image` | `varchar(100)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `avatar` | `varchar(50)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `live_time` | `varchar(50)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `create_date` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `status` | `tinyint` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `key_value`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`value`)`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `key` | `varchar(20)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `value` | `bigint` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `level_config`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `level` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `map` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `value` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `log_game_reference`
**Vai trò:** Log reference ván/cửa cược.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `reference_id` | `int` | `DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `total_bet_odd` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_bet_even` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_buy_odd` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_buy_even` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_bet_4_black` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_bet_4_white` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_bet_3_black` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_bet_3_white` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `result` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `total_refund` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_prize` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `fee` | `int` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `create_date` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `room_id` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name_room_master` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |

### `log_game_result`
**Vai trò:** Tổng hợp kết quả game theo user/room.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `total_received` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_bet` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_win` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_lose` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `profit` | `bigint` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `room_id` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `create_date` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `total_fee` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |

### `log_game_round`
**Vai trò:** Log vòng game/pot/fee.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `pot` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `money` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `pot_result` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | MONEY/RISK, ENUM/STATUS | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `fee` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_money` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `room_id` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `game_id` | `int` | `DEFAULT NULL` | ENUM/STATUS, IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `create_date` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `log_game_thau_vi`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `reference_id` | `int` | `DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `total_bet_4_black` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_bet_4_white` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_bet_3_black` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_bet_3_white` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `result` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `total_prize` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `revenue` | `int` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `user_name_thau_vi` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `room_id` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `create_date` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `log_tranfer_agent`
**Vai trò:** Log chuyển tiền đại lý/user.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `transaction_no_index` (`transaction_no`) USING BTREE`
- `KEY `agent_level1_index` (`agent_level1`) USING BTREE`
- `KEY `nick_name_send_index` (`nick_name_send`) USING BTREE`
- `KEY `nick_name_receive_index` (`nick_name_receive`) USING BTREE`
- `KEY `money_send_index` (`money_send`) USING BTREE`
- `KEY `money_receive_index` (`money_receive`) USING BTREE`
- `KEY `status_index` (`status`) USING BTREE`
- `KEY `fee_index` (`fee`) USING BTREE`
- `KEY `top_ds_index` (`top_ds`) USING BTREE`
- `KEY `process_index` (`process`) USING BTREE`
- `KEY `ti_gia_index` (`ti_gia`) USING BTREE`
- `KEY `des_send_index` (`des_send`(255)) USING BTREE`
- `KEY `des_receive_index` (`des_receive`(255)) USING BTREE`
- `KEY `is_freeze_money_index` (`is_freeze_money`) USING BTREE`
- `KEY `session_id_freeze_money_index` (`session_id_freeze_money`) USING BTREE`
- `KEY `trans_time_index` (`trans_time`) USING BTREE`
- `KEY `update_time_index` (`update_time`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `transaction_no` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | ENUM/STATUS, IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `agent_level1` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `nick_name_send` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `nick_name_receive` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `money_send` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `money_receive` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `status` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `fee` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `top_ds` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `process` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `ti_gia` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `is_freeze_money` | `int` | `DEFAULT NULL` | MONEY/RISK, ENUM/STATUS | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `des_send` | `varchar(500)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `des_receive` | `varchar(500)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `session_id_freeze_money` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | MONEY/RISK, IDENTIFIER | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. Nên có unique/index nếu dùng chống xử lý trùng. |
| `trans_time` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `update_time` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `login_daily`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(30)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `login_date` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `times` | `int` | `DEFAULT '0'` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `mission`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `mission_name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `condition` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `type` | `smallint` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `money` | `int` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `energy` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `skill` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `money_system`
**Vai trò:** Quỹ/tiền hệ thống.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `name` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `money` | `bigint` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `update_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `create_time` | `timestamp` | `NOT NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `operator_activity_log`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_code` (`operator_code`)`
- `KEY `idx_action` (`action`)`
- `KEY `idx_created_at` (`created_at`)`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `bigint` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `operator_code` | `varchar(50)` | `NOT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `action` | `varchar(100)` | `NOT NULL COMMENT 'AUTH_SUCCESS, API_CALL, etc'` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `endpoint` | `varchar(255)` | `DEFAULT NULL COMMENT 'API endpoint'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `request_id` | `varchar(100)` | `DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `response_code` | `varchar(20)` | `DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `response_message` | `text` | `` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `ip_address` | `varchar(50)` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `processing_time_ms` | `int` | `DEFAULT NULL` | ENUM/STATUS, TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `created_at` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `operator_activity_log_copy1`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_code` (`operator_code`)`
- `KEY `idx_action` (`action`)`
- `KEY `idx_created_at` (`created_at`)`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `bigint` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `operator_code` | `varchar(50)` | `NOT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `action` | `varchar(100)` | `NOT NULL COMMENT 'AUTH_SUCCESS, API_CALL, etc'` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `endpoint` | `varchar(255)` | `DEFAULT NULL COMMENT 'API endpoint'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `request_id` | `varchar(100)` | `DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `response_code` | `varchar(20)` | `DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `response_message` | `text` | `` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `ip_address` | `varchar(50)` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `processing_time_ms` | `int` | `DEFAULT NULL` | ENUM/STATUS, TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `created_at` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `operator_api_keys`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_id` (`operator_id`)`
- `KEY `idx_api_key` (`api_key`)`
- `KEY `idx_status` (`status`)`
- `CONSTRAINT `operator_api_keys_ibfk_1` FOREIGN KEY (`operator_id`) REFERENCES `operators` (`id`) ON DELETE CASCADE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `operator_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `api_key` | `varchar(255)` | `NOT NULL` | IDENTIFIER | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |
| `key_name` | `varchar(100)` | `DEFAULT NULL COMMENT 'e.g., Production Key'` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `status` | `enum('ACTIVE','REVOKED','EXPIRED')` | `DEFAULT 'ACTIVE'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `created_at` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `revoked_at` | `timestamp` | `NULL DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `expires_at` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `last_used_at` | `timestamp` | `NULL DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `usage_count` | `bigint` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `notes` | `text` | `` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `operator_api_keys_copy1`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_id` (`operator_id`)`
- `KEY `idx_api_key` (`api_key`)`
- `KEY `idx_status` (`status`)`
- `CONSTRAINT `operator_api_keys_copy1_ibfk_1` FOREIGN KEY (`operator_id`) REFERENCES `operators` (`id`) ON DELETE CASCADE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `operator_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `api_key` | `varchar(255)` | `NOT NULL` | IDENTIFIER | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |
| `key_name` | `varchar(100)` | `DEFAULT NULL COMMENT 'e.g., Production Key'` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `status` | `enum('ACTIVE','REVOKED','EXPIRED')` | `DEFAULT 'ACTIVE'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `created_at` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `revoked_at` | `timestamp` | `NULL DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `expires_at` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `last_used_at` | `timestamp` | `NULL DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `usage_count` | `bigint` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `notes` | `text` | `` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `operator_audit_log`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_id` (`operator_id`)`
- `KEY `idx_action` (`action`)`
- `KEY `idx_created_at` (`created_at`)`
- `KEY `idx_request_id` (`request_id`)`
- `CONSTRAINT `operator_audit_log_ibfk_1` FOREIGN KEY (`operator_id`) REFERENCES `operators` (`id`) ON DELETE CASCADE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `bigint` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `operator_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `action` | `varchar(100)` | `NOT NULL COMMENT 'AUTH_SUCCESS, GET_BALANCE, etc.'` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `endpoint` | `varchar(255)` | `DEFAULT NULL COMMENT '/v2/4001, /v2/4012, etc.'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `request_id` | `varchar(100)` | `DEFAULT NULL COMMENT 'X-Request-ID header'` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `response_code` | `varchar(10)` | `DEFAULT NULL COMMENT '0=success, other=error'` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `response_message` | `text` | `` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `ip_address` | `varchar(45)` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `user_agent` | `text` | `` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `processing_time_ms` | `int` | `DEFAULT NULL` | ENUM/STATUS, TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `created_at` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `operator_audit_log_copy1`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_id` (`operator_id`)`
- `KEY `idx_action` (`action`)`
- `KEY `idx_created_at` (`created_at`)`
- `KEY `idx_request_id` (`request_id`)`
- `CONSTRAINT `operator_audit_log_copy1_ibfk_1` FOREIGN KEY (`operator_id`) REFERENCES `operators` (`id`) ON DELETE CASCADE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `bigint` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `operator_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `action` | `varchar(100)` | `NOT NULL COMMENT 'AUTH_SUCCESS, GET_BALANCE, etc.'` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `endpoint` | `varchar(255)` | `DEFAULT NULL COMMENT '/v2/4001, /v2/4012, etc.'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `request_id` | `varchar(100)` | `DEFAULT NULL COMMENT 'X-Request-ID header'` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `response_code` | `varchar(10)` | `DEFAULT NULL COMMENT '0=success, other=error'` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `response_message` | `text` | `` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `ip_address` | `varchar(45)` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `user_agent` | `text` | `` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `processing_time_ms` | `int` | `DEFAULT NULL` | ENUM/STATUS, TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `created_at` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `operator_database_config`
**Vai trò:** Cấu hình DB riêng theo operator.

**Key/Index:**
- `PRIMARY KEY (`id`)`
- `UNIQUE KEY `uk_operator_id` (`operator_id`)`
- `KEY `idx_mysql_database` (`mysql_database`)`
- `KEY `idx_tier` (`tier`)`
- `KEY `idx_shard_group` (`shard_group`)`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `operator_id` | `int` | `NOT NULL COMMENT 'Reference to operators.id'` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `mysql_host` | `varchar(255)` | `NOT NULL COMMENT 'MySQL host'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mysql_port` | `int` | `DEFAULT '3306' COMMENT 'MySQL port'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mysql_database` | `varchar(100)` | `NOT NULL COMMENT 'Database name'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mysql_username` | `varchar(100)` | `NOT NULL COMMENT 'Database username'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mysql_password` | `varchar(255)` | `NOT NULL COMMENT 'Database password'` | DATA | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |
| `mysql_min_pool` | `int` | `DEFAULT '2' COMMENT 'Minimum pool connections'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mysql_max_pool` | `int` | `DEFAULT '10' COMMENT 'Maximum pool connections'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mongo_host` | `varchar(255)` | `DEFAULT NULL COMMENT 'MongoDB host'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mongo_port` | `int` | `DEFAULT '27017' COMMENT 'MongoDB port'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mongo_database` | `varchar(100)` | `DEFAULT NULL COMMENT 'MongoDB database name'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mongo_auth_database` | `varchar(100)` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mongo_username` | `varchar(100)` | `DEFAULT NULL COMMENT 'MongoDB username'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mongo_password` | `varchar(255)` | `DEFAULT NULL COMMENT 'MongoDB password'` | DATA | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |
| `tier` | `enum('SMALL','MEDIUM','LARGE','ENTERPRISE')` | `DEFAULT 'SMALL'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `shard_group` | `varchar(50)` | `DEFAULT NULL COMMENT 'Shard group identifier'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `use_shared_pool` | `tinyint(1)` | `DEFAULT '1'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `estimated_user_count` | `int` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `estimated_tps` | `int` | `DEFAULT '10'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `pool_status` | `enum('INITIALIZING','ACTIVE','INACTIVE','ERROR')` | `DEFAULT 'INITIALIZING'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `pool_initialized_at` | `timestamp` | `NULL DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `last_health_check` | `timestamp` | `NULL DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `health_status` | `varchar(50)` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `error_message` | `text` | `` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `is_active` | `tinyint(1)` | `DEFAULT '1'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `created_at` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `updated_at` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `operators`
**Vai trò:** Đối tác/operator multi-tenant.

**Key/Index:**
- `PRIMARY KEY (`id`)`
- `UNIQUE KEY `operator_code` (`operator_code`)`
- `KEY `idx_operator_code` (`operator_code`)`
- `KEY `idx_status` (`status`)`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `operator_code` | `varchar(50)` | `NOT NULL COMMENT 'OP001, OP002, etc.'` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `operator_name` | `varchar(255)` | `NOT NULL COMMENT 'Partner display name'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `api_key` | `varchar(255)` | `NOT NULL COMMENT 'API key for authentication'` | IDENTIFIER | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |
| `secret_key` | `varchar(255)` | `NOT NULL COMMENT 'Secret key for HMAC signature'` | IDENTIFIER | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |
| `status` | `enum('ACTIVE','INACTIVE','SUSPENDED')` | `DEFAULT 'ACTIVE'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `whitelisted_ips` | `text` | `COMMENT 'Comma-separated IPs'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `allowed_scopes` | `text` | `COMMENT 'Comma-separated scopes'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `rate_limit_per_minute` | `int` | `DEFAULT '100'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `contact_email` | `varchar(255)` | `DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `contact_phone` | `varchar(50)` | `DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `description` | `text` | `` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `created_at` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `updated_at` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `created_by` | `varchar(100)` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `updated_by` | `varchar(100)` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `product`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `name` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `price_usd` | `float` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `price_vnd` | `float` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `order` | `smallint` | `DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `type` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `star` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `image_id` | `int` | `DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `name_eng` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `product_user`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`nick_name`,`product_id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `nick_name` | `varchar(100)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `product_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `create_date` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `is_active` | `int` | `NOT NULL DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `type` | `int` | `NOT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `report_daily`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `date` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `totalBet` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `totalPrize` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `totalFee` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `totalBetThauVi` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `totalPayThauVi` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `totalRevenueThauVi` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `revenue` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `game` | `int` | `DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `report_money_daily`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `action_name` (`action_name`(255)) USING BTREE`
- `KEY `date` (`date`) USING BTREE`
- `KEY `id` (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `action_name` | `varchar(256)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `money_win` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `money_lost` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `money_other` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `fee` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `date` | `date` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `system_account`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `userId` | `int` | `NOT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `userName` | `varchar(20)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `gameName` | `varchar(20)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `type` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `status` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `system_cashout`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `date_UNIQUE` (`date`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `date` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `money` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `update_time` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `topup`
**Vai trò:** Nạp tiền tổng hợp.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_id` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `amount` | `int` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `transaction_code` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS, IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `order_no` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `channel` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `code` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `card_serial` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `card_code` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `message` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `create_time` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `status` | `tinyint` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `type` | `tinyint` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `phone_number` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `account_name` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `account_number` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `bank_type` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `address_wallet` | `varchar(500)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `network` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `topup_bank`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`request_id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `request_id` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `nick_name` | `varchar(30)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `bank` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `status` | `tinyint(1)` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `amount` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `money_user` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `message` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `create_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `topup_momo`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`momo_transId`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `momo_transId` | `varchar(20)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `nick_name` | `varchar(30)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `requestTime` | `varchar(20)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | TIME, IDENTIFIER | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `message` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `money` | `varchar(20)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `money_user` | `varchar(20)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `phone` | `varchar(20)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `type` | `tinyint` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `create_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `topup_vtpay`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`vtp_transId`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `vtp_transId` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `requestTime` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | TIME, IDENTIFIER | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `message` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `money` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `phone` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `nick_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `money_user` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `create_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `topup_zalopay`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`request_id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `request_id` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `nick_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `bank` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `status` | `tinyint` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `amount` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `money_user` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `message` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `create_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `user_appotp`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`nick_name`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `nick_name` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `secret` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | IDENTIFIER | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |

### `user_gate`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `address` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `gate` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `user_gun`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `gun_id` | `int` | `DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `gun_num` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `active` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `user_item`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `item_id` | `int` | `DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `item_num` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `user_level`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `level` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `user_mission_vin`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `id_UNIQUE` (`id`) USING BTREE`
- `KEY `nick_name` (`nick_name`) USING BTREE`
- `KEY `mission_name` (`mission_name`) USING BTREE`
- `KEY `nick_name_mission_name` (`nick_name`,`mission_name`) USING BTREE`
- `KEY `time_index` (`update_time`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `bigint` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_id` | `bigint` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `nick_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `mission_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `level` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `match_win` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `match_max` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `received_reward_level` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `create_time` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `update_time` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `user_mission_xu`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `id_UNIQUE` (`id`) USING BTREE`
- `KEY `nick_name` (`nick_name`) USING BTREE`
- `KEY `mission_name` (`mission_name`) USING BTREE`
- `KEY `nick_name_mission_name` (`nick_name`,`mission_name`) USING BTREE`
- `KEY `update_time` (`update_time`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `bigint` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_id` | `bigint` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `nick_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `mission_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `level` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `match_win` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `match_max` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `received_reward_level` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `create_time` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `update_time` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `user_telegram_otp`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`tele_phone_number`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `tele_phone_number` | `varchar(15)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `tele_chat_id` | `varchar(15)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `nick_name` | `varchar(30)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `otp` | `varchar(8)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL` | IDENTIFIER | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |
| `time` | `bigint` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `users`
**Vai trò:** Core user wallet/profile; bảng số dư chính.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `id_UNIQUE` (`id`) USING BTREE`
- `UNIQUE KEY `nick_name_UNIQUE` (`nick_name`) USING BTREE`
- `UNIQUE KEY `facebook_id_UNIQUE` (`facebook_id`) USING BTREE`
- `UNIQUE KEY `google_id_UNIQUE` (`google_id`) USING BTREE`
- `KEY `nickname_index` (`nick_name`) USING BTREE`
- `KEY `facebook_index` (`facebook_id`) USING BTREE`
- `KEY `google_index` (`google_id`) USING BTREE`
- `KEY `is_bot_index` (`is_bot`) USING BTREE`
- `KEY `dai_ly_index` (`dai_ly`) USING BTREE`
- `KEY `mobile_index` (`mobile`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `bigint` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(128)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `nick_name` | `varchar(128)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `password` | `varchar(128)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |
| `email` | `varchar(128)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `google_id` | `varchar(128)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `facebook_id` | `varchar(128)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mobile` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `identification` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | IDENTIFIER | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `avatar` | `varchar(500)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `birthday` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `gender` | `bit(1)` | `DEFAULT b'1'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `address` | `varchar(128)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `vin` | `bigint` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Số dư/giá trị tiền hoặc điểm trong ví/tài khoản; field rủi ro cao. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `xu` | `bigint` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Số dư/giá trị tiền hoặc điểm trong ví/tài khoản; field rủi ro cao. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `vin_total` | `bigint` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `xu_total` | `bigint(20) unsigned zerofill` | `NOT NULL DEFAULT '00000000000000000000'` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `safe` | `bigint` | `DEFAULT '0' COMMENT 'két sắt'` | DATA | Số dư/giá trị tiền hoặc điểm trong ví/tài khoản; field rủi ro cao. |  |
| `recharge_money` | `bigint` | `DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `vip_point` | `int` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `vip_point_save` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `money_vp` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `dai_ly` | `int` | `NOT NULL DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. |  |
| `status` | `int` | `NOT NULL DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `create_time` | `timestamp` | `NOT NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `security_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `login_otp` | `bigint` | `DEFAULT '-1'` | IDENTIFIER | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |
| `is_bot` | `int` | `NOT NULL DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. |  |
| `update_pw_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `parent_id` | `bigint` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `pin` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `level` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `currency` | `varchar(10)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `country` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `last_recharge_time` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `agent_code` | `varchar(10)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `total_level_1` | `int` | `DEFAULT '0'` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `total_level_2` | `int` | `DEFAULT '0'` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `money_affiliate` | `int` | `DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `total_bet` | `bigint` | `DEFAULT '0'` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `is_idol` | `int` | `DEFAULT '0'` | ENUM/STATUS, IDENTIFIER | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. |  |
| `user_tevi_id` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `users_in_game`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_id` | `bigint` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `game_id` | `int` | `DEFAULT NULL` | ENUM/STATUS, IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `num_total` | `int` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `num_win` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `num_loss` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `exp` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `users_vp_event`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`user_id`) USING BTREE`
- `UNIQUE KEY `nick_name_UNIQUE` (`nick_name`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `user_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `vp_real` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `vp_event` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `vp_add` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `num_add` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `vp_sub` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `num_sub` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `place` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `place_max` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `is_bot` | `int` | `NOT NULL DEFAULT '-1'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. |  |
| `update_time` | `timestamp` | `NOT NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `utm_campain`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `name_display` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `utm_medium`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `name_display` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `utm_source`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `name_display` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `videos`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `title` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `description` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `stream_url` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `thumnail` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `order` | `int` | `DEFAULT '0'` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `create_date` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `status` | `bit(1)` | `DEFAULT b'0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `weekly_mission`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `mission_type` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `complete` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `status` | `smallint` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `update_time` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `user_name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |

### `withdraw`
**Vai trò:** Rút tiền tổng hợp.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_id` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `amount` | `int` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `bank_code` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `bank_account` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `account_name` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `transaction_code` | `varchar(20)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS, IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `order_no` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `message` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `create_time` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `admin_approve` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. |  |
| `approve_time` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `status` | `tinyint` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `type` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `updated_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `previous_balance` | `int` | `DEFAULT NULL` | MONEY/RISK | Số dư/giá trị tiền hoặc điểm trong ví/tài khoản; field rủi ro cao. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `balance_fluctuation` | `int` | `DEFAULT NULL` | MONEY/RISK | Số dư/giá trị tiền hoặc điểm trong ví/tài khoản; field rủi ro cao. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `phone_number` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `partner` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `address_wallet` | `varchar(500)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `network` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `txId` | `varchar(500)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `momoTransId` | `varchar(250)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

## 7.x. Database `vinplay_admin`
### `access_link`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`ID`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `ID` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `User_ID` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `Group_ID` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `Menu_ID` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `Link` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `action_admin`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `action` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `groupuser`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`Id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `Id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `Name` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `Description` | `varchar(150)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `Type` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `log_admin`
**Vai trò:** Log thao tác admin.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `username_index` (`username`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `action` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `quantity` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `money` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `account_name` | `text` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `money_type` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | MONEY/RISK, ENUM/STATUS | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `username` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `timestamp` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `reason` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `status` | `varchar(11)` | `CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `log_loginadmin`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `nickname_index` (`nickname`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `username` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `nickname` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `ip` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `status` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `agent` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `action` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `tool` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `createdate` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `menu`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `Name_index` (`Name`) USING BTREE`
- `KEY `Param_index` (`Param`) USING BTREE`
- `KEY `Link_index` (`Link`) USING BTREE`
- `KEY `Status_index` (`Status`) USING BTREE`
- `KEY `Parrent_ID_index` (`Parrent_ID`) USING BTREE`
- `KEY `isThuong_index` (`isThuong`) USING BTREE`
- `KEY `isDaily_index` (`isDaily`) USING BTREE`
- `KEY `isSuper_index` (`isSuper`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `Name` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `Param` | `int` | `DEFAULT '1'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `Link` | `varchar(150)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `Status` | `char(1)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `Parrent_ID` | `int` | `DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `isThuong` | `int` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `isDaily` | `int` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `isSuper` | `int` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `price_giftcode`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `price` | `int` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `money_type` | `int` | `DEFAULT NULL` | MONEY/RISK, ENUM/STATUS | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `request_withdraw`
**Vai trò:** Yêu cầu rút trong admin/backoffice.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(20)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `bank` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `bank_account_name` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `bank_account_number` | `varchar(255)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `amount` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `create_date` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `rolemenu`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`ID`) USING BTREE`
- `KEY `Group_ID_index` (`Group_ID`) USING BTREE`
- `KEY `Menu_ID_index` (`Menu_ID`) USING BTREE`
- `KEY `Type_index` (`Type`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `Group_ID` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `Menu_ID` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `ID` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `Type` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `source_giftcode`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `name` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `key` | `varchar(11)` | `CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `type` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `display` | `int` | `DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. |  |

### `url_builder`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `url_web` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `utm_source` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `utm_medium` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `utm_term` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `utm_content` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `utm_campaign` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `url_generate` | `varchar(2000)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `user`
**Vai trò:** Tài khoản admin.

**Key/Index:**
- `PRIMARY KEY (`ID`) USING BTREE`
- `KEY `UserName_index` (`UserName`) USING BTREE`
- `KEY `FullName_index` (`FullName`) USING BTREE`
- `KEY `Status_index` (`Status`) USING BTREE`
- `KEY `isThuong_index` (`isThuong`) USING BTREE`
- `KEY `isSuper_index` (`isSuper`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `ID` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `UserName` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `Password` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |
| `NameAgent` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `FullName` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `Email` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `Address` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `BirthDay` | `date` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `CMND` | `int` | `DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `Phone` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `Status` | `char(2)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `ParentID` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `Active` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `isThuong` | `int` | `DEFAULT '2'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `isSuper` | `int` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `Facebook` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `Key` | `varchar(11)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `Balance` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Số dư/giá trị tiền hoặc điểm trong ví/tài khoản; field rủi ro cao. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |

### `useragent`
**Vai trò:** Tài khoản đại lý/agent admin.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `nickname_index` (`nickname`) USING BTREE`
- `KEY `status_index` (`status`) USING BTREE`
- `KEY `parentid_index` (`parentid`) USING BTREE`
- `KEY `show_index` (`show`) USING BTREE`
- `KEY `active_index` (`active`) USING BTREE`
- `KEY `sms_index` (`sms`) USING BTREE`
- `KEY `order_index` (`order`) USING BTREE`
- `KEY `percent_bonus_vincard` (`percent_bonus_vincard`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `username` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `nickname` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `password` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Thông tin bảo mật/credential; cần hash/mã hóa/ẩn log. | Không log/plaintext; cần hash hoặc mã hóa tùy loại credential. |
| `nameagent` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `address` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `phone` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `email` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `facebook` | `varchar(255)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `key` | `varchar(10)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `status` | `varchar(2)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `parentid` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `namebank` | `varchar(255)` | `CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `nameaccount` | `varchar(255)` | `CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `numberaccount` | `varchar(255)` | `CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL` | DATA | Thông tin cá nhân/thanh toán; cần bảo vệ dữ liệu và hạn chế log thô. |  |
| `show` | `int` | `DEFAULT '1'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. |  |
| `active` | `int` | `DEFAULT '1'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `createtime` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `updatetime` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `order` | `int` | `DEFAULT '1'` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `sms` | `int` | `DEFAULT '-1'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `percent_bonus_vincard` | `int` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `parent` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `balance` | `bigint` | `DEFAULT '0'` | MONEY/RISK | Số dư/giá trị tiền hoặc điểm trong ví/tài khoản; field rủi ro cao. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |

### `userrole`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`ID`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `ID` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `User_ID` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `Group_ID` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `Type` | `int` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

## 7.x. Database `vinplay_minigame`
### `game_result`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `game` | `int` | `DEFAULT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `result` | `varchar(20)` | `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `create_date` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `referenceId` | `int` | `DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |

### `hu_game_bai`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `pot_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `value` | `bigint` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `key_value`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`key`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `key` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `value` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `updated_at` | `date` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `lucky_rotation`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `nickname_UNIQUE` (`nick_name`) USING BTREE`
- `UNIQUE KEY `user_id_UNIQUE` (`user_id`) USING BTREE`
- `KEY `user_id_index` (`user_id`) USING BTREE`
- `KEY `nickname_index` (`nick_name`) USING BTREE`
- `KEY `login_date_index` (`login_date`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `rotate_daily` | `int` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `rotate_free` | `int` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `rotate_in_day` | `int` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `login_date` | `date` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `rotate_time` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `lucky_rotation_ip_block`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `ip_address_UNIQUE` (`ip_address`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `ip_address` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `rotate_win_in_day` | `int` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `rotate_date` | `date` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `minigame_funds`
**Vai trò:** Quỹ mini game.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `fund_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `value` | `bigint` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `minigame_pots`
**Vai trò:** Hũ/pot mini game.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `pot_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `value` | `bigint` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `references`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `game_id` | `int` | `DEFAULT NULL` | ENUM/STATUS, IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `value` | `bigint` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |

### `result_tai_xiu`
**Vai trò:** Kết quả phiên Tài Xỉu.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `reference_index` (`reference_id`) USING BTREE`
- `KEY `money_type_index` (`money_type`) USING BTREE`
- `KEY `timestamp_index` (`timestamp`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `reference_id` | `bigint` | `DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `result` | `tinyint` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `dice1` | `tinyint` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `dice2` | `tinyint` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `dice3` | `tinyint` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `total_tai` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_xiu` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `num_bet_tai` | `int` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `num_bet_xiu` | `int` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `total_prize` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_refund_tai` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_refund_xiu` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_revenue` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `money_type` | `tinyint` | `DEFAULT NULL` | MONEY/RISK, ENUM/STATUS | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `timestamp` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `rotate_slot_free`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`user_id`,`nick_name`,`game_name`,`room`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `user_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `game_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `room` | `int` | `NOT NULL DEFAULT '100'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `rotate_free` | `int` | `DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `max_winning` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `update_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `thanh_du`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `username_index` (`user_name`) USING BTREE`
- `KEY `type_index` (`type`) USING BTREE`
- `KEY `last_update_index` (`last_update`) USING BTREE`
- `KEY `update_index` (`user_name`,`last_update`,`type`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `number` | `int` | `DEFAULT '1'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `total_betting` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `last_reference` | `bigint` | `DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `references` | `varchar(512)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `last_update` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `type` | `tinyint` | `DEFAULT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |

### `transaction_detail_tai_xiu`
**Vai trò:** Chi tiết giao dịch Tài Xỉu.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `reference_index` (`reference_id`) USING BTREE`
- `KEY `timestampt_index` (`timestamp`) USING BTREE`
- `KEY `user_name_index` (`user_name`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `reference_id` | `bigint` | `DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `transaction_code` | `varchar(120)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | ENUM/STATUS, IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `user_id` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `bet_value` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `bet_side` | `tinyint` | `DEFAULT NULL` | MONEY/RISK, ENUM/STATUS, IDENTIFIER | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `prize` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `refund` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `input_time` | `int` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `money_type` | `tinyint` | `DEFAULT NULL` | MONEY/RISK, ENUM/STATUS | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `timestamp` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `transaction_tai_xiu`
**Vai trò:** Giao dịch Tài Xỉu tổng.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `reference_index` (`reference_id`) USING BTREE`
- `KEY `user_name_index` (`user_name`) USING BTREE`
- `KEY `timestamp_index` (`timestamp`) USING BTREE`
- `KEY `money_type_index` (`money_type`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `reference_id` | `bigint` | `DEFAULT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `user_id` | `int` | `DEFAULT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `bet_value` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `bet_side` | `tinyint` | `DEFAULT NULL` | MONEY/RISK, ENUM/STATUS, IDENTIFIER | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `total_prize` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_refund` | `bigint` | `DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `total_exchange` | `bigint` | `DEFAULT '0'` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `money_type` | `tinyint` | `DEFAULT NULL` | MONEY/RISK, ENUM/STATUS | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `timestamp` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `user_rut_loc`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `user_name_UNIQUE` (`user_name`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `user_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Tên tài khoản/username, dùng cho đăng nhập hoặc truy vết giao dịch. |  |
| `so_lan_rut` | `int` | `DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `last_update` | `timestamp` | `NULL DEFAULT CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

## 7.x. Database `vinplay_gamebai`
### `game_data`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `key` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `value` | `varchar(1000)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `create_time` | `timestamp` | `NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `update_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `game_free_code_detail`
**Vai trò:** Mã free code chi tiết.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `code_UNIQUE` (`code`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `bigint` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `code` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `package_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `game_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `type` | `int` | `NOT NULL DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `amount` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `status` | `int` | `NOT NULL DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `expire` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `create_time` | `timestamp` | `NOT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `nick_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `add_info` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `use_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `game_free_code_package`
**Vai trò:** Gói tạo free code.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `bigint` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `game_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `type` | `int` | `NOT NULL DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `quantity` | `int` | `NOT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `amount` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `expire` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `create_time` | `timestamp` | `NOT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `creater` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | DATA | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `game_tour_info`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`key`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `key` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `value` | `varchar(1000)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `create_time` | `timestamp` | `NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `update_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `game_tour_jackpot`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`key`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `key` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `value` | `bigint` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `create_time` | `timestamp` | `NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `game_tour_mark`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`nick_name`,`game_name`,`tour_id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `nick_name` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `game_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `tour_id` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `fee` | `int` | `NOT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `start_time` | `timestamp` | `NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `mark` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `top` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `user_total` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `status` | `int` | `NOT NULL DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `prize` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Kiểu dữ liệu tiền chưa an toàn/khó đối soát; nên chuẩn hóa BIGINT/DECIMAL. |
| `create_time` | `timestamp` | `NOT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `update_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `game_tour_vip`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`nick_name`,`vip_tour_id`,`game_name`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `nick_name` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `game_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | ENUM/STATUS | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `vip_tour_id` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | IDENTIFIER | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `value` | `varchar(1000)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `create_time` | `timestamp` | `NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `update_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |

### `poker_free_ticket`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `ticket` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `tour_type` | `int` | `NOT NULL DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `used` | `bit(1)` | `NOT NULL DEFAULT b'0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. |  |
| `create_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `available_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `limit_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `use_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `create_type` | `int` | `NOT NULL` | ENUM/STATUS | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `add_info` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `is_bot` | `bit(1)` | `NOT NULL DEFAULT b'0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. |  |
| `tour_id` | `int` | `NOT NULL DEFAULT '0'` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |

### `poker_tour`
**Vai trò:** Cấu hình poker tournament.

**Key/Index:**
- `PRIMARY KEY (`id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `id` | `int` | `NOT NULL AUTO_INCREMENT` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `start_time_schedule` | `timestamp` | `NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `end_register_schedule` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `tour_state` | `int` | `NOT NULL DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `tour_type` | `int` | `NOT NULL DEFAULT '0'` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `start_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `end_register_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `cancel_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `end_time` | `timestamp` | `NULL DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `level` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `ticket` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `count_time_up_level` | `int` | `NOT NULL DEFAULT '0'` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `fund` | `bigint` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |

### `poker_tour_user`
**Vai trò:** User trong poker tournament.

**Key/Index:**
- `PRIMARY KEY (`tour_id`,`nick_name`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `tour_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `nick_name` | `varchar(50)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `current_chip` | `bigint` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `ticket_count` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `out_tour_count` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `out_tour_time` | `bigint` | `NOT NULL DEFAULT '0'` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `last_chip` | `bigint` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `rank` | `int` | `NOT NULL DEFAULT '0'` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `mark` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Dữ liệu nghiệp vụ/phụ trợ của bảng. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `prize` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |

### `xoc_dia_boss`
**Vai trò:** Bảng nghiệp vụ/phụ trợ; xem field chi tiết và source backend để xác định flow đang dùng thật.

**Key/Index:**
- `PRIMARY KEY (`session_id`) USING BTREE`

| Field | Type | Attrs | Nhóm | Ý nghĩa nghiệp vụ | Ghi chú rủi ro |
|---|---|---|---|---|---|
| `session_id` | `varchar(100)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | IDENTIFIER | Mã tham chiếu giao dịch/phiên/request; nên dùng làm idempotency hoặc đối soát. | Nên có unique/index nếu dùng chống xử lý trùng. |
| `nick_name` | `varchar(45)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL` | DATA | Nickname của user/player, thường dùng để hiển thị và join logic với `users.nick_name`. |  |
| `room_id` | `int` | `NOT NULL` | IDENTIFIER | ID/tham chiếu định danh, dùng để liên kết logic giữa các bảng. |  |
| `room_setting` | `varchar(1000)` | `CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL` | DATA | Dữ liệu nghiệp vụ/phụ trợ của bảng. |  |
| `fund_initial` | `bigint` | `NOT NULL` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |
| `status` | `int` | `NOT NULL` | ENUM/STATUS | Trạng thái/loại nghiệp vụ; cần map enum từ source backend trước khi sửa logic. | Không tự đoán giá trị enum khi code; cần grep source để map số → ý nghĩa. |
| `create_time` | `datetime` | `NOT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `update_time` | `datetime` | `DEFAULT NULL` | TIME | Mốc thời gian dùng để audit, lọc báo cáo hoặc xác định vòng đời giao dịch. |  |
| `fee` | `int` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. Nếu là tiền thật nên kiểm tra overflow và đồng bộ với BIGINT của `users.vin/xu`. |
| `revenue` | `bigint` | `NOT NULL DEFAULT '0'` | MONEY/RISK | Giá trị tiền/điểm/cược/thưởng/quỹ; cần xử lý bằng transaction, lock và đối soát. | Không update ngoài transaction; cần balance_before/after hoặc ledger. |

---
## 8. Việc cần làm tiếp theo để biến V2 thành tài liệu production-level

1. Grep source backend để map chính xác toàn bộ enum/status/type/action.
2. Xác định bảng nào đang dùng thật, bảng nào là legacy/copy/backup.
3. Xác định transaction boundary: cùng connection hay cross-database/cross-service.
4. Thiết kế hoặc bổ sung `wallet_ledger` chuẩn cho mọi thay đổi số dư.
5. Thêm unique key/idempotency cho callback nạp/rút/bet/redeem nếu source chưa xử lý.
6. Viết migration chuẩn hóa kiểu tiền từ varchar/int không phù hợp sang BIGINT/DECIMAL nếu nghiệp vụ cho phép.
7. Tạo script reconcile: `users` ↔ topup/withdraw/game transaction/report/freeze.