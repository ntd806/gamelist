
---

# ước lượng chung cho báo cáo

```text id="kpq279"
Số lượt mô phỏng giả định: 1,000,000 paid BASE spins
Bet dùng để tính RTP: bet.totalBet = 0.40
Tổng cược: 1,000,000 x 0.40 = 400,000
Không bật jackpot payout
Không bật retrigger
Không sửa paytable ở bước đầu
Ước lượng RTP chỉ có giá trị nếu lỗi scale bet 0.40 / 4.00 đã được sửa
```

Nếu lỗi scale bet chưa sửa, **không nên dùng bất kỳ số RTP nào để ra quyết định production**.

---

# Tổng quan 4 kịch bản

| Kịch bản                                   | Mục tiêu                        | Ước RTP 1M paid spins | Mức hấp dẫn    | Rủi ro quỹ      |
| ------------------------------------------ | ------------------------------- | --------------------: | -------------- | --------------- |
| 1. Free Spin có ăn đều                     | Giảm quay trắng trong free spin |             98% ~100% | Tốt            | Trung bình-cao  |
| 2. Golden Wild bùng                        | Tạo cảm giác biến vàng, cascade |             98% ~100% | Rất tốt        | Cao             |
| 3. Multiplier leo nhanh                    | Có big moment khi cascade       |             98% ~100% | Trung bình-tốt | Trung bình      |
| 5. Ít trigger hơn, free spin đáng tiền hơn | Cân bằng game-feel và RTP       |             98% ~100% | Tốt            | Thấp-trung bình |

**Khuyến nghị:** nếu để làm production candidate, chọn **kịch bản 5**. Nếu muốn sửa nhanh cảm giác “free spin không ăn”, chọn **kịch bản 1** nhưng phải canh RTP kỹ. Kịch bản 2 chỉ nên dùng A/B test vì có nguy cơ quỹ cao.

---

# Kịch bản 1 — Free Spin có ăn đều

## Mục tiêu

Người chơi vào free spin phải thấy **có thắng nhỏ thường xuyên hơn**, giảm cảm giác 10 lượt free spin quay trắng.

Hiện response cũ cho thấy free spin hit rate chỉ khoảng:

```text id="hs0q4v"
38 win / 670 FREE_SPIN = 5.67%
```

Con số này quá thấp về mặt cảm xúc.

## Ý tưởng chỉnh

Không tăng SCATTER nữa. Trong free spin, SCATTER không retrigger nên nó gần như là symbol chết. Nên giảm SCATTER trong free spin, tăng WILD riêng cho free spin.

```text id="6vx2k6"
BASE giữ như hiện tại
FREE_SPIN WILD: 7%
FREE_SPIN SCATTER: 4.5%
Retrigger: false
Multiplier: giữ [2,4,6,10]
Golden: giữ như hiện tại
```

## Config đề xuất

Thêm field mới nếu engine chưa có:

