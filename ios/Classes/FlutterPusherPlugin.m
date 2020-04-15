#import "FlutterPusherPlugin.h"
#import <flutter_pusher_client/flutter_pusher_client-Swift.h>

@implementation FlutterPusherPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterPusherPlugin registerWithRegistrar:registrar];
}
@end
