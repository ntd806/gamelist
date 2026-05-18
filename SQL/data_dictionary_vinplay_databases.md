# Data Dictionary - Giải thích từng trường và kiểu dữ liệu

> Ghi chú: file schema không có comment nghiệp vụ đầy đủ, nên phần “ý nghĩa” được suy luận từ tên bảng/tên cột/kiểu dữ liệu. Những trường trạng thái (`status`, `type`, `state`) cần đối chiếu thêm với enum trong backend để xác nhận chính xác từng giá trị.

## Quy ước đọc kiểu dữ liệu

| Kiểu | Ý nghĩa | Lưu ý |
|---|---|---|
| INT / TINYINT | Số nguyên; thường dùng id, trạng thái, số lượng nhỏ | Nếu là tiền lớn nên tránh INT, ưu tiên BIGINT |
| BIGINT | Số nguyên lớn | Phù hợp lưu tiền game theo đơn vị nhỏ nhất, ví dụ VIN/XU |
| VARCHAR(n) | Chuỗi có giới hạn độ dài | Dùng cho tên, mã, transaction id, phone, email |
| TEXT | Chuỗi dài | Dùng cho log, nội dung dài, JSON hoặc mô tả |
| FLOAT / DOUBLE | Số thực | Không nên dùng cho tiền vì có sai số làm tròn |
| DECIMAL | Số thập phân chính xác | Phù hợp cho tiền thật nếu cần phần lẻ |
| DATETIME / TIMESTAMP | Ngày giờ | Dùng cho create/update/expire/approve time |
| DATE | Ngày | Không có giờ/phút/giây |

# Database `vinplay`

Tổng số bảng: **59**. Tổng số trường: **513**.


## `vinplay.agent`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `code` | `varchar(20) NOT NULL` | Mã định danh nghiệp vụ; có thể là mã agent, mã game, mã giao dịch hoặc mã quà. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `name` | `varchar(255) DEFAULT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `game` | `varchar(255) DEFAULT NULL` | Mã/loại game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `start_date` | `datetime DEFAULT CURRENT_TIMESTAMP` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `status` | `int DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`code`) USING BTREE`


## `vinplay.currency`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `code` | `varchar(255) DEFAULT NULL` | Mã định danh nghiệp vụ; có thể là mã agent, mã game, mã giao dịch hoặc mã quà. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `toCurrency` | `float DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số thực; không nên dùng cho tiền vì có sai số làm tròn. |
| `name` | `varchar(255) DEFAULT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `toUsd` | `float DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số thực; không nên dùng cho tiền vì có sai số làm tròn. |


## `vinplay.daily_event`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(100) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money` | `int DEFAULT NULL` | Số tiền/số lượng liên quan nghiệp vụ. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `create_date` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm/ngày tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `event_type` | `int DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.daily_mission`

**Vai trò:** Bảng nhiệm vụ/phần thưởng.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `mission_type` | `int DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `complete` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `status` | `smallint DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `update_time` | `datetime DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `user_name` | `varchar(255) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.dealer`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_id` | `int DEFAULT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_name` | `varchar(50) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name` | `varchar(50) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `room_type` | `int DEFAULT NULL` | Thông tin phiên/vòng/phòng chơi. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `is_active` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.event_vp`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `name` | `varchar(100) NOT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `int NOT NULL DEFAULT '0'` | Giá trị tương ứng với key/cấu hình. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `num` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `use` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `update_time` | `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm cập nhật bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.event_vp_lucky`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `date_run` | `varchar(45) NOT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `num_run` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `type` | `int NOT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `update_time` | `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm cập nhật bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`date_run`,`type`) USING BTREE`


## `vinplay.follows`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `follower_id` | `bigint NOT NULL` | ID liên kết tới đối tượng follower. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `idol_id` | `bigint NOT NULL` | ID liên kết tới đối tượng idol. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`follower_id`) USING BTREE`


## `vinplay.freeze_money`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `bigint NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `session_id` | `varchar(100) DEFAULT NULL` | Mã phiên chơi/phiên xử lý. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `user_id` | `bigint DEFAULT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `nick_name` | `varchar(45) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `game_name` | `varchar(45) DEFAULT NULL` | Tên hoặc mã game liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `room_id` | `varchar(100) DEFAULT NULL` | ID phòng chơi. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money` | `bigint DEFAULT NULL` | Số tiền/số lượng liên quan nghiệp vụ. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `money_type` | `varchar(5) DEFAULT NULL` | Loại tiền, ví dụ VIN/XU hoặc enum tương ứng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_time` | `datetime DEFAULT NULL` | Thời điểm tạo bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `update_time` | `datetime DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `status` | `int DEFAULT '0'` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `user_id_index` (`user_id`) USING BTREE`
- `KEY `session_id_index` (`session_id`) USING BTREE`
- `KEY `game_name_index` (`game_name`) USING BTREE`
- `KEY `nick_name_index` (`nick_name`) USING BTREE`
- `KEY `money_type_index` (`money_type`) USING BTREE`
- `KEY `status_index` (`status`) USING BTREE`


## `vinplay.game_config`

**Vai trò:** Bảng cấu hình dạng key-value/config.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `name` | `varchar(255) DEFAULT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `longtext` | Giá trị tương ứng với key/cấu hình. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `version` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `platform` | `varchar(50) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.game_config_xx`

**Vai trò:** Bảng cấu hình dạng key-value/config.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `name` | `varchar(255) DEFAULT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `longtext` | Giá trị tương ứng với key/cấu hình. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `version` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `platform` | `varchar(50) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.games`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `name` | `varchar(255) DEFAULT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `url` | `varchar(255) DEFAULT NULL` | Đường dẫn/link cấu hình hoặc truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `status` | `int DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.idol`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `user_id` | `int NOT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(50) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `display_name` | `varchar(100) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `image` | `varchar(100) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `avatar` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `live_time` | `varchar(50) DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_date` | `datetime DEFAULT NULL` | Thời điểm/ngày tạo bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `status` | `tinyint DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |

**Key / Index:**
- `PRIMARY KEY (`user_id`) USING BTREE`


## `vinplay.key_value`

**Vai trò:** Bảng cấu hình dạng key-value/config.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `key` | `varchar(20) DEFAULT NULL` | Khóa cấu hình hoặc tên biến trong bảng key-value. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `bigint NOT NULL DEFAULT '0'` | Giá trị tương ứng với key/cấu hình. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`value`)`


## `vinplay.level_config`

**Vai trò:** Bảng cấu hình dạng key-value/config.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `level` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `map` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `value` | `varchar(255) DEFAULT NULL` | Giá trị tương ứng với key/cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |


## `vinplay.log_game_reference`

**Vai trò:** Bảng log/audit phục vụ truy vết.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `reference_id` | `int DEFAULT NULL` | Mã tham chiếu giao dịch/vòng chơi. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `total_bet_odd` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_bet_even` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_buy_odd` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_buy_even` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_bet_4_black` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_bet_4_white` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_bet_3_black` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_bet_3_white` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `result` | `int DEFAULT NULL` | Kết quả game/phiên xử lý. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `total_refund` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_prize` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `fee` | `int DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `create_date` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm/ngày tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `room_id` | `int DEFAULT NULL` | ID phòng chơi. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_name_room_master` | `varchar(20) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.log_game_result`

**Vai trò:** Bảng kết quả game/phiên.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_name` | `varchar(255) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `total_received` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_bet` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_win` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_lose` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `profit` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `room_id` | `int DEFAULT NULL` | ID phòng chơi. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `create_date` | `datetime DEFAULT NULL` | Thời điểm/ngày tạo bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `total_fee` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.log_game_round`