```json id="sc1-config"
{
  "freeSpinReelSymbolWeights": {
    "0": {
      "WILD": 70,
      "SCATTER": 45,
      "ITEM_1": 35,
      "ITEM_2": 36,
      "ITEM_3": 41,
      "ITEM_4": 47,
      "ITEM_5": 53,
      "ITEM_6": 66,
      "ITEM_7": 97,
      "ITEM_8": 255,
      "ITEM_9": 255
    },
    "1": {
      "WILD": 70,
      "SCATTER": 45,
      "ITEM_1": 42,
      "ITEM_2": 48,
      "ITEM_3": 61,
      "ITEM_4": 112,
      "ITEM_5": 197,
      "ITEM_6": 197,
      "ITEM_7": 132,
      "ITEM_8": 48,
      "ITEM_9": 48
    },
    "2": {
      "WILD": 70,
      "SCATTER": 45,
      "ITEM_1": 90,
      "ITEM_2": 183,
      "ITEM_3": 183,
      "ITEM_4": 156,
      "ITEM_5": 76,
      "ITEM_6": 62,
      "ITEM_7": 49,
      "ITEM_8": 43,
      "ITEM_9": 43
    },
    "3": {
      "WILD": 70,
      "SCATTER": 45,
      "ITEM_1": 161,
      "ITEM_2": 160,
      "ITEM_3": 147,
      "ITEM_4": 120,
      "ITEM_5": 92,
      "ITEM_6": 64,
      "ITEM_7": 51,
      "ITEM_8": 45,
      "ITEM_9": 45
    },
    "4": {
      "WILD": 70,
      "SCATTER": 45,
      "ITEM_1": 192,
      "ITEM_2": 163,
      "ITEM_3": 135,
      "ITEM_4": 107,
      "ITEM_5": 80,
      "ITEM_6": 66,
      "ITEM_7": 52,
      "ITEM_8": 45,
      "ITEM_9": 45
    }
  },
  "freeSpinRetriggerEnabled": false,
  "freeSpin": {
    "retriggerEnabled": false
  }
}
```

## Ước lượng 1 triệu paid spins

```text id="sc1-rtp"
Tổng cược: 400,000
RTP ước lượng: 98% ~100%
Payout ước lượng: 412,000–432,000
Free spin hit rate kỳ vọng: 12%–18%
Cảm giác: thắng nhỏ nhiều hơn, ít quay trắng hơn
```

## Ưu điểm

```text id="sc1-pros"
Dễ thấy hiệu quả nhất với phàn nàn “free spin không ăn”
Không cần sửa paytable
Không cần bật retrigger
Không làm BASE quá dễ ăn
Dễ A/B test
```

## Nhược điểm

```text id="sc1-cons"
RTP có thể vượt target 98%
Nếu free spin vào quá nhiều như response trước, quỹ có thể bị áp lực
Chỉ tăng win nhỏ, chưa chắc tạo big moment đủ mạnh
```

## Rủi ro

```text id="sc1-risk"
Rủi ro chính là quỹ fund bị rút nhanh nếu hit rate free spin tăng nhưng fee/fund vẫn 1%/98%.
Cần test 1M–5M paid spins trước production.
```

---

# Kịch bản 2 — Golden Wild bùng

## Mục tiêu

Tạo cảm giác “bùng” bằng cơ chế:

```text id="6tmaav"
ăn symbol
symbol golden biến thành WILD
cascade tiếp
multiplier tăng
```

Hiện config chỉ để free spin golden chủ yếu ở reel 2:

```json id="7b0dzf"
"freeSpinGoldenReelIndex": 2,
"goldenSymbol": {
  "freeSpinGoldenReels": [2]
}
```

## Ý tưởng chỉnh

Mở thêm golden reel trong free spin:

```text id="bpu3ny"
FREE_SPIN golden reels: [2,3]
WILD/SCATTER giữ như hiện tại hoặc dùng nhẹ hơn kịch bản 1
Multiplier giữ [2,4,6,10]
Retrigger: false
```

## Config đề xuất

```json id="sc2-config"
{
  "freeSpinGoldenReelIndex": 2,
  "goldenSymbol": {
    "enabled": true,
    "baseGoldenReels": [1, 2, 3],
    "freeSpinGoldenReels": [2, 3],
    "excludeSymbols": ["WILD", "SCATTER"]
  },
  "freeSpinRetriggerEnabled": false,
  "freeSpin": {
    "retriggerEnabled": false
  }
}
```

Nếu source hiện tại chỉ đọc `freeSpinGoldenReelIndex` mà không đọc list `goldenSymbol.freeSpinGoldenReels`, thì Codex phải sửa source để dùng list. Không được chỉ thêm JSON rồi tưởng engine tự hiểu.

## Ước lượng 1 triệu paid spins

