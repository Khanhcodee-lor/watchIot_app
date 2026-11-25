# Hướng dẫn cảnh báo té ngã và gọi người thân

## Firebase identity và đường dẫn

Ứng dụng có hai UID khác mục đích:

- **UID tài khoản app**: tài khoản Email/Password của người giám sát, dùng để đăng nhập Firebase Authentication.
- **DEVICE_UID**: UID Firebase mà firmware ESP32 dùng để ghi dữ liệu. Nhập riêng trong **Hồ sơ → Cài đặt Firebase và người thân**. Không tự lấy DEVICE_UID từ tài khoản đăng nhập app.

URL Realtime Database và DEVICE_UID được lưu cục bộ bằng `flutter_secure_storage`. Dữ liệu cảnh báo được đọc bằng Firebase Realtime Database SDK tại:

```text
devices/{DEVICE_UID}/alerts/latest
```

Ví dụ payload:

```json
{
  "type": "alert",
  "status": "EMERGENCY_CONFIRMED",
  "alert_id": "fall-2026-11-25T081500Z-001",
  "notify_family": true,
  "message": "Fall confirmed! No button press received during grace period.",
  "p_fall": 1,
  "uptime_ms": 123456
}
```

Firmware phải tạo `alert_id` mới cho mỗi lần té ngã. App chỉ bắt đầu quy trình người thân khi `type` là `alert`, `status` đúng bằng `EMERGENCY_CONFIRMED`, `notify_family` là boolean `true`, và `alert_id` không rỗng. `FALL_ALERT_START`, `ALERT_CANCELLED_BY_USER`, `EMERGENCY_DISMISSED`, `notify_family: false` và payload sai định dạng không mở trình gọi.

## RTDB Rules: đọc được nhưng không ghi từ app

Trong Firebase Console, thêm quyền xem thiết bị cho người dùng app bằng dữ liệu được quản lý tin cậy, ví dụ:

```text
device_access/{DEVICE_UID}/{APP_AUTH_UID} = true
```

Không cho app tự ghi cây `device_access`. Ví dụ Rules dưới đây cấp quyền đọc cảnh báo, sức khỏe và lịch sử cho người dùng có trong danh sách; chỉ tài khoản ESP32 có UID trùng DEVICE_UID được ghi dữ liệu thiết bị:

```json
{
  "rules": {
    ".read": false,
    ".write": false,
    "devices": {
      "$deviceUid": {
        ".write": "auth != null && auth.uid == $deviceUid",
        "alerts": {
          "latest": {
            ".read": "auth != null && root.child('device_access').child($deviceUid).child(auth.uid).val() == true"
          }
        },
        "latest": {
          ".read": "auth != null && root.child('device_access').child($deviceUid).child(auth.uid).val() == true"
        },
        "events": {
          ".read": "auth != null && root.child('device_access').child($deviceUid).child(auth.uid).val() == true"
        }
      }
    }
  }
}
```

Rules này giả định firmware xác thực Firebase với UID trùng DEVICE_UID. Nếu firmware đang xác thực theo cách khác, sửa điều kiện `.write` cho đúng danh tính thiết bị; không mở `.read`/`.write` công khai. Phần cảnh báo của app không gọi `set`, `update` hay REST write lên RTDB. Dashboard và lịch sử hiện có vẫn cần quyền đọc `latest` và `events`.

Khi Firebase từ chối đọc, app hiển thị lỗi cùng đường dẫn cần quyền. Kiểm tra email đăng nhập, mapping `device_access`, project Firebase của app, URL database và Rules. Trạng thái `.info/connected` báo kết nối mạng/Firebase; nó không thay cho kiểm tra quyền đọc node cảnh báo.

## Hành vi cảnh báo và chống lặp

