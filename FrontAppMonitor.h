#import <Cocoa/Cocoa.h>

@interface FrontAppMonitor : NSObject

@property NSNotificationCenter *notificationCenterRef;

+ (FrontAppMonitor *)sharedMonitor;
+ (NSNotificationCenter *)notificationCenter;
- (NSNotificationCenter *)notificationCenter;
@end
