Mong muốn của Hy là:

```txt
Frontend không muốn tự đoán animation từ reels/reelsBefore/reelsAfterDrop nữa.
Frontend muốn backend trả dữ liệu animation đã “diễn sẵn logic” để FE chỉ việc render.
```

Cụ thể Hy muốn 5 ý chính:

**1. Bỏ `reels`, `reelsBefore`, `reelsAfterDrop` khỏi response cho FE**

Những field này chỉ giữ nội bộ backend để tính toán, lưu history/debug. FE chỉ dùng:

```txt
animationReels
cascadeSteps[].animationReelsBeforeDrop
cascadeSteps[].animationColumns
cascadeSteps[].animationReelsAfterDrop
```

**2. Mỗi item trong `animationReels` phải có `golden`**

Hiện response cũ có nhiều item trong `animationReels` chỉ có:

```json
{ "symbol": "ITEM_7", "displayOnly": false }
```

Hy muốn phải có:

```json
{ "symbol": "ITEM_7", "golden": false, "displayOnly": false }
```

để FE biết item nào là golden mà render đúng.

**3. Drop map phải theo từng cột**

Hy nói:

```txt
animationDropMap chưa theo cột
```

Nghĩa là không muốn một list phẳng toàn board. Hy muốn mỗi cột có dữ liệu riêng:

```json
{
  "col": 0,
  "before": ["ITEM_5", "ITEM_5", "ITEM_2", "ITEM_5", "ITEM_7", "ITEM_7"],
  "removed": [],
  "moves": [],
  "newSymbols": [],
  "after": ["ITEM_5", "ITEM_5", "ITEM_2", "ITEM_5", "ITEM_7", "ITEM_1"]
}
```

**4. Item mới phải append đúng chiều, không bị chèn ngược đầu mảng**

Case Hy nói rõ:

```txt
Before cột 1:
5,5,2,5,7,7

Remove ITEM_7 thứ 1:
5,5,2,5,_,7

ITEM_7 còn lại dồn lên:
5,5,2,5,7,_

Item mới ITEM_1 vào cuối:
5,5,2,5,7,1
```

Nhưng response cũ đang ra kiểu:

```txt
1,1,5,2,5,5
```

nên Hy thấy **mảng bị ngược và item bị thay sai**. Trong file cũ, step 3 đúng là có case cột 1 trước/sau đang bị lệch như vậy. 

**5. Golden không phải do drop gom thành**

Hy muốn hiểu rõ `goldenTransforms`.

Câu đúng là:

```txt
Golden là trạng thái có sẵn của item.
Nếu golden item tham gia win thì nó không bị remove, mà transform thành WILD.
Không phải item drop xuống rồi gom thành golden.
```

Ví dụ field đúng:

```json
"visualGoldenTransforms": [
  {
    "cellId": "s4-c2-r2",
    "fromSymbol": "ITEM_5",
    "toSymbol": "WILD",
    "fromGolden": true,
    "toGolden": false,
    "from": { "col": 2, "row": 2 },
    "to": { "col": 2, "row": 2 }
  }
]
```

Tóm lại, Hy muốn:

```txt
Backend trả response theo đúng logic animation FE nhìn thấy:

- chỉ dùng animationReels
- mỗi item có golden
- drop map group theo cột
- remove xong thì item phía sau dồn lên
- item mới append vào cuối cột
- afterDrop của step này phải bằng beforeDrop của step sau
- golden thắng thì transform thành WILD, không phải bị remove/drop
```

Bản `4001.md` trước đó đã đi đúng hướng bỏ field math và thêm animation fields, nhưng vẫn chưa đúng hoàn toàn vì `animationDropMap` chưa group theo cột và item mới vẫn chưa theo đúng chiều Hy mong muốn. 
