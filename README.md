# Smartwatch Fall & Health Monitor

Ứng dụng Flutter Android/iOS theo dõi dữ liệu sức khỏe và cảnh báo té ngã từ ESP32-C3 qua Firebase Realtime Database. UI dùng Dark Theme, Provider, biểu đồ 20 điểm gần nhất và lớp cảnh báo SOS.

## 1. Tạo project và cài dependencies

Project Flutter đã được khởi tạo trong thư mục này. Nếu tạo mới từ đầu:

```bash
flutter create --org com.example smartwatch_fall_health_monitor
cd smartwatch_fall_health_monitor
```

Thay nội dung `pubspec.yaml` bằng cấu hình trong project này, sau đó:

```bash
flutter pub get
```

Các package chính được ghim theo yêu cầu: `firebase_core`, `firebase_auth`, `firebase_database`, `provider`, `fl_chart`, `url_launcher`, `audioplayers`, `intl`.

## 2. Cấu hình Firebase Android/iOS

1. Trong Firebase Console, mở project `smartwatch-c1877`.
2. Vào **Authentication → Sign-in method**, bật **Email/Password**. Tạo sẵn tài khoản giám sát; ứng dụng hiện chỉ có đăng nhập và đặt lại mật khẩu.
3. Đảm bảo Realtime Database đang dùng URL `https://smartwatch-c1877-default-rtdb.firebaseio.com/`.
4. Android đã khớp application ID `com.iot.smartwatch` theo file Firebase hiện có. iOS đăng ký với bundle ID hiện tại trong Xcode (`com.example.watchiot`).
5. Tải `google-services.json` và đặt ở `android/app/`. Project đã khai báo Google Services Gradle plugin trong `android/settings.gradle.kts` và `android/app/build.gradle.kts`; plugin này biến cấu hình JSON thành tài nguyên Firebase Android. Tải `GoogleService-Info.plist`, đặt ở `ios/Runner/` và thêm vào target Runner trong Xcode. Firebase cần iOS 15 trở lên theo cấu hình SDK hiện tại.
6. Project gọi `Firebase.initializeApp()` để dùng cấu hình native mặc định. Giữ đúng tên file và application/bundle IDs đã đăng ký trong Firebase Console.
7. (Tùy chọn) FlutterFire CLI có thể đăng ký app và tạo `firebase_options.dart`:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Code hiện tại dùng native config từ hai file ở bước trên; file `firebase_options.dart` do CLI tạo không được import.
8. Chạy ứng dụng trên thiết bị hoặc emulator có Google Play Services:

   ```bash
   flutter run
   ```

Ứng dụng lấy `FirebaseAuth.currentUser.uid` làm UID thiết bị. Vì vậy, với cấu hình hiện tại, UID người đăng nhập phải đúng với `<UID>` trong `devices/<UID>/`. Nếu tài khoản người thân và UID của đồng hồ khác nhau, cần thay `deviceUid` trong `AuthGate` bằng mapping được cấp quyền từ backend/user profile; không lấy UID tùy ý từ input người dùng.

### Quy tắc Realtime Database tham khảo

Không dùng Rules mở công khai. Mẫu dưới đây giả định UID đăng nhập chính là UID thiết bị và firmware xác thực với Firebase:

```json
{
  "rules": {
    ".read": false,
    ".write": false,
    "devices": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        "latest": {
          ".write": "auth != null && auth.uid === $uid"
        },
        "events": {
          ".write": "auth != null && auth.uid === $uid"
        },
        "commands": {
          ".write": "auth != null && auth.uid === $uid"
        }
      }
    }
  }
}
```

Thiết bị ESP32-C3 cần gửi credential/token hợp lệ theo Rules; không nhúng Firebase Database Secret vào firmware/app. Trong Firebase Console hãy kiểm tra Rules phù hợp với cách firmware đang xác thực trước khi triển khai.

## 3. Cấu trúc dữ liệu và firmware cần phối hợp

App đọc các nhánh:

```text
devices/<UID>/latest/health
devices/<UID>/latest/sensor
devices/<UID>/latest/alert
devices/<UID>/events
```

Schema hiện có được đọc trực tiếp. Để xác định Online/Offline chính xác sau khi mở app lại, nên bổ sung `updated_at` (Unix milliseconds đồng bộ NTP) vào các payload `latest` hoặc một `last_seen` ở `devices/<UID>`. Nếu không có timestamp, UI dùng thời điểm app nhận snapshot gần nhất; snapshot ban đầu sau khi kết nối có thể là dữ liệu cũ.

Để đồng bộ bộ đếm 15 giây khi app mở giữa chừng, alert nên có `started_at` (Unix milliseconds), hoặc `countdown_remaining_ms`. Nếu không có, app bắt đầu đếm từ lúc nhận trạng thái `FALL_ALERT_START`.

Nút hủy không ghi đè `latest/alert`. App gửi lệnh:

```json
{
  "devices/<UID>/commands/cancel_alert": {
    "status": "REQUESTED",
    "requested_at": 1730000000000,
    "requested_by": "<auth uid>"
  }
}
```

Firmware cần theo dõi/đọc nhánh `commands/cancel_alert`, xử lý xác nhận an toàn, cập nhật `latest/alert.status` thành `ALERT_CANCELLED_BY_USER`, ghi event vào `events`, rồi xóa/acknowledge command. App chỉ hiện cuộc gọi 115 sau `EMERGENCY_CONFIRMED`; nút gọi người thân yêu cầu nhập số điện thoại. Đổi tên hiển thị app, package ID và số cấp cứu theo thị trường triển khai nếu cần.

`accel` được hiển thị theo đơn vị `m/s²` như yêu cầu. Firmware cần gửi SI units; nếu gửi gia tốc theo `g`, hãy nhân từng trục với `9.80665` trước khi dùng số đo này.

## 4. File chính

```text
lib/
  app/                      # composition root cho AuthGate và AppShell
  core/                     # theme và cấu hình dùng chung
  features/auth/
    data/                   # Firebase Auth datasource và repository impl
    domain/                 # AppUser, repository contract, use cases
    presentation/           # AuthProvider và LoginView
  features/monitoring/
    data/                   # RTDB datasource, mapper, repo impl, audio adapter
    domain/                 # entities, repository/alarm contracts, use cases
    presentation/           # WatchDataProvider, dashboard, history, SOS, widgets
  main.dart
```

Luồng phụ thuộc: `presentation → domain`; `data → domain`; Firebase và plugin chỉ nằm ở `data`. `main.dart` là composition root, tạo datasource, repository implementation và use case rồi inject chúng vào Provider.

Biểu đồ và còi hoạt động khi app đang chạy. Nếu cần cảnh báo đáng tin cậy khi app bị hệ điều hành đưa xuống nền/đóng, cần bổ sung Firebase Cloud Messaging và backend/Cloud Function phát push; listener Realtime Database trong app không thay thế được push notification nền.
