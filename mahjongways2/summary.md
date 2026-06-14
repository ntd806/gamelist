## Báo cáo tổng hợp từ dữ liệu thật

Mình đã đọc trực tiếp 3 file `time-001.json`, `time-002.json`, `time-003.json`. **Kết quả: cả 3 file có nội dung giống hệt nhau**, cùng SHA-256: `c8e735c1b121fc4daa84f015a6b4dc7c7108d6995a5163cff8ce3d0cf733f4bc`. Vì vậy báo cáo dưới đây tổng hợp trên **1 bộ dữ liệu duy nhất**, không nhân 3 lần.   

---

# 1. Thông tin mô phỏng

| Chỉ tiêu         |                                                            Giá trị |
| ---------------- | -----------------------------------------------------------------: |
| Game             |                                                   `MAHJONG_WAYS_2` |
| Config version   | `9b23e712399b8f2254352d323425d6bf349778f51bb5b2acb0afab650d6c6851` |
| Room ID          |                                                                `1` |
| Bet option       |                                                   `R1_BS_250_BL_9` |
| Seed             |                                                           `123456` |
| Paid spins       |                                                        `1,000,000` |
| Total rounds     |                                                        `1,000,000` |
| Base rounds      |                                                        `1,000,000` |
| Free spin rounds |                                                                `0` |

**Kết luận nguồn dữ liệu:** mô phỏng chỉ có **BASE round**, không phát sinh free spin round.

---

# 2. Kết quả RTP và House Edge

| Chỉ tiêu                     |                       Giá trị |
| ---------------------------- | ----------------------------: |
| Total charged bet            |                 `450,000,000` |
| Total win / total prize paid |               `403,332,905.5` |
| RTP                          | `0.89629535` = **89.629535%** |
| House edge                   | `0.10370465` = **10.370465%** |
| House return                 |                `46,667,094.5` |
| House return rate            |                **10.370465%** |
| Avg win per paid spin        |                 `403.3329055` |
| Bet trung bình mỗi paid spin |                         `450` |

Kiểm tra công thức từ dữ liệu:

```text
House return = Total charged bet - Total prize paid
             = 450,000,000 - 403,332,905.5
             = 46,667,094.5
```

Kết quả này **khớp đúng** với trường `houseReturn`.

---

# 3. Tần suất thắng và phân vị tiền thắng

| Chỉ tiêu           |                   Giá trị |
| ------------------ | ------------------------: |
| Hit rate           | `0.346872` = **34.6872%** |
| Base hit rate      |              **34.6872%** |
| Free spin hit rate |                       `0` |
| Max win            |               `2,189,944` |
| P95 win            |                   `1,800` |
| P99 win            |                 `7,042.5` |

Diễn giải đúng theo dữ liệu: trong 1,000,000 paid spins, tỷ lệ có thắng là **34.6872%**. Không có free spin nên không có hit rate từ free spin.

---

# 4. Big win / Mega win

| Loại         |    Count | Tỷ lệ trên paid spins |
| ------------ | -------: | --------------------: |
| Big win      | `14,032` |           **1.4032%** |
| Mega win     |  `3,291` |           **0.3291%** |
| Big mega win |  `1,188` |           **0.1188%** |

---

# 5. Free spin

| Chỉ tiêu                            |             Giá trị |
| ----------------------------------- | ------------------: |
| Free spin trigger count             |                 `0` |
| Free spin trigger rate              |                 `0` |
| Free spin frequency                 |               `N/A` |
| Free spin retrigger count           |                 `0` |
| Free spin retrigger rate            |                 `0` |
| Free spin rounds source             | `BASE_TRIGGER_ONLY` |
| Standalone free spin mode supported |             `false` |

**Kết luận:** dữ liệu này không ghi nhận bất kỳ lần trigger free spin nào.

---

# 6. Jackpot và fund/pot economy

| Chỉ tiêu                        |        Giá trị |
| ------------------------------- | -------------: |
| Jackpot hit count               |            `8` |
| Jackpot blocked by fund count   |          `493` |
| Jackpot removed by safety count |            `0` |
| Total jackpot prize paid        |   `13,326,388` |
| Initial pot                     |    `1,200,000` |
| Final pot                       |    `1,473,612` |
| Pot tăng                        |      `273,612` |
| Initial fund                    |    `2,400,000` |
| Final fund                      | `49,393,482.5` |
| Fund tăng                       | `46,993,482.5` |

Tỷ trọng jackpot trong tổng prize paid:

```text
13,326,388 / 403,332,905.5 = 3.3040666%
```

Tức là jackpot chiếm khoảng **3.3041%** tổng tiền trả thưởng.

---

# 7. Cơ cấu phí, pot, fund

