Dựa trên 4 file schema bạn gửi, hệ thống đang có **4 database chính**:

| Database           | Số bảng | Vai trò chính                                                                   |
| ------------------ | ------: | ------------------------------------------------------------------------------- |
| `vinplay`          | 59 bảng | Database lõi: user, ví tiền, nạp/rút, game config, log game, nhiệm vụ, operator |
| `vinplay_admin`    | 14 bảng | Admin CMS: tài khoản admin/đại lý, phân quyền menu, log thao tác, request rút   |
| `vinplay_minigame` | 14 bảng | Mini game: Tài Xỉu, pot/quỹ mini game, vòng quay, kết quả game                  |
| `vinplay_gamebai`  | 11 bảng | Game bài/tournament: poker tour, jackpot tournament, free code, xóc đĩa boss    |

---

# 1. Tổng quan kiến trúc database

## 1.1. `vinplay` là database quan trọng nhất

Đây là **core database** của toàn hệ thống.

Nó chứa:

| Nhóm                      | Bảng chính                                                                                        |
| ------------------------- | ------------------------------------------------------------------------------------------------- |
| User / ví                 | `users`, `freeze_money`, `money_system`                                                           |
| Nạp tiền                  | `topup`, `topup_bank`, `topup_momo`, `topup_vtpay`, `topup_zalopay`                               |
| Rút tiền                  | `withdraw`, `system_cashout`                                                                      |
| Game config               | `games`, `game_config`, `game_config_xx`                                                          |
| Log game                  | `log_game_result`, `log_game_round`, `log_game_reference`, `log_game_thau_vi`                     |
| Đại lý / agent            | `agent`, `dealer`, `log_tranfer_agent`                                                            |
| Mission / level           | `mission`, `daily_mission`, `weekly_mission`, `user_mission_vin`, `user_mission_xu`, `user_level` |
| OTP / bảo mật             | `user_appotp`, `user_telegram_otp`                                                                |
| Operator / multi-operator | `operators`, `operator_api_keys`, `operator_database_config`, `operator_audit_log`                |

**Kết luận:**
Nếu backend xử lý tiền, user, nạp/rút, log game thì gần như chắc chắn phải đụng tới `vinplay`.

---

# 2. Phân tích database `vinplay`

## 2.1. Bảng `users` — bảng user và ví tiền chính

Đây là bảng cực kỳ quan trọng.

Các trường đáng chú ý:

```sql
id
user_name
nick_name
password
mobile
identification
vin
xu
vin_total
xu_total
safe
recharge_money
vip_point
money_vp
dai_ly
status
is_bot
parent_id
currency
total_bet
```

### Ý nghĩa nghiệp vụ

| Trường           | Ý nghĩa                            |
| ---------------- | ---------------------------------- |
| `vin`            | Số dư tiền chính loại VIN          |
| `xu`             | Số dư tiền loại XU                 |
| `vin_total`      | Tổng VIN tích lũy                  |
| `xu_total`       | Tổng XU tích lũy                   |
| `safe`           | Tiền trong két/safe                |
| `recharge_money` | Tổng tiền đã nạp                   |
| `vip_point`      | Điểm VIP                           |
| `money_vp`       | Có thể liên quan điểm/tiền sự kiện |
| `dai_ly`         | Cờ xác định đại lý                 |
| `is_bot`         | Cờ bot                             |
| `total_bet`      | Tổng tiền cược                     |

### Nhận xét kỹ thuật

`users` là **source of truth của số dư user**.

Khi user chơi game, nạp tiền, rút tiền, thưởng, hoàn tiền, backend thường sẽ phải cập nhật các trường như:

```sql
users.vin
users.xu
users.safe
users.recharge_money
users.total_bet
```

### Rủi ro lớn

Bảng này không thấy cơ chế ledger rõ ràng trong schema. Nếu chỉ update trực tiếp:

```sql
UPDATE users SET vin = vin - amount WHERE id = ?
```

mà không có transaction, lock, idempotency, log đối soát thì rất dễ lỗi:

| Rủi ro                                           | Mức độ           |
| ------------------------------------------------ | ---------------- |
| Trừ tiền 2 lần                                   | Rất nghiêm trọng |
| Cộng tiền 2 lần                                  | Rất nghiêm trọng |
| Race condition khi user spam bet/rút/nạp         | Rất nghiêm trọng |
| Số dư âm                                         | Rất nghiêm trọng |
| Lệch giữa `users.vin` và log game/topup/withdraw | Rất nghiêm trọng |

---

## 2.2. Bảng `freeze_money` — tiền bị đóng băng

Các trường chính:

```sql
session_id
user_id
nick_name
game_name
room_id
money
money_type
status
create_time
update_time
```

### Ý nghĩa nghiệp vụ

Bảng này dùng để **giữ tiền tạm thời** trong một phiên game/phòng game.

Ví dụ:

1. User vào bàn game.
2. Backend đóng băng một khoản tiền.
3. Khi game kết thúc:

   * Nếu thua: tiền bị trừ thật.
   * Nếu thắng: hoàn/cộng tiền.
   * Nếu lỗi phiên: cần rollback/unfreeze.

### Rủi ro

Đây là bảng cực kỳ quan trọng cho game realtime.

Cần kiểm tra kỹ:

| Case                                                    | Rủi ro                        |
| ------------------------------------------------------- | ----------------------------- |
| Game crash giữa chừng                                   | Tiền bị freeze mãi            |
| User disconnect                                         | Không clear freeze            |
| Xử lý kết quả 2 lần                                     | Vừa unfreeze vừa cộng/trừ sai |
| Không có unique theo `session_id + user_id + game_name` | Có thể freeze trùng           |
| Không có trạng thái chuẩn                               | Dễ lệch tiền                  |

Nên có trạng thái rõ:

```text
0 = FROZEN
1 = SETTLED
2 = REFUNDED
3 = EXPIRED
4 = ERROR
```

---

## 2.3. Bảng `money_system` — tiền hệ thống

Các trường:

```sql
id
name
money
update_time
create_time
```

### Ý nghĩa

Có vẻ dùng để lưu **quỹ hệ thống**, ví dụ:

* quỹ nhà cái
* quỹ jackpot
* quỹ khuyến mãi
* quỹ hoàn trả

### Rủi ro

Nếu game cộng/trừ tiền từ `money_system`, cần đảm bảo:

```text
user thắng => users.vin tăng, money_system.money giảm
user thua => users.vin giảm, money_system.money tăng
```

Nếu chỉ update user mà không update quỹ hệ thống, báo cáo tài chính sẽ lệch.

---

## 2.4. Nhóm bảng nạp tiền

Các bảng:

```sql
topup
topup_bank
topup_momo
topup_vtpay
topup_zalopay
```

### `topup`

Đây có vẻ là bảng nạp tổng.

Các trường chính:

```sql
user_id
user_name
amount
transaction_code
order_no
channel
code
card_serial
card_code
message
status
type
phone_number
account_name
account_number
bank_type
address_wallet
network
```

### Các bảng kênh riêng

| Bảng            | Khóa chính     | Ý nghĩa            |
| --------------- | -------------- | ------------------ |
| `topup_bank`    | `request_id`   | Nạp qua bank       |
| `topup_momo`    | `momo_transId` | Nạp qua Momo       |
| `topup_vtpay`   | `vtp_transId`  | Nạp qua ViettelPay |
| `topup_zalopay` | `request_id`   | Nạp qua ZaloPay    |

### Nhận xét quan trọng

Có 2 tầng dữ liệu:

```text
topup = bảng tổng
topup_bank / momo / vtpay / zalopay = bảng theo kênh
```

Flow hợp lý nên là:

```text
Callback từ cổng thanh toán
        ↓
Ghi bảng kênh tương ứng
        ↓
Ghi hoặc update bảng topup
        ↓
Cộng tiền vào users.vin
        ↓
Ghi log đối soát
```

### Rủi ro nghiêm trọng

Một số bảng đang để `amount`, `money`, `money_user` là `varchar`.

Ví dụ:

```sql
topup_bank.amount varchar(45)
topup_momo.money varchar(20)
topup_vtpay.money varchar(45)
topup_zalopay.amount varchar(45)
```