**Vai trò:** Bảng log/audit phục vụ truy vết.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_name` | `varchar(255) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `pot` | `varchar(100) DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money` | `bigint DEFAULT NULL` | Số tiền/số lượng liên quan nghiệp vụ. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `pot_result` | `varchar(100) DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `fee` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_money` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `room_id` | `int DEFAULT NULL` | ID phòng chơi. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `game_id` | `int DEFAULT NULL` | ID liên kết tới đối tượng game. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `create_date` | `datetime DEFAULT NULL` | Thời điểm/ngày tạo bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.log_game_thau_vi`

**Vai trò:** Bảng log/audit phục vụ truy vết.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `reference_id` | `int DEFAULT NULL` | Mã tham chiếu giao dịch/vòng chơi. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `total_bet_4_black` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_bet_4_white` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_bet_3_black` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_bet_3_white` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `result` | `int DEFAULT NULL` | Kết quả game/phiên xử lý. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `total_prize` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `revenue` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_name_thau_vi` | `varchar(20) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `room_id` | `int DEFAULT NULL` | ID phòng chơi. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `create_date` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm/ngày tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.log_tranfer_agent`

**Vai trò:** Bảng log/audit phục vụ truy vết.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `transaction_no` | `varchar(45) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `agent_level1` | `varchar(45) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name_send` | `varchar(45) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name_receive` | `varchar(45) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money_send` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `money_receive` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `status` | `int DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `fee` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `top_ds` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `process` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `ti_gia` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `is_freeze_money` | `int DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `des_send` | `varchar(500) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `des_receive` | `varchar(500) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `session_id_freeze_money` | `varchar(45) DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `trans_time` | `varchar(45) DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `update_time` | `varchar(45) DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `transaction_no_index` (`transaction_no`) USING BTREE`
- `KEY `agent_level1_index` (`agent_level1`) USING BTREE`
- `KEY `nick_name_send_index` (`nick_name_send`) USING BTREE`
- `KEY `nick_name_receive_index` (`nick_name_receive`) USING BTREE`
- `KEY `money_send_index` (`money_send`) USING BTREE`
- `KEY `money_receive_index` (`money_receive`) USING BTREE`
- `KEY `status_index` (`status`) USING BTREE`
- `KEY `fee_index` (`fee`) USING BTREE`
- `KEY `top_ds_index` (`top_ds`) USING BTREE`
- `KEY `process_index` (`process`) USING BTREE`
- `KEY `ti_gia_index` (`ti_gia`) USING BTREE`
- `KEY `des_send_index` (`des_send`(255)) USING BTREE`
- `KEY `des_receive_index` (`des_receive`(255)) USING BTREE`
- `KEY `is_freeze_money_index` (`is_freeze_money`) USING BTREE`
- `KEY `session_id_freeze_money_index` (`session_id_freeze_money`) USING BTREE`
- `KEY `trans_time_index` (`trans_time`) USING BTREE`
- `KEY `update_time_index` (`update_time`) USING BTREE`


## `vinplay.login_daily`

**Vai trò:** Bảng log/audit phục vụ truy vết.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(30) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `login_date` | `datetime DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `times` | `int DEFAULT '0'` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.mission`

**Vai trò:** Bảng nhiệm vụ/phần thưởng.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `mission_name` | `varchar(255) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `condition` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `type` | `smallint DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `money` | `int DEFAULT NULL` | Số tiền/số lượng liên quan nghiệp vụ. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `energy` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `skill` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.money_system`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `name` | `varchar(50) NOT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money` | `bigint NOT NULL DEFAULT '0'` | Số tiền/số lượng liên quan nghiệp vụ. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `update_time` | `timestamp NULL DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `create_time` | `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.operator_activity_log`

**Vai trò:** Bảng log/audit phục vụ truy vết.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `bigint NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `operator_code` | `varchar(50) NOT NULL` | Mã nghiệp vụ; có thể cần unique để tránh trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `action` | `varchar(100) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `endpoint` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `request_id` | `varchar(100) DEFAULT NULL` | Mã request/yêu cầu; nên dùng làm idempotency key nếu đến từ đối tác. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `response_code` | `varchar(20) DEFAULT NULL` | Mã nghiệp vụ; có thể cần unique để tránh trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `response_message` | `text` | Nội dung mô tả/thông báo/log. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `ip_address` | `varchar(50) DEFAULT NULL` | Địa chỉ IP phục vụ log/bảo mật/chặn truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `processing_time_ms` | `int DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `created_at` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_code` (`operator_code`)`
- `KEY `idx_action` (`action`)`
- `KEY `idx_created_at` (`created_at`)`


## `vinplay.operator_activity_log_copy1`

**Vai trò:** Bảng log/audit phục vụ truy vết.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `bigint NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `operator_code` | `varchar(50) NOT NULL` | Mã nghiệp vụ; có thể cần unique để tránh trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `action` | `varchar(100) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `endpoint` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `request_id` | `varchar(100) DEFAULT NULL` | Mã request/yêu cầu; nên dùng làm idempotency key nếu đến từ đối tác. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `response_code` | `varchar(20) DEFAULT NULL` | Mã nghiệp vụ; có thể cần unique để tránh trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `response_message` | `text` | Nội dung mô tả/thông báo/log. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `ip_address` | `varchar(50) DEFAULT NULL` | Địa chỉ IP phục vụ log/bảo mật/chặn truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `processing_time_ms` | `int DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `created_at` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_code` (`operator_code`)`
- `KEY `idx_action` (`action`)`
- `KEY `idx_created_at` (`created_at`)`


## `vinplay.operator_api_keys`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `operator_id` | `int NOT NULL` | ID liên kết tới đối tượng operator. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `api_key` | `varchar(255) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `key_name` | `varchar(100) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `status` | `enum('ACTIVE','REVOKED','EXPIRED') DEFAULT 'ACTIVE'` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `created_at` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `revoked_at` | `timestamp NULL DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `expires_at` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `last_used_at` | `timestamp NULL DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `usage_count` | `bigint DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `notes` | `text` | Nội dung mô tả/thông báo/log. | Chuỗi dài; dùng cho nội dung/log/json dài. |

**Key / Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_id` (`operator_id`)`
- `KEY `idx_api_key` (`api_key`)`
- `KEY `idx_status` (`status`)`
- `CONSTRAINT `operator_api_keys_ibfk_1` FOREIGN KEY (`operator_id`) REFERENCES `operators` (`id`) ON DELETE CASCADE`


## `vinplay.operator_api_keys_copy1`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `operator_id` | `int NOT NULL` | ID liên kết tới đối tượng operator. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `api_key` | `varchar(255) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `key_name` | `varchar(100) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `status` | `enum('ACTIVE','REVOKED','EXPIRED') DEFAULT 'ACTIVE'` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `created_at` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `revoked_at` | `timestamp NULL DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `expires_at` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `last_used_at` | `timestamp NULL DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `usage_count` | `bigint DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `notes` | `text` | Nội dung mô tả/thông báo/log. | Chuỗi dài; dùng cho nội dung/log/json dài. |

**Key / Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_id` (`operator_id`)`
- `KEY `idx_api_key` (`api_key`)`
- `KEY `idx_status` (`status`)`
- `CONSTRAINT `operator_api_keys_copy1_ibfk_1` FOREIGN KEY (`operator_id`) REFERENCES `operators` (`id`) ON DELETE CASCADE`


## `vinplay.operator_audit_log`

