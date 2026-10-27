import Flutter
import Samvaad
import UIKit

/// Flutter binding for the Samvaad iOS SDK.
public class SamvaadWidgetPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SamvaadWidgetPlugin()
        let channel = FlutterMethodChannel(name: "samvaad_widget", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
        let events = FlutterEventChannel(name: "samvaad_widget/unread", binaryMessenger: registrar.messenger())
        events.setStreamHandler(instance)
    }

    // MARK: - Methods

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let method = call.method
        // The native SDK is main-actor isolated; Flutter calls arrive on the main thread.
        Task { @MainActor in
            SamvaadWidgetPlugin.run(method, args: args, result: result)
        }
    }

    @MainActor
    private static func run(_ method: String, args: [String: Any], result: FlutterResult) {
        switch method {
        case "configure":
            guard let tenantId = args["tenantId"] as? String, let host = args["host"] as? String else {
                result(badArgs("configure needs tenantId and host"))
                return
            }
            Samvaad.configure(tenantId: tenantId, host: host)
            result(nil)

        case "identify":
            guard let email = args["email"] as? String, let userHash = args["userHash"] as? String else {
                result(badArgs("identify needs email and userHash"))
                return
            }
            Samvaad.identify(email: email, name: args["name"] as? String, userHash: userHash)
            result(nil)

        case "present":
            Samvaad.present(from: nil, message: args["message"] as? String)
            result(nil)

        case "logout":
            Samvaad.logout()
            result(nil)

        case "setTheme":
            guard let name = args["theme"] as? String, let theme = SamvaadTheme(rawValue: name) else {
                result(badArgs("setTheme needs auto, light or dark"))
                return
            }
            Samvaad.theme = theme
            result(nil)

        case "unreadCount":
            result(Samvaad.unreadCount)

        case "setPushToken":
            guard let token = args["token"] as? String else {
                result(badArgs("setPushToken needs a token"))
                return
            }
            let route = args["route"] as? String ?? "fcm"
            switch route {
            case "fcm":
                Samvaad.setPushToken(fcmToken: token)
                result(nil)
            case "apns":
                guard let data = dataFromHex(token) else {
                    result(badArgs("apns token must be a hex string"))
                    return
                }
                Samvaad.setPushToken(data)
                result(nil)
            default:
                result(badArgs("unknown push route: \(route)"))
            }

        case "handlePush":
            let data = args["data"] as? [String: Any] ?? [:]
            var userInfo: [AnyHashable: Any] = [:]
            for (key, value) in data {
                userInfo[key] = value
            }
            result(Samvaad.handlePush(userInfo, from: nil))

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func badArgs(_ message: String) -> FlutterError {
        FlutterError(code: "bad_args", message: message, details: nil)
    }

    /// Decodes a hex APNs device token ("0a1b...") into bytes.
    static func dataFromHex(_ hex: String) -> Data? {
        let clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
        guard !clean.isEmpty, clean.count % 2 == 0 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(clean.count / 2)
        var index = clean.startIndex
        while index < clean.endIndex {
            let next = clean.index(index, offsetBy: 2)
            guard let byte = UInt8(clean[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        return Data(bytes)
    }

    // MARK: - Unread stream

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        Task { @MainActor in
            Samvaad.onUnreadChange = { count in events(count) }
            events(Samvaad.unreadCount)
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        Task { @MainActor in
            Samvaad.onUnreadChange = nil
        }
        return nil
    }
}
