import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private var privacyEnabled = false
  private var observersRegistered = false
  private var privacyCover: UIView?
  private var pendingPickResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let channel = FlutterMethodChannel(
      name: "localvault/security",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "enableSensitiveScreenProtection":
        self.privacyEnabled = true
        self.registerPrivacyObservers()
        result(nil)
      case "disableSensitiveScreenProtection":
        self.privacyEnabled = false
        self.hidePrivacyCover()
        result(nil)
      case "excludeFromBackup":
        guard
          let arguments = call.arguments as? [String: Any],
          let paths = arguments["paths"] as? [String]
        else {
          result(FlutterError(code: "bad_args", message: "Missing paths", details: nil))
          return
        }
        do {
          for path in paths {
            var url = URL(fileURLWithPath: path)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try url.setResourceValues(values)
          }
          result(nil)
        } catch {
          result(FlutterError(code: "exclude_failed", message: "Backup exclusion failed", details: nil))
        }
      case "pickBackupFile":
        self.pickBackupFile(result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func registerPrivacyObservers() {
    guard !observersRegistered else {
      return
    }
    observersRegistered = true
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(showPrivacyCover),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(hidePrivacyCover),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  @objc private func showPrivacyCover() {
    guard privacyEnabled, privacyCover == nil, let window = activeWindow() else {
      return
    }
    let cover = UIView(frame: window.bounds)
    cover.backgroundColor = UIColor(red: 0.067, green: 0.094, blue: 0.153, alpha: 1.0)
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    let label = UILabel()
    label.text = "LocalVault"
    label.textColor = .white
    label.font = UIFont.preferredFont(forTextStyle: .title1)
    label.translatesAutoresizingMaskIntoConstraints = false
    cover.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: cover.centerYAnchor)
    ])

    window.addSubview(cover)
    privacyCover = cover
  }

  @objc private func hidePrivacyCover() {
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }

  private func activeWindow() -> UIWindow? {
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }

  private func pickBackupFile(_ result: @escaping FlutterResult) {
    guard pendingPickResult == nil else {
      result(FlutterError(code: "pick_in_progress", message: "A file picker is already open.", details: nil))
      return
    }
    pendingPickResult = result
    let picker = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .import)
    picker.delegate = self
    picker.allowsMultipleSelection = false
    activeWindow()?.rootViewController?.present(picker, animated: true)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingPickResult?(nil)
    pendingPickResult = nil
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pendingPickResult else {
      return
    }
    pendingPickResult = nil
    guard let url = urls.first else {
      result(nil)
      return
    }
    let scoped = url.startAccessingSecurityScopedResource()
    defer {
      if scoped {
        url.stopAccessingSecurityScopedResource()
      }
    }
    do {
      let data = try Data(contentsOf: url)
      result(FlutterStandardTypedData(bytes: data))
    } catch {
      result(FlutterError(code: "read_failed", message: "Could not read the selected backup.", details: nil))
    }
  }
}
