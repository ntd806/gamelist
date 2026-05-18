Dưới đây là bản riêng, logic hơn, để dev backend đọc và implement theo đúng tài liệu đã cung cấp.

---

# Tài Liệu Công Thức & Luật Chơi Slot Jackpot

## 1. Luật chơi tổng quan

Game là slot jackpot có các thành phần chính:

| Thành phần    | Ý nghĩa                                 |
| ------------- | --------------------------------------- |
| Lines         | số dòng cược                            |
| BetValue      | tiền cược mỗi dòng                      |
| TotalBetValue | tổng tiền cược mỗi lượt quay            |
| Fund          | quỹ thưởng chung dùng trả thưởng thường |
| Pot           | hũ jackpot                              |
| InitPotValue  | giá trị hũ gốc sau khi reset            |
| Fee           | phần nhà cái giữ lại                    |
| MoneyToPot    | tiền cộng vào jackpot                   |
| MoneyToFund   | tiền cộng vào quỹ thưởng                |

---

# 2. Công thức tổng tiền cược

```text
totalBetValue = numberOfLines × betValue
```

Ví dụ:

```text
numberOfLines = 20
betValue = 1,000

totalBetValue = 20 × 1,000 = 20,000
```

Ý nghĩa:

> Đây là tổng số tiền người chơi bỏ ra cho 1 lượt quay.

---

# 3. Chia tiền sau mỗi lượt quay

Sau khi người chơi đặt cược, hệ thống chia `totalBetValue` thành 3 phần:

| Phần        | Công thức             | Ý nghĩa                   |
| ----------- | --------------------- | ------------------------- |
| Fee         | `totalBetValue × 2%`  | nhà cái giữ lại           |
| Jackpot Pot | `totalBetValue × 1%`  | cộng vào hũ jackpot       |
| Fund        | `totalBetValue × 97%` | cộng vào quỹ thưởng chung |

---

## 3.1. Fee nhà cái

```text
fee = totalBetValue × 2%
```

Ví dụ:

```text
fee = 20,000 × 2% = 400
```

---

## 3.2. Tiền cộng vào jackpot pot

```text
moneyToPot = totalBetValue × 1%
```

Ví dụ:

```text
moneyToPot = 20,000 × 1% = 200
```

---

## 3.3. Tiền cộng vào quỹ thưởng chung

```text
moneyToFund = totalBetValue - fee - moneyToPot
```

Hoặc viết gọn:

```text
moneyToFund = totalBetValue × 97%
```

Ví dụ:

```text
moneyToFund = 20,000 - 400 - 200 = 19,400
```

---

# 4. Cập nhật jackpot pot và fund

Sau mỗi lượt quay:

```text
potNew = potOld + moneyToPot
```

```text
fundNew = fundOld + moneyToFund
```

Ví dụ:

```text
potOld = 1,000,000
moneyToPot = 200

potNew = 1,000,200
```

```text
fundOld = 10,000,000
moneyToFund = 19,400

fundNew = 10,019,400
```

---

# 5. Công thức xác suất biểu tượng

Game không random biểu tượng đều nhau.
Mỗi biểu tượng có một `weight`.

Ví dụ:

| Symbol  | Weight | Ý nghĩa  |
| ------- | -----: | -------- |
| A       |     40 | dễ ra    |
| B       |     30 | dễ ra    |
| Wild    |      5 | hiếm     |
| Scatter |      1 | rất hiếm |

Tổng weight:

```text
totalWeight = 40 + 30 + 5 + 1 = 76
```

Xác suất ra một symbol:

```text
P(symbol) = weightOfSymbol / totalWeight
```

Ví dụ xác suất ra Wild:

```text
P(Wild) = 5 / 76
```

Ví dụ xác suất ra Scatter:

```text
P(Scatter) = 1 / 76
```

Ý nghĩa backend:

> Symbol nào càng có weight thấp thì càng khó xuất hiện.

---

# 6. Công thức xác suất jackpot

Nếu config:

```text
KhoBau_so_lan_no_hu = 1000
```

Thì xác suất nổ jackpot gần đúng:

```text
P(jackpot) ≈ 1 / 1000
```

