#pragma mark Imports

#include <UIKit/UIKit.h>
#include "EditorManager.h"
#include "HPManager.h"
#include "HomePlus.h"
#import <AudioToolbox/AudioToolbox.h>

#pragma mark Constants 

#define kUniqueLogIdentifier @"HPD"

#define kEditingModeChangedNotificationName @"HomePlusEditingModeChanged"
#define kEditingModeEnabledNotificationName @"HomePlusEditingModeEnabled"
#define kEditingModeDisabledNotificationName @"HomePlusEditingModeDisabled"
#define kDeviceIsLocked @"HomePlusDeviceIsLocked"
#define kDeviceIsUnlocked @"HomePlusDeviceIsUnlocked"
#define kWiggleActive @"HomePlusWiggleActive"
#define kWiggleInactive @"HomePlusWiggleInactive"
#define kDisableWiggleTrigger @"HomePlusDisableWiggle"

#define kIdentifier @"me.kritanta.homeplusprefs"
#define kSettingsChangedNotification (CFStringRef)@"me.kritanta.homeplusprefs/settingschanged"
#define kSettingsPath @"/var/mobile/Library/Preferences/me.kritanta.homeplusprefs.plist"

#pragma mark Global Values
static BOOL _pfEditingEnabled = NO;
static CGFloat _pfEditingScale = 0.7;

CGFloat customTopInset = 0;
CGFloat customSideInset = 0;


NSDictionary *prefs = nil;

# pragma mark Headers


@implementation HPHitboxView
@end

@implementation HPHitboxWindow
@end


#pragma mark SBHomeScreenWindow

%hook SBHomeScreenWindow

%property (nonatomic, retain) HPHitboxView *hp_hitbox;
%property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;

-(id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    id o = %orig(arg1, arg2, arg3, arg4, arg5);

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
    NSLog(@"%@%@", kUniqueLogIdentifier, @": Initialized SBHomeScreenWindow and added Observers");

    [self createManagers];
    return o;
}

%new
-(void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    BOOL notched = NO;

    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
            case 2436:
                notched = YES;
                break;

            case 2688:
                notched = YES;
                break;

            case 1792:
                notched = YES;
                break;

            default:
                notched = NO;
                break;
        }
    }   
    CGFloat cR = notched ?40:0;

    
    NSLog(@"%@%@", kUniqueLogIdentifier, @": SBHSW Notification Recieved");
    if (enabled) {
        self.layer.borderColor = enabled ? [[UIColor whiteColor] CGColor] : [[UIColor clearColor] CGColor];
        self.layer.borderWidth = enabled ? 1 : 0;
        self.layer.cornerRadius = enabled ? cR : 0;
    }
    if (!enabled)[[EditorManager sharedManager] toggleEditorView];
    [UIView animateWithDuration:.2 animations:^{
        self.transform = (enabled ? CGAffineTransformMakeScale(_pfEditingScale, _pfEditingScale) : CGAffineTransformIdentity);
    } completion:^(BOOL finished){
        if (enabled) [[EditorManager sharedManager] toggleEditorView];
        self.layer.borderColor = enabled ? [[UIColor whiteColor] CGColor] : [[UIColor clearColor] CGColor];
        self.layer.borderWidth = enabled ? 1 : 0;
        self.layer.cornerRadius = enabled ? cR : 0;
    }];
}

%new
-(void)toggleEditingMode
{
    BOOL enabled = !_pfEditingEnabled;

    NSLog(@"%@%@", kUniqueLogIdentifier, @": Editing toggled");
    if (enabled)
    {
        AudioServicesPlaySystemSound(1520);
        AudioServicesPlaySystemSound(1520);
        [[NSNotificationCenter defaultCenter] postNotificationName:kDisableWiggleTrigger object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeEnabledNotificationName object:nil];
        NSLog(@"%@%@", kUniqueLogIdentifier,  @": Sent Enable Notification");
    }
    else 
    {
        AudioServicesPlaySystemSound(1520);
        AudioServicesPlaySystemSound(1520);
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
        NSLog(@"%@%@", kUniqueLogIdentifier, @": Sent Disable Notification");
    }
    _pfEditingEnabled = enabled;
}
%new 
-(void)createManagers
{
    HPEditorWindow *view = [[EditorManager sharedManager] editorView];
    [[[UIApplication sharedApplication] keyWindow] addSubview:view];

    HPManager *manager = [HPManager sharedManager];
}


