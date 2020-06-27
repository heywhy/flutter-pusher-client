import Flutter
import UIKit
import PusherSwift

public class SwiftFlutterPusherPlugin: NSObject, FlutterPlugin, PusherDelegate {


    public static var pusher: Pusher?
    public static var isLoggingEnabled: Bool = false;
    public static var bindedEvents = [String:String]()
    public static var channels = [String:PusherChannel]()
    public static var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.github.heywhy/pusher", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterPusherPlugin()
        let eventChannel = FlutterEventChannel(name: "com.github.heywhy/pusherStream", binaryMessenger: registrar.messenger())

        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(StreamHandler())
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "init":
                setup(call, result: result)
            case "connect":
                connect(call, result: result)
            case "disconnect":
                disconnect(call, result: result)
            case "subscribe":
                subscribe(call, result: result)
            case "unsubscribe":
                unsubscribe(call, result: result)
            case "bind":
                bind(call, result: result)
            case "unbind":
                unbind(call, result: result)
            case "trigger":
                trigger(call, result: result)
            default:
                result(FlutterMethodNotImplemented)
        }
    }


    public func setup(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let pusherObj = SwiftFlutterPusherPlugin.pusher {
            pusherObj.unbindAll();
            pusherObj.unsubscribeAll()
        }

        for (_, pusherChannel) in SwiftFlutterPusherPlugin.channels {
            pusherChannel.unbindAll()
        }

        SwiftFlutterPusherPlugin.channels.removeAll();
        SwiftFlutterPusherPlugin.bindedEvents.removeAll()

        do {
            let json = call.arguments as! String
            let jsonDecoder = JSONDecoder()
            let initArgs = try jsonDecoder.decode(InitArgs.self, from: json.data(using: .utf8)!)

            SwiftFlutterPusherPlugin.isLoggingEnabled = initArgs.isLoggingEnabled

            let options = PusherClientOptions(
                authMethod: initArgs.options.auth != nil ? AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder(endpoint: initArgs.options.auth!.endpoint, headers: initArgs.options.auth!.headers)): .noMethod,
                host: initArgs.options.host != nil ? .host(initArgs.options.host!) : (initArgs.options.cluster != nil ? .cluster(initArgs.options.cluster!) : .host("ws.pusherapp.com")),
                port: initArgs.options.port ?? (initArgs.options.encrypted ?? true ? 443 : 80),
                encrypted: initArgs.options.encrypted ?? true,
                activityTimeout: Double(initArgs.options.activityTimeout ?? 30000) / 1000
            )

            SwiftFlutterPusherPlugin.pusher = Pusher(
                key: initArgs.appKey,
                options: options
            )
            SwiftFlutterPusherPlugin.pusher!.connection.delegate = self

            if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                print("Pusher init")
            }
        } catch {
            if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                print("Pusher init error:" + error.localizedDescription)
            }
        }
        result(nil);
    }

    public func connect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let pusherObj = SwiftFlutterPusherPlugin.pusher {
            pusherObj.connect();
            if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                print("Pusher connect")
            }
        }
        result(nil);
    }

    public func disconnect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let pusherObj = SwiftFlutterPusherPlugin.pusher {
            pusherObj.disconnect();
            if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                print("Pusher disconnect")
            }
        }
        result(nil);
    }

    public func subscribe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let pusherObj = SwiftFlutterPusherPlugin.pusher else {
            result(nil)
            return
        }
        
        guard let arguments = call.arguments as? NSDictionary else {
            result(nil)
            return
        }
        if let channelName = arguments["channelName"] as? String {
            let channelType = channelName.components(separatedBy: "-")[0]
            var channel: PusherChannel

            switch channelType{
            case "private":
                channel = pusherObj.subscribe(channelName)
                if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                    print("Pusher subscribe (private)")
                }
            case "presence":
                channel = pusherObj.subscribeToPresenceChannel(channelName: channelName)
                if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                    print("Pusher subscribe (presence)")
                }
            default:
                channel = pusherObj.subscribe(channelName)
                if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                    print("Pusher subscribe")
                }
            }

            SwiftFlutterPusherPlugin.channels[channelName] = channel;
        }
    }

    public func subscribeToPresence(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let pusherObj = SwiftFlutterPusherPlugin.pusher {
            let channelName = call.arguments as! String
            let channel = pusherObj.subscribeToPresenceChannel(channelName: channelName)
            SwiftFlutterPusherPlugin.channels[channelName] = channel;

            if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                print("Pusher subscribe to presence channel")
            }
        }
        result(nil);
    }

    public func unsubscribe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let pusherObj = SwiftFlutterPusherPlugin.pusher {
            let channelName = call.arguments as! String
            pusherObj.unsubscribe(channelName)
            SwiftFlutterPusherPlugin.channels.removeValue(forKey: "channelName")

            if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                print("Pusher unsubscribe")
            }
        }
        result(nil);
    }

    public func bind(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            let json = call.arguments as! String
            let jsonDecoder = JSONDecoder()
            let bindArgs = try jsonDecoder.decode(BindArgs.self, from: json.data(using: .utf8)!)

            let channel = SwiftFlutterPusherPlugin.channels[bindArgs.channelName]
            if let channelObj = channel {
                unbindIfBound(channelName: bindArgs.channelName, eventName: bindArgs.eventName)
                SwiftFlutterPusherPlugin.bindedEvents[bindArgs.channelName + bindArgs.eventName] = channelObj.bind(eventName: bindArgs.eventName, callback: { data in
                    do {
                        if let dataObj = data as? [String : AnyObject] {
                            let pushJsonData = try! JSONSerialization.data(withJSONObject: dataObj)
                            let pushJsonString = NSString(data: pushJsonData, encoding: String.Encoding.utf8.rawValue)
                            let event = Event(channel: bindArgs.channelName, event: bindArgs.eventName, data: pushJsonString! as String)
                            let message = PusherEventStreamMessage(event: event, connectionStateChange:  nil)
                            let jsonEncoder = JSONEncoder()
                            let jsonData = try jsonEncoder.encode(message)
                            let jsonString = String(data: jsonData, encoding: .utf8)
                            if let eventSinkObj = SwiftFlutterPusherPlugin.eventSink {
                                eventSinkObj(jsonString)

                                if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                                    print("Pusher event: CHANNEL:\(bindArgs.channelName) EVENT:\(bindArgs.eventName) DATA:\(jsonString ?? "no data")")
                                }
                            }
                        }
                    } catch {
                        if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                            print("Pusher bind error:" + error.localizedDescription)
                        }
                    }
                })
                if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                    print("Pusher bind (\(bindArgs.eventName))")
                }
            }
        } catch {
            if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                print("Pusher bind error:" + error.localizedDescription)
            }
        }
        result(nil);
    }

    public func unbind(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            let json = call.arguments as! String
            let jsonDecoder = JSONDecoder()
            let bindArgs = try jsonDecoder.decode(BindArgs.self, from: json.data(using: .utf8)!)
            unbindIfBound(channelName: bindArgs.channelName, eventName: bindArgs.eventName)
        } catch {
            if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                print("Pusher unbind error:" + error.localizedDescription)
            }
        }
        result(nil);
    }

    private func unbindIfBound(channelName: String, eventName: String) {
        let channel = SwiftFlutterPusherPlugin.channels[channelName]
        if let channelObj = channel {
            let callbackId = SwiftFlutterPusherPlugin.bindedEvents[channelName + eventName]
            if let callbackIdObj = callbackId {
                channelObj.unbind(eventName: eventName, callbackId: callbackIdObj)
                SwiftFlutterPusherPlugin.bindedEvents.removeValue(forKey: channelName + eventName)

                if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                    print("Pusher unbind")
                }
            }
        }
    }

    public func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        do {
            let stateChange = ConnectionStateChange(currentState: new.stringValue(), previousState: old.stringValue())
            let message = PusherEventStreamMessage(event: nil, connectionStateChange: stateChange)
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(message)
            let jsonString = String(data: jsonData, encoding: .utf8)
            if let eventSinkObj = SwiftFlutterPusherPlugin.eventSink {
                eventSinkObj(jsonString)
            }
        } catch {
            if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                print("Pusher changedConnectionState error:" + error.localizedDescription)
            }
        }
    }

    public func trigger(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            let json = call.arguments as! String
            let jsonDecoder = JSONDecoder()
            let bindArgs = try jsonDecoder.decode(BindArgs.self, from: json.data(using: .utf8)!)

            let channel = SwiftFlutterPusherPlugin.channels[bindArgs.channelName]
            if let channelObj = channel {
                let eventName = bindArgs.eventName

                channelObj.trigger(eventName: eventName, data: [])
            }
        } catch {
            if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                print("Pusher trigger error:" + error.localizedDescription)
            }
        }
    }
}