Đây là điểm rủi ro.

Tiền nên dùng:

```sql
BIGINT
DECIMAL(20,2)
```

Không nên dùng `varchar`, vì dễ gặp lỗi:

| Lỗi                       | Ví dụ                                          |
| ------------------------- | ---------------------------------------------- |
| So sánh sai               | `'10000' > '900'` theo string có thể sai logic |
| Convert lỗi               | `"10,000"`                                     |
| Dữ liệu bẩn               | `"10000 VND"`                                  |
| Không index/tính tổng tốt | SUM phải cast                                  |
| Dễ sai khi đối soát       | Khó chuẩn hóa                                  |

---

## 2.5. Bảng `withdraw` — rút tiền chính

Các trường chính:

```sql
user_id
user_name
amount
bank_code
bank_account
account_name
transaction_code
order_no
message
admin_approve
approve_time
status
type
previous_balance
balance_fluctuation
phone_number
partner
address_wallet
network
txId
momoTransId
```

### Ý nghĩa nghiệp vụ

Đây là bảng xử lý **lệnh rút tiền**.

Flow đúng nên là:

```text
User tạo yêu cầu rút
        ↓
Kiểm tra số dư
        ↓
Đóng băng hoặc trừ tiền tạm
        ↓
Tạo record withdraw status = PENDING
        ↓
Admin/partner xử lý
        ↓
Nếu success: confirm trừ tiền
Nếu failed: hoàn tiền
```

### Vấn đề nghiêm trọng

`withdraw.amount` đang là `int`.

```sql
amount int
previous_balance int
balance_fluctuation int
```

Trong khi `users.vin` là `bigint`.

Điều này không đồng nhất.

Nếu số tiền lớn, `int` có thể không đủ hoặc gây lệch kiểu dữ liệu.

Nên đổi các trường tiền sang:

```sql
BIGINT
```

### Cần có idempotency

Trong bảng `withdraw`, chưa thấy unique key cho:

```text
order_no
transaction_code
txId
momoTransId
```

Nếu callback từ partner gửi lại nhiều lần, có thể bị xử lý trùng.

Nên có unique/index:

```sql
UNIQUE(order_no)
UNIQUE(transaction_code)
UNIQUE(txId)
```

tùy flow thực tế.

---

## 2.6. Nhóm log game trong `vinplay`

Các bảng:

```sql
log_game_result
log_game_round
log_game_reference
log_game_thau_vi
```

### Vai trò

Đây là nhóm log để ghi:

* kết quả ván game
* vòng chơi
* reference giao dịch
* thông tin thắng/thua
* lịch sử đối soát

### Nhận xét

Đây là nhóm bảng cực kỳ quan trọng để QA/backend kiểm tra:

```text
User bị trừ bao nhiêu?
User thắng bao nhiêu?
Game round nào?
Session nào?
Có log reference không?
Có lệch với users.vin không?
```

### Rủi ro

Nếu log game không có quan hệ chặt với transaction tiền thì khi lỗi rất khó truy vết.

Nên có chuẩn:

```text
request_id / round_id / session_id / reference_id
user_id
nick_name
game_name
bet_amount
win_amount
before_balance
after_balance
money_type
created_time
status
```

---

# 3. Phân tích database `vinplay_minigame`

Database này chuyên cho mini game, đặc biệt thấy rõ nhóm **Tài Xỉu**.

Các bảng chính:

| Nhóm              | Bảng                                                |
| ----------------- | --------------------------------------------------- |
| Kết quả game      | `game_result`, `result_tai_xiu`                     |
| Giao dịch Tài Xỉu | `transaction_tai_xiu`, `transaction_detail_tai_xiu` |
| Pot/quỹ           | `minigame_pots`, `minigame_funds`                   |
| Jackpot/game bài  | `hu_game_bai`                                       |
| Vòng quay         | `lucky_rotation`, `rotate_slot_free`                |
| Config            | `key_value`, `references`                           |
| User event        | `user_rut_loc`, `thanh_du`                          |

---

## 3.1. `transaction_tai_xiu`

