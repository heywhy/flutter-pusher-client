import Flutter
import UIKit
import PusherSwift

public class SwiftFlutterPusherPlugin: NSObject, FlutterPlugin {

    public static var eventSink: FlutterEventSink?

    public var pusherInstanceMap = [String:PusherInstance]()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.github.heywhy/pusher", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterPusherPlugin()
        let eventChannel = FlutterEventChannel(name: "com.github.heywhy/pusherStream", binaryMessenger: registrar.messenger())

        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(StreamHandler())
    }

    private func getPusherInstance(instanceId: String?) -> PusherInstance {
        let id = instanceId! as String
        if (instanceId != nil && pusherInstanceMap[id] == nil) {
            pusherInstanceMap[id] = PusherInstance(instanceId: id)
        }
        return pusherInstanceMap[id]!
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = convertToDictionary(text: call.arguments as! String)
        let instanceId = (args!["instanceId"] as! NSNumber).stringValue
        let pusherInstance = getPusherInstance(instanceId: instanceId)
        
        pusherInstance.handle(call: call, result: result)
    }
}

func convertToDictionary(text: String) -> [String: Any]? {
    if let data = text.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
}
