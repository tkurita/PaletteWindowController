/* PaletteWindowController */

#import <Cocoa/Cocoa.h>

@interface PaletteWindowController : NSWindowController
{
	NSRect expandedRect;
	id contentViewBuffer;
}

@property NSString *applicationsFloatingOnKeyPath;
@property NSString *applicationsFloatingOnEntryName;
@property NSArray *applicationsFloatingOn;
@property NSArray *appIdentifiersFloatingOn;
@property NSString *frameName;
@property BOOL isOpened;
@property BOOL isCollapsed;

+ (void)setVisibilityController:(id)theObj;
+ (id)visibilityController;

- (BOOL)shouldUpdateVisibilityForApp:(NSDictionary *)appDict;
- (void)setVisibility:(BOOL)shouldShow;

//setup behavior
- (void)bindApplicationsFloatingOnForKey:(NSString *)theKeyPath;
- (void)setApplicationsFloatingOnFromDefaultName:(NSString *)entryName;
- (void)useWindowCollapse;
- (void)useFloating;
- (void)setUseFloating:(BOOL)aFlag;

//methods for override
- (void)saveDefaults;

//private
- (void)collapseAction;
- (float)titleBarHeight;
- (void)toggleCollapseWithAnimate:(BOOL)flag;
- (void)applicationWillTerminate:(NSNotification *)aNotification;

//using delegate methods
- (void)windowWillClose:(NSNotification *)aNotification;
- (BOOL)windowShouldClose:(id)sender;
@end