Đây là bảng giao dịch tổng của Tài Xỉu.

Có thể dùng để lưu:

```text
phiên Tài Xỉu
user
cửa đặt
số tiền đặt
kết quả thắng/thua
tiền nhận
trạng thái
```

### Vai trò

Đây là bảng rất quan trọng để đối soát mini game:

```text
users.vin/xu trong vinplay
        ↕
transaction_tai_xiu trong vinplay_minigame
```

### Rủi ro

Vì `users` nằm ở database `vinplay`, còn transaction Tài Xỉu nằm ở `vinplay_minigame`, khi xử lý tiền sẽ là **cross-database transaction**.

Nếu cùng một MySQL instance thì còn có thể dùng transaction chung. Nhưng nếu app tách connection hoặc xử lý không atomic thì có thể xảy ra:

```text
Đã ghi transaction_tai_xiu nhưng chưa trừ users.vin
Đã trừ users.vin nhưng chưa ghi transaction_tai_xiu
Đã trả thưởng nhưng log chưa update
```

Đây là nhóm lỗi nghiêm trọng nhất.

---

## 3.2. `transaction_detail_tai_xiu`

Bảng chi tiết giao dịch Tài Xỉu.

Có thể dùng để ghi chi tiết từng cửa cược hoặc từng bước xử lý.

Flow có thể là:

```text
transaction_tai_xiu = header
transaction_detail_tai_xiu = detail
```

Ví dụ:

```text
Phiên 1001
User A đặt Tài 10,000
User A đặt Chẵn 5,000
User B đặt Xỉu 20,000
```

### Rủi ro

Nếu bảng detail cho phép nhiều dòng trên cùng user/session/bet type nhưng không có unique constraint thì có thể bị ghi trùng khi user spam request.

Nên có key logic kiểu:

```text
session_id + user_id + bet_side + request_id
```

---

## 3.3. `result_tai_xiu`

Bảng kết quả Tài Xỉu.

Vai trò:

```text
Lưu kết quả từng phiên
Tài hay Xỉu
Bộ xúc xắc
Tổng điểm
Thời gian kết thúc
```

### Rủi ro

Khi trả thưởng, backend phải đảm bảo:

```text
Chỉ settle khi result_tai_xiu đã final
Mỗi transaction chỉ settle đúng 1 lần
Không settle lại khi service restart
```

Cần có trạng thái:

```text
OPEN
CLOSED
RESULTED
SETTLED
CANCELLED
```

---

## 3.4. `minigame_pots`

Bảng pot của mini game.

Dùng cho:

```text
hũ
jackpot
pot thưởng
quỹ tích lũy
```

### Rủi ro lớn

Pot thường bị update liên tục khi user cược.

Nếu không lock chuẩn, dễ xảy ra:

```text
Lost update
Sai số hũ
Nổ hũ 2 lần
Cộng jackpot 2 lần
```

Nên update dạng atomic:

```sql
UPDATE minigame_pots
SET value = value + ?
WHERE game_name = ? AND room_id = ?;
```

Với nổ hũ nên dùng điều kiện trạng thái:

```sql
UPDATE minigame_pots
SET value = new_value, status = 'LOCKED'
WHERE pot_id = ? AND status = 'ACTIVE';
```

---

## 3.5. `minigame_funds`

Bảng quỹ mini game.

Khác với pot, fund thường là quỹ tổng của game.

Cần phân biệt:

| Loại   | Ý nghĩa                               |
| ------ | ------------------------------------- |
| `pot`  | Hũ tích lũy trả jackpot               |
| `fund` | Quỹ vận hành/trả thưởng của mini game |

Nếu game thắng/thua liên quan fund, cần đối soát:

```text
Tổng user bet
- Tổng user win
- Fee
= Chênh lệch fund/pot
```

---

# 4. Phân tích database `vinplay_gamebai`

Database này phục vụ nhóm game bài, tournament, poker, free code.

Các bảng chính:

