# Hướng dẫn sử dụng Google Authenticator 2FA

## 1. Giới thiệu

Hệ thống sử dụng **Google Authenticator TOTP 2FA** để tăng cường bảo mật khi đăng nhập.

Ngoài **tài khoản** và **mật khẩu**, người dùng cần nhập thêm một **mã xác thực gồm 6 chữ số** được tạo trên ứng dụng Google Authenticator.

2FA được áp dụng cho:

- **CMS Admin:** `http://localhost:3000/`
- **Agent Portal:** `http://localhost:3000/en/agent/login`

> Google Authenticator không thay thế mật khẩu. Người dùng vẫn phải nhập đúng tài khoản và mật khẩu trước khi mã 2FA được chấp nhận.

---

## 2. Chuẩn bị trước khi sử dụng

Người dùng cần:

1. Điện thoại Android hoặc iPhone.
2. Cài ứng dụng **Google Authenticator**.
3. Có tài khoản và mật khẩu hợp lệ của CMS hoặc Agent Portal.
4. Đảm bảo ngày giờ trên điện thoại được đặt tự động và chính xác.

### Cài Google Authenticator

Tải ứng dụng **Google Authenticator** từ cửa hàng ứng dụng chính thức:

- Android: Google Play
- iPhone: App Store

Sau khi cài đặt, mở ứng dụng và cho phép sử dụng camera nếu muốn quét mã QR.

---

# 3. Kích hoạt 2FA lần đầu cho CMS Admin

## Bước 1: Mở trang CMS

Truy cập:

```text
http://localhost:3000/
```

Hệ thống sẽ chuyển đến trang đăng nhập CMS nếu bạn chưa đăng nhập.

## Bước 2: Nhập tài khoản và mật khẩu

Nhập:

- Username
- Password

Sau đó chọn **Sign In / Đăng nhập**.

Nếu tài khoản chưa từng kích hoạt Google Authenticator, hệ thống sẽ yêu cầu thiết lập 2FA.

## Bước 3: Quét mã QR

Màn hình sẽ hiển thị mã QR và có thể kèm theo **Manual Setup Key**.

Trên điện thoại:

1. Mở **Google Authenticator**.
2. Nhấn nút `+`.
3. Chọn **Scan a QR code / Quét mã QR**.
4. Quét mã QR đang hiển thị trên CMS.

Sau khi quét thành công, Google Authenticator sẽ tạo một mục tương tự:

```text
VS9 CMS
admin01

381 294
```

Mã `381294` chỉ là ví dụ.

Mã thật sẽ thay đổi tự động sau khoảng 30 giây.

## Bước 4: Nhập mã 6 số

Nhập mã đang hiển thị trên Google Authenticator vào ô:

```text
Authentication Code
```

Ví dụ:

```text
381294
```

Sau đó chọn **Verify / Xác nhận**.

Nếu mã hợp lệ:

- 2FA được kích hoạt cho tài khoản.
- Hệ thống hoàn tất đăng nhập.
- Google Authenticator sẽ được yêu cầu trong các lần đăng nhập tiếp theo.

---

# 4. Kích hoạt 2FA lần đầu cho Agent Portal

## Bước 1: Mở trang Agent

Truy cập:

```text
http://localhost:3000/en/agent/login
```

## Bước 2: Nhập tài khoản Agent và mật khẩu

Nhập:

- Account
- Password

Sau đó chọn **Sign In**.

Nếu tài khoản Agent chưa kích hoạt 2FA, hệ thống sẽ hiển thị màn hình thiết lập Google Authenticator.

## Bước 3: Quét QR

Trong Google Authenticator:

1. Nhấn `+`.
2. Chọn **Scan a QR code**.
3. Quét mã QR trên màn hình Agent Portal.

Ứng dụng có thể hiển thị mục tương tự:

```text
VS9 Agent Portal
AGENT_S8VIP

742 103
```

## Bước 4: Xác nhận mã đầu tiên

Nhập 6 chữ số đang hiển thị trên điện thoại vào Agent Portal.

Ví dụ:

```text
742103
```

Chọn **Verify**.

Nếu mã đúng:

- 2FA được kích hoạt.
- Phiên đăng nhập Agent được tạo.
- Người dùng được chuyển vào trang Agent tương ứng với quyền của tài khoản.

---

# 5. Đăng nhập sau khi đã kích hoạt 2FA

Sau khi đã thiết lập Google Authenticator, hệ thống sẽ không yêu cầu quét QR lại trong mỗi lần đăng nhập.

## CMS Admin

Truy cập:

```text
http://localhost:3000/
```

Nhập:

```text
Username
Password
Authentication Code
```

Mở Google Authenticator và lấy mã 6 chữ số hiện tại.

Ví dụ:

```text
503821
```

Nhập mã vào CMS và chọn **Sign In**.

Đăng nhập chỉ thành công khi:

```text
Tài khoản đúng
+
Mật khẩu đúng
+
Mã Google Authenticator đúng
```

## Agent Portal

Truy cập:

```text
http://localhost:3000/en/agent/login
```

Nhập:

```text
Account
Password
Authentication Code
```

Sau đó nhập mã 6 chữ số hiện tại trên Google Authenticator và chọn **Sign In**.

---

# 6. Mã Google Authenticator hoạt động như thế nào?

Google Authenticator tạo mã gồm 6 chữ số.

Ví dụ:

```text
481923
```

Sau khoảng 30 giây, mã sẽ đổi:

```text
057241
```

Vì vậy:

- Không lưu mã 6 chữ số để dùng lại sau.
- Luôn lấy mã đang hiển thị tại thời điểm đăng nhập.
- Nếu mã sắp hết thời gian, nên chờ mã mới rồi nhập.
- Không gửi mã 2FA cho người khác.

Google Authenticator có thể tạo mã ngay cả khi điện thoại không có Internet.

---

# 7. Recovery Code

Sau khi kích hoạt 2FA, hệ thống có thể hiển thị một danh sách **Recovery Codes**.

Ví dụ:

```text
ABCD-EFGH-IJKL
MNPQ-RSTU-VWXY
...
```

> Các mã trên chỉ là ví dụ.

## Recovery Code dùng để làm gì?

Recovery Code dùng trong trường hợp bạn không thể sử dụng Google Authenticator, ví dụ:

- Mất điện thoại.
- Điện thoại bị hỏng.
- Xóa nhầm Google Authenticator.
- Không còn tài khoản Google Authenticator đã đăng ký.

## Khi nhận Recovery Codes

Bạn nên:

1. Lưu chúng tại nơi an toàn.
2. Không gửi qua chat công khai.
3. Không chia sẻ với người khác.
4. Không lưu ở nơi người khác dễ truy cập.
5. Có thể in ra và cất giữ an toàn.

Thông thường, mỗi Recovery Code chỉ sử dụng được **một lần**.

---

# 8. Đăng nhập bằng Recovery Code

Nếu không thể lấy mã từ Google Authenticator:

1. Mở trang đăng nhập.
2. Chọn **Use recovery code / Sử dụng mã khôi phục**.
3. Nhập:
   - Tài khoản
   - Mật khẩu
   - Recovery Code
4. Chọn đăng nhập.

Ví dụ:

```text
Account: AGENT_S8VIP
Password: ********
Recovery Code: XXXX-XXXX-XXXX
```

Nếu Recovery Code hợp lệ và chưa từng sử dụng, hệ thống cho phép đăng nhập.

Sau khi sử dụng:

```text
Recovery Code đó không thể sử dụng lần thứ hai.
```

---

# 9. Mất điện thoại thì phải làm gì?

Nếu mất điện thoại nhưng vẫn còn Recovery Code:

1. Sử dụng Recovery Code để đăng nhập.
2. Liên hệ quản trị viên nếu cần reset 2FA.
3. Kích hoạt lại Google Authenticator bằng QR mới khi hệ thống yêu cầu.

Nếu mất điện thoại và cũng không còn Recovery Code:

- Không cố đăng nhập liên tục.
- Liên hệ quản trị viên có thẩm quyền để yêu cầu **reset 2FA**.
- Quản trị viên không cần và không nên yêu cầu bạn cung cấp mật khẩu hiện tại qua chat.

Sau khi 2FA được reset, lần đăng nhập tiếp theo sẽ yêu cầu quét một QR mới.

---

