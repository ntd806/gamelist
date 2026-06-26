
---

# BÁO CÁO TEST RTP — MAHJONG WAYS 2

## 1. Thông tin test

| Hạng mục                |            Giá trị |
| ----------------------- | -----------------: |
| Game                    |   `MAHJONG_WAYS_2` |
| Config source           | `mysql-local-fast` |
| Source config version   |               `20` |
| Room                    |                `1` |
| Bet option              |   `R1_BS_250_BL_9` |
| Bet size active         |              `250` |
| Total bet mỗi paid spin |              `450` |
| Seed                    |           `123456` |
| Paid spins              |        `1,000,000` |
| Base rounds             |        `1,000,000` |
| Free spin rounds        |        `4,285,466` |
| Total spin events       |        `5,285,466` |
| Tổng tiền bet đã charge |      `450,000,000` |

Kết quả test được lấy từ file `summary.json`, với `valid=true` và `invariantFailures=[]`, nghĩa là các invariant kỹ thuật trong simulator đều pass. 

---

## 2. Cấu hình weight đang test

Config active hiện tại: **v20 — base-trigger40**.

Thứ tự symbol:

```text
WILD, SCATTER, ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6, ITEM_7, ITEM_8, ITEM_9
```

|   Reel | WILD | SCATTER | ITEM_1 | ITEM_2 | ITEM_3 | ITEM_4 | ITEM_5 | ITEM_6 | ITEM_7 | ITEM_8 | ITEM_9 | Tổng weight |
| -----: | ---: | ------: | -----: | -----: | -----: | -----: | -----: | -----: | -----: | -----: | -----: | ----------: |
| Reel 0 |    1 |     119 |     36 |     38 |     42 |     48 |     55 |     68 |    100 |    263 |    263 |       1,033 |
| Reel 1 |    1 |     119 |     42 |     48 |     61 |    113 |    198 |    198 |    133 |     48 |     48 |       1,009 |
| Reel 2 |    1 |     119 |     87 |    178 |    178 |    152 |     74 |     61 |     48 |     42 |     42 |         982 |
| Reel 3 |    1 |     119 |    152 |    152 |    139 |    113 |     87 |     61 |     48 |     42 |     42 |         956 |
| Reel 4 |    1 |     119 |    178 |    152 |    126 |    100 |     74 |     61 |     48 |     42 |     42 |         943 |

### Nhận xét cấu hình

Cấu hình này đang đẩy `SCATTER = 119` trên cả 5 reel, nên tỷ lệ vào free spin rất cao. Đây là cấu hình thiên về **hook người chơi bằng free spin**, không phải cấu hình production cân bằng.

---

## 3. Kết quả RTP tổng quan

| Chỉ số                          |           Kết quả |
| ------------------------------- | ----------------: |
| Raw math total win trước safety | `3,213,168,412.5` |
| Raw math RTP trước safety       |         `714.04%` |
| Paid total win sau safety       |     `437,599,215` |
| RTP thực trả                    |       `97.24427%` |
| House edge                      |        `2.75573%` |
| Avg win / paid spin             |          `437.60` |
| Hit rate tổng                   |          `15.77%` |
| Base hit rate                   |          `23.97%` |
| Free spin hit rate              |          `13.86%` |
| Base RTP                        |          `20.48%` |
| Free spin RTP                   |          `76.76%` |

## Đánh giá RTP

```text
RTP thực trả = 97.24%
House edge = 2.76%
```

Về mặt kết quả cuối cùng, RTP đang nằm ở vùng hợp lý nếu target là khoảng **97%**. Tuy nhiên, điểm rất đáng lo là:

```text
Raw math RTP trước safety = 714.04%
Blocked RTP = 616.79%
```

Nghĩa là nếu không có `PrizeSafety`, cấu hình này sẽ phá quỹ rất nặng. RTP cuối đẹp là do safety chặn rất nhiều win, không phải do math gốc cân bằng.

---

## 4. Free spin performance

| Chỉ số                               |             Kết quả |
| ------------------------------------ | ------------------: |
| Free spin trigger count              |           `399,698` |
| Free spin trigger rate               |          `39.9698%` |
| Theoretical base trigger rate        |        `39.983252%` |
| Target base trigger rate             |               `40%` |
| Free spin frequency                  |  `1 / 3 paid spins` |
| Free spin rounds / paid spin         |          `4.285466` |
| Total free spins awarded / paid spin |          `4.285466` |
| Free spin retrigger count            |                 `0` |
| Free spin retrigger rate             |                `0%` |
| Free spin source                     | `BASE_TRIGGER_ONLY` |

