# 360° Video Viewer | عارض الفيديو 360 درجة

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Three.js-000000?style=for-the-badge&logo=three.js&logoColor=white" alt="Three.js"/>
  <img src="https://img.shields.io/badge/WebGL-990000?style=for-the-badge&logo=webgl&logoColor=white" alt="WebGL"/>
</div>

## 📱 نظرة عامة | Overview

**العربية:**
عارض فيديو 360 درجة متقدم مطور بتقنية Flutter يدعم جميع المنصات (Android, iOS, Web). يوفر تجربة مشاهدة غامرة للفيديوهات البانورامية مع تحكم تفاعلي كامل.

**English:**
Advanced 360° video viewer built with Flutter supporting all platforms (Android, iOS, Web). Provides immersive viewing experience for panoramic videos with full interactive controls.

## ✨ المميزات الرئيسية | Key Features

### 🎥 عرض الفيديو | Video Playback
- **عرض 360 درجة كامل** | Full 360° panoramic viewing
- **تشغيل تلقائي مع الصوت** | Auto-play with audio support
- **تحكم في مستوى الصوت** | Volume control with mute/unmute
- **سرعات تشغيل متعددة** | Multiple playback speeds (0.5x - 2x)
- **وضع الشاشة الكاملة** | Fullscreen mode support

### 🎮 التحكم التفاعلي | Interactive Controls
- **التحكم بالماوس/اللمس** | Mouse/Touch drag controls
- **التكبير والتصغير** | Zoom in/out with scroll wheel
- **إعادة تعيين العرض** | View reset with smooth animation
- **الدوران التلقائي** | Auto-rotation toggle
- **اختصارات لوحة المفاتيح** | Comprehensive keyboard shortcuts

### 🎨 المؤثرات البصرية | Visual Effects
- **مرشحات متعددة** | Multiple visual filters:
  - عادي | Normal
  - مشرق | Bright
  - كلاسيكي | Vintage
  - بارد | Cool
  - دافئ | Warm

### 📊 معلومات الفيديو | Video Information
- **لوحة معلومات مفصلة** | Detailed video information panel
- **إحصائيات الأداء** | Performance statistics
- **معلومات التقنية** | Technical details

### 🌍 دعم متعدد المنصات | Multi-Platform Support
- **Android** - تحسين خاص للأندرويد مع دعم اللمس
- **iOS** - تحسين خاص للآيفون مع دعم الإيماءات
- **Web** - تقنية Three.js للمتصفحات الحديثة

## 🚀 كيفية الاستخدام | How to Use

### التشغيل | Running the App
```bash
# تشغيل على الويب | Run on Web
flutter run -d chrome --web-port=8080

# تشغيل على الأندرويد | Run on Android
flutter run -d android

# تشغيل على iOS | Run on iOS
flutter run -d ios
```

### الاختصارات | Keyboard Shortcuts
| المفتاح | الوظيفة | Key | Function |
|---------|---------|-----|----------|
| مسطرة | تشغيل/إيقاف | Space | Play/Pause |
| M | كتم الصوت | M | Mute/Unmute |
| F | الشاشة الكاملة | F | Fullscreen |
| R | إعادة تعيين العرض | R | Reset View |
| I | معلومات الفيديو | I | Video Info |
| E | المؤثرات البصرية | E | Visual Effects |
| A | الدوران التلقائي | A | Auto-Rotate |
| ↑/↓ | مستوى الصوت | ↑/↓ | Volume |
| ←/→ | التقديم/التأخير | ←/→ | Seek |
| 1-6 | سرعة التشغيل | 1-6 | Playback Speed |
| Esc | خروج من الشاشة الكاملة | Esc | Exit Fullscreen |

## 🛠️ التقنيات المستخدمة | Technologies Used

### Frontend
- **Flutter** - إطار العمل الرئيسي
- **Dart** - لغة البرمجة
- **Three.js** - عرض الرسومات ثلاثية الأبعاد للويب
- **WebGL** - تسريع الرسومات

### المكتبات | Libraries
- `webview_flutter` - عرض المحتوى على الموبايل
- `file_picker` - اختيار الملفات
- `permission_handler` - إدارة الأذونات

## 📋 المتطلبات | Requirements

- Flutter SDK 3.0+
- Dart 3.0+
- Android SDK 21+ (للأندرويد)
- iOS 11+ (للآيفون)
- متصفح حديث يدعم WebGL (للويب)

## 🔧 التثبيت | Installation

1. **استنساخ المشروع | Clone the repository:**
```bash
git clone https://github.com/basem902/vedio360.git
cd vedio360
```

2. **تثبيت التبعيات | Install dependencies:**
```bash
flutter pub get
```

3. **تشغيل المشروع | Run the project:**
```bash
flutter run
```

## 📱 لقطات الشاشة | Screenshots

### الواجهة الرئيسية | Main Interface
- واجهة حديثة وسهلة الاستخدام
- دعم اللغة العربية والإنجليزية
- تصميم متجاوب لجميع الأحجام

### عارض الفيديو | Video Viewer
- عرض 360 درجة كامل
- تحكم تفاعلي سلس
- جودة عالية مع أداء محسن

## 🎯 الاستخدامات | Use Cases

- **التعليم** | Education - جولات افتراضية تعليمية
- **السياحة** | Tourism - استكشاف الأماكن السياحية
- **العقارات** | Real Estate - عرض العقارات بشكل تفاعلي
- **الترفيه** | Entertainment - محتوى ترفيهي غامر
- **التدريب** | Training - محاكاة بيئات التدريب

## 🔄 التحديثات المستقبلية | Future Updates

- [ ] دعم البث المباشر | Live streaming support
- [ ] مشاركة الفيديوهات | Video sharing
- [ ] حفظ المواضع المفضلة | Bookmark favorite positions
- [ ] تحسينات الأداء | Performance optimizations
- [ ] مؤثرات بصرية إضافية | Additional visual effects

## 🤝 المساهمة | Contributing

نرحب بالمساهمات! يرجى:
1. عمل Fork للمشروع
2. إنشاء فرع جديد للميزة
3. إضافة التحسينات
4. إرسال Pull Request

We welcome contributions! Please:
1. Fork the project
2. Create a feature branch
3. Add your improvements
4. Submit a Pull Request

## 📄 الترخيص | License

هذا المشروع مرخص تحت MIT License - راجع ملف [LICENSE](LICENSE) للتفاصيل.

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 المطور | Developer

**Basem** - [GitHub Profile](https://github.com/basem902)

## 🌟 إذا أعجبك المشروع | If you like this project

⭐ لا تنس إعطاء نجمة للمشروع!
⭐ Don't forget to give the project a star!

---

<div align="center">
  <p>صُنع بـ ❤️ باستخدام Flutter | Made with ❤️ using Flutter</p>
</div>