**Vai trò:** Bảng log/audit phục vụ truy vết.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `bigint NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `operator_id` | `int NOT NULL` | ID liên kết tới đối tượng operator. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `action` | `varchar(100) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `endpoint` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `request_id` | `varchar(100) DEFAULT NULL` | Mã request/yêu cầu; nên dùng làm idempotency key nếu đến từ đối tác. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `response_code` | `varchar(10) DEFAULT NULL` | Mã nghiệp vụ; có thể cần unique để tránh trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `response_message` | `text` | Nội dung mô tả/thông báo/log. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `ip_address` | `varchar(45) DEFAULT NULL` | Địa chỉ IP phục vụ log/bảo mật/chặn truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `user_agent` | `text` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `processing_time_ms` | `int DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `created_at` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_id` (`operator_id`)`
- `KEY `idx_action` (`action`)`
- `KEY `idx_created_at` (`created_at`)`
- `KEY `idx_request_id` (`request_id`)`
- `CONSTRAINT `operator_audit_log_ibfk_1` FOREIGN KEY (`operator_id`) REFERENCES `operators` (`id`) ON DELETE CASCADE`


## `vinplay.operator_audit_log_copy1`

**Vai trò:** Bảng log/audit phục vụ truy vết.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `bigint NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `operator_id` | `int NOT NULL` | ID liên kết tới đối tượng operator. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `action` | `varchar(100) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `endpoint` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `request_id` | `varchar(100) DEFAULT NULL` | Mã request/yêu cầu; nên dùng làm idempotency key nếu đến từ đối tác. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `response_code` | `varchar(10) DEFAULT NULL` | Mã nghiệp vụ; có thể cần unique để tránh trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `response_message` | `text` | Nội dung mô tả/thông báo/log. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `ip_address` | `varchar(45) DEFAULT NULL` | Địa chỉ IP phục vụ log/bảo mật/chặn truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `user_agent` | `text` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `processing_time_ms` | `int DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `created_at` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`)`
- `KEY `idx_operator_id` (`operator_id`)`
- `KEY `idx_action` (`action`)`
- `KEY `idx_created_at` (`created_at`)`
- `KEY `idx_request_id` (`request_id`)`
- `CONSTRAINT `operator_audit_log_copy1_ibfk_1` FOREIGN KEY (`operator_id`) REFERENCES `operators` (`id`) ON DELETE CASCADE`


## `vinplay.operator_database_config`

**Vai trò:** Bảng cấu hình dạng key-value/config.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `operator_id` | `int NOT NULL` | ID liên kết tới đối tượng operator. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `mysql_host` | `varchar(255) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `mysql_port` | `int DEFAULT '3306'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `mysql_database` | `varchar(100) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `mysql_username` | `varchar(100) NOT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `mysql_password` | `varchar(255) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `mysql_min_pool` | `int DEFAULT '2'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `mysql_max_pool` | `int DEFAULT '10'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `mongo_host` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `mongo_port` | `int DEFAULT '27017'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `mongo_database` | `varchar(100) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `mongo_auth_database` | `varchar(100) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `mongo_username` | `varchar(100) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `mongo_password` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `tier` | `enum('SMALL','MEDIUM','LARGE','ENTERPRISE') DEFAULT 'SMALL'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `shard_group` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `use_shared_pool` | `tinyint(1) DEFAULT '1'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `estimated_user_count` | `int DEFAULT '0'` | Thông tin định danh user/tài khoản/đại lý liên quan. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `estimated_tps` | `int DEFAULT '10'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `pool_status` | `enum('INITIALIZING','ACTIVE','INACTIVE','ERROR') DEFAULT 'INITIALIZING'` | Trạng thái nghiệp vụ; cần map enum trong backend để hiểu chính xác từng giá trị. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `pool_initialized_at` | `timestamp NULL DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `last_health_check` | `timestamp NULL DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `health_status` | `varchar(50) DEFAULT NULL` | Trạng thái nghiệp vụ; cần map enum trong backend để hiểu chính xác từng giá trị. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `error_message` | `text` | Nội dung mô tả/thông báo/log. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `is_active` | `tinyint(1) DEFAULT '1'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `created_at` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `updated_at` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Thời điểm cập nhật bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`)`
- `UNIQUE KEY `uk_operator_id` (`operator_id`)`
- `KEY `idx_mysql_database` (`mysql_database`)`
- `KEY `idx_tier` (`tier`)`
- `KEY `idx_shard_group` (`shard_group`)`


## `vinplay.operators`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `operator_code` | `varchar(50) NOT NULL` | Mã nghiệp vụ; có thể cần unique để tránh trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `operator_name` | `varchar(255) NOT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `api_key` | `varchar(255) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `secret_key` | `varchar(255) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `status` | `enum('ACTIVE','INACTIVE','SUSPENDED') DEFAULT 'ACTIVE'` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `whitelisted_ips` | `text` | Địa chỉ IP phục vụ log/bảo mật/chặn truy cập. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `allowed_scopes` | `text` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `rate_limit_per_minute` | `int DEFAULT '100'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `contact_email` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `contact_phone` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `description` | `text` | Mô tả chi tiết. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `created_at` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `updated_at` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Thời điểm cập nhật bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `created_by` | `varchar(100) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `updated_by` | `varchar(100) DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`)`
- `UNIQUE KEY `operator_code` (`operator_code`)`
- `KEY `idx_operator_code` (`operator_code`)`
- `KEY `idx_status` (`status`)`


## `vinplay.product`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `name` | `varchar(255) DEFAULT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `price_usd` | `float DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số thực; không nên dùng cho tiền vì có sai số làm tròn. |
| `price_vnd` | `float DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số thực; không nên dùng cho tiền vì có sai số làm tròn. |
| `order` | `smallint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `type` | `int DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `star` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `image_id` | `int DEFAULT NULL` | ID liên kết tới đối tượng image. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `name_eng` | `varchar(255) NOT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.product_user`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `nick_name` | `varchar(100) NOT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `product_id` | `int NOT NULL` | ID liên kết tới đối tượng product. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `create_date` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `is_active` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `type` | `int NOT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`nick_name`,`product_id`) USING BTREE`


## `vinplay.report_daily`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `date` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `totalBet` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `totalPrize` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `totalFee` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `totalBetThauVi` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `totalPayThauVi` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `totalRevenueThauVi` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `revenue` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `game` | `int DEFAULT NULL` | Mã/loại game. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.report_money_daily`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `action_name` | `varchar(256) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money_win` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `money_lost` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `money_other` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `fee` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `date` | `date DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày, không gồm giờ. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `action_name` (`action_name`(255)) USING BTREE`
- `KEY `date` (`date`) USING BTREE`
- `KEY `id` (`id`) USING BTREE`


## `vinplay.system_account`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `userId` | `int NOT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `userName` | `varchar(20) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `gameName` | `varchar(20) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `type` | `int DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `status` | `int DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.system_cashout`

**Vai trò:** Bảng yêu cầu/rút tiền.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `date` | `varchar(45) NOT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money` | `varchar(45) NOT NULL DEFAULT '0'` | Số tiền/số lượng liên quan nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `update_time` | `datetime DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `date_UNIQUE` (`date`) USING BTREE`


## `vinplay.topup`