```text id="sc2-rtp"
Tổng cược: 400,000
RTP ước lượng: 98% ~100%
Payout ước lượng: 428,000–460,000
Free spin hit rate kỳ vọng: 8%–14%
Golden transform kỳ vọng: tăng mạnh
Cảm giác: bùng hơn, có cascade dây chuyền hơn
```

## Ưu điểm

```text id="sc2-pros"
Tạo cảm giác hấp dẫn nhất về mặt hình ảnh
Có khả năng tạo big moment tốt
Không cần tăng SCATTER
Không cần retrigger
Làm free spin có “kịch tính” hơn
```

## Nhược điểm

```text id="sc2-cons"
RTP có thể tăng mạnh và khó đoán
Nếu golden transform nhiều quá, cascade có thể kéo dài
Có thể tạo nhiều WILD tích lũy dẫn đến payout spike
```

## Rủi ro

```text id="sc2-risk"
Rủi ro quỹ cao nhất trong 4 kịch bản.
Chỉ nên dùng để test nội bộ hoặc A/B nhóm nhỏ.
Không nên đẩy production nếu chưa chạy simulator lớn.
```

---

# Kịch bản 3 — Multiplier leo nhanh

## Mục tiêu

Không nhất thiết tăng số lần thắng quá nhiều, nhưng khi đã thắng thì phải có cảm giác **leo multiplier và bùng**.

Hiện free spin multiplier:

```json id="36xuzy"
"freeSpinCascadeMultipliers": [2, 4, 6, 10]
```

## Ý tưởng chỉnh

Tăng multiplier free spin:

```text id="65b8u2"
Từ [2,4,6,10]
Sang [2,5,10,20]
```

Không sửa WILD/SCATTER ở bước này.

## Config đề xuất

Phải sửa cả field top-level và field nested để tránh lệch config:

```json id="sc3-config"
{
  "freeSpinCascadeMultipliers": [2, 5, 10, 20],
  "cascade": {
    "baseMultipliers": [1, 2, 3, 5],
    "freeSpinMultipliers": [2, 5, 10, 20],
    "maxCascadeSteps": 50
  },
  "freeSpinRetriggerEnabled": false,
  "freeSpin": {
    "retriggerEnabled": false
  }
}
```

## Ước lượng 1 triệu paid spins

```text id="sc3-rtp"
Tổng cược: 400,000
RTP ước lượng: 98% ~100%
Payout ước lượng: 404,000–420,000
Free spin hit rate kỳ vọng: gần baseline
BigWin count kỳ vọng: tăng
Cảm giác: ít thắng vẫn có vài pha nổ tốt hơn
```

## Ưu điểm

```text id="sc3-pros"
Sửa ít nhất
Dễ rollback
Ít ảnh hưởng trigger rate
Ít làm thay đổi symbol distribution
Tạo big moment rõ hơn khi cascade xảy ra
```

## Nhược điểm

```text id="sc3-cons"
Không giải quyết triệt để phàn nàn “free spin không ăn”
Nếu free spin vẫn ít cascade, người chơi vẫn thấy khô
Hiệu quả phụ thuộc vào số lần cascade, mà hiện cascade chưa nhiều
```

## Rủi ro

```text id="sc3-risk"
Rủi ro RTP trung bình.
Có thể tạo payout spike ở một số session cascade dài.
Nhưng tổng thể dễ kiểm soát hơn kịch bản 1 và 2.
```

---

# Kịch bản 5 — Ít trigger hơn, free spin đáng tiền hơn

## Mục tiêu

Đây là kịch bản cân bằng nhất.

Thay vì:

```text id="wy32ml"
vào free spin nhiều nhưng chán
```

chuyển thành:

```text id="rn1vhf"
vào free spin ít hơn một chút nhưng đáng mong chờ hơn
```

## Ý tưởng chỉnh