| Bảng                     | Vai trò                   |
| ------------------------ | ------------------------- |
| `game_data`              | Config key-value game bài |
| `game_tour_info`         | Config tournament         |
| `game_tour_jackpot`      | Jackpot tournament        |
| `game_tour_mark`         | Điểm/rank tournament      |
| `game_tour_vip`          | VIP tournament            |
| `poker_tour`             | Thông tin tour poker      |
| `poker_tour_user`        | User tham gia tour        |
| `xoc_dia_boss`           | Bàn/phòng xóc đĩa boss    |
| `game_free_code_package` | Gói free code             |
| `game_free_code_detail`  | Mã code chi tiết          |

---

## 4.1. `game_tour_jackpot`

Các trường:

```sql
key
value
create_time
```

### Ý nghĩa

Bảng lưu jackpot theo dạng key-value.

Ví dụ:

```text
poker_jackpot_room_1 = 10000000
```

### Nhận xét

Cấu trúc key-value linh hoạt nhưng rủi ro khi scale:

| Vấn đề                         | Tác động                |
| ------------------------------ | ----------------------- |
| Không có cột `game_name` riêng | Khó query/report        |
| Không có `room_id` riêng       | Khó index               |
| Không có trạng thái            | Khó lock khi nổ jackpot |
| Không có lịch sử thay đổi      | Khó đối soát            |

---

## 4.2. `poker_tour`

Các trường đáng chú ý:

```sql
id
start_time_schedule
end_register_schedule
tour_state
tour_type
start_time
end_register_time
cancel_time
end_time
level
ticket
count_time_up_level
fund
```

### Ý nghĩa

Bảng cấu hình giải poker/tournament.

`fund` là quỹ giải.

### Rủi ro

`fund` liên quan tiền/thưởng nên cần:

```text
Khi user đăng ký: trừ vé/tiền
Khi user out: cập nhật rank/chip
Khi kết thúc: chia thưởng
```

Cần đảm bảo không trả thưởng tournament 2 lần.

---

## 4.3. `poker_tour_user`

Primary key:

```sql
PRIMARY KEY (tour_id, nick_name)
```

Các trường:

```sql
tour_id
nick_name
current_chip
ticket_count
out_tour_count
out_tour_time
last_chip
rank
mark
prize
```

### Ý nghĩa

Lưu trạng thái user trong tournament.

### Nhận xét tốt

Bảng này có primary key kép:

```text
tour_id + nick_name
```

Điều này giúp tránh một user bị ghi trùng trong cùng một tour.

---

## 4.4. `game_free_code_detail`

Có unique key:

```sql
UNIQUE KEY code_UNIQUE (code)
```

### Nhận xét tốt

Free code có unique theo `code`, hợp lý.

Tuy nhiên khi user dùng code, cần xử lý atomic:

```sql
UPDATE game_free_code_detail
SET status = USED, nick_name = ?, use_time = NOW()
WHERE code = ? AND status = UNUSED;
```

Không nên:

```text
SELECT status trước
sau đó UPDATE
```

vì có thể bị double redeem khi user spam.

---

# 5. Phân tích database `vinplay_admin`

Database này dùng cho admin/backoffice.

Các bảng chính:

| Nhóm         | Bảng                                                       |
| ------------ | ---------------------------------------------------------- |
| Admin user   | `user`, `useragent`                                        |
| Phân quyền   | `groupuser`, `userrole`, `rolemenu`, `menu`, `access_link` |
| Log admin    | `log_admin`, `log_loginadmin`, `action_admin`              |
| Rút tiền     | `request_withdraw`                                         |
| Giftcode     | `price_giftcode`, `source_giftcode`                        |
| Tracking URL | `url_builder`                                              |

---

## 5.1. `user` trong `vinplay_admin`

Đây là bảng tài khoản admin.

Có các trường:

```sql
UserName
Password
NameAgent
FullName
Email
Phone
Status
ParentID
Active
isThuong
isSuper
Balance
```

### Cần chú ý

`Password` là `varchar(50)`.

Nếu đang lưu password dạng plain text hoặc hash yếu thì rất nguy hiểm.

Password hash hiện đại thường dài hơn, ví dụ bcrypt thường khoảng 60 ký tự.

Nên dùng:

```sql
password_hash varchar(255)
```

---

## 5.2. `useragent`

