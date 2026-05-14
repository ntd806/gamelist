# Tổng Hợp Full Flow Slot Jackpot System Cho Backend Developer

Tài liệu này giải thích:

* luật game
* flow spin
* cách tính thắng
* cascade
* multiplier
* jackpot
* RTP
* quỹ thưởng
* chống âm tiền
* kiến trúc backend

theo góc nhìn:

> backend developer có thể đọc và implement được hệ thống.

---

# I. MỤC TIÊU CỦA HỆ THỐNG

Hệ thống phải đảm bảo:

| Mục tiêu                | Ý nghĩa                  |
| ----------------------- | ------------------------ |
| Người chơi thấy hấp dẫn | có cảm giác “sắp thắng”  |
| Jackpot tăng liên tục   | tạo FOMO                 |
| RTP đúng config         | giữ house edge           |
| Không âm quỹ            | hệ thống không bankrupt  |
| Có thể scale            | nhiều room/game/operator |

---

# II. KHÁI NIỆM QUAN TRỌNG

---

# 1. RTP

```txt id="u6lm9v"
Return To Player
```

Ví dụ:

RTP = 97%

Nghĩa là:

* người chơi cược 100 tỷ
* hệ thống trả lại khoảng 97 tỷ
* nhà cái giữ khoảng 3 tỷ

---

# 2. House Edge

```txt id="5z0krq"
House Edge = 100% - RTP
```

Ví dụ:

100%-97%=3%

---

# 3. Fund

Đây là:

```txt id="q20b1m"
quỹ trả thưởng nội bộ
```

Dùng để:

* trả thưởng thường
* trả cascade
* trả free spin
* trả multiplier

---

# 4. Jackpot Pot

Đây là:

```txt id="v6tx58"
hũ jackpot tăng dần
```

Mỗi spin:

* trích 1 phần tiền cược vào hũ.

---

# III. FLOW GAME TOÀN HỆ THỐNG

# Bước 1 — Player Spin

Client gửi:

```json
{
  "playerId": 1001,
  "betValue": 1000,
  "lines": 20
}
```

---

# Bước 2 — Tính Tổng Cược

## Công thức

TotalBet = Lines \times BetPerLine

Ví dụ:

20 \times 1000 = 20000

---

# IV. ECONOMY SPLIT

Sau khi nhận tiền cược:

hệ thống chia tiền.

---

# 1. Fee Nhà Cái

Fee = TotalBet \times 2%

Ví dụ:

20000 \times 2% = 400

Đây là:

* lợi nhuận hệ thống.

---

# 2. Jackpot Contribution

MoneyToPot = TotalBet \times 1%

Ví dụ:

20000 \times 1% = 200

---

# 3. Fund Contribution

MoneyToFund = TotalBet - Fee - MoneyToPot

Hoặc:

MoneyToFund = TotalBet \times 97%

Ví dụ:

20000 \times 97% = 19400

---

# V. UPDATE ECONOMY

---

# 1. Update Jackpot Pot

Pot_{new}=Pot_{old}+MoneyToPot

---

# 2. Update Fund

Fund_{new}=Fund_{old}+MoneyToFund

---

# VI. RANDOM ENGINE

Game không random đều.

Mỗi symbol có weight khác nhau.

---

# Ví dụ Symbol Weight

| Symbol  | Weight |
| ------- | ------ |
| A       | 40     |
| B       | 30     |
| Wild    | 5      |
| Scatter | 1      |

---

# Probability Formula

P(Symbol)=\frac{Weight_{Symbol}}{TotalWeight}

---

# Ý nghĩa

Symbol:

* càng hiếm
  → càng giá trị.

---

# VII. GENERATE BOARD

Ví dụ board:

```txt id="08t0r6"
A A A B C
A A WILD C D
B A A A C
D C B A WILD
```

Board thường:

* 5 reels
* 4 rows

---

# VIII. WAYS CALCULATION

Game không dùng payline cố định.

Dùng:

```txt id="dz10ej"
WAYS SYSTEM
```

---

# Công thức

Ways = Reel_1 \times Reel_2 \times Reel_3 \times \cdots

---

# Ví dụ

* reel1 có 2 A
* reel2 có 3 A
* reel3 có 1 A

→

2 \times 3 \times 1 = 6

=> có 6 ways thắng.

---

# IX. PAYOUT ENGINE

---

# Công thức payout

Win = Bet \times Paytable \times Ways \times Multiplier

---

# Ví dụ

