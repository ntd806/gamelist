Dưới đây là bản **flow + tài liệu chuẩn cuối cùng** cho **Backend** và **Frontend** của game **Mahjong2**, đã rà soát lại theo:

```text
1. Source SlotMachine hiện tại
2. Tài liệu jackpot / economy
3. Ảnh luật chơi Mahjong2
4. Các điểm đã hiệu chỉnh trước đó
```

---

# A. Mahjong2 — Backend Technical Specification

## 1. Kết luận thiết kế

Mahjong2 là game mới, **chưa có sẵn trong source SlotMachine hiện tại**. Backend cần implement mới bằng cách reuse architecture cũ.

Mahjong2 không phải game line slot cũ.

Mahjong2 là:

```text
5-reel cascading ways slot
layout 4-5-5-5-4
2000 ways
có cascade
có multiplier theo cascade
có Golden Symbol
có Golden → Wild transform
có Free Spin
reuse jackpot / fund / wallet system cũ
```

---

## 2. Những gì reuse từ source cũ

Backend giữ lại các flow cũ:

```text
socket numeric command
Module nhận command
Room xử lý play
subscribe room
change room
auto play
stop auto play
force stop
update pot
big win
minimize
wallet debit / credit
transaction log
spin history
jackpot history
```

Command ID cụ thể cho Mahjong2 **chưa có trong source**, nên để:

```text
TBD — cấp sau trong SlotCMD.java
```

Không hardcode `4101`, `6001` nếu chưa được backend chính thức cấp.

---

## 3. Những gì reuse từ jackpot system cũ

Theo tài liệu jackpot, mỗi spin vẫn chia tiền cược thành:

```text
fee = totalBet × 2%
moneyToPot = totalBet × 1%
moneyToFund = totalBet × 97%
```

Sau đó:

```text
pot += moneyToPot
fund += moneyToFund
```

Tài liệu jackpot cũng xác nhận hệ thống chia tiền cược thành 2% fee, 1% jackpot pot và 97% fund. 

Jackpot chỉ được xét khi:

```text
fund > 2 × initPotValue
```

Điều kiện này được ghi rõ trong tài liệu jackpot để tránh hệ thống âm quỹ. 

Khi nổ jackpot:

```text
jackpotPrize = pot
```

hoặc nếu có X2 config:

```text
jackpotPrize = 2 × pot
```

Sau khi nổ:

```text
pot = initPotValue
```

Tài liệu cũng mô tả jackpot thường, jackpot X2 và reset pot sau khi nổ. 

Phần jackpot không trừ trực tiếp vào fund:

```text
soTienNoHuKhongTruQuy = jackpotPrize
```

Khi trừ fund:

```text
fundCost = totalPrizes - soTienNoHuKhongTruQuy
```

Safety check:

```text
fund - fundCost >= 0
```

Tài liệu jackpot đã mô tả phần `soTienNoHuKhongTruQuy` và safety check chống âm quỹ. 

---

# 4. Backend game rule chính thức cho Mahjong2

## 4.1. Reel layout

Mahjong2 không dùng board đều `4x5`.

Game dùng:

```text
5 reels
row layout = 4 - 5 - 5 - 5 - 4
```

Cụ thể:

| Reel   | Row count |
| ------ | --------: |
| Reel 1 |         4 |
| Reel 2 |         5 |
| Reel 3 |         5 |
| Reel 4 |         5 |
| Reel 5 |         4 |

Tổng ways:

```text
4 × 5 × 5 × 5 × 4 = 2000 ways
```

Backend không dùng:

```java
Cell[4][5]
```

Backend dùng:

```java
List<List<Mahjong2Cell>> reels;
```

---

## 4.2. Symbol rule

Hiện chỉ xác nhận các nhóm symbol sau:

| Symbol            | Vai trò                              |
| ----------------- | ------------------------------------ |
| `WILD`            | thay thế symbol thường               |
| `SCATTER`         | trigger Free Spin                    |
| `ITEM_1...ITEM_7` | normal payable symbols               |
| `golden: true`    | trạng thái mạ vàng của normal symbol |

Không định nghĩa chính thức:

```text
BONUS
JACKPOT / JP symbol trên reels
```

Lý do: luật Mahjong2 hiện tại chưa xác nhận có Bonus symbol hoặc JP symbol trên reels.

Jackpot vẫn tồn tại ở tầng **system/economy**, nhưng không đồng nghĩa có `JP` symbol trên board.

---

## 4.3. Golden Symbol rule

Golden không phải item riêng.

Golden là trạng thái của cell:

```java
symbol = ITEM_1
golden = true
```

Rule:

```text
Golden chỉ xuất hiện ở reel 2, 3, 4.
Golden không áp dụng cho WILD và SCATTER.
Golden symbol nếu tham gia winning ways sẽ chuyển thành WILD ở cascade tiếp theo.
```

Nếu backend index từ 0:

```text
reel 2,3,4 = index 1,2,3
```

Trong Free Spin:

```text
Symbol trên reel 3, trừ Wild và Scatter, sẽ là Golden.
```

Nếu index từ 0:

```text
reel 3 = reelIndex 2
```

---

## 4.4. Ways rule

Game không dùng line.

Game dùng:

```text
2000 ways
```

Win condition:

```text
Symbol thắng phải xuất hiện từ reel trái sang phải.
Tối thiểu 3 reels liên tiếp mới được tính thắng.
```

Wild rule:

```text
Wild thay symbol thường.
Wild không thay Scatter.
```

Ways formula:

```text
ways = countReel1 × countReel2 × countReel3 × ...
```

Ví dụ:

| Reel   | Count ITEM_1 |
| ------ | -----------: |
| Reel 1 |            2 |
| Reel 2 |            3 |
| Reel 3 |            1 |
| Reel 4 |            0 |

Kết quả:

```text
matchedReels = 3
ways = 2 × 3 × 1 = 6
```

Tài liệu full-flow cũng xác nhận ways được tính bằng phép nhân số symbol trên từng reel. 

---

## 4.5. Payout rule

Payout theo ways:

```text
winAmount = totalBet × payRate × ways × multiplier
```

Tài liệu full-flow mô tả payout theo công thức:

```text
Win = Bet × Paytable × Ways × Multiplier
```



Lưu ý:

```text
payRate chưa có dữ liệu thật
weight chưa có dữ liệu thật
```

Vì vậy:

```text
Paytable = config
WeightTable = config
Không hardcode payout/weight giả vào production
```

---

## 4.6. Cascade rule

Sau khi có win:

```text
symbol thắng phát nổ / bị remove
symbol phía trên rơi xuống
symbol mới fill vào
sau đó tính win lại
```

Flow:

```text
Calculate ways win
↓
If no win → stop
↓
Collect win positions
↓
Collect golden transforms
↓
Remove winning symbols
↓
Drop symbols
↓
Fill new symbols
↓
Increase cascade step
↓
Recalculate ways
```

Tài liệu full-flow mô tả cascade là `Win → Remove Symbols → Drop New Symbols → Recalculate Win`. 

---

## 4.7. Multiplier rule

### Base Game

| Cascade Step | Multiplier |
| -----------: | ---------: |
|       Step 1 |         x1 |
|       Step 2 |         x2 |
|       Step 3 |         x3 |
|      Step 4+ |         x5 |

### Free Spin

| Cascade Step | Multiplier |
| -----------: | ---------: |
|       Step 1 |         x2 |
|       Step 2 |         x4 |
|       Step 3 |         x6 |
|      Step 4+ |        x10 |

Backend lấy multiplier theo:

```text
mode + cascadeStep
```

Không dùng multiplier cố định.

Tài liệu full-flow cũng xác nhận multiplier tăng theo cascade. 

---

## 4.8. Free Spin rule

Trigger:

```text
3 Scatter = 10 free spins
mỗi Scatter thêm = +2 free spins
```

Bảng:

| Scatter Count | Free Spins |
| ------------: | ---------: |
|             3 |         10 |
|             4 |         12 |
|             5 |         14 |

Công thức:

```text
freeSpinAwarded = 10 + (scatterCount - 3) × 2
```

Free Spin có thể retrigger nếu trong Free Spin tiếp tục xuất hiện đủ Scatter.