## Đánh giá free spin

Cấu hình đạt đúng mục tiêu thiết kế của bản test:

```text
Target trigger rate: 40%
Actual trigger rate: 39.97%
```

Tức là phần trigger free spin đang hoạt động đúng theo cấu hình. Nhưng mức này quá cao cho production vì trung bình khoảng **3 paid spins đã vào free spin 1 lần**. Điều này làm game rất “nhiều event”, nhưng cũng làm raw RTP tăng cực mạnh.

---

## 5. Quỹ thưởng / fund safety

| Chỉ số                            |           Kết quả |
| --------------------------------- | ----------------: |
| Total charged bet                 |     `450,000,000` |
| Total fee                         |       `9,000,000` |
| Total pot contribution            |       `4,000,000` |
| Total fund contribution           |     `437,000,000` |
| Total fund cost                   |     `437,599,215` |
| Initial aggregate fund            |       `2,400,000` |
| Final aggregate fund              |       `1,800,785` |
| Initial active bucket fund        |         `600,000` |
| Final active bucket fund          |             `785` |
| Regular prize before safety       | `3,213,168,412.5` |
| Regular prize paid                |     `437,599,215` |
| Regular prize blocked by safety   | `2,775,569,197.5` |
| Prize safety zero count           |         `589,498` |
| Cross-bucket borrow attempt count |         `589,495` |
| Bucket invariant failures         |               `0` |

## Đánh giá quỹ

Về mặt kỹ thuật:

```text
Quỹ không âm.
Bucket active cuối còn 785.
Invariant quỹ pass.
```

Nhưng về mặt vận hành:

```text
Active bucket gần như bị rút cạn.
Final bucket fund chỉ còn 785.
Safety block 589,498 lần.
Blocked prize = 2.775 tỷ.
```

Đây là dấu hiệu rất rủi ro. Cấu hình hiện tại **không phá quỹ nhờ PrizeSafety**, nhưng đang phụ thuộc quá mạnh vào cơ chế chặn thưởng.

---

## 6. Big win / mega win

| Chỉ số       | Raw trước safety | Paid sau safety |  Bị block |
| ------------ | ---------------: | --------------: | --------: |
| Big win      |        `116,336` |           `587` | `115,749` |
| Mega win     |         `33,941` |             `7` |  `33,934` |
| Big mega win |         `16,183` |             `2` |  `16,181` |

| Chỉ số khác                   |   Kết quả |
| ----------------------------- | --------: |
| Largest paid win              |  `34,830` |
| Largest raw win before safety | `914,355` |
| Max payout ratio              |   `77.4x` |
| P95 win                       |     `540` |
| P99 win                       |   `1,440` |
| Paid spin package P95         |   `1,980` |
| Paid spin package P99         |   `3,240` |

## Đánh giá big win

Game sinh rất nhiều big win raw, nhưng phần lớn bị safety chặn:

```text
Raw big win: 116,336
Paid big win: 587
Tỷ lệ big win được trả rất thấp.
```

Điều này có thể gây cảm giác “game có vẻ sinh win lớn nhưng thực tế hay bị về 0” nếu player trace/debug thấy được hoặc nếu UI experience bị hụt.

---

## 7. Symbol appearance

| Symbol  | Observed rate |
| ------- | ------------: |
| WILD    |   `0.101873%` |
| SCATTER |  `11.597091%` |
| ITEM_1  |   `9.958571%` |
| ITEM_2  |  `11.663636%` |
| ITEM_3  |  `11.285165%` |
| ITEM_4  |  `10.984006%` |
| ITEM_5  |  `10.311905%` |
| ITEM_6  |   `9.465801%` |
| ITEM_7  |   `7.775130%` |
| ITEM_8  |   `8.430596%` |
| ITEM_9  |   `8.426227%` |

## Đánh giá symbol

`SCATTER` có observed rate khoảng `11.6%`, rất cao. Đây là nguyên nhân trực tiếp khiến free spin trigger rate đạt gần `40%`.

`WILD` rất thấp, chỉ khoảng `0.1%`, nên game không phụ thuộc vào wild mà chủ yếu phụ thuộc scatter + cascade + multiplier.

---

## 8. Symbol payout contribution