```text id="gw7sha"
BASE SCATTER giảm từ 10% xuống 7%
BASE WILD giữ 5%
FREE_SPIN WILD tăng lên 8%
FREE_SPIN SCATTER giảm còn 4.5%
FREE_SPIN golden reels mở [2,3]
FREE_SPIN multiplier đổi [2,5,10,20]
Retrigger vẫn false
```

## Config đề xuất

### BASE reelSymbolWeights

```json id="sc5-base"
{
  "reelSymbolWeights": {
    "0": {
      "WILD": 50,
      "SCATTER": 70,
      "ITEM_1": 35,
      "ITEM_2": 36,
      "ITEM_3": 40,
      "ITEM_4": 47,
      "ITEM_5": 53,
      "ITEM_6": 65,
      "ITEM_7": 96,
      "ITEM_8": 254,
      "ITEM_9": 254
    },
    "1": {
      "WILD": 50,
      "SCATTER": 70,
      "ITEM_1": 41,
      "ITEM_2": 48,
      "ITEM_3": 61,
      "ITEM_4": 112,
      "ITEM_5": 196,
      "ITEM_6": 196,
      "ITEM_7": 131,
      "ITEM_8": 48,
      "ITEM_9": 47
    },
    "2": {
      "WILD": 50,
      "SCATTER": 70,
      "ITEM_1": 89,
      "ITEM_2": 182,
      "ITEM_3": 182,
      "ITEM_4": 155,
      "ITEM_5": 76,
      "ITEM_6": 62,
      "ITEM_7": 49,
      "ITEM_8": 43,
      "ITEM_9": 42
    },
    "3": {
      "WILD": 50,
      "SCATTER": 70,
      "ITEM_1": 160,
      "ITEM_2": 159,
      "ITEM_3": 146,
      "ITEM_4": 119,
      "ITEM_5": 91,
      "ITEM_6": 64,
      "ITEM_7": 51,
      "ITEM_8": 45,
      "ITEM_9": 45
    },
    "4": {
      "WILD": 50,
      "SCATTER": 70,
      "ITEM_1": 190,
      "ITEM_2": 163,
      "ITEM_3": 135,
      "ITEM_4": 107,
      "ITEM_5": 80,
      "ITEM_6": 65,
      "ITEM_7": 52,
      "ITEM_8": 44,
      "ITEM_9": 44
    }
  }
}
```

### FREE_SPIN reelSymbolWeights

```json id="sc5-free-spin"
{
  "freeSpinReelSymbolWeights": {
    "0": {
      "WILD": 80,
      "SCATTER": 45,
      "ITEM_1": 35,
      "ITEM_2": 36,
      "ITEM_3": 40,
      "ITEM_4": 46,
      "ITEM_5": 53,
      "ITEM_6": 65,
      "ITEM_7": 96,
      "ITEM_8": 252,
      "ITEM_9": 252
    },
    "1": {
      "WILD": 80,
      "SCATTER": 45,
      "ITEM_1": 41,
      "ITEM_2": 47,
      "ITEM_3": 61,
      "ITEM_4": 111,
      "ITEM_5": 195,
      "ITEM_6": 195,
      "ITEM_7": 131,
      "ITEM_8": 47,
      "ITEM_9": 47
    },
    "2": {
      "WILD": 80,
      "SCATTER": 45,
      "ITEM_1": 89,
      "ITEM_2": 181,
      "ITEM_3": 181,
      "ITEM_4": 155,
      "ITEM_5": 75,
      "ITEM_6": 62,
      "ITEM_7": 48,
      "ITEM_8": 42,
      "ITEM_9": 42
    },
    "3": {
      "WILD": 80,
      "SCATTER": 45,
      "ITEM_1": 160,
      "ITEM_2": 159,
      "ITEM_3": 145,
      "ITEM_4": 118,
      "ITEM_5": 91,
      "ITEM_6": 64,
      "ITEM_7": 50,
      "ITEM_8": 44,
      "ITEM_9": 44
    },
    "4": {
      "WILD": 80,
      "SCATTER": 45,
      "ITEM_1": 189,
      "ITEM_2": 162,
      "ITEM_3": 134,
      "ITEM_4": 106,
      "ITEM_5": 79,
      "ITEM_6": 65,
      "ITEM_7": 52,
      "ITEM_8": 44,
      "ITEM_9": 44
    }
  }
}
```