---

## 4.9. Bet rule

Theo luật mới, bet gồm 3 phần:

```text
totalBet = betSize × betLevel × baseBet
```

Ví dụ:

```text
2.50 × 9 × 20 = 450
```

Nếu là Free Spin:

```text
không deduct bet
vẫn dùng totalBet của lượt trigger / state hiện tại để tính payout theo rule backend
```

---

# 5. Backend class structure chuẩn

## 5.1. Config

```java
public class Mahjong2Config {

    public static final int REEL_COUNT = 5;

    public static final List<Integer> REEL_ROWS = List.of(4, 5, 5, 5, 4);

    public static final int TOTAL_WAYS = 2000;

    public static final int MIN_MATCHED_REELS = 3;

    public static final List<Integer> GOLDEN_ALLOWED_REELS = List.of(1, 2, 3);

    public static final String MODE_BASE = "BASE";
    public static final String MODE_FREE_SPIN = "FREE_SPIN";

    public static final int FREE_SPIN_MIN_SCATTER = 3;
    public static final int FREE_SPIN_BASE_COUNT = 10;
    public static final int FREE_SPIN_EXTRA_PER_SCATTER = 2;

    public static int getMultiplier(String mode, int cascadeStep) {
        int step = Math.min(cascadeStep, 4);

        if (MODE_FREE_SPIN.equals(mode)) {
            return switch (step) {
                case 1 -> 2;
                case 2 -> 4;
                case 3 -> 6;
                default -> 10;
            };
        }

        return switch (step) {
            case 1 -> 1;
            case 2 -> 2;
            case 3 -> 3;
            default -> 5;
        };
    }
}
```

---

## 5.2. Symbol

```java
public enum Mahjong2Symbol {

    NONE(-1, "NONE", false, false, false),

    SCATTER(0, "SCATTER", true, false, false),
    WILD(1, "WILD", false, true, false),

    ITEM_1(2, "ITEM_1", false, false, true),
    ITEM_2(3, "ITEM_2", false, false, true),
    ITEM_3(4, "ITEM_3", false, false, true),
    ITEM_4(5, "ITEM_4", false, false, true),
    ITEM_5(6, "ITEM_5", false, false, true),
    ITEM_6(7, "ITEM_6", false, false, true),
    ITEM_7(8, "ITEM_7", false, false, true);

    private final int id;
    private final String code;
    private final boolean scatter;
    private final boolean wild;
    private final boolean payable;

    Mahjong2Symbol(int id, String code, boolean scatter, boolean wild, boolean payable) {
        this.id = id;
        this.code = code;
        this.scatter = scatter;
        this.wild = wild;
        this.payable = payable;
    }

    public String getCode() {
        return code;
    }

    public boolean isScatter() {
        return scatter;
    }

    public boolean isWild() {
        return wild;
    }

    public boolean isPayable() {
        return payable;
    }

    public boolean canBeGolden() {
        return payable;
    }
}
```

---

## 5.3. Cell

```java
public class Mahjong2Cell {

    private Mahjong2Symbol symbol;
    private final int reelIndex;
    private final int rowIndex;
    private boolean golden;

    public Mahjong2Cell(
            Mahjong2Symbol symbol,
            int reelIndex,
            int rowIndex,
            boolean golden
    ) {
        this.symbol = symbol;
        this.reelIndex = reelIndex;
        this.rowIndex = rowIndex;
        this.golden = golden;
    }

    public Mahjong2Symbol getSymbol() {
        return symbol;
    }

    public void setSymbol(Mahjong2Symbol symbol) {
        this.symbol = symbol;
    }

    public int getReelIndex() {
        return reelIndex;
    }

    public int getRowIndex() {
        return rowIndex;
    }

    public boolean isGolden() {
        return golden;
    }

    public void setGolden(boolean golden) {
        this.golden = golden;
    }
}
```

---

## 5.4. Board

