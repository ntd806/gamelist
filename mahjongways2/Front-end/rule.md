# Luật chơi Mahjong Ways 2 / Đường Mạt Chược 2

## 1. Tổng quan

Mahjong Ways 2 là game video slot gồm:

```text
5 guồng quay
4 hàng chính
có 1 hàng bổ sung cho guồng 2, 3 và 4
tổng cộng 2,000 ways cố định
```

Layout guồng:

| Guồng  | Số hàng |
| ------ | ------: |
| Reel 1 |       4 |
| Reel 2 |       5 |
| Reel 3 |       5 |
| Reel 4 |       5 |
| Reel 5 |       4 |

Công thức ways:

```text
4 × 5 × 5 × 5 × 4 = 2,000 ways
```

---

# 2. Cược

Game có:

```text
20 cược cơ sở
mức cược từ 1 đến 10
lượng chip cược từ 0.02 đến 2.50
```

Các thành phần cược:

| Thành phần   | Ý nghĩa            |
| ------------ | ------------------ |
| Kích Cỡ Cược | giá trị chip cược  |
| Mức Cược     | cấp độ cược        |
| Cược Cơ Sở   | cố định 20         |
| Số Tiền Cược | tổng tiền đặt cược |

Công thức:

```text
Số Tiền Cược = Kích Cỡ Cược × Mức Cược × Cược Cơ Sở
```

Ví dụ:

```text
2.50 × 9 × 20 = 450
```

---

# 3. Cách thắng

Game không dùng paylines kiểu cũ.

Game dùng:

```text
2,000 ways
```

Một tổ hợp thắng được tính khi:

```text
các biểu tượng thắng xuất hiện liên tiếp từ guồng ngoài cùng bên trái sang phải
```

Tối thiểu cần:

```text
ít nhất 3 guồng liên tiếp
```

Ví dụ:

| Guồng  | Số biểu tượng ITEM_1 |
| ------ | -------------------: |
| Reel 1 |                    2 |
| Reel 2 |                    3 |
| Reel 3 |                    1 |
| Reel 4 |                    0 |

Kết quả:

```text
ways = 2 × 3 × 1 = 6 ways
```

Nếu có nhiều biểu tượng thắng khác nhau trong cùng một vòng, các chiến thắng sẽ được cộng dồn.

---

# 4. Cách tính tiền thắng

Tiền thắng theo symbol được tính dựa trên:

```text
giá trị trong Bảng Trả Thưởng
× Kích Cỡ Cược
× Mức Cược
× số ways thắng
× multiplier
```

Công thức:

```text
Win Amount = PaytableValue × BetSize × BetLevel × Ways × Multiplier
```

Lưu ý:

```text
Cược Cơ Sở dùng để tính tổng tiền cược.
Còn payout theo từng symbol dùng giá trị bảng trả thưởng × kích cỡ cược × mức cược.
```

---

# 5. Wild

Biểu tượng Wild có chức năng:

```text
thay thế cho tất cả biểu tượng thường
```

Ngoại trừ:

```text
Wild không thay thế Scatter
```

Wild giúp tạo hoặc kéo dài tổ hợp thắng trong ways.

---

# 6. Scatter

Scatter dùng để kích hoạt Free Spin.

Rule:

```text
3 Scatter xuất hiện ở mọi vị trí sẽ kích hoạt 10 vòng quay miễn phí
mỗi Scatter bổ sung sẽ cộng thêm 2 vòng quay miễn phí
```

Bảng Free Spin:

| Scatter | Free Spins |
| ------: | ---------: |
|       3 |         10 |
|       4 |         12 |
|       5 |         14 |

Free Spin có thể được tái kích hoạt.

---

# 7. Cascade / thắng liên hoàn

Sau khi trả thưởng mỗi vòng chơi:

```text
tất cả biểu tượng thắng sẽ phát nổ / biến mất
các biểu tượng phía trên sẽ rơi xuống
biểu tượng mới được thêm vào
sau đó game kiểm tra tiếp tổ hợp thắng mới
```

Flow:

```text
Tính thắng
↓
Trả thưởng
↓
Xóa biểu tượng thắng
↓
Biểu tượng phía trên rơi xuống
↓
Thêm biểu tượng mới
↓
Tính thắng tiếp
↓
Lặp lại cho đến khi không còn tổ hợp thắng
```

Các chiến thắng cascade sẽ được cộng dồn vào tổng thắng của spin.

---

# 8. Multiplier trong game thường

Trong vòng quay thường, multiplier tăng theo chuỗi cascade thắng liên tiếp:

|                Cascade | Multiplier |
| ---------------------: | ---------: |
|          Lần thắng đầu |         x1 |
|        Lần thắng thứ 2 |         x2 |
|        Lần thắng thứ 3 |         x3 |
| Lần thắng thứ 4 trở đi |         x5 |

Điều kiện tăng multiplier:

```text
cascade hiện tại có thắng
→ biểu tượng thắng biến mất
→ biểu tượng mới rơi xuống
→ nếu tiếp tục có thắng ở cascade sau
→ multiplier tăng
```

---

# 9. Multiplier trong Free Spin

Trong Free Spin, multiplier cao hơn:

|                Cascade | Multiplier |
| ---------------------: | ---------: |
|          Lần thắng đầu |         x2 |
|        Lần thắng thứ 2 |         x4 |
|        Lần thắng thứ 3 |         x6 |
| Lần thắng thứ 4 trở đi |        x10 |

---

# 10. Golden Symbol / Biểu tượng Mạ Vàng

Golden Symbol là trạng thái mạ vàng của biểu tượng thường.

Golden Symbol:

```text
chỉ xuất hiện trên guồng 2, 3 và 4
```

Không áp dụng cho:

```text
Wild
Scatter
```

Trong bất kỳ vòng quay nào:

```text
một số biểu tượng thường trên guồng 2, 3 và/hoặc 4 có thể xuất hiện dưới dạng vàng
```

---

# 11. Golden chuyển thành Wild

Rule quan trọng:

```text
Ở mỗi vòng chơi mới sau khi biểu tượng mới rơi xuống,
bất kỳ biểu tượng mạ vàng nào đã tham gia vào chiến thắng ở vòng trước
sẽ được chuyển hóa thành Wild
```

Nói đơn giản:

```text
Golden symbol nằm trong tổ hợp thắng
→ cascade sau chuyển thành Wild
```

Không phải tất cả Golden đều chuyển thành Wild. Chỉ Golden nào tham gia thắng mới được chuyển.

---

# 12. Golden trong Free Spin

Trong Free Spin của Mahjong Ways 2:

```text
tất cả biểu tượng trên guồng 3
ngoại trừ Wild và Scatter
sẽ xuất hiện bằng vàng
```

Nếu backend/frontend dùng index từ 0:

```text
guồng 3 = reelIndex 2
```

---

# 13. Vòng quay tự động

Quay Tự Động sẽ tự động chơi theo số vòng đã chọn.

Có thể dừng Quay Tự Động bằng nút dừng.

---

# 14. Quay nhanh / Turbo

Quay Nhanh dùng để rút ngắn thời gian quay của các guồng trong ván chơi chính.

Frontend có thể dùng trạng thái:

```text
turbo = true / false
```

để bật hoặc tắt hiệu ứng quay nhanh.

---

# 15. Lịch sử

Game có phần lịch sử để hiển thị các ván đã chơi trước đó.

Người chơi có thể chọn ngày để xem lịch sử.

Kết quả trong lịch sử là kết quả cuối cùng trong trường hợp có tranh chấp.

---

# 16. Tóm tắt rule quan trọng

| Rule                 | Mahjong Ways 2                         |
| -------------------- | -------------------------------------- |
| Reels                | 5                                      |
| Layout               | 4-5-5-5-4                              |
| Ways                 | 2,000                                  |
| Win direction        | Trái sang phải                         |
| Min match            | 3 reels liên tiếp                      |
| Wild                 | Thay symbol thường, không thay Scatter |
| Scatter              | Trigger Free Spin                      |
| Free Spin            | 3 Scatter = 10 spins                   |
| Extra Scatter        | +2 spins mỗi Scatter thêm              |
| Cascade              | Có                                     |
| Base multiplier      | x1, x2, x3, x5                         |
| Free Spin multiplier | x2, x4, x6, x10                        |
| Golden reels         | Reel 2, 3, 4                           |
| Golden transform     | Golden thắng → Wild                    |
| Free Spin Golden     | Reel 3 thành Golden, trừ Wild/Scatter  |
| Bonus symbol         | Chưa xác nhận                          |
| JP symbol trên reels | Chưa xác nhận                          |
| Jackpot system       | Nếu có, là tầng system/economy riêng   |


Dưới đây là phần **luật chơi + mô tả chi tiết** cho phần trong hình về **Biểu tượng Mạ Vàng / Golden Symbols** và **Số Nhân Cascade**.

---

# Luật Biểu Tượng Mạ Vàng

## 1. Biểu tượng mạ vàng là gì?

Trong mỗi lượt quay, một số biểu tượng thường có thể xuất hiện dưới dạng **biểu tượng mạ vàng**.

Biểu tượng mạ vàng là phiên bản đặc biệt của các biểu tượng thường, dùng để tạo thêm cơ hội thắng trong các lượt cascade tiếp theo.

Các biểu tượng có thể mạ vàng:

```text
ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5,
ITEM_6, ITEM_7, ITEM_8, ITEM_9
```

Các biểu tượng **không được mạ vàng**:

```text
WILD
SCATTER
```

Nghĩa là **WILD và SCATTER vẫn có thể xuất hiện trên guồng quay**, nhưng **không bao giờ xuất hiện dưới dạng mạ vàng**.

---

