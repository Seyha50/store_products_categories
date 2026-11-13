# product_app: Dashboard + Products + Categories (Flutter + Laravel API)

## Screens
- Main screen: bottom navigation (Dashboard / Products / Categories)
- Dashboard: totals, stock value, low stock, expiring soon, products per category,
  quick buttons "Add Product" and "Add Category"
- Products: list, search, add, edit, delete
- Categories: list, add, edit, delete (server refuses delete if it still has products)

## Setup
1. flutter create product_app
2. Copy this project's `lib/` folder and `pubspec.yaml` over the new ones.
3. flutter pub get
4. android/app/src/main/AndroidManifest.xml
     above <application>:  <uses-permission android:name="android.permission.INTERNET"/>
     in <application ...>: android:usesCleartextTraffic="true"
5. iOS only: add NSPhotoLibraryUsageDescription to ios/Runner/Info.plist
6. Edit lib/config.dart -> host (10.0.2.2 for Android emulator, PC IP for real phone)
7. Laravel: php artisan serve --host=0.0.0.0 --port=8000   (and php artisan storage:link)
8. flutter run

Images are loaded from  <host>/storage/<path>, so APP_URL in Laravel .env does not matter.
