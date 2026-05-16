Dưới đây là bản tài liệu chuẩn cho **Mahjong Ways 1 / Đường Mạt Chược**, tách riêng **Backend** và **Frontend**. Bản này **không dùng rule của Mahjong Ways 2**.

---

# Mahjong Ways 1 — Backend & Frontend Specification

## 0. Phạm vi tài liệu

Tài liệu này áp dụng cho game:

```text
Đường Mạt Chược / Mahjong Ways 1
```

Không áp dụng cho:

```text
Đường Mạt Chược 2 / Mahjong Ways 2
```

Khác biệt lớn nhất:

| Game           |    Layout |      Ways | Free Spin gốc |
| -------------- | --------: | --------: | ------------: |
| Mahjong Ways 1 | 4-4-4-4-4 | 1024 ways | 12 free spins |
| Mahjong Ways 2 | 4-5-5-5-4 | 2000 ways | 10 free spins |

---

# A. Backend Technical Specification

---

# 1. Game overview

Mahjong Ways 1 là game slot:

```text
5 reels
4 rows mỗi reel
1024 ways
có cascade
có multiplier tăng dần
có Golden Symbol
có Golden → Wild transform
có Free Spin
Wild thay thế symbol thường, trừ Scatter
```

Backend nên reuse:

```text
socket architecture cũ
numeric command convention cũ
room/module flow cũ
wallet / fund / pot / jackpot flow cũ
transaction / spin history flow cũ
```

---

# 2. Board layout

Mahjong Ways 1 dùng board đều:

```text
5 reels × 4 rows
```

Tức là:

| Reel   | Row count |
| ------ | --------: |
| Reel 1 |         4 |
| Reel 2 |         4 |
| Reel 3 |         4 |
| Reel 4 |         4 |
| Reel 5 |         4 |

Backend có thể lưu dạng:

```java
List<List<MahjongWaysCell>> reels;
```

Config:

```java
public class MahjongWaysConfig {

    public static final int REEL_COUNT = 5;

    public static final List<Integer> REEL_ROWS = List.of(
            4, 4, 4, 4, 4
    );

    public static final int TOTAL_WAYS = 1024;

    public static final int BASE_BET = 20;

    public static final int MIN_MATCHED_REELS = 3;

    public static final List<Integer> GOLDEN_ALLOWED_REELS = List.of(
            1, 2, 3
    );
    // index 1,2,3 = reel 2,3,4

    public static final String MODE_BASE = "BASE";
    public static final String MODE_FREE_SPIN = "FREE_SPIN";
}
```

Tổng ways:

```text
4 × 4 × 4 × 4 × 4 = 1024
```

---

# 3. Symbol design

Theo hình luật Mahjong Ways 1, các symbol chắc chắn cần có:

| Symbol            | Vai trò                              |
| ----------------- | ------------------------------------ |
| `WILD`            | thay thế symbol thường, trừ Scatter  |
| `SCATTER`         | kích hoạt Free Spin                  |
| `ITEM_1...ITEM_N` | symbol thường trả thưởng             |
| `golden: true`    | trạng thái mạ vàng của symbol thường |

Không nên định nghĩa chính thức:

```text
BONUS
JACKPOT / JP symbol trên reels
```

Lý do: trong hình luật Mahjong Ways 1 chưa thấy rule xác nhận Bonus symbol hoặc JP symbol trên reels.

Jackpot nếu có thì nằm ở tầng **system/economy**, không đồng nghĩa có JP symbol trên board.

---

## 3.1. Symbol enum gợi ý

```java
public enum MahjongWaysSymbol {

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

    MahjongWaysSymbol(
            int id,
            String code,
            boolean scatter,
            boolean wild,
            boolean payable
    ) {
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

`ITEM_1...ITEM_7` là placeholder. Khi có asset/paytable thật thì đổi sang symbol code thật.

---

# 4. Cell / Board structure

## 4.1. Cell

```java
public class MahjongWaysCell {

    private MahjongWaysSymbol symbol;

    private final int reelIndex;

    private final int rowIndex;

    private boolean golden;