```java
public class Mahjong2Board {

    private final List<List<Mahjong2Cell>> reels;

    public Mahjong2Board(List<List<Mahjong2Cell>> reels) {
        this.reels = reels;
    }

    public List<List<Mahjong2Cell>> getReels() {
        return reels;
    }

    public List<Mahjong2Cell> getReel(int reelIndex) {
        return reels.get(reelIndex);
    }

    public Mahjong2Cell getCell(int reelIndex, int rowIndex) {
        return reels.get(reelIndex).get(rowIndex);
    }

    public int getReelCount() {
        return reels.size();
    }

    public int getRowCount(int reelIndex) {
        return reels.get(reelIndex).size();
    }
}
```

---

## 5.5. Position

```java
public record Mahjong2Position(
        int reel,
        int row
) {
}
```

---

# 6. Backend core play flow

```text
PLAY_MAHJONG2
↓
Get room
↓
Get player mode: BASE / FREE_SPIN
↓
Calculate totalBet = betSize × betLevel × baseBet
↓
Validate balance
↓
If BASE:
    deduct totalBet
    split fee / pot / fund
    update pot / fund
↓
Generate initial reels layout 4-5-5-5-4
↓
Process cascade:
    calculate ways
    apply multiplier
    collect removedPositions
    collect goldenTransforms
    remove winning symbols
    drop symbols
    fill new symbols
    repeat until no win
↓
Sum cascade stepWin = regularWin
↓
Count Scatter
↓
If Scatter >= 3:
    award free spins
↓
Check jackpot system:
    fund > 2 × initPotValue
    random jackpot hit
↓
Calculate totalWin = regularWin + jackpotPrize
↓
Safety check fund
↓
Credit player
↓
Deduct fundCost
↓
Reset pot if jackpot
↓
Save transaction
↓
Save spin history
↓
Return RESULT_MAHJONG2
```

---

# B. Mahjong2 — Frontend Integration Specification

## 1. Frontend kết luận thiết kế

Frontend không cần làm socket architecture mới.

Frontend cần:

```text
reuse socket cũ
reuse numeric command convention cũ
reuse subscribe/play/autoplay/minimize flow cũ
```

Chỉ mở rộng:

```text
RESULT payload
dynamic reels 4-5-5-5-4
cascadeSteps
removedPositions
goldenTransforms
freeSpin state
```

---

# 2. Command rule

Dự án cũ dùng numeric command.

Với Mahjong2:

```text
Command ID cụ thể = TBD
Backend sẽ cấp trong SlotCMD.java
Frontend không hardcode ID nếu chưa có
```

Flow command vẫn theo pattern cũ:

```text
SUBSCRIBE_MAHJONG2
INFO_MAHJONG2
CHANGE_ROOM_MAHJONG2
PLAY_MAHJONG2
RESULT_MAHJONG2
UPDATE_POT_MAHJONG2
BIG_WIN_MAHJONG2
AUTO_PLAY_MAHJONG2
STOP_AUTO_PLAY_MAHJONG2
FORCE_STOP_AUTO_MAHJONG2
MINIMIZE_MAHJONG2
MINIMIZE_RESULT_MAHJONG2
UNSUBSCRIBE_MAHJONG2
```

---

# 3. Init game config cho frontend

Khi frontend subscribe hoặc nhận info, backend nên trả:

```json
{
  "cmd": "TBD_INFO_MAHJONG2",
  "room": {
    "roomId": 1,
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "totalBet": 450,
    "pot": 1200000
  },
  "gameConfig": {
    "gameCode": "MAHJONG2",
    "reelCount": 5,
    "reelRows": [4, 5, 5, 5, 4],
    "totalWays": 2000,
    "minMatchedReels": 3,
    "winDirection": "LEFT_TO_RIGHT",
    "hasCascade": true,
    "hasGoldenSymbol": true,
    "hasFreeSpin": true
  },
  "symbols": [
    {
      "code": "WILD",
      "type": "SPECIAL",
      "role": "WILD",
      "assetKey": "wild",
      "canBeGolden": false,
      "payable": false
    },
    {
      "code": "SCATTER",
      "type": "SPECIAL",
      "role": "SCATTER",
      "assetKey": "scatter",
      "canBeGolden": false,
      "payable": false
    },
    {
      "code": "ITEM_1",
      "type": "NORMAL",
      "role": "PAYABLE",
      "assetKey": "item_1",
      "canBeGolden": true,
      "payable": true
    }
  ],
  "goldenRule": {
    "enabled": true,
    "allowedReels": [1, 2, 3],
    "excludedSymbols": ["WILD", "SCATTER"],
    "transformTo": "WILD",
    "transformCondition": "PARTICIPATED_IN_PREVIOUS_WIN"
  },
  "multipliers": {
    "BASE": {
      "1": 1,
      "2": 2,
      "3": 3,
      "4+": 5
    },
    "FREE_SPIN": {
      "1": 2,
      "2": 4,
      "3": 6,
      "4+": 10
    }
  },
  "freeSpinRule": {
    "triggerSymbol": "SCATTER",
    "minScatter": 3,
    "baseFreeSpin": 10,
    "extraSpinPerAdditionalScatter": 2,
    "retrigger": true
  },
  "playerState": {
    "balance": 1000000,
    "mode": "BASE",
    "remainingFreeSpin": 0
  }
}
```

