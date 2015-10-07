#import "PaletteWindowController.h"

#define useLog 0

static id VisibilityController;

@implementation PaletteWindowController

+ (void)setVisibilityController:(id)theObj
{
	VisibilityController = theObj;
}

+ (id)visibilityController
{
	return VisibilityController;
}

#pragma mark init and actions
- (IBAction)showWindow:(id)sender
{
	[super showWindow:sender];
	[VisibilityController addWindowController:self];
	_isOpened = YES;
	NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
	[notiCenter addObserver:self selector:@selector(applicationWillTerminate:) 
					   name:NSApplicationWillTerminateNotification object:nil];
}

#pragma mark methods for applications the window float on
- (void)setUseFloating:(BOOL)aFlag
{
	NSWindow *a_window = [self window];
	if (aFlag) {
		[a_window setLevel:NSFloatingWindowLevel];
	} else {
		[a_window setLevel:NSNormalWindowLevel];
	}
}

- (void)useFloating
{
	NSWindow *theWindow = [self window];
	[theWindow setHidesOnDeactivate:NO];
	[theWindow setLevel:NSFloatingWindowLevel];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:_applicationsFloatingOnKeyPath]) {
		NSArray *appList = [[[object values] valueForKey:_applicationsFloatingOnEntryName] valueForKey:@"appName"];
		self.applicationsFloatingOn = appList;
	}
}

- (void)setApplicationsFloagingOnKeyPathFromKey:(NSString *)theKey
{
	self.applicationsFloatingOnEntryName = theKey;
	
	NSString *firstKey = @"values";
	NSString *keyPath = [firstKey stringByAppendingPathExtension:theKey];
	
	self.applicationsFloatingOnKeyPath = keyPath;
}

- (void)bindApplicationsFloatingOnForKey:(NSString *)theKey
{
#if useLog
	NSLog(@"start bindApplicationsFloatingOnForKey");
#endif
	[self setApplicationsFloagingOnKeyPathFromKey:theKey];
	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	NSArray *app_list = [[[defaultsController values] valueForKey:theKey] valueForKey:@"appName"];
	NSArray *identifier_list = [[[defaultsController values] valueForKey:theKey] valueForKey:@"identifier"];
	self.applicationsFloatingOn = app_list;
	self.appIdentifiersFloatingOn = identifier_list;
	[defaultsController addObserver:self forKeyPath:_applicationsFloatingOnKeyPath
										options:NSKeyValueObservingOptionNew context:nil];
}

- (void)setApplicationsFloatingOnFromDefaultName:(NSString *)entryName
{
#if useLog
	NSLog(@"setApplicationsFloatingOnFromDefaultName");
#endif
	NSArray *appList = [[[NSUserDefaults standardUserDefaults] 
						arrayForKey:entryName] valueForKey:@"appName"];
	self.applicationsFloatingOn = appList;
}

#pragma mark methods for others
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillTerminate in PaletteWindowController");
#endif	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveDefaults
{
	NSWindow *a_window = [self window];
    if (_collapsedStateName) {
        [[NSUserDefaults standardUserDefaults] setBool:_isCollapsed forKey:_collapsedStateName];
    }
	if (_frameName) {
        if (_isCollapsed) {
            [self toggleCollapseWithAnimate:NO];
        }
        [a_window saveFrameUsingName:_frameName];
    }
}

#pragma mark methods for toggle visibility
- (BOOL)shouldUpdateVisibilityForApp:(NSDictionary *)appDict
{
#if useLog
	NSLog(@"start shouldUpdateVisibilityForApp");
#endif
	NSString *app_identifier = appDict[@"NSApplicationBundleIdentifier"]; 
	
	BOOL result = NO;
	if (app_identifier != nil)
		result = [_appIdentifiersFloatingOn containsObject:app_identifier];
	
	if (!result) {
		NSString *app_name = appDict[@"NSApplicationName"];
		result = [_applicationsFloatingOn containsObject:app_name];
	}
	
	return result;
}

