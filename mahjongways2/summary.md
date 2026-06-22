# Báo cáo tổng quan kết quả RTP — Mahjong Ways 2

## 1. Thông tin phiên test

Phiên test RTP được thực hiện cho game `MAHJONG_WAYS_2` với cấu hình:

* Room: `1`
* Bet option: `R1_BS_250_BL_9`
* Seed: `123456`
* Paid spins: `10,000`
* Total rounds: `10,000`
* Base rounds: `10,000`
* Free Spin rounds: `0`

Kết quả tổng quan:

* Total Charged Bet: `4,500,000`
* Total Win / Total Prize Paid: `3,732,435`
* RTP: `82.943%`
* House Edge: `17.057%`
* Hit Rate: `34.63%`
* Report status: `valid = true`
* Invariant failures: `0`

Kết quả này cho thấy phiên test đã chạy đủ số lượt paid spin, không phát sinh lỗi invariant trong quá trình tính toán RTP và kế toán.

---

## 2. Tổng quan kế toán dòng tiền

Tổng tiền người chơi bị charge trong 10,000 paid spins là:

```text
Total Charged Bet = 4,500,000
```

Khoản này được phân bổ thành các phần:

| Hạng mục                |   Giá trị |
| ----------------------- | --------: |
| Total Charged Bet       | 4,500,000 |
| Total Fee               |    90,000 |
| Total Pot Contribution  |    40,000 |
| Total Fund Contribution | 4,370,000 |
| Total Prize Paid        | 3,732,435 |
| House Return            |   767,565 |

Công thức đối soát chính:

```text
House Return = Total Charged Bet - Total Prize Paid
             = 4,500,000 - 3,732,435
             = 767,565
```

Tỷ lệ house return:

```text
House Return Rate = 767,565 / 4,500,000
                  = 17.057%
```

Tỷ lệ này khớp với `houseEdge = 0.17057` trong report.

---

## 3. Phân tích RTP và payout

Tổng tiền thắng đã trả cho người chơi:

```text
Total Prize Paid = 3,732,435
```

Do không có jackpot được trả trong phiên test, toàn bộ prize paid đến từ regular prize:

| Hạng mục                    |   Giá trị |
| --------------------------- | --------: |
| Regular Prize Before Safety | 3,732,435 |
| Regular Prize Paid          | 3,732,435 |
| Jackpot Prize Paid          |         0 |
| Total Prize Paid            | 3,732,435 |

RTP được tính như sau:

```text
RTP = Total Prize Paid / Total Charged Bet
    = 3,732,435 / 4,500,000
    = 82.943%
```

Trong đó:

| Thành phần RTP | Giá trị |
| -------------- | ------: |
| Regular RTP    | 82.943% |
| Jackpot RTP    |      0% |
| Total RTP      | 82.943% |

Như vậy, toàn bộ RTP trong phiên test này đến từ regular prize. Jackpot không đóng góp vào RTP do không có jackpot hit.

---

## 4. Phân tích quỹ fund và pot

Trạng thái quỹ tổng:

| Hạng mục               |   Giá trị |
| ---------------------- | --------: |
| Initial Aggregate Fund | 2,400,000 |
| Final Aggregate Fund   | 3,037,565 |
| Fund Increase          |   637,565 |

Trạng thái pot:

| Hạng mục     |   Giá trị |
| ------------ | --------: |
| Initial Pot  | 1,200,000 |
| Final Pot    | 1,240,000 |
| Pot Increase |    40,000 |

Đối soát house return:

```text
Fee + Pot Increase + Fund Increase
= 90,000 + 40,000 + 637,565
= 767,565
```

Giá trị này khớp với:

```text
House Return = 767,565
```

Điều này cho thấy dòng tiền kế toán đang cân bằng giữa charge, payout, fee, pot và fund.

---

## 5. Phân tích theo bucket active

Phiên test đang chạy trên bucket active:

```text
MAHJONG_WAYS_2:R1:BS250:VND
```

Các bucket khác không phát sinh contribution hoặc payout.

Bucket active có số liệu:

| Hạng mục             |   Giá trị |
| -------------------- | --------: |
| Initial Bucket Fund  |   600,000 |
| Bucket Contributions | 4,370,000 |
| Bucket Fund Costs    | 3,732,435 |
| Final Bucket Fund    | 1,237,565 |

Đối soát bucket active:

```text
Final Bucket Fund
= Initial Bucket Fund + Bucket Contributions - Bucket Fund Costs
= 600,000 + 4,370,000 - 3,732,435
= 1,237,565
```

Kết quả này khớp với `finalBucketFunds` trong report.

Không có cross-bucket borrow:

```text
crossBucketBorrowAttemptCount = 0
aggregateMismatchBlockCount = 0
bucketInvariantFailuresCount = 0
```

Điều này cho thấy phiên test không phát sinh lỗi mượn quỹ chéo bucket hoặc lệch aggregate fund.