%end

#pragma mark Wallpaper View

%hook _SBWallpaperWindow 
-(id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    id o = %orig(arg1, arg2, arg3, arg4, arg5);

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
    NSLog(@"%@%@", kUniqueLogIdentifier, @": Initialized _SBWallpaperWindow and added Observers");

    return o;
}
%new
-(void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    _pfEditingEnabled = enabled;
    BOOL notched = NO;

    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
            case 2436:
                notched = YES;
                break;

            case 2688:
                notched = YES;
                break;

            case 1792:
                notched = YES;
                break;

            default:
                notched = NO;
                break;
        }
    }   
    CGFloat cR = notched ?40:0;

    NSLog(@"%@%@", kUniqueLogIdentifier, @": Notification Recieved in SBWW");
    if (enabled) 
        self.layer.cornerRadius = enabled ? cR : 0;
    [UIView animateWithDuration:.2 animations:^{
        self.transform = (enabled ? CGAffineTransformMakeScale(_pfEditingScale, _pfEditingScale) : CGAffineTransformIdentity);
    }completion:^(BOOL finished){
        self.layer.cornerRadius = enabled ? cR : 0;
    }];
}
%end


%hook SBMainScreenActiveInterfaceOrientationWindow

-(id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    id o = %orig(arg1, arg2, arg3, arg4, arg5);

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
    NSLog(@"%@%@", kUniqueLogIdentifier, @": Initialized _SBWallpaperWindow and added Observers");

    return o;
}
%new
-(void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    _pfEditingEnabled = enabled;
    BOOL notched = NO;

    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
            case 2436:
                notched = YES;
                break;

            case 2688:
                notched = YES;
                break;

            case 1792:
                notched = YES;
                break;

            default:
                notched = NO;
                break;
        }
    }   
    CGFloat cR = notched ?40:0;

    NSLog(@"%@%@", kUniqueLogIdentifier, @": Notification Recieved in SBWW");
    if (enabled) 
        self.layer.cornerRadius = enabled ? cR : 0;
    [UIView animateWithDuration:.2 animations:^{
        self.transform = (enabled ? CGAffineTransformMakeScale(_pfEditingScale, _pfEditingScale) : CGAffineTransformIdentity);
    } completion:^(BOOL finished) {
        self.layer.cornerRadius = enabled ? cR : 0;
    }];
}
%end
@interface SBIconView : UIView
@property (nonatomic, retain) UIView *labelView;
@end
%hook SBIconView 
-(void)layoutSubviews
{
    %orig;
    self.labelView.hidden = ![[HPManager sharedManager] currentLoadoutShouldShowIconLabels];
}
%end
@interface SBEditingDoneButton : UIButton
@end
@interface SBRootFolderView
@property (nonatomic, retain) SBEditingDoneButton *doneButton;
@end
@interface SBRootFolderController
-(void)doneButtonTriggered:(id)button; 
@property (nonatomic, retain) SBRootFolderView *contentView;
@end
%hook SBRootFolderController
-(void)viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableWiggle:) name:kDisableWiggleTrigger object:nil];
}
%new 
-(void)disableWiggle:(NSNotification *)notification {
    [self doneButtonTriggered:self.contentView.doneButton];
}
%end
%hook SBRootFolderView
- (void)setEditing:(_Bool)arg1 animated:(_Bool)arg2 
{
    %orig(arg1, arg2);
    if (arg1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kWiggleActive object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kWiggleInactive object:nil];
    }
}
%end

%hook SBRootIconListView 

%property (nonatomic, assign) BOOL configured;