# 10. Đổi điện thoại

Không nên xóa Google Authenticator trên điện thoại cũ trước khi chắc chắn tài khoản đã được chuyển sang điện thoại mới.

Nếu hệ thống không hỗ trợ chuyển trực tiếp:

1. Giữ điện thoại cũ.
2. Yêu cầu reset 2FA theo quy trình quản trị.
3. Đăng nhập lại.
4. Quét QR mới bằng điện thoại mới.
5. Xác nhận mã 6 số.
6. Chỉ sau khi xác nhận thành công mới xóa cấu hình cũ.

---

# 11. Không quét QR của người khác

Mỗi QR đại diện cho một secret 2FA riêng.

Không:

- Chụp QR rồi gửi cho người khác.
- Đăng QR vào nhóm chat.
- Gửi QR qua email không an toàn.
- Cho người khác quét cùng QR của tài khoản bạn.

Nếu người khác có secret từ QR, họ có khả năng tạo mã 2FA giống điện thoại của bạn.

Nếu nghi ngờ QR hoặc secret đã bị lộ, hãy yêu cầu reset 2FA và thiết lập lại bằng QR mới.

---

# 12. Không chia sẻ mã 6 số

Không cung cấp mã Google Authenticator cho:

- Người lạ.
- Người tự xưng là hỗ trợ kỹ thuật qua chat.
- Website khác.
- Form không thuộc CMS/Agent Portal chính thức.

Mã 2FA chỉ nên được nhập trực tiếp vào trang đăng nhập hợp lệ của hệ thống.

---

# 13. Các lỗi thường gặp

## 13.1. Mã đúng nhưng hệ thống báo sai

Kiểm tra:

1. Có nhập đúng 6 chữ số không.
2. Có chọn đúng tài khoản trong Google Authenticator không.
3. Mã có vừa hết hạn không.
4. Ngày giờ trên điện thoại có chính xác không.

Nên bật:

```text
Date & Time
→ Set automatically
```

hoặc chức năng tương đương trên điện thoại.

Sau đó đợi mã mới và thử lại.

## 13.2. Mã vừa đổi khi đang nhập

Nếu mã đổi đúng lúc bạn đang đăng nhập, hãy:

1. Xóa mã cũ.
2. Lấy mã mới trên Google Authenticator.
3. Nhập lại mã mới.

## 13.3. Không nhìn thấy QR

Thử:

1. Refresh trang.
2. Đăng nhập lại bằng tài khoản và mật khẩu.
3. Kiểm tra mạng.
4. Không mở nhiều tab setup 2FA cùng lúc.

Nếu challenge thiết lập đã hết hạn, đăng nhập lại để tạo QR mới.

## 13.4. Quét QR nhưng Google Authenticator báo lỗi

Thử dùng **Manual Setup Key** nếu màn hình có cung cấp.

Trong Google Authenticator:

1. Nhấn `+`.
2. Chọn **Enter a setup key**.
3. Nhập tên tài khoản.
4. Nhập Setup Key.
5. Chọn kiểu **Time based**.
6. Lưu.

Sau đó sử dụng mã 6 chữ số được tạo.

## 13.5. Google Authenticator hiện nhiều tài khoản giống nhau

Không nên giữ nhiều cấu hình cũ có cùng tên.

Nếu vừa reset 2FA:

- Xóa entry cũ sau khi QR mới đã được xác nhận thành công.
- Dùng entry mới nhất.

Nếu không chắc entry nào đúng, liên hệ quản trị viên.

## 13.6. Nhập mã nhiều lần vẫn thất bại

Hệ thống có thể tạm thời giới hạn số lần thử để chống dò mã.

Không thử liên tục.

Kiểm tra:

- tài khoản;
- mật khẩu;
- đúng entry Google Authenticator;
- thời gian điện thoại.

Sau đó thử lại theo chính sách của hệ thống hoặc liên hệ quản trị viên.

---

# 14. Lưu ý khi dùng mã có số 0 ở đầu

Mã Google Authenticator luôn có 6 chữ số.

Ví dụ:

```text
012345
```

Đây là mã hợp lệ.

Phải nhập đầy đủ:

```text
012345
```

Không nhập:

```text
12345
```

---

