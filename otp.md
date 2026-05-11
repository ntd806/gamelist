`BACKEND_OTP` là **OTP nhập từ bên ngoài vào script**, không tự lấy trực tiếp từ database.

Backend validate như sau:

- Với `reset password c=14`: gọi `BackendUtils.checkOTPSuperAdmin(otp, type)`.
- Hàm này lấy danh sách super admin từ config `SUPER_ADMIN` trong `GameCommon`.
- `SUPER_ADMIN` được load từ database `game_common`, key/config phần `billing`, field `super_admin`.
- Sau đó backend kiểm tra OTP với từng nickname super admin bằng `OtpServiceImpl.checkOtp(...)`.

Nguồn OTP thực tế có 2 trường hợp:

1. Nếu DB config `game_common` phần `otp.otp_default` có giá trị, thì backend dùng OTP mặc định đó.
   Ví dụ `OTP_DEFAULT=123456` thì `BACKEND_OTP=123456`.

2. Nếu `otp_default` rỗng, backend dùng Google Authenticator/TOTP theo secret của super admin trong bảng:
   `vinplay.user_appotp`
   Cột quan trọng: `nick_name`, `secret`.

Nói ngắn gọn: `BACKEND_OTP` nên là **mã OTP hiện tại của super admin**, hoặc **OTP_DEFAULT** nếu môi trường test đang cấu hình OTP mặc định. `.env` chỉ lưu giá trị để script gửi lên backend.