**Vai trò:** Bảng nạp tiền hoặc log nạp theo kênh.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_id` | `int DEFAULT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_name` | `varchar(100) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `amount` | `int DEFAULT NULL` | Số tiền/số lượng giao dịch. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `transaction_code` | `varchar(20) DEFAULT NULL` | Mã giao dịch; nên unique theo nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `order_no` | `varchar(50) DEFAULT NULL` | Mã đơn hàng/yêu cầu; nên dùng để chống xử lý trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `channel` | `varchar(20) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `code` | `varchar(20) DEFAULT NULL` | Mã định danh nghiệp vụ; có thể là mã agent, mã game, mã giao dịch hoặc mã quà. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `card_serial` | `varchar(20) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `card_code` | `varchar(20) DEFAULT NULL` | Mã nghiệp vụ; có thể cần unique để tránh trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `message` | `varchar(255) DEFAULT NULL` | Thông điệp trả về từ hệ thống/đối tác hoặc lý do xử lý. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_time` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `status` | `tinyint DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `type` | `tinyint DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `phone_number` | `varchar(20) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `account_name` | `varchar(100) DEFAULT NULL` | Tên chủ tài khoản. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `account_number` | `varchar(100) DEFAULT NULL` | Số tài khoản. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `bank_type` | `varchar(50) DEFAULT NULL` | Loại/kênh ngân hàng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `address_wallet` | `varchar(500) DEFAULT NULL` | Thông tin kênh thanh toán/ngân hàng/ ví. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `network` | `varchar(50) DEFAULT NULL` | Thông tin kênh thanh toán/ngân hàng/ ví. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.topup_bank`

**Vai trò:** Bảng nạp tiền hoặc log nạp theo kênh.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `request_id` | `varchar(20) NOT NULL` | Mã request/yêu cầu; nên dùng làm idempotency key nếu đến từ đối tác. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name` | `varchar(30) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `bank` | `varchar(45) DEFAULT NULL` | Thông tin kênh thanh toán/ngân hàng/ ví. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `status` | `tinyint(1) DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `amount` | `varchar(45) DEFAULT NULL` | Số tiền/số lượng giao dịch. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money_user` | `varchar(45) DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `message` | `varchar(255) DEFAULT NULL` | Thông điệp trả về từ hệ thống/đối tác hoặc lý do xử lý. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_time` | `timestamp NULL DEFAULT NULL` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`request_id`) USING BTREE`


## `vinplay.topup_momo`

**Vai trò:** Bảng nạp tiền hoặc log nạp theo kênh.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `momo_transId` | `varchar(20) NOT NULL` | Mã giao dịch Momo. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name` | `varchar(30) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `requestTime` | `varchar(20) DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `message` | `varchar(255) DEFAULT NULL` | Thông điệp trả về từ hệ thống/đối tác hoặc lý do xử lý. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money` | `varchar(20) DEFAULT NULL` | Số tiền/số lượng liên quan nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money_user` | `varchar(20) DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `phone` | `varchar(20) DEFAULT NULL` | Số điện thoại. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `type` | `tinyint DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `create_time` | `timestamp NULL DEFAULT NULL` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`momo_transId`) USING BTREE`


## `vinplay.topup_vtpay`

**Vai trò:** Bảng nạp tiền hoặc log nạp theo kênh.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `vtp_transId` | `varchar(20) NOT NULL` | Mã giao dịch ViettelPay. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `requestTime` | `varchar(45) DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `message` | `varchar(255) DEFAULT NULL` | Thông điệp trả về từ hệ thống/đối tác hoặc lý do xử lý. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money` | `varchar(45) DEFAULT NULL` | Số tiền/số lượng liên quan nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `phone` | `varchar(45) DEFAULT NULL` | Số điện thoại. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name` | `varchar(45) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money_user` | `varchar(45) DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_time` | `timestamp NULL DEFAULT NULL` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`vtp_transId`) USING BTREE`


## `vinplay.topup_zalopay`

**Vai trò:** Bảng nạp tiền hoặc log nạp theo kênh.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `request_id` | `varchar(20) NOT NULL` | Mã request/yêu cầu; nên dùng làm idempotency key nếu đến từ đối tác. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name` | `varchar(45) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `bank` | `varchar(45) DEFAULT NULL` | Thông tin kênh thanh toán/ngân hàng/ ví. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `status` | `tinyint DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `amount` | `varchar(45) DEFAULT NULL` | Số tiền/số lượng giao dịch. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `money_user` | `varchar(45) DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `message` | `varchar(45) DEFAULT NULL` | Thông điệp trả về từ hệ thống/đối tác hoặc lý do xử lý. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_time` | `timestamp NULL DEFAULT NULL` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`request_id`) USING BTREE`


## `vinplay.user_appotp`

**Vai trò:** Bảng quỹ/hũ/jackpot.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `nick_name` | `varchar(100) NOT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `secret` | `varchar(100) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`nick_name`) USING BTREE`


## `vinplay.user_gate`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `address` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `gate` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.user_gun`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(20) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `gun_id` | `int DEFAULT NULL` | ID liên kết tới đối tượng gun. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `gun_num` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `active` | `int DEFAULT NULL` | Cờ đang hoạt động/kích hoạt. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.user_item`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(20) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `item_id` | `int DEFAULT NULL` | ID liên kết tới đối tượng item. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `item_num` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.user_level`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(255) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `level` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.user_mission_vin`

**Vai trò:** Bảng nhiệm vụ/phần thưởng.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `bigint NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `user_id` | `bigint DEFAULT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `user_name` | `varchar(45) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name` | `varchar(45) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `mission_name` | `varchar(45) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `level` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `match_win` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `match_max` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `received_reward_level` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `create_time` | `varchar(45) DEFAULT NULL` | Thời điểm tạo bản ghi. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `update_time` | `varchar(45) DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `id_UNIQUE` (`id`) USING BTREE`
- `KEY `nick_name` (`nick_name`) USING BTREE`
- `KEY `mission_name` (`mission_name`) USING BTREE`
- `KEY `nick_name_mission_name` (`nick_name`,`mission_name`) USING BTREE`
- `KEY `time_index` (`update_time`) USING BTREE`


## `vinplay.user_mission_xu`

**Vai trò:** Bảng nhiệm vụ/phần thưởng.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `bigint NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `user_id` | `bigint DEFAULT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `user_name` | `varchar(45) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name` | `varchar(45) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `mission_name` | `varchar(45) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `level` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `match_win` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `match_max` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `received_reward_level` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `create_time` | `varchar(45) DEFAULT NULL` | Thời điểm tạo bản ghi. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `update_time` | `varchar(45) DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `id_UNIQUE` (`id`) USING BTREE`
- `KEY `nick_name` (`nick_name`) USING BTREE`
- `KEY `mission_name` (`mission_name`) USING BTREE`
- `KEY `nick_name_mission_name` (`nick_name`,`mission_name`) USING BTREE`
- `KEY `update_time` (`update_time`) USING BTREE`


## `vinplay.user_telegram_otp`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `tele_phone_number` | `varchar(15) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `tele_chat_id` | `varchar(15) DEFAULT NULL` | ID liên kết tới đối tượng tele_chat. Nên kiểm tra quan hệ với bảng gốc. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name` | `varchar(30) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `otp` | `varchar(8) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `time` | `bigint DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`tele_phone_number`) USING BTREE`


## `vinplay.users`

**Vai trò:** Bảng user chính và số dư ví.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `bigint NOT NULL` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `user_name` | `varchar(128) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name` | `varchar(128) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `password` | `varchar(128) DEFAULT NULL` | Mật khẩu hoặc hash mật khẩu. Cần kiểm tra có đang hash an toàn không. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `email` | `varchar(128) DEFAULT NULL` | Email. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `google_id` | `varchar(128) DEFAULT NULL` | ID liên kết tới đối tượng google. Nên kiểm tra quan hệ với bảng gốc. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `facebook_id` | `varchar(128) DEFAULT NULL` | ID liên kết tới đối tượng facebook. Nên kiểm tra quan hệ với bảng gốc. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `mobile` | `varchar(45) DEFAULT NULL` | Số điện thoại người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `identification` | `varchar(45) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `avatar` | `varchar(500) DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `birthday` | `datetime DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `gender` | `bit(1) DEFAULT b'1'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `address` | `varchar(128) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `vin` | `bigint NOT NULL DEFAULT '0'` | Số dư VIN hiện tại của user. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `xu` | `bigint NOT NULL DEFAULT '0'` | Số dư XU hiện tại của user. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `vin_total` | `bigint NOT NULL DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `xu_total` | `bigint(20) unsigned zerofill NOT NULL DEFAULT '00000000000000000000'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `safe` | `bigint DEFAULT '0'` | Số dư trong két/safe của user. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `recharge_money` | `bigint DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `vip_point` | `int DEFAULT '0'` | Địa chỉ IP phục vụ log/bảo mật/chặn truy cập. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `vip_point_save` | `int NOT NULL DEFAULT '0'` | Địa chỉ IP phục vụ log/bảo mật/chặn truy cập. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `money_vp` | `int NOT NULL DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `dai_ly` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `status` | `int NOT NULL DEFAULT '0'` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `create_time` | `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `security_time` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `login_otp` | `bigint DEFAULT '-1'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `is_bot` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `update_pw_time` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `parent_id` | `bigint DEFAULT NULL` | ID liên kết tới đối tượng parent. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `pin` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `level` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `currency` | `varchar(10) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `country` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `last_recharge_time` | `varchar(255) DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `agent_code` | `varchar(10) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `total_level_1` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `total_level_2` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `money_affiliate` | `int DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `total_bet` | `bigint DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `is_idol` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_tevi_id` | `varchar(20) DEFAULT NULL` | ID liên kết tới đối tượng user_tevi. Nên kiểm tra quan hệ với bảng gốc. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `id_UNIQUE` (`id`) USING BTREE`
- `UNIQUE KEY `nick_name_UNIQUE` (`nick_name`) USING BTREE`
- `UNIQUE KEY `facebook_id_UNIQUE` (`facebook_id`) USING BTREE`
- `UNIQUE KEY `google_id_UNIQUE` (`google_id`) USING BTREE`
- `KEY `nickname_index` (`nick_name`) USING BTREE`
- `KEY `facebook_index` (`facebook_id`) USING BTREE`
- `KEY `google_index` (`google_id`) USING BTREE`
- `KEY `is_bot_index` (`is_bot`) USING BTREE`
- `KEY `dai_ly_index` (`dai_ly`) USING BTREE`
- `KEY `mobile_index` (`mobile`) USING BTREE`


