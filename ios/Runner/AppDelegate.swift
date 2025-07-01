import UIKit
import Flutter
import Libmtorrentserver
import app_links
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let mChannel = FlutterMethodChannel(name: "com.dvillegas.mangayomi.libmtorrentserver", binaryMessenger: controller.binaryMessenger)
              mChannel.setMethodCallHandler({
                  (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                  switch call.method {
                  case "start":
                      let args = call.arguments as? Dictionary<String, Any>
                      let config = args?["config"] as? String
                      var error: NSError?
                      let mPort = UnsafeMutablePointer<Int>.allocate(capacity: MemoryLayout<Int>.stride)
                      if LibmtorrentserverStart(config, mPort, &error){
                          result(mPort.pointee)
                      }else{
                          result(FlutterError(code: "ERROR", message: error.debugDescription, details: nil))
                      }
                  default:
                      result(FlutterMethodNotImplemented)
                  }
              })

    // Configure Google Sign In BEFORE registering plugins
    do {
      if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
         let plist = NSDictionary(contentsOfFile: path),
         let clientId = plist["CLIENT_ID"] as? String {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        print("Google Sign In configured successfully with client ID: \(clientId)")
      } else {
        print("Warning: GoogleService-Info.plist not found or CLIENT_ID missing")
      }
    } catch {
      print("Error configuring Google Sign In: \(error)")
    }

    GeneratedPluginRegistrant.register(with: self)

    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      AppLinks.shared.handleLink(url: url)
      return true
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    print("Opening URL: \(url)")

    // Handle Google Sign In URL
    do {
      if GIDSignIn.sharedInstance.handle(url) {
        print("Google Sign In handled URL successfully")
        return true
      }
    } catch {
      print("Error handling Google Sign In URL: \(error)")
    }

    // Handle other URLs
    return super.application(app, open: url, options: options)
  }
}
