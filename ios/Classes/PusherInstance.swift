
import PusherSwift

public class PusherInstance: PusherDelegate {
    var instanceId: String
    public var pusher: Pusher?
    public var isLoggingEnabled: Bool = false;
    public var bindedEvents = [String:String]()
    public var channels = [String:PusherChannel]()

    init(instanceId: String) {
        self.instanceId = instanceId
    }

    public func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {

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
            case "getSocketId":
                getSocketId(call, result: result)
            default:
                result(FlutterMethodNotImplemented)
        }
    }
    
    public func getSocketId(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(pusher?.connection.socketId);
    }

    public func setup(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let pusherObj = pusher {
            pusherObj.unbindAll();
            pusherObj.unsubscribeAll()
        }

        for (_, pusherChannel) in channels {
            pusherChannel.unbindAll()
        }

        channels.removeAll();
        bindedEvents.removeAll()

        do {
            let json = call.arguments as! String
            let jsonDecoder = JSONDecoder()
            let initArgs = try jsonDecoder.decode(InitArgs.self, from: json.data(using: .utf8)!)

            isLoggingEnabled = initArgs.isLoggingEnabled

            let options = PusherClientOptions(
                authMethod: initArgs.options.auth != nil ? AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder(endpoint: initArgs.options.auth!.endpoint, headers: initArgs.options.auth!.headers, isLoggingEnabled: isLoggingEnabled)): .noMethod,
                host: initArgs.options.host != nil ? .host(initArgs.options.host!) : (initArgs.options.cluster != nil ? .cluster(initArgs.options.cluster!) : .host("ws.pusherapp.com")),
                port: initArgs.options.port ?? (initArgs.options.encrypted ?? true ? 443 : 80),
                encrypted: initArgs.options.encrypted ?? true,
                activityTimeout: Double(initArgs.options.activityTimeout ?? 30000) / 1000
            )

            pusher = Pusher(
                key: initArgs.appKey,
                options: options
            )
            pusher!.connection.delegate = self

            if (isLoggingEnabled) {
                print("Pusher init")
            }
        } catch {
            if (isLoggingEnabled) {
                print("Pusher init error:" + error.localizedDescription)
            }
        }
        result(nil);
    }

    public func connect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let pusherObj = pusher {
            pusherObj.connect();
            if (isLoggingEnabled) {
                print("Pusher connect")
            }
        }
        result(nil);
    }

    public func disconnect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let pusherObj = pusher {
            pusherObj.disconnect();
            if (isLoggingEnabled) {
                print("Pusher disconnect")
            }
        }
        result(nil);
    }

    public func subscribe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let pusherObj = pusher {
            let json = call.arguments as! String
            let map = convertToDictionary(text: json)
            let channelName = map!["channelName"] as! String
            let channelType = channelName.components(separatedBy: "-")[0]
            var channel: PusherChannel

            switch channelType{
            case "private":
                channel = pusherObj.subscribe(channelName)
                if (isLoggingEnabled) {
                    print("Pusher subscribe (private)")
                }
            case "presence":
                channel = pusherObj.subscribeToPresenceChannel(channelName: channelName)
                if (isLoggingEnabled) {
                    print("Pusher subscribe (presence)")
                }
            default:
                channel = pusherObj.subscribe(channelName)
                if (isLoggingEnabled) {
                    print("Pusher subscribe")
                }
            }

            channels[channelName] = channel;
        }
        result(nil);
    }

    public func subscribeToPresence(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let pusherObj = pusher {
            let json = call.arguments as! String
            let map = convertToDictionary(text: json)
            let channelName = map!["channelName"] as! String
            let channel = pusherObj.subscribeToPresenceChannel(channelName: channelName)
            channels[channelName] = channel;

            if (isLoggingEnabled) {
                print("Pusher subscribe to presence channel")
            }
        }
        result(nil);
    }

    public func unsubscribe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let pusherObj = pusher {
            let json = call.arguments as! String
            let map = convertToDictionary(text: json)
            let channelName = map!["channelName"] as! String
            pusherObj.unsubscribe(channelName)
            channels.removeValue(forKey: "channelName")

            if (isLoggingEnabled) {
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

            let channel = channels[bindArgs.channelName]
            if let channelObj = channel {
                unbindIfBound(channelName: bindArgs.channelName, eventName: bindArgs.eventName)
                bindedEvents[bindArgs.channelName + bindArgs.eventName] = channelObj.bind(eventName: bindArgs.eventName, callback: { data in
                    do {
                        if let dataObj = data as? [String : AnyObject] {
                            let pushJsonData = try! JSONSerialization.data(withJSONObject: dataObj)
                            let pushJsonString = NSString(data: pushJsonData, encoding: String.Encoding.utf8.rawValue)
                            let event = Event(channel: bindArgs.channelName, event: bindArgs.eventName, data: pushJsonString! as String)
                            let message = PusherEventStreamMessage(event: event, connectionStateChange:  nil, instanceId: self.instanceId)
                            let jsonEncoder = JSONEncoder()
                            let jsonData = try jsonEncoder.encode(message)
                            let jsonString = String(data: jsonData, encoding: .utf8)
                            if let eventSinkObj = SwiftFlutterPusherPlugin.eventSink {
                                eventSinkObj(jsonString)

                                if (self.isLoggingEnabled) {
                                    print("Pusher event: CHANNEL:\(bindArgs.channelName) EVENT:\(bindArgs.eventName) DATA:\(jsonString ?? "no data")")
                                }
                            }
                        }
                    } catch {
                        if (self.isLoggingEnabled) {
                            print("Pusher bind error:" + error.localizedDescription)
                        }
                    }
                })
                if (isLoggingEnabled) {
                    print("Pusher bind (\(bindArgs.eventName))")
                }
            }
        } catch {
            if (isLoggingEnabled) {
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
            if (isLoggingEnabled) {
                print("Pusher unbind error:" + error.localizedDescription)
            }
        }
        result(nil);
    }

    private func unbindIfBound(channelName: String, eventName: String) {
        let channel = channels[channelName]
        if let channelObj = channel {
            let callbackId = bindedEvents[channelName + eventName]
            if let callbackIdObj = callbackId {
                channelObj.unbind(eventName: eventName, callbackId: callbackIdObj)
                bindedEvents.removeValue(forKey: channelName + eventName)

                if (isLoggingEnabled) {
                    print("Pusher unbind")
                }
            }
        }
    }

    public func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        do {
            let stateChange = ConnectionStateChange(currentState: new.stringValue(), previousState: old.stringValue())
            let message = PusherEventStreamMessage(event: nil, connectionStateChange: stateChange, instanceId: instanceId)
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(message)
            let jsonString = String(data: jsonData, encoding: .utf8)
            if let eventSinkObj = SwiftFlutterPusherPlugin.eventSink {
                eventSinkObj(jsonString)
            }
        } catch {
            if (isLoggingEnabled) {
                print("Pusher changedConnectionState error:" + error.localizedDescription)
            }
        }
    }

    public func trigger(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            let json = call.arguments as! String
            let jsonDecoder = JSONDecoder()
            let bindArgs = try jsonDecoder.decode(BindArgs.self, from: json.data(using: .utf8)!)

            let channel = channels[bindArgs.channelName]
            if let channelObj = channel {
                let eventName = bindArgs.eventName

                channelObj.trigger(eventName: eventName, data: [])
            }
        } catch {
            if (isLoggingEnabled) {
                print("Pusher trigger error:" + error.localizedDescription)
            }
        }
    }
}



class AuthRequestBuilder: AuthRequestBuilderProtocol {
    var endpoint: String
    var headers: [String: String]
    var isLoggingEnabled: Bool

    init(endpoint: String, headers: [String: String], isLoggingEnabled: Bool) {
        self.endpoint = endpoint
        self.headers = headers
        self.isLoggingEnabled = isLoggingEnabled
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
            if (isLoggingEnabled) {
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
    var instanceId: String
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