## `vinplay.users_in_game`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_id` | `bigint DEFAULT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `game_id` | `int DEFAULT NULL` | ID liên kết tới đối tượng game. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `num_total` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `num_win` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `num_loss` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `exp` | `varchar(45) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.users_vp_event`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `user_id` | `int NOT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(45) NOT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `vp_real` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `vp_event` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `vp_add` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `num_add` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `vp_sub` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `num_sub` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `place` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `place_max` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `is_bot` | `int NOT NULL DEFAULT '-1'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `update_time` | `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm cập nhật bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`user_id`) USING BTREE`
- `UNIQUE KEY `nick_name_UNIQUE` (`nick_name`) USING BTREE`


## `vinplay.utm_campain`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `name` | `varchar(255) DEFAULT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `name_display` | `varchar(255) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.utm_medium`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `name` | `varchar(255) DEFAULT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `name_display` | `varchar(255) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.utm_source`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `name` | `varchar(255) DEFAULT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `name_display` | `varchar(255) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.videos`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `title` | `varchar(255) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `description` | `varchar(255) DEFAULT NULL` | Mô tả chi tiết. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `stream_url` | `varchar(255) DEFAULT NULL` | Đường dẫn/link cấu hình hoặc truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `thumnail` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `order` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `create_date` | `datetime DEFAULT NULL` | Thời điểm/ngày tạo bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `status` | `bit(1) DEFAULT b'0'` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.weekly_mission`

**Vai trò:** Bảng nhiệm vụ/phần thưởng.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `mission_type` | `varchar(255) DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `complete` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `status` | `smallint DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `update_time` | `datetime DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `user_name` | `varchar(255) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay.withdraw`

**Vai trò:** Bảng yêu cầu/rút tiền.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_id` | `int DEFAULT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_name` | `varchar(100) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `amount` | `int DEFAULT NULL` | Số tiền/số lượng giao dịch. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `bank_code` | `varchar(50) DEFAULT NULL` | Mã ngân hàng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `bank_account` | `varchar(50) DEFAULT NULL` | Số tài khoản ngân hàng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `account_name` | `varchar(100) DEFAULT NULL` | Tên chủ tài khoản. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `transaction_code` | `varchar(20) DEFAULT NULL` | Mã giao dịch; nên unique theo nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `order_no` | `varchar(50) DEFAULT NULL` | Mã đơn hàng/yêu cầu; nên dùng để chống xử lý trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `message` | `varchar(255) DEFAULT NULL` | Thông điệp trả về từ hệ thống/đối tác hoặc lý do xử lý. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_time` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `admin_approve` | `varchar(100) DEFAULT NULL` | Admin duyệt yêu cầu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `approve_time` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm duyệt. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `status` | `tinyint DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `type` | `varchar(50) DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `updated_time` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `previous_balance` | `int DEFAULT NULL` | Số dư trước giao dịch. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `balance_fluctuation` | `int DEFAULT NULL` | Biến động số dư trong giao dịch. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `phone_number` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `partner` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `address_wallet` | `varchar(500) DEFAULT NULL` | Thông tin kênh thanh toán/ngân hàng/ ví. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `network` | `varchar(100) DEFAULT NULL` | Thông tin kênh thanh toán/ngân hàng/ ví. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `txId` | `varchar(500) DEFAULT NULL` | Transaction ID từ đối tác/blockchain/kênh thanh toán. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `momoTransId` | `varchar(250) DEFAULT NULL` | Mã giao dịch Momo. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


# Database `vinplay_admin`

Tổng số bảng: **14**. Tổng số trường: **112**.


## `vinplay_admin.access_link`

**Vai trò:** Bảng admin/phân quyền/tài khoản quản trị.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `ID` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `User_ID` | `int DEFAULT NULL` | ID liên kết tới đối tượng user. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Group_ID` | `int DEFAULT NULL` | ID liên kết tới đối tượng group. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Menu_ID` | `int DEFAULT NULL` | ID liên kết tới đối tượng menu. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Link` | `varchar(50) DEFAULT NULL` | Đường dẫn/link cấu hình hoặc truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`ID`) USING BTREE`


## `vinplay_admin.action_admin`

**Vai trò:** Bảng admin/phân quyền/tài khoản quản trị.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `action` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_admin.groupuser`

**Vai trò:** Bảng admin/phân quyền/tài khoản quản trị.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `Id` | `int NOT NULL AUTO_INCREMENT` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Name` | `varchar(50) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `Description` | `varchar(150) DEFAULT NULL` | Mô tả chi tiết. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `Type` | `int DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`Id`) USING BTREE`


## `vinplay_admin.log_admin`

**Vai trò:** Bảng log/audit phục vụ truy vết.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `action` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `quantity` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `money` | `bigint DEFAULT NULL` | Số tiền/số lượng liên quan nghiệp vụ. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `account_name` | `text` | Tên chủ tài khoản. | Chuỗi dài; dùng cho nội dung/log/json dài. |
| `money_type` | `varchar(50) DEFAULT NULL` | Loại tiền, ví dụ VIN/XU hoặc enum tương ứng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `username` | `varchar(50) DEFAULT NULL` | Tên đăng nhập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `timestamp` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `reason` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `status` | `varchar(11) DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `username_index` (`username`) USING BTREE`


## `vinplay_admin.log_loginadmin`

**Vai trò:** Bảng log/audit phục vụ truy vết.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `username` | `varchar(255) DEFAULT NULL` | Tên đăng nhập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nickname` | `varchar(255) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `ip` | `varchar(255) DEFAULT NULL` | Địa chỉ IP phục vụ log/bảo mật/chặn truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `status` | `int DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `agent` | `varchar(255) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `action` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `tool` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `createdate` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `nickname_index` (`nickname`) USING BTREE`