* bet = 450
* paytable = 0.2
* ways = 6
* multiplier = 3

→

450 \times 0.2 \times 6 \times 3 = 1620

---

# X. CASCADE ENGINE

Nếu thắng:

* symbol thắng biến mất
* symbol mới rơi xuống

---

# Flow

```txt id="3gq9fw"
Win
 ↓
Remove Symbols
 ↓
Drop New Symbols
 ↓
Recalculate Win
```

---

# XI. MULTIPLIER ENGINE

Multiplier tăng theo cascade.

Ví dụ:

| Cascade | Multiplier |
| ------- | ---------- |
| 1       | x1         |
| 2       | x2         |
| 3       | x3         |
| 4       | x5         |

---

# Ý nghĩa

Spin càng kéo dài:
→ payout càng mạnh.

---

# XII. FREE SPIN ENGINE

Nếu đủ scatter:

Ví dụ:

* 3 scatter

→ vào free spin.

---

# Trong Free Spin

* multiplier mạnh hơn
* wild nhiều hơn
* RTP cao hơn

---

# XIII. JACKPOT ENGINE

---

# Điều kiện jackpot

Ví dụ config:

```json
{
  "jackpotRate": 1000
}
```

→

P(Jackpot)=\frac{1}{1000}

---

# Nhưng phải thêm điều kiện quỹ

## Safety Check

Fund - TotalPrizes - JackpotCost \ge 0

---

# Ý nghĩa

Không cho:

* trả jackpot nếu hệ thống không đủ tiền.

---

# XIV. JACKPOT PAYOUT

Nếu nổ hũ:

---

# Jackpot thường

JackpotPrize = Pot

---

# Jackpot X2

JackpotPrize = 2 \times Pot

---

# XV. RESET JACKPOT

Sau khi nổ:

Pot = InitPotValue

---

# XVI. FUND DEDUCTION

Sau khi trả thưởng:

Fund = Fund - (RegularPrize + BonusPrize)

Jackpot thường:

* trừ từ jackpot pot.

---

# XVII. CHỐNG ÂM TIỀN (QUAN TRỌNG NHẤT)

Đây là phần sống còn của backend casino.

---

# 1. Safety Validation

Trước khi trả thưởng:

```java
if (fund - payout < 0) {
    denyJackpot();
}
```

---

# 2. Exposure Control

Giới hạn payout tối đa:

MaxExposure = Bet \times MaxMultiplier

Ví dụ:

* max = 5000x bet.

---

# 3. Dynamic RTP

Nếu:

* fund thấp

→ giảm:

* bonus rate
* jackpot rate
* multiplier frequency

---

# XVIII. RTP CONTROL

Backend thật thường có:

| Thành phần        | Điều khiển     |
| ----------------- | -------------- |
| RTP target        | 96–97%         |
| Hit frequency     | số lần thắng   |
| Variance          | độ nổ          |
| Bonus frequency   | tần suất bonus |
| Jackpot frequency | tần suất nổ hũ |

---

# XIX. HỆ THỐNG DATABASE

---

# Core Tables

| Table           | Ý nghĩa       |
| --------------- | ------------- |
| players         | user          |
| wallets         | số dư         |
| jackpot_pot     | hũ            |
| fund            | quỹ           |
| spin_history    | lịch sử spin  |
| transactions    | ledger        |
| game_config     | RTP config    |
| jackpot_history | lịch sử nổ hũ |

---

# XX. CORE BACKEND FLOW

# Pseudo Flow

```txt id="i56s8d"
Receive Spin Request
    ↓
Validate Balance
    ↓
Deduct Bet
    ↓
Split Economy
    ↓
Update Pot + Fund
    ↓
Generate Board
    ↓
Calculate Wins
    ↓
Process Cascade
    ↓
Process Multiplier
    ↓
Check Jackpot
    ↓
Validate Fund Safety
    ↓
Credit Reward
    ↓
Save Transactions
    ↓
Return Spin Result
```

---

# XXI. THỨ QUAN TRỌNG NHẤT DEV PHẢI HIỂU

Game slot không phải:

> random đơn giản.

Nó là:

# “hệ thống quản lý xác suất + dòng tiền”

Mục tiêu là:

| Hệ thống phải làm | Ý nghĩa         |
| ----------------- | --------------- |
| giữ RTP đúng      | casino có lời   |
| không âm quỹ      | tránh bankrupt  |
| tạo dopamine      | giữ người chơi  |
| jackpot tăng dần  | tạo FOMO        |
| payout hợp lý     | game không chết |