    public MahjongWaysCell(
            MahjongWaysSymbol symbol,
            int reelIndex,
            int rowIndex,
            boolean golden
    ) {
        this.symbol = symbol;
        this.reelIndex = reelIndex;
        this.rowIndex = rowIndex;
        this.golden = golden;
    }

    public MahjongWaysSymbol getSymbol() {
        return symbol;
    }

    public void setSymbol(MahjongWaysSymbol symbol) {
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

## 4.2. Position

```java
public record MahjongWaysPosition(
        int reel,
        int row
) {
}
```

## 4.3. Board

```java
public class MahjongWaysBoard {

    private final List<List<MahjongWaysCell>> reels;

    public MahjongWaysBoard(List<List<MahjongWaysCell>> reels) {
        this.reels = reels;
    }

    public List<List<MahjongWaysCell>> getReels() {
        return reels;
    }

    public List<MahjongWaysCell> getReel(int reelIndex) {
        return reels.get(reelIndex);
    }

    public MahjongWaysCell getCell(int reelIndex, int rowIndex) {
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

# 5. Bet rule

Theo hình luật Mahjong Ways 1:

```text
20 cược cơ sở
mức cược 1 đến 10
chip cược 0.02 đến 2.50
```

Backend nên tách:

```text
betSize = kích cỡ cược / chip cược
betLevel = mức cược
baseBet = 20
```

Công thức tổng cược:

```text
totalBet = betSize × betLevel × baseBet
```

Ví dụ:

```text
betSize = 2.50
betLevel = 9
baseBet = 20

totalBet = 2.50 × 9 × 20 = 450
```

---

# 6. Economy / Jackpot reuse

Sau khi tính `totalBet`, hệ thống cũ chia tiền cược thành:

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

Tài liệu jackpot cũ đã mô tả rõ phần chia cược thành fee, jackpot pot và fund theo tỷ lệ 2% / 1% / 97%. 

Jackpot system cũ có thể reuse:

```text
jackpotAllowed = fund > 2 × initPotValue
jackpotPrize = pot hoặc 2 × pot
pot = initPotValue sau khi nổ
fundCost = totalPrizes - soTienNoHuKhongTruQuy
fund - fundCost >= 0
```

Tài liệu jackpot cũng mô tả điều kiện nổ hũ, jackpot thường, jackpot X2, reset pot và safety check chống âm quỹ. 

---

# 7. Weighted random

Backend không random đều.

Mỗi symbol có weight riêng:

```text
P(symbol) = weightOfSymbol / totalWeight
```

Weight cụ thể chưa có, nên để config:

```java
public class MahjongWaysWeightTable {

    private final Map<MahjongWaysSymbol, Integer> weights;

    public MahjongWaysWeightTable(Map<MahjongWaysSymbol, Integer> weights) {
        this.weights = new EnumMap<>(MahjongWaysSymbol.class);
        this.weights.putAll(weights);
    }

    public Map<MahjongWaysSymbol, Integer> getWeights() {
        return weights;
    }
}
```

Tài liệu full-flow cũng xác nhận random engine dùng symbol weight, không random đều. 

---

# 8. Golden Symbol rule

Golden Symbol là trạng thái của symbol thường.

```text
Golden chỉ xuất hiện ở reel 2, 3, 4.
Golden không áp dụng cho Wild và Scatter.
```

Nếu index từ 0:

```text
reel 2,3,4 = index 1,2,3
```

Random golden:

```java
public boolean randomGolden(
        int reelIndex,
        MahjongWaysSymbol symbol
) {
    if (!symbol.canBeGolden()) {
        return false;
    }

    if (!MahjongWaysConfig.GOLDEN_ALLOWED_REELS.contains(reelIndex)) {
        return false;
    }

    // TODO: replace with config goldenRate
    return ThreadLocalRandom.current().nextInt(100) < 5;
}
```

---

# 9. Golden → Wild transform rule

Theo hình luật:

```text
Ở mỗi vòng chơi sau khi symbol mới rơi xuống,
bất kỳ Golden Symbol nào tham gia chiến thắng ở vòng trước
sẽ chuyển thành Wild.
```

Điểm cần implement cẩn thận:

```text
Golden winning symbol không nên xử lý như symbol thắng thường bị remove ngay.
Nó cần được giữ lại / đánh dấu transform để cascade sau chuyển thành WILD.
```

Backend nên tách:

```text
removedPositions = winning positions không phải golden transform
goldenTransforms = winning golden positions chuyển thành WILD
```

Gợi ý:

```java
List<MahjongWaysGoldenTransform> collectGoldenTransforms(
        MahjongWaysBoard board,
        Set<MahjongWaysPosition> winPositions
) {
    List<MahjongWaysGoldenTransform> transforms = new ArrayList<>();

    for (MahjongWaysPosition pos : winPositions) {
        MahjongWaysCell cell = board.getCell(pos.reel(), pos.row());

        if (cell.isGolden() && cell.getSymbol().isPayable()) {
            transforms.add(new MahjongWaysGoldenTransform(
                    pos,
                    cell.getSymbol(),
                    MahjongWaysSymbol.WILD
            ));
        }
    }

    return transforms;
}
```

Khi apply:

```java
void applyGoldenTransforms(
        MahjongWaysBoard board,
        List<MahjongWaysGoldenTransform> transforms
) {
    for (MahjongWaysGoldenTransform transform : transforms) {
        MahjongWaysCell cell = board.getCell(
                transform.getPosition().reel(),
                transform.getPosition().row()
        );

        cell.setSymbol(MahjongWaysSymbol.WILD);
        cell.setGolden(false);
    }
}
```

---

# 10. Ways rule

Mahjong Ways 1 không dùng paylines.

Win condition:

```text
Symbol thắng xuất hiện từ reel trái sang phải.
Tối thiểu 3 reels liên tiếp.
```

Wild rule:

```text
Wild thay thế symbol thường.
Wild không thay Scatter.
```

Ways formula:

```text
ways = countReel1 × countReel2 × countReel3 × ...
```

Tài liệu full-flow xác nhận ways system tính bằng phép nhân số symbol xuất hiện trên từng reel. 

---

# 11. Payout rule

Trong hình luật Mahjong Ways 1 có 2 câu quan trọng:

```text
Tiền thắng theo đường cược = giá trị trên Bảng Trả Thưởng × Kích Cỡ Cược × Mức Cược.
Tiền trả thưởng symbol thắng sẽ được nhân với số đường cược thắng.
```

Vì vậy backend nên dùng:

```text
lineBet = betSize × betLevel
winAmount = payTableValue × lineBet × ways × multiplier
```

Không nên dùng trực tiếp:

```text
totalBet × payRate × ways
```

trừ khi paytable đã được thiết kế theo total bet.

Công thức chuẩn theo luật hình:

```text
winAmount = payTableValue × betSize × betLevel × ways × multiplier
```

Tài liệu full-flow có công thức tổng quát `Win = Bet × Paytable × Ways × Multiplier`; với Mahjong Ways 1, `Bet` trong payout nên hiểu là `betSize × betLevel`. 

---

# 12. Multiplier rule

## Base Game

| Cascade Step | Multiplier |
| -----------: | ---------: |
|       Step 1 |         x1 |
|       Step 2 |         x2 |
|       Step 3 |         x3 |
|      Step 4+ |         x5 |

Rule:

```text
Nếu cascade hiện tại có win,
cascade tiếp theo tăng multiplier theo bảng.
```

## Free Spin

| Cascade Step | Multiplier |
| -----------: | ---------: |
|       Step 1 |         x2 |
|       Step 2 |         x4 |
|       Step 3 |         x6 |
|      Step 4+ |        x10 |

Tài liệu full-flow cũng mô tả multiplier tăng theo cascade và cascade càng kéo dài thì payout càng mạnh. 

Code:

```java
public static int getMultiplier(String mode, int cascadeStep) {
    int step = Math.min(cascadeStep, 4);

    if ("FREE_SPIN".equals(mode)) {
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
```

---

# 13. Cascade rule

Flow cascade:

```text
Calculate ways win
↓
If no win → stop
↓
Collect winning positions
↓
Collect goldenTransforms
↓
Remove normal winning symbols
↓
Apply goldenTransforms → WILD
↓
Drop symbols
↓
Fill new symbols
↓
Increase multiplier
↓
Recalculate
```

Tài liệu full-flow mô tả cascade là `Win → Remove Symbols → Drop New Symbols → Recalculate Win`. 

Response backend nên lưu từng step:

```java
public class MahjongWaysCascadeStep {

    private int step;
    private String mode;
    private int multiplier;

    private MahjongWaysBoard reelsBefore;

    private List<MahjongWaysWin> wins;

    private Set<MahjongWaysPosition> removedPositions;

    private List<MahjongWaysGoldenTransform> goldenTransforms;

    private MahjongWaysBoard reelsAfterDrop;

    private BigDecimal stepWin;
}
```

---

# 14. Free Spin rule

Theo hình Mahjong Ways 1:

```text
3 Scatter = 12 free spins
mỗi Scatter bổ sung = +2 free spins
Free Spin có thể retrigger
```

Công thức:

```text
freeSpinAwarded = 12 + (scatterCount - 3) × 2
```

Bảng:

| Scatter Count | Free Spins |
| ------------: | ---------: |
|             3 |         12 |
|             4 |         14 |
|             5 |         16 |

Code:

```java
public static int calculateFreeSpinAwarded(int scatterCount) {
    if (scatterCount < 3) {
        return 0;
    }

    return 12 + (scatterCount - 3) * 2;
}
```

Lưu ý:

```text
Trong ảnh Mahjong Ways 1 hiện tại chưa thấy rule “reel 3 luôn golden trong Free Spin”.
Rule đó thuộc Mahjong Ways 2, không đưa vào Mahjong Ways 1 nếu chưa có ảnh/source xác nhận.
```

---

# 15. Backend full spin flow

```text
PLAY_MAHJONG_WAYS
↓
Get room
↓
Get mode: BASE / FREE_SPIN
↓
Calculate:
    lineBet = betSize × betLevel
    totalBet = lineBet × baseBet(20)
↓
Validate balance
↓
If BASE:
    debit totalBet
    split fee / pot / fund
    update pot / fund
↓
Generate initial board 5x4
↓
Process cascade:
    calculate ways
    apply multiplier
    calculate payout
    collect removedPositions
    collect goldenTransforms
    remove normal win symbols
    transform golden winners to Wild
    drop symbols
    fill symbols
    repeat until no win
↓
Sum all stepWin = regularWin
↓
Count Scatter
↓
If Scatter >= 3:
    award free spins = 12 + (scatterCount - 3) × 2
↓
Check jackpot system cũ nếu game room bật jackpot
↓
Safety check fund
↓
Credit reward
↓
Save transaction
↓
Save spin history
↓
Return RESULT
```

---

# B. Mahjong Ways 1 — Frontend Integration Specification

---

# 1. Frontend overview

Frontend cần render:

```text
5 reels
4 rows mỗi reel
1024 ways
cascade animation
golden overlay
golden → wild transform
free spin state
multiplier per cascade step
```

Không dùng layout của Mahjong Ways 2:

```text
4-5-5-5-4
2000 ways
```

---

# 2. Init game config

Khi `SUBSCRIBE` hoặc `INFO`, backend nên trả:

```json
{
  "cmd": "TBD_INFO_MAHJONG_WAYS",
  "room": {
    "roomId": 1,
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450,
    "pot": 1200000
  },
  "gameConfig": {
    "gameCode": "MAHJONG_WAYS",
    "reelCount": 5,
    "reelRows": [4, 4, 4, 4, 4],
    "totalWays": 1024,
    "minMatchedReels": 3,
    "winDirection": "LEFT_TO_RIGHT",
    "hasCascade": true,
    "hasGoldenSymbol": true,
    "hasFreeSpin": true
  },
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
    "baseFreeSpin": 12,
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

---

# 3. Symbol init

```json
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
]
```

Không tự giả định:

```text
BONUS
JP / JACKPOT symbol
```

nếu backend không trả.

---

# 4. Board response

Frontend nhận reels dạng:

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
    { "symbol": "ITEM_4", "golden": true }
  ],
  [
    { "symbol": "ITEM_1", "golden": false },
    { "symbol": "ITEM_3", "golden": true },
    { "symbol": "ITEM_4", "golden": false },
    { "symbol": "ITEM_5", "golden": false }
  ],
  [
    { "symbol": "ITEM_1", "golden": false },
    { "symbol": "ITEM_2", "golden": true },
    { "symbol": "ITEM_3", "golden": false },
    { "symbol": "ITEM_4", "golden": false }
  ],
  [
    { "symbol": "ITEM_2", "golden": false },
    { "symbol": "ITEM_3", "golden": false },
    { "symbol": "ITEM_4", "golden": false },
    { "symbol": "ITEM_5", "golden": false }
  ]
]
```

Vì Mahjong Ways 1 là board đều 4x5 nên frontend có thể render grid 4 rows × 5 reels, nhưng vẫn nên giữ format `reels[reel][row]` để thống nhất với các game ways khác.

---

# 5. Play request

```json
{
  "cmd": "TBD_PLAY_MAHJONG_WAYS",
  "betSize": 2.5,
  "betLevel": 9,
  "baseBet": 20,
  "turbo": false
}
```

Frontend có thể hiển thị:

```text
lineBet = betSize × betLevel
totalBet = lineBet × baseBet
```

---

# 6. Result response

```json
{
  "cmd": "TBD_RESULT_MAHJONG_WAYS",
  "spinId": "SPIN_10001",

  "reels": [],

  "cascadeSteps": [],

  "totalWin": 4800,
  "balance": 1050000,

  "bet": {
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
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

# 7. Cascade step response

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

Frontend render:

```text
render reelsBefore
highlight wins[].positions
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
  "payTableValue": 10,
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

---

# 9. Golden transform response

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

# 10. Free Spin response

```json
"freeSpin": {
  "triggered": true,
  "awarded": 12,
  "remaining": 12,
  "retriggered": false,
  "scatterCount": 3
}
```

Nếu 4 Scatter:

```json
"freeSpin": {
  "triggered": true,
  "awarded": 14,
  "remaining": 14,
  "retriggered": false,
  "scatterCount": 4
}
```

Frontend cần hiển thị:

```text
Free Spin intro
12 free spins hoặc nhiều hơn nếu có extra Scatter
remaining free spins
retrigger nếu có
free spin multiplier x2/x4/x6/x10
```

---

# 11. Frontend render flow

```text
Receive RESULT_MAHJONG_WAYS
↓
Render reels 5x4
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

# 12. Những thứ frontend không được tự giả định

Frontend không tự giả định:

```text
Mahjong Ways 1 là 2000 ways
layout 4-5-5-5-4
Free Spin gốc là 10
Có reel 3 golden trong Free Spin
Có BONUS symbol
Có JP symbol trên reels
Golden là symbol riêng
Một spin chỉ có một win result
```

Frontend phải đọc từ config/response:

```text
gameConfig.reelRows
gameConfig.totalWays
symbols[]
cascadeSteps
goldenTransforms
freeSpin
state.mode
multipliers
```

---

# C. Chốt cuối

## Mahjong Ways 1 backend

```text
Board = 5 reels × 4 rows
Ways = 1024
Free Spin gốc = 12
Extra Scatter = +2 spins
Golden reels = 2,3,4
Golden winning symbol → Wild
Base multiplier = x1,x2,x3,x5
Free Spin multiplier = x2,x4,x6,x10
Payout = payTableValue × betSize × betLevel × ways × multiplier
Economy/jackpot reuse system cũ
```

## Mahjong Ways 1 frontend

```text
Render 5x4 reels
Display 1024 ways
Use cascadeSteps
Use removedPositions
Use goldenTransforms
Use freeSpin state
Do not assume BONUS/JP symbol
Do not use Mahjong Ways 2 layout/rules
```