## `vinplay_admin.menu`

**Vai trò:** Bảng admin/phân quyền/tài khoản quản trị.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Name` | `varchar(100) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `Param` | `int DEFAULT '1'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Link` | `varchar(150) DEFAULT NULL` | Đường dẫn/link cấu hình hoặc truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `Status` | `char(1) DEFAULT NULL` | Trạng thái nghiệp vụ; cần map enum trong backend để hiểu chính xác từng giá trị. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `Parrent_ID` | `int DEFAULT NULL` | ID liên kết tới đối tượng parrent. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `isThuong` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `isDaily` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `isSuper` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `Name_index` (`Name`) USING BTREE`
- `KEY `Param_index` (`Param`) USING BTREE`
- `KEY `Link_index` (`Link`) USING BTREE`
- `KEY `Status_index` (`Status`) USING BTREE`
- `KEY `Parrent_ID_index` (`Parrent_ID`) USING BTREE`
- `KEY `isThuong_index` (`isThuong`) USING BTREE`
- `KEY `isDaily_index` (`isDaily`) USING BTREE`
- `KEY `isSuper_index` (`isSuper`) USING BTREE`


## `vinplay_admin.price_giftcode`

**Vai trò:** Bảng giftcode/free code.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `price` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `money_type` | `int DEFAULT NULL` | Loại tiền, ví dụ VIN/XU hoặc enum tương ứng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_admin.request_withdraw`

**Vai trò:** Bảng yêu cầu/rút tiền.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(20) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `bank` | `varchar(255) DEFAULT NULL` | Thông tin kênh thanh toán/ngân hàng/ ví. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `bank_account_name` | `varchar(255) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `bank_account_number` | `varchar(255) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `amount` | `bigint DEFAULT NULL` | Số tiền/số lượng giao dịch. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `create_date` | `datetime DEFAULT NULL` | Thời điểm/ngày tạo bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_admin.rolemenu`

**Vai trò:** Bảng admin/phân quyền/tài khoản quản trị.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `Group_ID` | `int NOT NULL` | ID liên kết tới đối tượng group. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Menu_ID` | `int NOT NULL` | ID liên kết tới đối tượng menu. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `ID` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Type` | `int DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`ID`) USING BTREE`
- `KEY `Group_ID_index` (`Group_ID`) USING BTREE`
- `KEY `Menu_ID_index` (`Menu_ID`) USING BTREE`
- `KEY `Type_index` (`Type`) USING BTREE`


## `vinplay_admin.source_giftcode`

**Vai trò:** Bảng giftcode/free code.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `name` | `varchar(255) DEFAULT NULL` | Tên hiển thị hoặc tên cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `key` | `varchar(11) DEFAULT NULL` | Khóa cấu hình hoặc tên biến trong bảng key-value. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `type` | `int DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `display` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_admin.url_builder`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay_admin.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `url_web` | `varchar(50) DEFAULT NULL` | Đường dẫn/link cấu hình hoặc truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `utm_source` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `utm_medium` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `utm_term` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `utm_content` | `varchar(50) DEFAULT NULL` | Nội dung mô tả/thông báo/log. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `utm_campaign` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `url_generate` | `varchar(2000) DEFAULT NULL` | Đường dẫn/link cấu hình hoặc truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_admin.user`

**Vai trò:** Bảng admin/phân quyền/tài khoản quản trị.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `ID` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `UserName` | `varchar(50) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `Password` | `varchar(50) DEFAULT NULL` | Mật khẩu hoặc hash mật khẩu. Cần kiểm tra có đang hash an toàn không. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `NameAgent` | `varchar(50) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `FullName` | `varchar(100) DEFAULT NULL` | Tên hiển thị/tên đối tượng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `Email` | `varchar(50) DEFAULT NULL` | Email. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `Address` | `varchar(50) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `BirthDay` | `date DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Ngày, không gồm giờ. |
| `CMND` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Phone` | `varchar(255) DEFAULT NULL` | Số điện thoại. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `Status` | `char(2) DEFAULT NULL` | Trạng thái nghiệp vụ; cần map enum trong backend để hiểu chính xác từng giá trị. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `ParentID` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Active` | `int DEFAULT NULL` | Cờ đang hoạt động/kích hoạt. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `isThuong` | `int DEFAULT '2'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `isSuper` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Facebook` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `Key` | `varchar(11) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `Balance` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`ID`) USING BTREE`
- `KEY `UserName_index` (`UserName`) USING BTREE`
- `KEY `FullName_index` (`FullName`) USING BTREE`
- `KEY `Status_index` (`Status`) USING BTREE`
- `KEY `isThuong_index` (`isThuong`) USING BTREE`
- `KEY `isSuper_index` (`isSuper`) USING BTREE`


## `vinplay_admin.useragent`

**Vai trò:** Bảng admin/phân quyền/tài khoản quản trị.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `username` | `varchar(50) DEFAULT NULL` | Tên đăng nhập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nickname` | `varchar(50) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `password` | `varchar(50) DEFAULT NULL` | Mật khẩu hoặc hash mật khẩu. Cần kiểm tra có đang hash an toàn không. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nameagent` | `varchar(50) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `address` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `phone` | `varchar(50) DEFAULT NULL` | Số điện thoại. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `email` | `varchar(50) DEFAULT NULL` | Email. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `facebook` | `varchar(255) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `key` | `varchar(10) DEFAULT NULL` | Khóa cấu hình hoặc tên biến trong bảng key-value. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `status` | `varchar(2) DEFAULT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `parentid` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `namebank` | `varchar(255) DEFAULT NULL` | Thông tin kênh thanh toán/ngân hàng/ ví. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nameaccount` | `varchar(255) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `numberaccount` | `varchar(255) DEFAULT NULL` | Thông tin định danh user/tài khoản/đại lý liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `show` | `int DEFAULT '1'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `active` | `int DEFAULT '1'` | Cờ đang hoạt động/kích hoạt. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `createtime` | `datetime DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `updatetime` | `datetime DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `order` | `int DEFAULT '1'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `sms` | `int DEFAULT '-1'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `percent_bonus_vincard` | `int DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `parent` | `varchar(45) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `balance` | `bigint DEFAULT '0'` | Số dư tài khoản/đại lý/admin tùy bảng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `nickname_index` (`nickname`) USING BTREE`
- `KEY `status_index` (`status`) USING BTREE`
- `KEY `parentid_index` (`parentid`) USING BTREE`
- `KEY `show_index` (`show`) USING BTREE`
- `KEY `active_index` (`active`) USING BTREE`
- `KEY `sms_index` (`sms`) USING BTREE`
- `KEY `order_index` (`order`) USING BTREE`
- `KEY `percent_bonus_vincard` (`percent_bonus_vincard`) USING BTREE`


## `vinplay_admin.userrole`