# 15. Có cần Internet để Google Authenticator tạo mã không?

Không.

Google Authenticator sử dụng:

```text
Secret đã đăng ký
+
Thời gian hiện tại
```

để tạo mã.

Vì vậy ứng dụng có thể tạo mã khi điện thoại không có Wi-Fi hoặc 4G/5G.

Tuy nhiên, thời gian của điện thoại phải chính xác.

---

# 16. Google Authenticator có gửi mã cho server không?

Không.

Ứng dụng không tự gửi mã tới CMS hoặc VinPlayBackend.

Luồng là:

```text
Google Authenticator
→ hiển thị mã cho người dùng
→ người dùng nhập mã vào trang đăng nhập
→ backend kiểm tra
```

---

# 17. Có cần email để sử dụng Google Authenticator không?

Không.

TOTP không yêu cầu email.

CMS hoặc Agent Portal liên kết 2FA với tài khoản nội bộ của hệ thống.

Email, nếu có, là thông tin độc lập và không phải điều kiện bắt buộc để Google Authenticator hoạt động.

---

# 18. Những việc tuyệt đối không nên làm

Không:

- Chia sẻ mật khẩu.
- Chia sẻ mã 6 số.
- Chia sẻ Recovery Code.
- Chụp và gửi QR setup cho người khác.
- Lưu QR ở nơi công khai.
- Nhập mã 2FA vào website không rõ nguồn gốc.
- Dùng cùng Recovery Code nhiều lần.
- Xóa Google Authenticator trước khi có phương án khôi phục.
- Cố gắng đăng nhập liên tục khi bị giới hạn số lần thử.

---

# 19. Checklist kích hoạt lần đầu

## CMS Admin

- [ ] Cài Google Authenticator.
- [ ] Mở `http://localhost:3000/`.
- [ ] Nhập username và password.
- [ ] Quét QR.
- [ ] Nhập mã 6 số.
- [ ] Xác nhận setup thành công.
- [ ] Lưu Recovery Codes.
- [ ] Logout và thử đăng nhập lại bằng OTP.

## Agent Portal

- [ ] Cài Google Authenticator.
- [ ] Mở `http://localhost:3000/en/agent/login`.
- [ ] Nhập account và password.
- [ ] Quét QR.
- [ ] Nhập mã 6 số.
- [ ] Xác nhận setup thành công.
- [ ] Lưu Recovery Codes.
- [ ] Logout và thử đăng nhập lại bằng OTP.

---

# 20. Checklist đăng nhập hằng ngày

- [ ] Mở đúng trang CMS hoặc Agent Portal.
- [ ] Nhập đúng tài khoản.
- [ ] Nhập đúng mật khẩu.
- [ ] Mở Google Authenticator.
- [ ] Chọn đúng tài khoản.
- [ ] Nhập đầy đủ 6 chữ số hiện tại.
- [ ] Không chia sẻ mã với bất kỳ ai.

---

# 21. Liên hệ hỗ trợ

Liên hệ quản trị viên hệ thống khi:

- Mất điện thoại.
- Mất Recovery Codes.
- Cần reset 2FA.
- QR setup liên tục không hoạt động.
- Tài khoản bị khóa do thử OTP nhiều lần.
- Nghi ngờ QR/secret 2FA đã bị lộ.
- Phát hiện lần đăng nhập đáng ngờ.

Khi liên hệ hỗ trợ:

**Không gửi mật khẩu, mã OTP hiện tại, QR setup hoặc Recovery Code qua chat.**

Chỉ cung cấp các thông tin định danh mà quy trình nội bộ cho phép, ví dụ username, partner code hoặc agent code.

---

# 22. Tóm tắt

Sau khi kích hoạt 2FA, đăng nhập thông thường sẽ là:

```text
Tài khoản
+
Mật khẩu
+
Mã Google Authenticator 6 số
↓
Đăng nhập thành công
```

Nếu không có mã Google Authenticator hợp lệ hoặc Recovery Code hợp lệ, hệ thống sẽ không cho phép hoàn tất đăng nhập.

Google Authenticator là lớp bảo vệ bổ sung giúp giảm nguy cơ tài khoản bị chiếm quyền khi mật khẩu bị lộ.
