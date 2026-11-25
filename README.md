# Smartwatch Fall & Health Monitor

Ứng dụng Flutter Android/iOS theo dõi sức khỏe, đọc cảnh báo từ ESP32 qua Firebase Realtime Database và mở trình gọi điện để người dùng liên hệ người thân. UI hiện dùng giao diện sáng trắng/vàng nhạt.

## Chạy ứng dụng

1. Cài Flutter và Android Studio; trên macOS cài Xcode/CocoaPods để build iOS.
2. Bật **Authentication → Email/Password** trong Firebase Console.
3. Đặt cấu hình Firebase native:
   - Android: `android/app/google-services.json` (application ID: `com.iot.smartwatch`).
   - iOS: tải `GoogleService-Info.plist`, thêm vào `ios/Runner/` và target Runner trong Xcode (bundle ID: `com.example.watchiot`). Target iOS tối thiểu là 15.
4. Lấy URL Realtime Database và UID Firebase mà firmware ESP32 dùng. UID này có thể khác UID tài khoản đăng nhập app.
5. Chạy:

   ```bash
   flutter pub get
   flutter run
   ```

6. Đăng nhập bằng tài khoản Firebase Authentication của người giám sát. Mở **Hồ sơ → Cài đặt Firebase và người thân**, nhập URL/DEVICE_UID, thêm số điện thoại, rồi chủ động bật **Cho phép gọi khi xác nhận té ngã**.

Không đưa service account key, Database Secret hoặc mật khẩu Firebase vào app. Firebase native config không phải thông tin xác thực thay thế cho RTDB Rules.

## Luồng cảnh báo

App lắng nghe `devices/{DEVICE_UID}/alerts/latest`. Chỉ xử lý khi `type == "alert"`, `status == "EMERGENCY_CONFIRMED"`, `notify_family == true` và có `alert_id`. App bỏ qua bản ghi hiện hữu trong lần kết nối đầu tiên của thiết bị, lưu ID đã xử lý trong vùng lưu trữ bảo mật, và chỉ mở trình gọi sau khi người dùng bấm nút.

Xem hướng dẫn Rules, payload, trạng thái lỗi, giới hạn Android/iOS và thiết lập cảnh báo nền tại [docs/emergency-alerts.md](docs/emergency-alerts.md).

## Kiểm tra

```bash
flutter analyze lib test
flutter test
flutter build apk --debug
```

Build iOS cần macOS/Xcode và file `ios/Runner/GoogleService-Info.plist` của app iOS đã đăng ký trong Firebase Console.