**Vai trò:** Bảng admin/phân quyền/tài khoản quản trị.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `ID` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `User_ID` | `int NOT NULL` | ID liên kết tới đối tượng user. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Group_ID` | `int NOT NULL` | ID liên kết tới đối tượng group. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `Type` | `int DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`ID`) USING BTREE`


# Database `vinplay_minigame`

Tổng số bảng: **14**. Tổng số trường: **90**.


## `vinplay_minigame.game_result`

**Vai trò:** Bảng kết quả game/phiên.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `game` | `int DEFAULT NULL` | Mã/loại game. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `result` | `varchar(20) DEFAULT NULL` | Kết quả game/phiên xử lý. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_date` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `referenceId` | `int DEFAULT NULL` | Mã tham chiếu giao dịch/vòng chơi. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_minigame.hu_game_bai`

**Vai trò:** Bảng quỹ/hũ/jackpot.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `pot_name` | `varchar(45) DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `bigint DEFAULT NULL` | Giá trị tương ứng với key/cấu hình. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_minigame.key_value`

**Vai trò:** Bảng cấu hình dạng key-value/config.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `key` | `varchar(45) NOT NULL` | Khóa cấu hình hoặc tên biến trong bảng key-value. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `int DEFAULT NULL` | Giá trị tương ứng với key/cấu hình. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `updated_at` | `date DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày, không gồm giờ. |

**Key / Index:**
- `PRIMARY KEY (`key`) USING BTREE`


## `vinplay_minigame.lucky_rotation`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay_minigame.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_id` | `int NOT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(45) NOT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `rotate_daily` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `rotate_free` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `rotate_in_day` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `login_date` | `date DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày, không gồm giờ. |
| `rotate_time` | `datetime DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `nickname_UNIQUE` (`nick_name`) USING BTREE`
- `UNIQUE KEY `user_id_UNIQUE` (`user_id`) USING BTREE`
- `KEY `user_id_index` (`user_id`) USING BTREE`
- `KEY `nickname_index` (`nick_name`) USING BTREE`
- `KEY `login_date_index` (`login_date`) USING BTREE`


## `vinplay_minigame.lucky_rotation_ip_block`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay_minigame.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `ip_address` | `varchar(45) NOT NULL` | Địa chỉ IP phục vụ log/bảo mật/chặn truy cập. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `rotate_win_in_day` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `rotate_date` | `date DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày, không gồm giờ. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `ip_address_UNIQUE` (`ip_address`) USING BTREE`


## `vinplay_minigame.minigame_funds`

**Vai trò:** Bảng quỹ/hũ/jackpot.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `fund_name` | `varchar(45) DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `bigint DEFAULT NULL` | Giá trị tương ứng với key/cấu hình. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_minigame.minigame_pots`

**Vai trò:** Bảng quỹ/hũ/jackpot.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `pot_name` | `varchar(45) NOT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `bigint DEFAULT NULL` | Giá trị tương ứng với key/cấu hình. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_minigame.references`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay_minigame.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `game_id` | `int DEFAULT NULL` | ID liên kết tới đối tượng game. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `value` | `bigint DEFAULT NULL` | Giá trị tương ứng với key/cấu hình. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_minigame.result_tai_xiu`

**Vai trò:** Bảng kết quả game/phiên.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `reference_id` | `bigint DEFAULT NULL` | Mã tham chiếu giao dịch/vòng chơi. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `result` | `tinyint DEFAULT NULL` | Kết quả game/phiên xử lý. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `dice1` | `tinyint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `dice2` | `tinyint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `dice3` | `tinyint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `total_tai` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_xiu` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `num_bet_tai` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `num_bet_xiu` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `total_prize` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_refund_tai` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_refund_xiu` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_revenue` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `money_type` | `tinyint DEFAULT NULL` | Loại tiền, ví dụ VIN/XU hoặc enum tương ứng. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `timestamp` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `reference_index` (`reference_id`) USING BTREE`
- `KEY `money_type_index` (`money_type`) USING BTREE`
- `KEY `timestamp_index` (`timestamp`) USING BTREE`


## `vinplay_minigame.rotate_slot_free`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay_minigame.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `user_id` | `int NOT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(45) NOT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `game_name` | `varchar(45) NOT NULL` | Tên hoặc mã game liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `room` | `int NOT NULL DEFAULT '100'` | Thông tin phiên/vòng/phòng chơi. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `rotate_free` | `int DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `max_winning` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `update_time` | `timestamp NULL DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`user_id`,`nick_name`,`game_name`,`room`) USING BTREE`


## `vinplay_minigame.thanh_du`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay_minigame.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_name` | `varchar(45) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `number` | `int DEFAULT '1'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `total_betting` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `last_reference` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `references` | `varchar(512) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `last_update` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `type` | `tinyint DEFAULT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `username_index` (`user_name`) USING BTREE`
- `KEY `type_index` (`type`) USING BTREE`
- `KEY `last_update_index` (`last_update`) USING BTREE`
- `KEY `update_index` (`user_name`,`last_update`,`type`) USING BTREE`


## `vinplay_minigame.transaction_detail_tai_xiu`

**Vai trò:** Bảng giao dịch game/nghiệp vụ.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `reference_id` | `bigint DEFAULT NULL` | Mã tham chiếu giao dịch/vòng chơi. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `transaction_code` | `varchar(120) DEFAULT NULL` | Mã giao dịch; nên unique theo nghiệp vụ. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `user_id` | `int DEFAULT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_name` | `varchar(45) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `bet_value` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `bet_side` | `tinyint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `prize` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `refund` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `input_time` | `int DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `money_type` | `tinyint DEFAULT NULL` | Loại tiền, ví dụ VIN/XU hoặc enum tương ứng. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `timestamp` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `reference_index` (`reference_id`) USING BTREE`
- `KEY `timestampt_index` (`timestamp`) USING BTREE`
- `KEY `user_name_index` (`user_name`) USING BTREE`


## `vinplay_minigame.transaction_tai_xiu`

**Vai trò:** Bảng giao dịch game/nghiệp vụ.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `reference_id` | `bigint DEFAULT NULL` | Mã tham chiếu giao dịch/vòng chơi. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `user_id` | `int DEFAULT NULL` | ID người dùng, thường tham chiếu tới users.id. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_name` | `varchar(45) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `bet_value` | `bigint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `bet_side` | `tinyint DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `total_prize` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_refund` | `bigint DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `total_exchange` | `bigint DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `money_type` | `tinyint DEFAULT NULL` | Loại tiền, ví dụ VIN/XU hoặc enum tương ứng. | Số nguyên rất nhỏ; thường dùng cờ boolean/trạng thái. |
| `timestamp` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `KEY `reference_index` (`reference_id`) USING BTREE`
- `KEY `user_name_index` (`user_name`) USING BTREE`
- `KEY `timestamp_index` (`timestamp`) USING BTREE`
- `KEY `money_type_index` (`money_type`) USING BTREE`


## `vinplay_minigame.user_rut_loc`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay_minigame.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_name` | `varchar(45) DEFAULT NULL` | Tên đăng nhập hoặc username của người dùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `so_lan_rut` | `int DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `last_update` | `timestamp NULL DEFAULT CURRENT_TIMESTAMP` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `user_name_UNIQUE` (`user_name`) USING BTREE`


# Database `vinplay_gamebai`

Tổng số bảng: **11**. Tổng số trường: **95**.


## `vinplay_gamebai.game_data`

