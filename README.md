# 📝 NoteCards Pro - Ứng Dụng Ghi Chú Thẻ Thông Minh

Ứng dụng ghi chú thẻ (Card-based Notes) đa nền tảng tối ưu cho **Windows** và **Android**, tích hợp trợ lý thú cưng ảo (Desktop Pet) nhắc nhở deadline và hạn chót công việc.

---

## ✨ Tính Năng Nổi Bật

- 🎨 **Ghi chú thẻ trực quan**: Hệ màu sắc phong phú, hiển thị dạng Masonry Grid, Danh sách, Bảng Kanban phân theo thư mục, và Lịch (Calendar View).
- 🐾 **Trợ lý Pet ảo (Desktop & In-app)**:
  - **Desktop Pet**: Ứng dụng thú cưng WPF chạy ngoài màn hình Windows (Chó Shiba, Mèo Kawaii, Bé Anime, Thần Chết), tự động xuất hiện tuần tra và nhắc bạn khi có deadline đến hạn.
  - **In-app Pet**: Bé pet Flutter chạy lon ton ngay trong app với bóng thoại và nút hoàn thành tức thì.
- 📋 **Checklist & Markdown**: Hỗ trợ danh sách việc cần làm (to-do checklist) tích chọn trực tiếp trên thẻ ghi chú, hỗ trợ định dạng Markdown kèm xem trước (Preview).
- 🔒 **Bảo mật**: Khóa thẻ ghi chú quan trọng bằng mã PIN.
- 📂 **Phân loại & Tìm kiếm**: Tổ chức theo Thư mục danh mục, gắn thẻ `#tag`, tìm kiếm nhanh theo tiêu đề/nội dung.
- ⌨️ **Phím tắt Windows**: `Ctrl + N` (Thẻ mới), `Ctrl + B` (Ẩn/Hiện thanh bên), `Ctrl + S` (Lưu nhanh), `Ctrl + F` (Tìm kiếm), `Esc` (Đóng/Thoát).
- 💾 **Sao lưu & Xuất file**:
  - Sao lưu toàn bộ ghi chú và danh mục ra file `JSON` và khôi phục khi cần.
  - Xuất thẻ ghi chú ra định dạng `Markdown (.md)`.
- 🪟 **Tích hợp Windows System Tray**: Thu nhỏ xuống khay hệ thống khi bấm nút đóng `X`, chạy nền mượt mà.

---

## 🛠️ Cài Đặt & Phát Triển

### Yêu cầu môi trường
- [Flutter SDK](https://flutter.dev) (>= 3.9.0)
- Dart SDK
- Windows 10/11 hoặc Android Studio (cho Android)
- C# .NET Framework (biên dịch Desktop Pet nếu sửa đổi)

### Chạy ứng dụng chế độ Debug

```bash
# Cài đặt dependencies
flutter pub get

# Chạy trên Windows
flutter run -d windows

# Chạy trên Android
flutter run -d android
```

### Kiểm tra mã nguồn & Kiểm thử

```bash
flutter analyze
flutter test
```

### Đóng gói ứng dụng

**1. Build Windows:**
```bash
flutter build windows --release
```
*Sau khi build xong, bạn có thể dùng Inno Setup mở file `windows_installer.iss` để tạo file cài đặt `NoteCards_Pro_Setup.exe`.*

**2. Build Android APK:**
```bash
flutter build apk --release
```

---

## 📂 Cấu Trúc Dự Án

```
notepro/
├── assets/                  # Icon và tài nguyên ảnh
├── desktop_pet/             # Mã nguồn C# WPF và DesktopPet.exe
├── lib/
│   ├── core/
│   │   ├── database/        # SQLite DatabaseHelper
│   │   ├── theme/           # AppTheme & Bảng màu CardPalette
│   │   └── utils/           # DesktopPetService, SystemTrayService, FileHelper
│   ├── models/              # NoteModel, ChecklistItem, FolderModel
│   ├── providers/           # NotesProvider, ThemeProvider
│   ├── screens/             # HomeScreen, NoteEditorScreen, SettingsScreen...
│   └── widgets/             # NoteCardWidget, WanderingPetWidget, KanbanView...
├── test/                    # Unit & Smoke tests
└── windows_installer.iss    # Inno Setup Script đóng gói bộ cài Windows
```
