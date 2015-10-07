#import <Carbon/Carbon.h>
#import "WindowVisibilityController.h"
#import "PaletteWindowController.h"
#import "FrontAppMonitor.h"

#define useLog 0

#define TIMERINVERVAL 1

static id sharedObj;

static void focusChanged(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon)
{
#if useLog
	NSLog([NSString stringWithFormat:@"focusChanged with notification : %@", notification]);
#endif	
	CFComparisonResult result = CFStringCompare(notification, kAXCreatedNotification, 0);
	if (result == kCFCompareEqualTo) {
		[(__bridge id)refcon performSelector:@selector(updateVisibility:) withObject:nil afterDelay:2];
	}
	else {
		[(__bridge id)refcon updateVisibility:nil];
	}
}

@implementation WindowVisibilityController

+ (id)sharedWindowVisibilityController
{
	if (sharedObj)
		return sharedObj;
	else
		return [self new];
}

- (id)init
{
	if (self = [super init]) {
		_windowControllers = [[NSMutableArray alloc] init];;
	}
	
	if (sharedObj == nil) {
		sharedObj = self;
	}
	_installedAppSwitchEvent = NO;
	_focusWatchApplication = nil;
	_appObserver = nil;
	_isUseTimer = NO;
	_visibilityForCurrentApplication = kShouldNotChange;
	return self;
}

#pragma mark private
- (void)windowChanged:(NSNotification *)notification
{
	NSLog(@"%@",[notification description]);
}

- (void)updateVisibility:(NSNotification *)notification
{
#if useLog
	NSLog(@"start updateVisibility");
#endif	
	NSDictionary *app_dict = [[NSWorkspace sharedWorkspace] activeApplication];
	int pid = [[NSProcessInfo processInfo] processIdentifier];
	VisibilityUpdateMode showFlag;
	if ([app_dict[@"NSApplicationProcessIdentifier"] intValue] == pid) {
#if useLog
		NSLog(@"current application is active");
#endif
		showFlag = _visibilityForCurrentApplication;
	} else {
		showFlag = [self judgeVisibilityForApp:app_dict];
	}
	
	NSEnumerator *enumerator = [_windowControllers objectEnumerator];
	id window_controller;
	BOOL shouldShow = YES;
	while(window_controller = [enumerator nextObject]) {
		switch (showFlag) {
			case kShouldPostController : 
				shouldShow = [window_controller shouldUpdateVisibilityForApp:app_dict];
				break;
			case kShouldHide :
				shouldShow = NO;
				break;
			case kShouldShow : 
				shouldShow = YES;
				break;
			case kShouldNotChange :
				return;
		}
		[window_controller setVisibility:shouldShow];
	}
}

- (void)setupFocusChangeObserver 
{
	NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:_focusWatchApplication];
    if (!apps.count) {
        NSLog(@"%@ is not launched.", _focusWatchApplication);
		return;
    }
	pid_t pid = ((NSRunningApplication *)[apps lastObject]).processIdentifier;
	_targetApp = AXUIElementCreateApplication(pid);
	
	AXError axerr = AXObserverCreate(pid, focusChanged, &_appObserver);
	if (axerr != kAXErrorSuccess) {
		NSLog(@"fail to AXObserverCreate:%i", axerr);
		return;
	}
	
	CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(_appObserver), kCFRunLoopDefaultMode);
	
	axerr = AXObserverAddNotification(_appObserver, _targetApp, kAXFocusedWindowChangedNotification, (__bridge void *)(self));
	if (axerr != kAXErrorSuccess) {
		NSLog(@"fail to AXObserverAddNotification:%i", axerr);
		return;
	}
	/*
	 axerr = AXObserverAddNotification(_appObserver, _targetApp, kAXCreatedNotification, self);
	 if (axerr != kAXErrorSuccess) {
	 NSLog([NSString stringWithFormat:@"fail to AXObserverAddNotification for kAXCreatedNotification:%i", axerr]);
	 return;
	 }
	 */
	
}

- (void)setupAppChangeEvent
{
#if useLog	
	NSLog(@"start setupAppChangeEvent");
#endif	
	[[FrontAppMonitor notificationCenter] addObserver:self selector:@selector(updateVisibility:)
												 name:@"FrontAppChangedNotification" object:nil];
	_installedAppSwitchEvent = YES;
}

#pragma mark public
- (void)addWindowController:(id)windowController
{
#if useLog
	NSLog(@"start addWindowController");
#endif	
	if (_isUseTimer && (_displayToggleTimer == nil)) {
		[self setupDisplayToggleTimer];
	}

	if (!_installedAppSwitchEvent) {
		[self setupAppChangeEvent];
	}
	
	if ((_focusWatchApplication != nil) && (_appObserver == nil)) {
		[self setupFocusChangeObserver];
	}
	
	[_windowControllers addObject:windowController];
}

- (void)removeWindowController:(id)windowController
{
	[_windowControllers removeObject:windowController];
	[[FrontAppMonitor notificationCenter] removeObserver:windowController];
	if ([_windowControllers count] == 0) {
		[self stopDisplayToggleTimer];
	}
}

- (void)setDelegate:(id)obj
{
	delegate = obj;
}

- (void)setVisibilityForCurrentApplication:(VisibilityUpdateMode)mode
{
	_visibilityForCurrentApplication = mode;
}

- (int)judgeVisibilityForApp:(NSDictionary *)appDict
{
	/*
	result = -1 : can't judge in this routine
		0 : should hide	
		1: should show
		2: should not change
	*/
	int result;
	if (delegate != nil) {
		result = [delegate judgeVisibilityForApp:appDict];
	}
	else {
		result = kShouldPostController;
	}
#if useLog
	NSLog([NSString stringWithFormat:@"judge result is %d for app %@", result, appDict]);
#endif	
	return result;
}

#pragma mark methods related timer

- (BOOL)isWorkingDisplayToggleTimer
{
	if (!_displayToggleTimer) return NO;
	return [_displayToggleTimer isValid];
}

- (void)updateVisibilityWithTimer:(NSTimer *)theTimer
{
	[self updateVisibility:nil];
}

- (void)stopDisplayToggleTimer
{
	if (_displayToggleTimer) {
		[_displayToggleTimer invalidate];
		self.displayToggleTimer = nil;
	}
}

- (void)setupDisplayToggleTimer
{
	if (_displayToggleTimer) {
		[_displayToggleTimer invalidate];
	}
	self.displayToggleTimer = [NSTimer scheduledTimerWithTimeInterval:TIMERINVERVAL
									target:self selector:@selector(updateVisibilityWithTimer:) userInfo:nil repeats:YES];
}

- (void)temporaryStopDisplayToggleTimer
{
	if (_displayToggleTimer) {
		[_displayToggleTimer invalidate];
		self.displayToggleTimer = nil;
		_isWorkedDisplayToggleTimer = YES;
	}
	else {
		_isWorkedDisplayToggleTimer = NO;
	}
}

- (void)restartStopDisplayToggleTimer
{
	if (_isWorkedDisplayToggleTimer) {
		[self setupDisplayToggleTimer];
	}
}

@end