| Chỉ tiêu                |       Giá trị | Tỷ lệ trên total charged bet |
| ----------------------- | ------------: | ---------------------------: |
| Total fee               |   `9,000,000` |                  **2.0000%** |
| Total pot contribution  |   `4,000,000` |                  **0.8889%** |
| Total fund contribution | `437,000,000` |                 **97.1111%** |

Tổng cộng:

```text
9,000,000 + 4,000,000 + 437,000,000 = 450,000,000
```

Khớp với `totalChargedBet`.

---

# 8. Phân rã regular prize và jackpot prize

| Chỉ tiêu                          |         Giá trị |
| --------------------------------- | --------------: |
| Total regular prize before safety | `390,006,517.5` |
| Total regular prize paid          | `390,006,517.5` |
| Total jackpot prize paid          |    `13,326,388` |
| Total prize paid                  | `403,332,905.5` |
| Total fund cost                   | `390,006,517.5` |

Tỷ trọng:

| Loại prize         |         Giá trị | Tỷ trọng trong total prize paid |
| ------------------ | --------------: | ------------------------------: |
| Regular prize paid | `390,006,517.5` |                    **96.6959%** |
| Jackpot prize paid |    `13,326,388` |                     **3.3041%** |

---

# 9. Cascade step distribution

| Cascade steps |     Count |        Tỷ lệ |
| ------------: | --------: | -----------: |
|             0 | `653,135` | **65.3135%** |
|             1 | `249,751` | **24.9751%** |
|             2 |  `70,643` |  **7.0643%** |
|             3 |  `19,454` |  **1.9454%** |
|             4 |   `5,230` |  **0.5230%** |
|             5 |   `1,315` |  **0.1315%** |
|             6 |     `354` |  **0.0354%** |
|             7 |      `90` |  **0.0090%** |
|             8 |      `21` |  **0.0021%** |
|             9 |       `5` |  **0.0005%** |
|            10 |       `1` |  **0.0001%** |
|            11 |       `1` |  **0.0001%** |

Tổng count cascade:

```text
653,135 + 249,751 + ... + 1 = 1,000,000
```

Khớp với `totalRounds`.

---

# 10. Symbol win breakdown

Sắp xếp theo `totalWin` giảm dần:

| Symbol |    Count |      Total win | Avg win / hit | Tỷ trọng trong regular prize |
| ------ | -------: | -------------: | ------------: | ---------------------------: |
| ITEM_2 | `39,184` |   `99,183,150` |    `2,531.22` |                 **25.4312%** |
| ITEM_3 | `50,874` |   `81,522,855` |    `1,602.45` |                 **20.9029%** |
| ITEM_1 | `21,843` |   `66,393,900` |    `3,039.60` |                 **17.0238%** |
| ITEM_4 | `80,333` | `57,999,487.5` |      `721.99` |                 **14.8714%** |
| ITEM_5 | `78,123` |   `30,533,895` |      `390.84` |                  **7.8291%** |
| ITEM_6 | `81,433` |   `25,367,355` |      `311.51` |                  **6.5043%** |
| ITEM_7 | `75,004` |   `14,016,960` |      `186.88` |                  **3.5940%** |
| ITEM_9 | `62,663` |  `7,513,807.5` |      `119.91` |                  **1.9266%** |
| ITEM_8 | `63,364` |  `7,475,107.5` |      `117.97` |                  **1.9167%** |

Tổng `symbolWinBreakdown.totalWin`:

```text
390,006,517.5
```

Khớp với `totalRegularPrizePaid`.

---

# 11. Invariant check

Dữ liệu ghi nhận:

| Chỉ tiêu            | Giá trị                            |
| ------------------- | ---------------------------------- |
| `checkedInvariants` | Có danh sách invariant đã kiểm tra |
| `invariantFailures` | `[]`                               |

**Kết luận:** theo dữ liệu trong file, không có invariant nào bị fail.

---

# 12. Kết luận ngắn gọn

* 3 file là **cùng một kết quả mô phỏng**, không phải 3 kết quả khác nhau.
* Mô phỏng chạy **1,000,000 paid spins**, tổng cược **450,000,000**.
* Tổng trả thưởng **403,332,905.5**, RTP thực tế **89.629535%**.
* House edge / house return rate là **10.370465%**.
* Không có free spin phát sinh: `freeSpinRounds = 0`, `freeSpinTriggerCount = 0`.
* Jackpot hit **8 lần**, jackpot bị block do fund **493 lần**.
* Symbol đóng góp regular prize cao nhất là **ITEM_2** với `99,183,150`, chiếm **25.4312%** regular prize.
* Dữ liệu tự khai báo `invariantFailures = []`, tức là không ghi nhận lỗi invariant trong kết quả mô phỏng.