---

## 6. Safety và blocked prize

Trong phiên test này, hệ thống không block prize vì safety:

| Hạng mục                        | Giá trị |
| ------------------------------- | ------: |
| Regular Prize Safety Zero Count |       0 |
| Blocked Regular Prize Minor     |       0 |
| Blocked RTP                     |       0 |
| Jackpot Blocked By Fund Count   |       0 |
| Jackpot Removed By Safety Count |       0 |

Điều này có nghĩa là toàn bộ regular prize phát sinh đều được chi trả đầy đủ, không có khoản win nào bị đưa về 0 do không đủ fund hoặc do safety rule.

---

## 7. Free Spin

Trong 10,000 paid spins, kết quả ghi nhận:

| Chỉ số                    | Giá trị |
| ------------------------- | ------: |
| Free Spin Rounds          |       0 |
| Free Spin Trigger Count   |       0 |
| Free Spin Trigger Rate    |       0 |
| Free Spin Retrigger Count |       0 |
| Free Spin Frequency       |     N/A |

Free Spin không phát sinh trong phiên test này. Về mặt kế toán, điều này có nghĩa:

* Không có round Free Spin được chơi.
* Không có payout nào đến từ Free Spin.
* Không có charged bet từ Free Spin.
* Toàn bộ RTP và payout trong phiên test đều đến từ paid BASE spins.

Theo xác suất đã rà soát từ cấu hình hiện tại, Free Spin có tần suất trigger rất thấp. Với 10,000 spins, việc chưa xuất hiện Free Spin vẫn nằm trong vùng hợp lý. Ngay cả với 1,000,000 spins, số lần trigger kỳ vọng chỉ khoảng 1–2 lần và vẫn có khả năng không xuất hiện Free Spin.

Vì vậy, `freeSpinRounds = 0` trong report này chưa phải dấu hiệu lỗi kế toán. Nó chỉ cho thấy sample hiện tại chưa phát sinh event Free Spin.

---

## 8. Jackpot

Trong phiên test này:

| Chỉ số                          | Giá trị |
| ------------------------------- | ------: |
| Jackpot Hit Count               |       0 |
| Jackpot Prize Paid              |       0 |
| Jackpot RTP                     |       0 |
| Jackpot Blocked By Fund Count   |       0 |
| Jackpot Removed By Safety Count |       0 |

Jackpot không phát sinh nên không ảnh hưởng đến payout, RTP hoặc fund cost của phiên test.

---

## 9. Big win và phân phối win

Các chỉ số win lớn:

| Loại win     | Count |
| ------------ | ----: |
| Big Win      |   127 |
| Mega Win     |    32 |
| Big Mega Win |    12 |

Các chỉ số payout:

| Chỉ số                    |  Giá trị |
| ------------------------- | -------: |
| Max Win                   | 47,722.5 |
| Average Win Per Paid Spin | 373.2435 |
| P95 Win                   |    1,800 |
| P99 Win                   |    6,795 |

Hit rate:

```text
Hit Rate = 34.63%
```

Nghĩa là khoảng 34.63% paid spins có phát sinh win.

---

## 10. Nhận định sơ bộ

Về mặt kế toán, report hiện tại đang cân bằng:

```text
Total Charged Bet = 4,500,000
Total Prize Paid = 3,732,435
House Return = 767,565
House Return Rate = 17.057%
RTP = 82.943%
```

Các dòng tiền fee, pot và fund đều đối soát được:

```text
Fee + Pot Increase + Fund Increase = House Return
90,000 + 40,000 + 637,565 = 767,565
```

Bucket active cũng cân bằng:

```text
Initial Fund + Contribution - Payout = Final Fund
600,000 + 4,370,000 - 3,732,435 = 1,237,565
```

Không ghi nhận lỗi invariant, không có blocked prize, không có jackpot payout, không có cross-bucket borrow.

Free Spin bằng 0 trong phiên test này không làm sai kế toán, vì không phát sinh Free Spin thì toàn bộ charged bet, payout, RTP và house return đều được tính trên paid BASE spins.

---

## 11. Kết luận

Kết quả RTP hiện tại hợp lệ về mặt kế toán.

Các chỉ số chính đang khớp:

* Total charged bet khớp với paid spin package.
* Total prize paid khớp với regular prize paid.
* RTP khớp với công thức payout / charged bet.
* House return khớp với charged bet trừ prize paid.
* Fee, pot increase và fund increase cộng lại khớp house return.
* Bucket active cân bằng contribution và payout.
* Không có invariant failure.

Điểm cần lưu ý duy nhất là Free Spin chưa phát sinh trong sample 10,000 spins. Tuy nhiên, với xác suất trigger hiện tại, kết quả này vẫn nằm trong vùng hợp lý và chưa đủ căn cứ kết luận lỗi.
