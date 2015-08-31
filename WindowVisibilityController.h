#import <Cocoa/Cocoa.h>

enum VisibilityUpdateMode {
	kShouldPostController = -1,
	kShouldHide = 0,
	kShouldShow = 1,
	kShouldNotChange = 2
};
typedef enum VisibilityUpdateMode VisibilityUpdateMode;

@interface WindowVisibilityController : NSObject {
    IBOutlet id delegate;	
	NSMutableArray *_windowControllers;
	
	BOOL _isWorkedDisplayToggleTimer;
	BOOL _installedAppSwitchEvent;
	AXObserverRef _appObserver;
	AXUIElementRef _targetApp;
	BOOL _installedFocusWatchObserver;
	VisibilityUpdateMode _visibilityForCurrentApplication;
}
@property NSTimer *displayToggleTimer;
@property (setter=setUseTimer:) BOOL isUseTimer;
@property NSString *focusWatchApplication;

//private
- (void)setupFocusChangeObserver;
- (void)setupAppChangeEvent;
- (void)updateVisibility:(NSNotification *)notification;

//public
+ (id)sharedWindowVisibilityController;
- (void)addWindowController:(id)windowController;
- (void)removeWindowController:(id)windowController;
- (int)judgeVisibilityForApp:(NSDictionary *)appDict;
- (void)setVisibilityForCurrentApplication:(VisibilityUpdateMode)mode;

- (void)setDelegate:(id)obj;

// methods for timer
- (void)setupDisplayToggleTimer;
- (void)stopDisplayToggleTimer;
- (void)temporaryStopDisplayToggleTimer;
- (void)restartStopDisplayToggleTimer;
- (BOOL)isWorkingDisplayToggleTimer;

@end