Tức là trung bình khoảng 1000 lượt quay có thể có 1 lượt đủ điều kiện nổ hũ.

Nhưng jackpot không chỉ phụ thuộc random.
Cần thêm điều kiện quỹ.

---

# 7. Điều kiện được phép nổ jackpot

Jackpot chỉ được xét khi quỹ đủ an toàn.

Điều kiện quỹ:

```text
fund > 2 × initPotValue
```

Ý nghĩa:

> Chỉ cho phép nổ hũ khi quỹ thưởng chung đủ lớn, tránh hệ thống âm tiền.

Ví dụ:

```text
initPotValue = 1,000,000
fund = 2,500,000

2 × initPotValue = 2,000,000

fund > 2,000,000
=> được phép xét nổ hũ
```

Nếu:

```text
fund = 1,500,000
```

thì:

```text
fund < 2 × initPotValue
=> không xét nổ hũ
```

---

# 8. Công thức jackpot prize

## 8.1. Jackpot thường

```text
jackpotPrize = pot
```

Ví dụ:

```text
pot = 5,000,000

jackpotPrize = 5,000,000
```

---

## 8.2. Jackpot X2

```text
jackpotPrize = 2 × pot
```

Ví dụ:

```text
pot = 5,000,000

jackpotPrize = 10,000,000
```

---

# 9. Reset jackpot sau khi nổ

Sau khi jackpot nổ:

```text
pot = initPotValue
```

Ví dụ:

```text
pot hiện tại = 5,000,000
initPotValue = 1,000,000

Sau khi nổ:
pot = 1,000,000
```

---

# 10. Tính thưởng thường

Thưởng thường có thể đến từ:

| Loại thưởng | Ý nghĩa                         |
| ----------- | ------------------------------- |
| Win thường  | thắng theo line/ways            |
| Multiplier  | nhân tiền thắng                 |
| Cascade     | thắng liên tiếp trong cùng spin |
| Free spin   | lượt quay miễn phí              |
| Bonus       | thưởng phụ                      |

Công thức tổng quát:

```text
regularPrize = baseWin × multiplier
```

Nếu dùng ways:

```text
baseWin = betValue × paytable × ways
```

Vậy:

```text
regularPrize = betValue × paytable × ways × multiplier
```

Ví dụ:

```text
betValue = 1,000
paytable = 0.2
ways = 6
multiplier = 3

regularPrize = 1,000 × 0.2 × 6 × 3 = 3,600
```

---

# 11. Tổng tiền thưởng của một lượt quay

```text
totalPrizes = regularPrize + bonusPrize + jackpotPrize
```

Nếu không nổ jackpot:

```text
totalPrizes = regularPrize + bonusPrize
```

Nếu có jackpot:

```text
totalPrizes = regularPrize + bonusPrize + jackpotPrize
```

---

# 12. Phần jackpot không trừ vào fund

Theo tài liệu:

```text
soTienNoHuKhongTruQuy
```

có thể hiểu là:

> phần tiền nổ hũ lấy từ jackpot pot, không trừ trực tiếp vào fund.

Vì vậy khi trừ quỹ thưởng chung, cần loại phần này ra.

Công thức:

```text
fund = fund - (totalPrizes - soTienNoHuKhongTruQuy)
```

Trong đó:

```text
soTienNoHuKhongTruQuy = jackpotPrize
```

nếu jackpot được trả từ `pot`.

---

# 13. Safety check chống âm quỹ

Trước khi trả thưởng, hệ thống phải kiểm tra:

```text
fund - (totalPrizes - soTienNoHuKhongTruQuy) >= 0
```

Nếu đúng:

```text
cho phép trả thưởng
```

Nếu sai:

```text
không cho nổ jackpot / giảm payout / chuyển sang kết quả an toàn
```

---

# 14. Logic xử lý một lượt quay hoàn chỉnh