Bảng này có vẻ là tài khoản đại lý/agent trong admin.

Có các trường:

```sql
username
nickname
password
nameagent
phone
email
namebank
nameaccount
numberaccount
status
active
balance
percent_bonus_vincard
```

### Ý nghĩa

Đại lý có:

* thông tin đăng nhập
* thông tin ngân hàng
* balance
* phần trăm bonus
* trạng thái hoạt động

### Rủi ro

Có trường `balance` trong `vinplay_admin.useragent`, trong khi `users.vin` ở `vinplay` cũng là số dư.

Cần xác định rõ:

```text
useragent.balance là tiền đại lý?
users.vin là tiền người chơi?
agent/dealer trong vinplay có liên quan không?
```

Nếu nhiều bảng cùng lưu balance, rủi ro lệch tiền rất cao.

---

## 5.3. `request_withdraw`

Các trường:

```sql
nick_name
bank
bank_account_name
bank_account_number
amount
create_date
```

### Nhận xét

Bảng này cũng là request rút tiền, nhưng trong `vinplay` đã có bảng `withdraw`.

Vậy hệ thống đang có **2 nơi lưu rút tiền**:

```text
vinplay.withdraw
vinplay_admin.request_withdraw
```

### Đây là điểm cần làm rõ ngay

Có 2 khả năng:

## Khả năng 1: `request_withdraw` là bảng cũ

Nếu vậy nên ngừng dùng hoặc migrate.

## Khả năng 2: `request_withdraw` là request từ admin/manual

Nếu vậy phải map rõ:

```text
request_withdraw.id
        ↓
withdraw.order_no / transaction_code
```

Nếu không map, sẽ rất khó đối soát.

---

# 6. Những database liên quan trực tiếp tới tiền

Xếp theo mức độ quan trọng:

## 1. `vinplay`

Liên quan tiền trực tiếp nhất.

Các bảng:

```text
users
freeze_money
money_system
topup
topup_bank
topup_momo
topup_vtpay
topup_zalopay
withdraw
system_cashout
report_money_daily
log_tranfer_agent
```

Đây là database bắt buộc phải bảo vệ kỹ nhất.

---

## 2. `vinplay_minigame`

Liên quan tiền qua game mini.

Các bảng:

```text
transaction_tai_xiu
transaction_detail_tai_xiu
result_tai_xiu
minigame_pots
minigame_funds
game_result
hu_game_bai
```

Database này không nhất thiết giữ số dư chính, nhưng giữ transaction/bet/result. Nếu lệch với `vinplay.users`, sẽ không đối soát được.

---

## 3. `vinplay_gamebai`

Liên quan tiền qua tournament/jackpot/free code.

Các bảng:

```text
game_tour_jackpot
poker_tour
poker_tour_user
xoc_dia_boss
game_free_code_detail
game_free_code_package
```

---

## 4. `vinplay_admin`

Liên quan tiền qua admin/đại lý/rút tiền/manual action.

Các bảng:

```text
useragent
request_withdraw
log_admin
price_giftcode
source_giftcode
```

---

# 7. Vấn đề thiết kế lớn nhất trong toàn bộ schema

## 7.1. Không thấy foreign key rõ ràng

Phần lớn bảng không có foreign key thật sự.

Ví dụ:

```text
withdraw.user_id
topup.user_id
freeze_money.user_id
transaction_tai_xiu.user_id
```

nên tham chiếu tới:

```text
users.id
```

Nhưng schema không thể hiện FK rõ.

### Hệ quả

Database không tự bảo vệ được tính toàn vẹn.

Có thể xảy ra:

```text
withdraw.user_id không tồn tại trong users
topup.user_name sai nick_name
transaction có nick_name nhưng user đã bị xóa/đổi
```

---

## 7.2. Có quá nhiều bảng tiền nhưng thiếu ledger trung tâm

Hiện schema có nhiều nơi ghi tiền:

```text
users.vin
users.xu
users.safe
freeze_money.money
money_system.money
topup.amount
withdraw.amount
minigame_pots
minigame_funds
transaction_tai_xiu
poker_tour.fund
useragent.balance
```