## 2. Vị trí xuất hiện của biểu tượng mạ vàng

Biểu tượng mạ vàng chỉ có thể xuất hiện ở các guồng giữa:

```text
Guồng 2, Guồng 3, Guồng 4
```

Nếu màn hình có 5 cột:

```text
Cột 1 | Cột 2 | Cột 3 | Cột 4 | Cột 5
        Gold    Gold    Gold
```

Thì biểu tượng mạ vàng chỉ xuất hiện ở:

```text
Cột 2, Cột 3, Cột 4
```

Không xuất hiện ở:

```text
Cột 1 và Cột 5
```

---

## 3. Điều kiện biến thành WILD

Nếu một biểu tượng mạ vàng **tham gia vào tổ hợp thắng**, biểu tượng đó sẽ được chuyển thành **WILD** ở lượt cascade tiếp theo.

Ví dụ:

```text
ITEM_5 mạ vàng nằm trong tổ hợp thắng
=> Sau khi tính thưởng
=> ITEM_5 mạ vàng biến thành WILD
=> WILD này có thể giúp tạo thêm tổ hợp thắng mới
```

Nói đơn giản:

```text
Biểu tượng mạ vàng chỉ biến thành WILD nếu nó có góp phần tạo win.
```

Nếu biểu tượng mạ vàng **không nằm trong tổ hợp thắng**, nó không biến thành WILD.

---

## 4. Thứ tự xử lý trong một lượt thắng

Khi có tổ hợp thắng, game xử lý theo thứ tự:

```text
1. Xác định các tổ hợp thắng.
2. Tính tiền thắng theo paytable và số nhân hiện tại.
3. Kiểm tra biểu tượng mạ vàng nào nằm trong tổ hợp thắng.
4. Các biểu tượng mạ vàng thắng sẽ biến thành WILD.
5. Các biểu tượng thắng khác bị loại bỏ khỏi màn hình.
6. Biểu tượng phía trên rơi xuống để lấp chỗ trống.
7. Biểu tượng mới được thêm vào.
8. Game tiếp tục kiểm tra thắng ở cascade tiếp theo.
```

Điểm quan trọng:

```text
Biểu tượng mạ vàng thắng không bị xóa ngay như symbol thường.
Nó biến thành WILD trước, rồi có thể tiếp tục tham gia các lượt thắng sau.
```

---

# Luật Số Nhân Cascade

## 1. Số nhân là gì?

Mỗi khi người chơi thắng và tạo ra cascade, số tiền thắng sẽ được nhân với hệ số tương ứng.

Trong chế độ thường, số nhân tăng theo thứ tự:

```text
Lượt thắng đầu tiên: x1
Cascade thứ 2:       x2
Cascade thứ 3:       x3
Cascade thứ 4 trở đi: x5
```

---

## 2. Ví dụ cách tính

Giả sử người chơi có chuỗi thắng liên tục trong một lượt quay:

```text
Cascade 1: thắng 100, multiplier x1 => nhận 100
Cascade 2: thắng 100, multiplier x2 => nhận 200
Cascade 3: thắng 100, multiplier x3 => nhận 300
Cascade 4: thắng 100, multiplier x5 => nhận 500
```

Tổng thắng:

```text
100 + 200 + 300 + 500 = 1,100
```

---

## 3. Mối liên hệ giữa Golden Symbol và Multiplier

Biểu tượng mạ vàng giúp tăng khả năng kéo dài cascade.

Khi biểu tượng mạ vàng biến thành WILD, nó có thể tạo thêm tổ hợp thắng mới. Nếu tiếp tục thắng, multiplier cũng tăng lên.

Ví dụ:

```text
Lượt đầu: ITEM_5 mạ vàng tạo win ở x1
=> ITEM_5 mạ vàng biến thành WILD

Cascade tiếp theo:
WILD mới giúp tạo thêm win ở x2

Cascade tiếp nữa:
Nếu tiếp tục thắng, multiplier tăng lên x3
```

Vì vậy, Golden Symbol là cơ chế giúp game có cảm giác:

```text
thắng nối tiếp
cascade kéo dài
multiplier tăng dần
cơ hội tạo win lớn hơn
```

---

# Tóm tắt ngắn để đưa vào game rule

**Biểu tượng Mạ Vàng:**
Trong mỗi lượt quay, một số biểu tượng thường, ngoại trừ WILD và SCATTER, có thể xuất hiện dưới dạng mạ vàng trên guồng 2, 3 và 4. Nếu biểu tượng mạ vàng tham gia vào tổ hợp thắng, nó sẽ biến thành WILD trong lượt cascade tiếp theo. WILD này có thể tiếp tục tham gia tạo các tổ hợp thắng mới.

**Số Nhân:**
Khi có cascade liên tiếp, số nhân thắng sẽ tăng dần theo thứ tự `x1 → x2 → x3 → x5`. Từ cascade thứ tư trở đi, số nhân giữ ở mức `x5`.
