import Firebase  // 1. لازم تستورد مكتبة الفايربيس هنا
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {  // شلنا البروتوكول الزيادة لتبسيط الربط مع Firebase
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 2. تهيئة Firebase قبل تسجيل الإضافات
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // 3. تسجيل الإضافات (الخاصة بـ Flutter)
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