### Multiplier + golden

```json id="sc5-extra"
{
  "freeSpinCascadeMultipliers": [2, 5, 10, 20],
  "cascade": {
    "baseMultipliers": [1, 2, 3, 5],
    "freeSpinMultipliers": [2, 5, 10, 20],
    "maxCascadeSteps": 50
  },
  "goldenSymbol": {
    "enabled": true,
    "baseGoldenReels": [1, 2, 3],
    "freeSpinGoldenReels": [2, 3],
    "excludeSymbols": ["WILD", "SCATTER"]
  },
  "freeSpinRetriggerEnabled": false,
  "freeSpin": {
    "enabled": true,
    "triggerScatterCount": 3,
    "initialFreeSpins": 10,
    "extraFreeSpinsPerScatter": 2,
    "retriggerEnabled": false
  }
}
```

## Ước lượng 1 triệu paid spins

```text id="sc5-rtp"
Tổng cược: 400,000
RTP ước lượng: 98% ~100%
Payout ước lượng: 392,000–412,000
Trigger rate kỳ vọng: giảm so với hiện tại
Free spin hit rate kỳ vọng: tăng rõ
Big moment kỳ vọng: tăng vừa phải
Cảm giác: vào free spin ít hơn nhưng đáng tiền hơn
```

## Ưu điểm

```text id="sc5-pros"
Cân bằng nhất giữa cảm xúc và quỹ
Giảm số lần free spin rỗng
Không bật retrigger nên dễ kiểm soát hơn
Giảm BASE trigger để bù cho free spin mạnh hơn
Phù hợp làm production candidate
```

## Nhược điểm

```text id="sc5-cons"
Người chơi có thể thấy khó vào free spin hơn bản hiện tại
Cần code hỗ trợ freeSpinReelSymbolWeights nếu engine chưa có
Cần kiểm tra kỹ golden reels [2,3] có làm RTP vượt không
```

## Rủi ro

```text id="sc5-risk"
Nếu giảm BASE SCATTER quá mạnh, complaint có thể chuyển từ “free spin không thắng” sang “khó vào free spin”.
Nếu free spin WILD 8% + multiplier [2,5,10,20] quá mạnh, RTP có thể vượt target.
Cần test các biến thể SCATTER 7%, 8% và WILD FS 7%, 8%.
```

---

# So sánh tài chính ước lượng trên 1 triệu paid spins

Tổng cược là:

```text id="w0q6l0"
1,000,000 x 0.40 = 400,000
```

| Kịch bản              | RTP ước lượng | Payout ước lượng | Chênh so với tổng cược | Đánh giá quỹ                    |
| --------------------- | ------------: | ---------------: | ---------------------: | ------------------------------- |
| Baseline v21 quan sát |     98% ~100% |         ~401,200 |                 -1,200 | Đang sát hòa vốn nếu scale đúng |
| Scenario 1            |     98% ~100% |  412,000–432,000 |    -12,000 đến -32,000 | Hấp dẫn nhưng dễ âm quỹ         |
| Scenario 2            |     98% ~100% |  428,000–460,000 |    -28,000 đến -60,000 | Rủi ro cao                      |
| Scenario 3            |     98% ~100% |  404,000–420,000 |     -4,000 đến -20,000 | Rủi ro vừa                      |
| Scenario 5            |     98% ~100% |  392,000–412,000 |     +8,000 đến -12,000 | Cân bằng nhất                   |

Dấu `+` nghĩa là còn dư so với payout; dấu `-` nghĩa là payout vượt tổng cược, chưa tính fee/pot/fund.

---