1. Lần đầu app kết nối một cặp URL/DEVICE_UID, snapshot hiện hữu được xem là dữ liệu nền. Nếu đó là cảnh báo xác nhận cũ, ID được lưu là lịch sử và app không phát còi, rung hay bật quy trình gọi.
2. ID đã xử lý, ID lịch sử ban đầu và ID đã mở trình gọi được lưu trong `flutter_secure_storage`; reconnect hoặc khởi động app lại không tự mở trình gọi lần nữa.
3. Với cảnh báo mới hợp lệ, app hiển thị màn hình khẩn cấp, phát âm báo/rung khi hệ điều hành cho phép, và hiện trạng thái **Đang chờ bạn xác nhận gọi**.
4. Người dùng bấm **GỌI NGƯỜI THÂN NGAY**. Nếu có nhiều số, chọn một người. App chỉ yêu cầu hệ điều hành mở URI `tel:`; người dùng hoàn tất hoặc hủy thao tác trong trình gọi/xác nhận hệ điều hành.
5. App báo **Đã mở trình gọi**, không khẳng định cuộc gọi đã kết nối. iOS/Android không cung cấp cho luồng này bằng chứng đáng tin cậy rằng người dùng đã thực sự gọi hoặc đã hủy hộp thoại hệ thống. Nút ẩn trên app chỉ ẩn giao diện cục bộ, không ghi thay đổi về đồng hồ.
6. Có thể bật/tắt **Cho phép gọi khi xác nhận té ngã** trong Cài đặt an toàn. Mặc định tắt; cần URL, DEVICE_UID và ít nhất một số điện thoại hợp lệ mới bật được.

## Giới hạn gọi điện trên Android và iOS

App dùng `url_launcher` với `tel:` và không yêu cầu `CALL_PHONE`, không gọi ngầm và không cố vượt qua bước xác nhận của hệ điều hành. Trên Android, `tel:` mở trình quay số để người dùng bấm gọi. Trên iOS, hệ thống hiển thị xác nhận trước khi gọi. Vì vậy trạng thái `dialerOpened` chỉ có nghĩa là đã mở trình gọi, không phải cuộc gọi đã được thực hiện.

Số điện thoại người thân chỉ nằm trong vùng lưu trữ cục bộ bảo vệ bởi hệ điều hành; app không đưa số điện thoại vào log hoặc Firebase.

## Cảnh báo khi app ở nền/đã bị đóng

Listener Realtime Database chạy trong tiến trình app không bảo đảm nhận sự kiện khi app bị hệ điều hành tạm dừng, bị đóng hoặc thiết bị khởi động lại. Bản app hiện tại chưa triển khai FCM và không giả định listener luôn hoạt động nền.

Để bổ sung push:

1. Thêm Firebase Cloud Functions (hoặc backend tin cậy) lắng nghe thay đổi `devices/{DEVICE_UID}/alerts/latest`.
2. Ở backend, chỉ nhận `EMERGENCY_CONFIRMED` cùng `notify_family == true`, xác thực người nhận được liên kết với thiết bị, và lưu/kiểm tra `alert_id` bằng thao tác idempotent trước khi gửi.
3. Đăng ký FCM token của app sau khi xin quyền thông báo; lưu mapping token với app user/device ở backend có kiểm soát truy cập.
4. Gửi FCM notification cho người thân. Trên iOS cấu hình APNs trong Firebase; trên Android cấu hình notification channel và quyền thông báo phù hợp phiên bản hệ điều hành.
5. Khi người dùng chạm notification, mở màn hình cảnh báo rồi để người dùng chủ động bấm gọi. Push notification cũng không cho app tự bỏ qua xác nhận cuộc gọi.

Không đặt Firebase Admin/service account key trong ứng dụng Flutter. Cloud Function/backend dùng danh tính server ở môi trường máy chủ.

## Cấu hình nền tảng và kiểm tra

- Bật Email/Password ở Firebase Authentication.
- Android cần `android/app/google-services.json` cho application ID `com.iot.smartwatch`.
- iOS cần đăng ký bundle ID `com.example.watchiot`, tải `GoogleService-Info.plist`, thêm vào target Runner và dùng iOS 15 trở lên.
- Realtime Database URL mặc định nằm ở `lib/core/app_config.dart`; có thể thay URL và DEVICE_UID trong màn hình cài đặt.
- Từ thư mục project chạy:

  ```bash
  flutter pub get
  flutter analyze lib test
  flutter test
  flutter run
  ```

Test tự động bao phủ cảnh báo cũ, FALL/cancel/dismiss, `notify_family: false`, xác nhận hợp lệ, chặn ID trùng qua reconnect và lỗi permission-denied.
