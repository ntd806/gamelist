## 1. Tài liệu API cần tham khảo

Doc API Seamless Wallet:

`https://gitlab.com/neymarjr21021998/s8gamelib/-/blob/main/SeamlessWallet/doc/GAME_WALLET_API.md?ref_type=heads`

Test partner endpoint:

`http://13.231.110.67:8083/test-partner/`

## 2. Cách lấy thông tin user

Game backend sẽ **không dùng Hazelcast nữa**.

Thay vào đó, hệ thống chuyển sang dùng **Redis** để dễ **scale ngang**.

Backend cần sử dụng các thư viện:

* `VBeeCommon`
* `VinplayUserCore`

Mục đích:

* Lấy thông tin user từ Redis.
* Dùng `SeamlessPlayerCacheModel` trong `VBeeCommon`.
* Lấy thông tin user dựa trên `token`.

Flow cơ bản:

```text
Client gửi token
        ↓
Game backend nhận token
        ↓
Dùng SeamlessPlayerCacheModel trong VBeeCommon
        ↓
Lấy thông tin user từ Redis
        ↓
Dùng thông tin user để xử lý game / wallet / bet
```

## 3. Redis cluster / Redis nodes cần kiểm tra khi deploy test

Khi deploy bản test, cần ping/check kết nối Redis tới các IP private sau:

### Redis Server A

IP:

```text
172.31.33.103
```

Ports:

```text
7000
7001
7002
```

### Redis Server B

IP:

```text
172.31.36.131
```

Ports:

```text
7003
7004
7005
```

## 4. Yêu cầu chính cho backend

Backend cần đảm bảo:

```text
1. Tích hợp theo Seamless Wallet API doc.

2. Không dùng Hazelcast.

3. Chuyển sang Redis để hỗ trợ scale ngang.

4. Sử dụng VBeeCommon và VinplayUserCore để lấy user info.

5. Dùng SeamlessPlayerCacheModel để lấy thông tin user theo token.

6. Khi deploy test, kiểm tra kết nối Redis tới 2 server:
   - 172.31.33.103:7000,7001,7002
   - 172.31.36.131:7003,7004,7005
```