Nhưng chưa thấy bảng kiểu:

```text
wallet_ledger
wallet_transaction
balance_change_log
```

Đây là thiếu sót rất lớn nếu hệ thống xử lý tiền thật.

Nên có bảng ledger trung tâm:

```sql
wallet_ledger
- id
- request_id
- user_id
- nick_name
- money_type
- action_type
- amount
- balance_before
- balance_after
- reference_type
- reference_id
- status
- created_at
```

Ví dụ action type:

```text
BET
WIN
REFUND
TOPUP
WITHDRAW
ADMIN_ADD
ADMIN_SUB
FREEZE
UNFREEZE
JACKPOT
MISSION_REWARD
```

---

## 7.3. Kiểu dữ liệu tiền không đồng nhất

Có bảng dùng `bigint`:

```text
users.vin
users.xu
freeze_money.money
money_system.money
```

Có bảng dùng `int`:

```text
withdraw.amount
topup.amount
```

Có bảng dùng `varchar`:

```text
topup_bank.amount
topup_momo.money
topup_vtpay.money
topup_zalopay.amount
```

### Đánh giá

Đây là lỗi thiết kế cần sửa.

Với tiền game, nên chuẩn hóa:

```sql
BIGINT NOT NULL DEFAULT 0
```

Không dùng `varchar` cho tiền.

---

## 7.4. Thiếu idempotency key ở nạp/rút/game transaction

Các thao tác cần chống xử lý trùng:

| Nghiệp vụ              | Cần idempotency |
| ---------------------- | --------------- |
| Nạp tiền callback      | Có              |
| Rút tiền callback      | Có              |
| Đặt cược               | Có              |
| Trả thưởng             | Có              |
| Dùng giftcode/freecode | Có              |
| Nhận nhiệm vụ          | Có              |
| Jackpot                | Có              |

Hiện một số bảng có primary key theo mã giao dịch như:

```text
momo_transId
vtp_transId
request_id
code
```

Nhưng bảng tổng `topup`, `withdraw`, transaction game chưa thấy đủ unique constraint cho flow chống trùng.

---

# 8. Flow database đề xuất cho các nghiệp vụ chính

## 8.1. Flow đặt cược game

```text
1. Backend nhận request bet
2. Check idempotency_key
3. SELECT users FOR UPDATE
4. Kiểm tra users.vin >= bet_amount
5. Trừ users.vin
6. Ghi wallet_ledger action = BET
7. Ghi transaction game / log_game_reference
8. Commit
```

Không nên xử lý kiểu:

```text
Trừ tiền ở vinplay
Ghi log ở minigame sau
```

mà không có transaction.

---

## 8.2. Flow trả thưởng

```text
1. Nhận kết quả game
2. Lock transaction game
3. Kiểm tra transaction chưa settle
4. SELECT users FOR UPDATE
5. Cộng tiền thắng
6. Update transaction status = SETTLED
7. Ghi wallet_ledger action = WIN
8. Commit
```

Cần tránh settle lại.

---

## 8.3. Flow nạp tiền

```text
1. Nhận callback từ cổng thanh toán
2. Check transaction_id/order_no đã xử lý chưa
3. Ghi bảng channel: topup_momo/topup_bank/...
4. Ghi bảng topup tổng
5. SELECT users FOR UPDATE
6. Cộng users.vin
7. Ghi wallet_ledger action = TOPUP
8. Commit
```

---

## 8.4. Flow rút tiền

```text
1. User tạo yêu cầu rút
2. Check số dư
3. SELECT users FOR UPDATE
4. Trừ hoặc freeze tiền
5. Tạo withdraw status = PENDING
6. Ghi wallet_ledger action = WITHDRAW_HOLD
7. Commit
```

Khi partner callback thành công:

```text
1. Check callback idempotency
2. Update withdraw status = SUCCESS
3. Ghi wallet_ledger action = WITHDRAW_SUCCESS
```

Khi thất bại:

```text
1. SELECT users FOR UPDATE
2. Hoàn tiền
3. Update withdraw status = FAILED
4. Ghi wallet_ledger action = WITHDRAW_REFUND
```

