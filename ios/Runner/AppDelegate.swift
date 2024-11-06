import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {  // Removed UNUserNotificationCenterDelegate
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()  // Initialize Firebase
    GeneratedPluginRegistrant.register(with: self)

    // Set the delegate for UNUserNotificationCenter
    UNUserNotificationCenter.current().delegate = self

    // Request notification authorization
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { granted, error in
        if let error = error {
          print("Error requesting notification authorization: \(error)")
        } else {
          print("Notification authorization granted: \(granted)")
        }
      }
    )

    // Register for remote notifications
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle the device token for push notifications
  override func application(_ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Handle notification presentation in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
      willPresent notification: UNNotification,
      withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .badge, .sound])
  }
}