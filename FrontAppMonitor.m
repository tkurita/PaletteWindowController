#import "FrontAppMonitor.h"
#import <Carbon/Carbon.h>

#define useLog 0

@implementation FrontAppMonitor

static FrontAppMonitor *sharedMonitor = nil;

+ (FrontAppMonitor *)sharedMonitor
{
	if (sharedMonitor == nil) {
		sharedMonitor = [[self alloc] init];
	}
	return sharedMonitor;
}

+ (NSNotificationCenter *)notificationCenter
{
	return [[self sharedMonitor] notificationCenter];
}

#pragma mark private

- (void)appSwitched
{
#if useLog
	NSLog(@"appSwitched");
#endif
	NSNotification *notification = [NSNotification notificationWithName:@"FrontAppChangedNotification"
																 object:self];
	[_notificationCenterRef postNotification:notification];
}

static OSStatus appSwitched(EventHandlerCallRef nextHandler, EventRef theEvent, void* userData)
{
#if useLog
	NSLog(@"start appSwitched");
#endif
	[(__bridge id)userData appSwitched];
	return(CallNextEventHandler(nextHandler, theEvent));
}

- (void)setupAppChangeEvent
{
#if useLog	
	NSLog(@"start setupAppChangeEvent");
#endif	
	OSStatus err;
	
    EventTypeSpec spec = { kEventClassApplication,  kEventAppFrontSwitched };
	EventHandlerUPP handlerUPP = NewEventHandlerUPP(appSwitched);
    err = InstallApplicationEventHandler(handlerUPP, 1, &spec, (__bridge void*)self, NULL);
	if (err != noErr) NSLog(@"fail to InstallApplicationEventHandler");
	DisposeEventHandlerUPP(handlerUPP);
}

#pragma mark public

- (NSNotificationCenter *)notificationCenter
{
	if (!_notificationCenterRef) {
		self.notificationCenterRef = [NSNotificationCenter new];
		[self setupAppChangeEvent];
	}
	
	return _notificationCenterRef;
}

@end