---

# 9. Bảng nào backend/frontend/QA cần quan tâm nhất?

## Backend cần quan tâm nhất

| Ưu tiên | Bảng                                                              |
| ------: | ----------------------------------------------------------------- |
|       1 | `vinplay.users`                                                   |
|       2 | `vinplay.freeze_money`                                            |
|       3 | `vinplay.topup`, `vinplay.withdraw`                               |
|       4 | `vinplay_minigame.transaction_tai_xiu`                            |
|       5 | `vinplay_minigame.transaction_detail_tai_xiu`                     |
|       6 | `vinplay_minigame.result_tai_xiu`                                 |
|       7 | `vinplay_minigame.minigame_pots`, `minigame_funds`                |
|       8 | `vinplay.log_game_result`, `log_game_round`, `log_game_reference` |
|       9 | `vinplay_admin.log_admin`                                         |
|      10 | `vinplay_gamebai.game_tour_jackpot`, `poker_tour_user`            |

---

## Frontend cần quan tâm

Frontend không nên biết trực tiếp database, nhưng cần hiểu response sẽ liên quan:

| Nghiệp vụ    | Dữ liệu cần hiển thị                     |
| ------------ | ---------------------------------------- |
| Số dư        | `users.vin`, `users.xu`, `safe`          |
| Lịch sử nạp  | `topup`, bảng kênh nạp                   |
| Lịch sử rút  | `withdraw`                               |
| Lịch sử game | `log_game_result`, `transaction_tai_xiu` |
| Jackpot/pot  | `minigame_pots`, `game_tour_jackpot`     |
| Free code    | `game_free_code_detail`                  |
| Mission      | `user_mission_vin`, `user_mission_xu`    |

Frontend cần luôn gửi:

```text
idempotency_key
request_id
client_time chỉ để log, không dùng làm source of truth
```

---

## QA cần test mạnh nhất

| Nhóm test                  | Database cần check                                   |
| -------------------------- | ---------------------------------------------------- |
| Bet trừ tiền đúng          | `users`, `transaction_tai_xiu`, `log_game_reference` |
| Win cộng tiền đúng         | `users`, `transaction_tai_xiu`, `game_result`        |
| Nạp không cộng trùng       | `topup`, bảng channel, `users`                       |
| Rút không trừ trùng        | `withdraw`, `users`, `freeze_money`                  |
| User spam request          | `users`, transaction game                            |
| Callback gửi lại nhiều lần | `topup`, `withdraw`                                  |
| Game crash                 | `freeze_money`                                       |
| Jackpot nổ                 | `minigame_pots`, `game_tour_jackpot`, `users`        |
| Admin cộng/trừ tiền        | `log_admin`, `users`                                 |

---

# 10. Kết luận ngắn gọn

Hệ thống có 4 database:

```text
vinplay          = core user / ví / nạp rút / log game
vinplay_admin    = admin / phân quyền / log admin / request rút
vinplay_minigame = mini game / tài xỉu / pot / fund / transaction
vinplay_gamebai  = game bài / tournament / jackpot / free code
```

Database quan trọng nhất là:

```text
vinplay
```

vì nó giữ:

```text
users.vin
users.xu
topup
withdraw
freeze_money
money_system
```

Điểm nguy hiểm nhất hiện tại:

```text
1. Tiền nằm rải rác ở nhiều bảng.
2. Không thấy ledger trung tâm.
3. Kiểu dữ liệu tiền không đồng nhất: bigint / int / varchar.
4. Thiếu unique idempotency cho nhiều nghiệp vụ tiền.
5. Không thấy foreign key rõ ràng.
6. Rút tiền có ở cả vinplay.withdraw và vinplay_admin.request_withdraw.
7. Mini game nằm database riêng, dễ lệch với ví chính nếu transaction không atomic.
```

Nếu làm backend cho hệ thống này, ưu tiên số 1 là chuẩn hóa lại **money flow** quanh `vinplay.users` và thêm một bảng ledger trung tâm để mọi nghiệp vụ nạp/rút/cược/thắng/thua/admin/jackpot đều có dấu vết đối soát.