Frontend dùng config này để:

```text
render layout
map asset
render multiplier UI
render free spin rules
render golden overlay
```

---

# 4. Frontend không dùng matrix 4x5

Frontend phải render theo:

```text
reels[reelIndex][rowIndex]
```

Vì layout là:

```text
[4, 5, 5, 5, 4]
```

Ví dụ:

```json
"reels": [
  [
    { "symbol": "ITEM_1", "golden": false },
    { "symbol": "ITEM_2", "golden": false },
    { "symbol": "SCATTER", "golden": false },
    { "symbol": "ITEM_3", "golden": false }
  ],
  [
    { "symbol": "ITEM_1", "golden": true },
    { "symbol": "WILD", "golden": false },
    { "symbol": "ITEM_2", "golden": false },
    { "symbol": "ITEM_4", "golden": true },
    { "symbol": "ITEM_5", "golden": false }
  ],
  [
    { "symbol": "ITEM_1", "golden": false },
    { "symbol": "ITEM_3", "golden": true },
    { "symbol": "ITEM_4", "golden": false },
    { "symbol": "ITEM_5", "golden": false },
    { "symbol": "ITEM_6", "golden": false }
  ],
  [
    { "symbol": "ITEM_1", "golden": false },
    { "symbol": "ITEM_2", "golden": true },
    { "symbol": "ITEM_3", "golden": false },
    { "symbol": "ITEM_4", "golden": false },
    { "symbol": "ITEM_5", "golden": false }
  ],
  [
    { "symbol": "ITEM_2", "golden": false },
    { "symbol": "ITEM_3", "golden": false },
    { "symbol": "ITEM_4", "golden": false },
    { "symbol": "ITEM_5", "golden": false }
  ]
]
```

---

# 5. PLAY request

```json
{
  "cmd": "TBD_PLAY_MAHJONG2",
  "betSize": 2.5,
  "betLevel": 9,
  "baseBet": 20,
  "turbo": false
}
```

Formula:

```text
totalBet = betSize × betLevel × baseBet
```

---

# 6. RESULT payload chuẩn

```json
{
  "cmd": "TBD_RESULT_MAHJONG2",
  "spinId": "SPIN_10001",

  "reels": [],

  "cascadeSteps": [],

  "totalWin": 4800,
  "balance": 1050000,

  "bet": {
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "totalBet": 450
  },

  "freeSpin": {
    "triggered": false,
    "awarded": 0,
    "remaining": 0,
    "retriggered": false,
    "scatterCount": 0
  },

  "jackpot": {
    "triggered": false,
    "type": null,
    "amount": 0
  },

  "state": {
    "mode": "BASE",
    "pot": 1200000,
    "bigWin": false,
    "turbo": false
  }
}
```

---

# 7. Cascade step payload

```json
{
  "step": 1,
  "mode": "BASE",
  "multiplier": 1,
  "reelsBefore": [],
  "wins": [],
  "removedPositions": [],
  "goldenTransforms": [],
  "reelsAfterDrop": [],
  "stepWin": 1200
}
```

Frontend render sequence:

```text
render reelsBefore
highlight wins.positions
show multiplier
show stepWin
explode removedPositions
animate goldenTransforms
animate drop to reelsAfterDrop
next cascade step
```

---

# 8. Win object

```json
{
  "symbol": "ITEM_1",
  "matchedReels": 4,
  "ways": 8,
  "payRate": 0.2,
  "multiplier": 2,
  "winAmount": 3200,
  "positions": [
    { "reel": 0, "row": 0 },
    { "reel": 1, "row": 0 },
    { "reel": 1, "row": 3 },
    { "reel": 2, "row": 1 }
  ]
}
```

Frontend dùng `positions` để highlight symbol thắng.

---

# 9. Removed positions

```json
"removedPositions": [
  { "reel": 0, "row": 0 },
  { "reel": 1, "row": 0 },
  { "reel": 1, "row": 3 },
  { "reel": 2, "row": 1 }
]
```

Frontend dùng để:

```text
explode
remove symbol
drop animation
```

---

# 10. Golden transform

```json
"goldenTransforms": [
  {
    "position": { "reel": 2, "row": 1 },
    "from": {
      "symbol": "ITEM_3",
      "golden": true
    },
    "to": {
      "symbol": "WILD",
      "golden": false
    }
  }
]
```

Frontend animate:

```text
Golden ITEM_3 → WILD
```

---

# 11. Free Spin response

```json
"freeSpin": {
  "triggered": true,
  "awarded": 10,
  "remaining": 10,
  "retriggered": false,
  "scatterCount": 3
}
```

Nếu đang Free Spin:

```json
"state": {
  "mode": "FREE_SPIN"
}
```

Frontend hiển thị:

```text
Free Spin intro
remaining free spin
Free Spin multiplier UI
retrigger nếu có
```

---

# 12. Jackpot response

Jackpot là system reward, không nhất thiết là reel symbol.

```json
"jackpot": {
  "triggered": false,
  "type": null,
  "amount": 0
}
```

Nếu nổ:

```json
"jackpot": {
  "triggered": true,
  "type": "NORMAL",
  "amount": 5000000
}
```

Frontend không tự giả định có `JP` symbol trên reels.

---

# 13. Frontend render flow

```text
Receive RESULT_MAHJONG2
↓
Render initial reels layout 4-5-5-5-4
↓
For each cascadeStep:
    render reelsBefore
    highlight wins[].positions
    display multiplier
    display stepWin
    explode removedPositions
    animate goldenTransforms
    animate drop to reelsAfterDrop
↓
Update totalWin
↓
Update balance
↓
Update pot
↓
If freeSpin.triggered:
    show free spin intro
↓
If state.mode = FREE_SPIN:
    show remaining free spins
↓
If jackpot.triggered:
    show jackpot animation
↓
Ready next spin / autoplay next spin
```

---

# 14. Những thứ frontend không được tự giả định

Frontend không tự giả định:

```text
matrix 4x5 đều
1024 ways
BONUS symbol
JP symbol trên reels
multiplier luôn x1
một spin chỉ có một win result
free spin luôn chỉ 10 không cộng thêm
golden là item riêng
```

Frontend phải đọc từ response/config:

```text
reels
gameConfig.reelRows
cascadeSteps
removedPositions
goldenTransforms
freeSpin
state.mode
multiplier
symbols[]
```

---

# C. Bản chốt cuối cùng

## Backend chốt

```text
Mahjong2 implement mới.
Không dùng Lines.
Không dùng matrix 4x5 đều.
Dùng reels layout 4-5-5-5-4.
Dùng WaysEngine.
Dùng CascadeEngine.
Dùng GoldenTransform.
Dùng FreeSpinState.
Reuse jackpot/economy cũ.
Command ID = TBD cho đến khi thêm vào SlotCMD.java.
```

## Frontend chốt

```text
Reuse socket cũ.
Reuse numeric command cũ.
Render dynamic reels 4-5-5-5-4.
Không dùng linesWin.
Dùng cascadeSteps để chạy animation.
Dùng removedPositions để explode.
Dùng goldenTransforms để animate Golden → Wild.
Dùng freeSpin object để hiển thị state.
Không tự giả định BONUS / JP symbol.
```