- (void)setVisibility:(BOOL)shouldShow
{
#if useLog
	NSLog(@"start setVisibility %d", shouldShow);
#endif	
	NSWindow *theWindow = [self window];
	
	if (shouldShow){
		if (![theWindow isMiniaturized] && ![theWindow isVisible]) {
#if useLog
			NSLog(@"window will be visible");
#endif
			[theWindow orderBack:self];
		}
	}
	else {
		if ([theWindow isVisible]) {
			if ([theWindow attachedSheet] == nil) {
#if useLog
				NSLog(@"window will be hidden");
#endif				
				[theWindow orderOut:self];
			}
		}
	}
}

#pragma mark methods for collapsing
- (float)titleBarHeight
{
	id theWindow = [self window];
	 NSRect windowRect = [theWindow frame];
	 NSRect contentRect = [NSWindow contentRectForFrameRect:windowRect
												  styleMask:[theWindow styleMask]];
	 //NSRect contentRect = [[theWindow contentView] frame];
	 return NSHeight(windowRect) - NSHeight(contentRect);
}

- (void)collapseAction
{
	[self toggleCollapseWithAnimate:NO];
}

- (void)toggleCollapseWithAnimate:(BOOL)flag
{
	NSWindow *theWindow = [self window];
	NSRect windowRect = [theWindow frame];

	if (_isCollapsed) {
		windowRect.origin.y = windowRect.origin.y - expandedRect.size.height + windowRect.size.height;
		windowRect.size.height = expandedRect.size.height;
		[theWindow setFrame:windowRect display:YES animate:flag];
		if (_frameName) [theWindow saveFrameUsingName:_frameName];
		[theWindow setContentView:contentViewBuffer];
		self.isCollapsed = NO;
		
	}
	else {
		expandedRect = windowRect;
		NSRect contentRect = [NSWindow contentRectForFrameRect:windowRect styleMask:[theWindow styleMask]];
		windowRect.origin.y = windowRect.origin.y + NSHeight(contentRect);
		windowRect.size.height = NSHeight(windowRect) - NSHeight(contentRect);
		if (_frameName) [theWindow saveFrameUsingName:_frameName];
		[theWindow setContentView:nil];
		[theWindow setFrame:windowRect display:YES animate:flag];
		
		self.isCollapsed = YES;
	}
}


- (void)useWindowCollapse
{
	self.isCollapsed = NO;
	id theWindow = [self window];
	contentViewBuffer = [theWindow contentView];
	NSButton *zoomButton = [theWindow standardWindowButton:NSWindowZoomButton];
	[zoomButton setTarget:self];
	[zoomButton setAction:@selector(collapseAction)];
}

#pragma mark delegates and overriding methods
- (void)windowDidLoad
{
	NSWindow *theWindow = [self window];
	[theWindow center];
	if (_frameName) [theWindow setFrameUsingName:_frameName];
    if (_collapsedStateName) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:_collapsedStateName]) {
            [self toggleCollapseWithAnimate:NO];
        }
    }
	[super windowDidLoad];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
	if (_isCollapsed) {
		NSRect currentRect = [sender frame];
		return currentRect.size;
	}
	else {
		return proposedFrameSize;
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start windowWillClose:");
#endif
	self.isOpened = NO;
	[VisibilityController removeWindowController:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if (_applicationsFloatingOnKeyPath) {
		[[NSUserDefaultsController sharedUserDefaultsController] 
			removeObserver:self forKeyPath:_applicationsFloatingOnKeyPath];
	}
	
	[self saveDefaults];
#if useLog
	NSLog(@"end windowWillClose;");
#endif	
}

- (BOOL)windowShouldClose:(id)sender
{
#if useLog
	NSLog(@"start windowShouldClose");
#endif
	self.isOpened = NO;
	[VisibilityController removeWindowController:self];
	return YES;
}

@end