/*
-(id)initWithModel:(id)arg1 orientation:(id)arg2 viewMap:(id)arg3 {
    id o = %orig(arg1, arg2, arg3);

    return o;
}
*/
-(void)layoutSubviews 
{
    %orig;
    if (!self.configured) {
        [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
        [self layoutIconsNow];
        self.configured = YES;
    }
}

%new
-(void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    if (!enabled) {
        [[HPManager sharedManager] saveCurrentLoadoutName];
        [[HPManager sharedManager] saveCurrentLoadout];
    }
}

%new
-(void)resetValuesToDefaults 
{
    [self layoutIconsNow];
    _pfEditingEnabled = NO;
}

-(CGFloat)verticalIconPadding 
{
    CGFloat x = %orig;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:x
                  forKey:@"defaultVSpacing"];
    return [[HPManager sharedManager] currentLoadoutVerticalSpacing];
}

-(CGFloat)sideIconInset
{   
    CGFloat x = %orig;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:x
                  forKey:@"defaultHSpacing"];
    return [[HPManager sharedManager] currentLoadoutHorizontalSpacing];
}

-(CGFloat)topIconInset
{
    CGFloat x = %orig;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:x
                  forKey:@"defaultTopInset"];
    return [[HPManager sharedManager] currentLoadoutTopInset];
}

+(NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1{
	NSInteger x = %orig(arg1);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:x
                  forKey:@"defaultColumns"];
	return [[HPManager sharedManager] currentLoadoutColumns];
}

+(NSUInteger)iconRowsForInterfaceOrientation:(NSInteger)arg1{
	NSInteger x = %orig(arg1);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:x
                  forKey:@"defaultRows"];
	return [[HPManager sharedManager] currentLoadoutRows];
}
%end

%hook FBSystemGestureView

%property (nonatomic, assign) BOOL hitboxViewExists;
%property (nonatomic, retain) HPHitboxView *hp_hitbox;
%property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;

%new
-(void)toggleEditingMode
{
    if (![(SpringBoard*)[UIApplication sharedApplication] isShowingHomescreen]) {
        return;
    }
    BOOL enabled = !_pfEditingEnabled;

    NSLog(@"%@%@", kUniqueLogIdentifier, @": Editing toggled");
    if (enabled)
    {
        AudioServicesPlaySystemSound(1520);
        AudioServicesPlaySystemSound(1520);
        [[NSNotificationCenter defaultCenter] postNotificationName:kDisableWiggleTrigger object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeEnabledNotificationName object:nil];
        NSLog(@"%@%@", kUniqueLogIdentifier,  @": Sent Enable Notification");
    }
    else 
    {
        AudioServicesPlaySystemSound(1520);
        AudioServicesPlaySystemSound(1520);
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
        NSLog(@"%@%@", kUniqueLogIdentifier, @": Sent Disable Notification");
    }
    _pfEditingEnabled = enabled;
}
%new 
-(void)createEditorView
{
    self.hp_hitbox_window = [[HPHitboxWindow alloc] initWithFrame:CGRectMake(0, 0, 60, 20)];

    self.hp_hitbox = [[HPHitboxView alloc] init];
    self.hp_hitbox.backgroundColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.001];
    [self.hp_hitbox setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];

    UISwipeGestureRecognizer *swipeDownGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleEditingMode)];
    [swipeDownGesture setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.hp_hitbox addGestureRecognizer: swipeDownGesture];

    UISwipeGestureRecognizer *swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleEditingMode)];
    [swipeUpGesture setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.hp_hitbox addGestureRecognizer: swipeUpGesture];

    CGSize hitboxSize = CGSizeMake(60, 20);

    self.hp_hitbox.frame = CGRectMake(0, 0, hitboxSize.width, hitboxSize.height);
    [self.hp_hitbox_window addSubview:self.hp_hitbox];
    [self addSubview:self.hp_hitbox_window];
    self.hp_hitbox_window.hidden = NO;
}

-(void)layoutSubviews {
    %orig;
    if (!self.hp_hitbox_window) {
        [self createEditorView];
    }
}

%end

#pragma mark Preferences
/*
static void reloadPrefs() {
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList) {
			prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (!prefs) {
				prefs = [NSDictionary new];
			}
			CFRelease(keyList);
		}
	} else {
		prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	}
}

static void preferencesChanged() {
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);
	reloadPrefs();

}
*/
#pragma mark ctor

%ctor {

}