class AuthRequestBuilder: AuthRequestBuilderProtocol {
    var endpoint: String
    var headers: [String: String]

    init(endpoint: String, headers: [String: String]) {
        self.endpoint = endpoint
        self.headers = headers
    }

    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        do{
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "POST"

            if(headers.values.contains("application/json")){
                let jsonEncoder = JSONEncoder()
                request.httpBody = try jsonEncoder.encode(["socket_id": socketID, "channel_name": channelName])
            }else{
                request.httpBody = "socket_id=\(socketID)&channel_name=\(channelName)".data(using: String.Encoding.utf8)
            }

            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
            return request
        } catch {
            if (SwiftFlutterPusherPlugin.isLoggingEnabled) {
                print("Authentication error:" + error.localizedDescription)
            }
            return nil
        }

    }
}

class StreamHandler: NSObject, FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        SwiftFlutterPusherPlugin.eventSink = events
        return nil;
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil;
    }
}

struct InitArgs: Codable {
    var appKey: String
    var options: Options
    var isLoggingEnabled: Bool
}

struct Options: Codable {
    var cluster: String?
    var host: String?
    var port: Int?
    var encrypted: Bool?
    var auth: Auth?
    var activityTimeout: Int?
}

struct Auth: Codable{
    var endpoint: String
    var headers: [String: String]
}

struct PusherEventStreamMessage: Codable {
    var event: Event?
    var connectionStateChange: ConnectionStateChange?
}

struct ConnectionStateChange: Codable {
    var currentState: String
    var previousState: String
}

struct Event: Codable {
    var channel: String
    var event: String
    var data: String
}

struct BindArgs: Codable {
    var channelName: String
    var eventName: String
}