| Symbol | Win event count |   Total win raw | Win share |
| ------ | --------------: | --------------: | --------: |
| ITEM_1 |        `97,104` | `542,002,162.5` |  `16.87%` |
| ITEM_2 |       `157,587` |   `645,252,030` |  `20.08%` |
| ITEM_3 |       `209,738` |   `552,094,245` |  `17.18%` |
| ITEM_4 |       `351,396` | `461,309,962.5` |  `14.36%` |
| ITEM_5 |       `406,287` | `321,642,382.5` |  `10.01%` |
| ITEM_6 |       `447,998` | `305,736,097.5` |   `9.52%` |
| ITEM_7 |       `439,536` |   `189,913,140` |   `5.91%` |
| ITEM_8 |       `373,224` |  `97,715,362.5` |   `3.04%` |
| ITEM_9 |       `372,399` |    `97,503,030` |   `3.03%` |

## Đánh giá payout

Các symbol đóng góp win lớn nhất:

```text
ITEM_2: 20.08%
ITEM_3: 17.18%
ITEM_1: 16.87%
ITEM_4: 14.36%
```

Tức là RTP raw đang bị kéo mạnh bởi các symbol top/mid ở reel sau, cộng thêm việc free spin xuất hiện quá nhiều.

---

## 9. Invariant / tính đúng kỹ thuật

Simulator xác nhận:

```text
valid = true
invariantFailures = []
```

Các invariant quan trọng đã pass:

```text
- totalWin equals sum(cascadeSteps.stepWin)
- stepWin equals sum(visualWins.winAmount)
- visualWins use lineBet payout
- BASE chargedAmount equals totalBet
- FREE_SPIN chargedAmount is 0
- FREE_SPIN payoutBase is locked lineBet
- totalChargedBet only sums paid BASE totalBet
- visualWins never pay WILD or SCATTER
- remainingFreeSpin is never negative
- FREE_SPIN rounds come from BASE triggers only
- RTP denominator is paid BASE totalBet only
- fund cost excludes jackpot prize
```

Về mặt logic tính tiền và invariant, bản test **pass**.

---

# 10. Kết luận

## Kết quả đạt

```text
1. Simulator valid.
2. Không có invariant failure.
3. RTP thực trả = 97.24%.
4. House edge = 2.76%.
5. Quỹ tổng không âm.
6. Bucket active không âm.
7. Free spin trigger rate đạt gần đúng target 40%.
8. FREE_SPIN không bị charge tiền và dùng locked bet đúng.
```

## Rủi ro lớn

```text
1. Raw math RTP = 714.04%, quá cao.
2. Blocked RTP = 616.79%, nghĩa là game phụ thuộc nặng vào PrizeSafety.
3. PrizeSafety zero count = 589,498 lần / 1,000,000 paid spins.
4. Active bucket cuối chỉ còn 785, gần cạn quỹ.
5. Raw big win/mega win bị block gần như toàn bộ.
6. Free spin trigger 39.97% quá dày cho production.
```

# 11. Đánh giá production

```text
Không khuyến nghị dùng production.
```

Lý do: mặc dù RTP cuối và quỹ không âm, cấu hình này đạt được nhờ safety block quá nhiều. Math gốc không ổn định.

# 12. Đề xuất

## Nếu dùng cho demo/test

Có thể dùng cấu hình này để test:

```text
- Trigger free spin nhiều.
- Kiểm tra flow free spin.
- Kiểm tra 4020 summary.
- Kiểm tra PrizeSafety.
- Kiểm tra bucket không âm.
```

## Nếu dùng production

Cần giảm `SCATTER` và raw RTP.

Khuyến nghị:

```text
1. Giảm SCATTER từ 119 xuống vùng 20–35.
2. Target free spin trigger rate production: 1%–3%.
3. Giữ freeSpinRetriggerEnabled = false.
4. Giảm rawRegularRtpBeforeSafety từ 714% xuống dưới 110%–120%.
5. Giảm regularPrizeSafetyZeroCount xuống dưới 0.5% paid spins.
6. Không để active bucket cuối sát 0.
```

---

# Final verdict

```text
Bản config v20-base-trigger40:
- Đúng kỹ thuật.
- Đúng mục tiêu test free spin 40%.
- RTP thực trả đạt 97.24%.
- Quỹ không âm.

Nhưng:
- Không đạt chuẩn production.
- Raw RTP quá cao.
- Safety block quá nhiều.
- Bucket active gần cạn.

```