**Vai trò:** Bảng cấu hình dạng key-value/config.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `key` | `varchar(100) NOT NULL` | Khóa cấu hình hoặc tên biến trong bảng key-value. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `varchar(1000) NOT NULL` | Giá trị tương ứng với key/cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_time` | `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `update_time` | `timestamp NULL DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |


## `vinplay_gamebai.game_free_code_detail`

**Vai trò:** Bảng giftcode/free code.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `bigint NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `code` | `varchar(45) NOT NULL` | Mã định danh nghiệp vụ; có thể là mã agent, mã game, mã giao dịch hoặc mã quà. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `package_id` | `int NOT NULL` | ID liên kết tới đối tượng package. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `game_name` | `varchar(45) NOT NULL` | Tên hoặc mã game liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `type` | `int NOT NULL DEFAULT '0'` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `amount` | `int NOT NULL DEFAULT '0'` | Số tiền/số lượng giao dịch. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `status` | `int NOT NULL DEFAULT '0'` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `expire` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `create_time` | `timestamp NOT NULL` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `nick_name` | `varchar(45) DEFAULT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `add_info` | `varchar(45) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `use_time` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`
- `UNIQUE KEY `code_UNIQUE` (`code`) USING BTREE`


## `vinplay_gamebai.game_free_code_package`

**Vai trò:** Bảng giftcode/free code.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `bigint NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `game_name` | `varchar(45) NOT NULL` | Tên hoặc mã game liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `type` | `int NOT NULL DEFAULT '0'` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `quantity` | `int NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `amount` | `int NOT NULL DEFAULT '0'` | Số tiền/số lượng giao dịch. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `expire` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `create_time` | `timestamp NOT NULL` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `creater` | `varchar(45) NOT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_gamebai.game_tour_info`

**Vai trò:** Bảng tournament/giải đấu game bài.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `key` | `varchar(100) NOT NULL` | Khóa cấu hình hoặc tên biến trong bảng key-value. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `varchar(1000) NOT NULL` | Giá trị tương ứng với key/cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_time` | `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `update_time` | `timestamp NULL DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`key`) USING BTREE`


## `vinplay_gamebai.game_tour_jackpot`

**Vai trò:** Bảng quỹ/hũ/jackpot.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `key` | `varchar(100) NOT NULL` | Khóa cấu hình hoặc tên biến trong bảng key-value. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `bigint NOT NULL DEFAULT '0'` | Giá trị tương ứng với key/cấu hình. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `create_time` | `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`key`) USING BTREE`


## `vinplay_gamebai.game_tour_mark`

**Vai trò:** Bảng tournament/giải đấu game bài.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `nick_name` | `varchar(100) NOT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `game_name` | `varchar(45) NOT NULL` | Tên hoặc mã game liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `tour_id` | `varchar(45) NOT NULL` | ID liên kết tới đối tượng tour. Nên kiểm tra quan hệ với bảng gốc. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `fee` | `int NOT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `start_time` | `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `mark` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `top` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `user_total` | `int NOT NULL DEFAULT '0'` | Thông tin định danh user/tài khoản/đại lý liên quan. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `status` | `int NOT NULL DEFAULT '0'` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `prize` | `varchar(45) DEFAULT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_time` | `timestamp NOT NULL` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `update_time` | `timestamp NULL DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`nick_name`,`game_name`,`tour_id`) USING BTREE`


## `vinplay_gamebai.game_tour_vip`

**Vai trò:** Bảng tournament/giải đấu game bài.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `nick_name` | `varchar(100) NOT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `game_name` | `varchar(45) NOT NULL` | Tên hoặc mã game liên quan. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `vip_tour_id` | `varchar(45) NOT NULL` | ID liên kết tới đối tượng vip_tour. Nên kiểm tra quan hệ với bảng gốc. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `value` | `varchar(1000) DEFAULT NULL` | Giá trị tương ứng với key/cấu hình. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `create_time` | `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `update_time` | `timestamp NULL DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |

**Key / Index:**
- `PRIMARY KEY (`nick_name`,`vip_tour_id`,`game_name`) USING BTREE`


## `vinplay_gamebai.poker_free_ticket`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay_gamebai.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(45) NOT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `ticket` | `int NOT NULL DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `tour_type` | `int NOT NULL DEFAULT '0'` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `used` | `bit(1) NOT NULL DEFAULT b'0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `create_time` | `timestamp NULL DEFAULT NULL` | Thời điểm tạo bản ghi. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `available_time` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `limit_time` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `use_time` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `create_type` | `int NOT NULL` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `add_info` | `varchar(45) DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `is_bot` | `bit(1) NOT NULL DEFAULT b'0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Kiểu dữ liệu khác; cần kiểm tra nghiệp vụ sử dụng thực tế. |
| `tour_id` | `int NOT NULL DEFAULT '0'` | ID liên kết tới đối tượng tour. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_gamebai.poker_tour`

**Vai trò:** Bảng tournament/giải đấu game bài.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `id` | `int NOT NULL AUTO_INCREMENT` | Khóa định danh dòng dữ liệu, thường auto increment. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `start_time_schedule` | `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `end_register_schedule` | `timestamp NULL DEFAULT NULL` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `tour_state` | `int NOT NULL DEFAULT '0'` | Trạng thái nghiệp vụ; cần map enum trong backend để hiểu chính xác từng giá trị. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `tour_type` | `int NOT NULL DEFAULT '0'` | Loại nghiệp vụ; cần map enum trong backend. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `start_time` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `end_register_time` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `cancel_time` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `end_time` | `timestamp NULL DEFAULT NULL` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Ngày giờ có cơ chế default/update; thường dùng created/updated time. |
| `level` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `ticket` | `int NOT NULL DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `count_time_up_level` | `int NOT NULL DEFAULT '0'` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `fund` | `bigint NOT NULL DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`id`) USING BTREE`


## `vinplay_gamebai.poker_tour_user`

**Vai trò:** Bảng tournament/giải đấu game bài.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `tour_id` | `int NOT NULL` | ID liên kết tới đối tượng tour. Nên kiểm tra quan hệ với bảng gốc. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `nick_name` | `varchar(50) NOT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `current_chip` | `bigint NOT NULL DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `ticket_count` | `int NOT NULL DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `out_tour_count` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `out_tour_time` | `bigint NOT NULL DEFAULT '0'` | Thời điểm/ngày liên quan tới vòng đời bản ghi hoặc nghiệp vụ. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `last_chip` | `bigint NOT NULL DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `rank` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `mark` | `int NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `prize` | `int NOT NULL DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |

**Key / Index:**
- `PRIMARY KEY (`tour_id`,`nick_name`) USING BTREE`


## `vinplay_gamebai.xoc_dia_boss`

**Vai trò:** Bảng nghiệp vụ thuộc database vinplay_gamebai.

| Trường | Kiểu dữ liệu / constraint | Ý nghĩa nghiệp vụ | Ghi chú kiểu dữ liệu |
|---|---|---|---|
| `session_id` | `varchar(100) NOT NULL` | Mã phiên chơi/phiên xử lý. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `nick_name` | `varchar(45) NOT NULL` | Nickname hiển thị/định danh trong game. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `room_id` | `int NOT NULL` | ID phòng chơi. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `room_setting` | `varchar(1000) NOT NULL` | Thông tin phiên/vòng/phòng chơi. | Chuỗi giới hạn độ dài; dùng cho mã, tên, trạng thái dạng text. |
| `fund_initial` | `bigint NOT NULL` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |
| `status` | `int NOT NULL` | Trạng thái xử lý/nghiệp vụ. Cần có enum rõ ràng trong code. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `create_time` | `datetime NOT NULL` | Thời điểm tạo bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `update_time` | `datetime DEFAULT NULL` | Thời điểm cập nhật bản ghi. | Ngày giờ; thường dùng thời điểm nghiệp vụ. |
| `fee` | `int NOT NULL DEFAULT '0'` | Trường số tiền/số lượng/quỹ trong nghiệp vụ. Cần kiểm tra đơn vị và chống cập nhật trùng. | Số nguyên; dùng cho id, trạng thái, số lượng. Nếu là tiền lớn nên cân nhắc BIGINT. |
| `revenue` | `bigint NOT NULL DEFAULT '0'` | Chưa có comment trong schema; ý nghĩa cần xác nhận thêm từ code backend hoặc dữ liệu mẫu. | Số nguyên lớn; phù hợp cho tiền/số lượng lớn nếu dùng đơn vị nhỏ nhất. |

**Key / Index:**
- `PRIMARY KEY (`session_id`) USING BTREE`