```text
Bước 1:
Nhận bet từ người chơi

Bước 2:
Tính totalBetValue

Bước 3:
Trừ tiền người chơi

Bước 4:
Chia tiền:
- fee
- moneyToPot
- moneyToFund

Bước 5:
Cộng moneyToPot vào jackpot pot

Bước 6:
Cộng moneyToFund vào fund

Bước 7:
Random symbol theo weight

Bước 8:
Tính thưởng thường:
- line/ways
- multiplier
- cascade
- free spin nếu có

Bước 9:
Kiểm tra điều kiện jackpot:
- fund > 2 × initPotValue
- random jackpot thành công theo tỷ lệ 1 / KhoBau_so_lan_no_hu

Bước 10:
Nếu jackpot:
- jackpotPrize = pot hoặc 2 × pot
- soTienNoHuKhongTruQuy = jackpotPrize

Bước 11:
Tính totalPrizes

Bước 12:
Safety check:
fund - (totalPrizes - soTienNoHuKhongTruQuy) >= 0

Bước 13:
Nếu hợp lệ:
- cộng thưởng cho người chơi
- trừ fund phần thưởng thường
- reset pot nếu nổ jackpot

Bước 14:
Ghi transaction / spin history / jackpot history
```

---

# 15. Pseudo code backend

```java
totalBetValue = numberOfLines * betValue;

fee = totalBetValue * 0.02;
moneyToPot = totalBetValue * 0.01;
moneyToFund = totalBetValue - fee - moneyToPot;

player.balance -= totalBetValue;

pot += moneyToPot;
fund += moneyToFund;

regularPrize = calculateRegularPrize(board, betValue);

jackpotPrize = 0;
soTienNoHuKhongTruQuy = 0;

boolean enoughFundForJackpot = fund > 2 * initPotValue;
boolean jackpotRandomHit = random(1, KhoBau_so_lan_no_hu) == 1;

if (enoughFundForJackpot && jackpotRandomHit) {
    jackpotPrize = pot; // hoặc 2 * pot nếu jackpot X2
    soTienNoHuKhongTruQuy = jackpotPrize;
}

totalPrizes = regularPrize + jackpotPrize;

fundCost = totalPrizes - soTienNoHuKhongTruQuy;

if (fund - fundCost < 0) {
    // Không đủ quỹ
    jackpotPrize = 0;
    soTienNoHuKhongTruQuy = 0;

    totalPrizes = regularPrize;
    fundCost = regularPrize;

    if (fund - fundCost < 0) {
        totalPrizes = 0;
        fundCost = 0;
    }
}

player.balance += totalPrizes;
fund -= fundCost;

if (jackpotPrize > 0) {
    pot = initPotValue;
}
```

---

# 16. Công thức tổng hợp cuối cùng

```text
totalBetValue = numberOfLines × betValue
```

```text
fee = totalBetValue × 2%
```

```text
moneyToPot = totalBetValue × 1%
```

```text
moneyToFund = totalBetValue × 97%
```

```text
potNew = potOld + moneyToPot
```

```text
fundNew = fundOld + moneyToFund
```

```text
P(symbol) = weightOfSymbol / totalWeight
```

```text
P(jackpot) ≈ 1 / KhoBau_so_lan_no_hu
```

```text
jackpotAllowed = fund > 2 × initPotValue
```

```text
jackpotPrize = pot
```

hoặc:

```text
jackpotPrize = 2 × pot
```

```text
totalPrizes = regularPrize + bonusPrize + jackpotPrize
```

```text
fundCost = totalPrizes - soTienNoHuKhongTruQuy
```

```text
fund - fundCost >= 0
```

```text
pot = initPotValue
```

---

# 17. Kết luận ngắn gọn

Game này có 3 hệ chính:

| Hệ          | Vai trò                                          |
| ----------- | ------------------------------------------------ |
| Xác suất    | quyết định symbol, win, jackpot                  |
| Jackpot pot | hũ tăng dần và reset sau khi nổ                  |
| Fund        | quỹ thưởng chung, đảm bảo hệ thống không âm tiền |

Backend dev chỉ cần nhớ logic lõi:

```text
Tiền cược vào
→ chia fee / pot / fund
→ random kết quả
→ tính thưởng
→ kiểm tra quỹ
→ trả thưởng
→ cập nhật pot/fund
→ ghi log
```

Đây là flow chính để viết hệ thống slot jackpot đúng logic tài liệu.
