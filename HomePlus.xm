#pragma mark Imports

#include <UIKit/UIKit.h>
#include "EditorManager.h"
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

    [self createEditorView];
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
-(void)createEditorView
{
    HPEditorWindow *view = [[EditorManager sharedManager] editorView];
    [[[UIApplication sharedApplication] keyWindow] addSubview:view];

    self.hp_hitbox_window = [[HPHitboxWindow alloc] initWithFrame:CGRectMake(0, 0, 110, 40)];

    self.hp_hitbox = [[HPHitboxView alloc] init];
    self.hp_hitbox.backgroundColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.001];
    [self.hp_hitbox setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];

    UISwipeGestureRecognizer *swipeDownGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleEditingMode)];
    [swipeDownGesture setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.hp_hitbox addGestureRecognizer: swipeDownGesture];

    UISwipeGestureRecognizer *swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleEditingMode)];
    [swipeUpGesture setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.hp_hitbox addGestureRecognizer: swipeUpGesture];

    CGSize hitboxSize = CGSizeMake(110, 40);

    self.hp_hitbox.frame = CGRectMake(0, 0, hitboxSize.width, hitboxSize.height);
    [self.hp_hitbox_window addSubview:self.hp_hitbox];
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.hp_hitbox_window];
    self.hp_hitbox_window.hidden = NO;
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

%property (nonatomic, assign) CGFloat customTopInset;
%property (nonatomic, assign) CGFloat customLeftOffset;
%property (nonatomic, assign) CGFloat customVerticalSpacing;
%property (nonatomic, assign) CGFloat customSideInset;


-(id)initWithModel:(id)arg1 orientation:(id)arg2 viewMap:(id)arg3 {
    id o = %orig(arg1, arg2, arg3);
    self.customTopInset = [o topIconInset];
    self.customSideInset = [o sideIconInset];
    [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
    self.customTopInset = [[NSUserDefaults standardUserDefaults] floatForKey:@"customTopInset"] ?:0.0;
    self.customLeftOffset = [[NSUserDefaults standardUserDefaults] floatForKey:@"customLeftOffset"] ?:0.0;
    self.customSideInset = [[NSUserDefaults standardUserDefaults] floatForKey:@"customSideInset"] ?:0.0;
    self.customVerticalSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:@"customVerticalSpacing"] ?:0.0;
    [self layoutIconsNow];
    return o;
}

%new
-(void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    if (!enabled) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        [userDefaults setFloat:self.customTopInset
                        forKey:@"customTopInset"];
        [userDefaults setFloat:self.customLeftOffset
                        forKey:@"customLeftOffset"];
        [userDefaults setFloat:self.customSideInset
                        forKey:@"customSideInset"];
        [userDefaults setFloat:self.customVerticalSpacing
                        forKey:@"customVerticalSpacing"];
        // – setBool:forKey:
        // – setFloat:forKey:  
        // in your case 
        [userDefaults synchronize];
    } else {
        self.customTopInset = [[NSUserDefaults standardUserDefaults] floatForKey:@"customTopInset"] ?:0.0;
        self.customLeftOffset = [[NSUserDefaults standardUserDefaults] floatForKey:@"customLeftOffset"] ?:0.0;
        self.customVerticalSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:@"customVerticalSpacing"] ?:0.0;
        self.customSideInset = [[NSUserDefaults standardUserDefaults] floatForKey:@"customSideInset"] ?:0.0;
        [self layoutIconsNow];
        [self updateLeftOffset:self.customLeftOffset];
    }
}
%new
-(void)resetValuesToDefaults 
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.customTopInset = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultTopInset"] ?:0.0;
    self.customLeftOffset = 0.0;
    self.customVerticalSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultVerticalSpacing"] ?:0.0;
    self.customSideInset = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultSideInset"] ?:0.0;

    [userDefaults setFloat:self.customTopInset
                    forKey:@"customTopInset"];
    [userDefaults setFloat:self.customLeftOffset
                    forKey:@"customLeftOffset"];
    [userDefaults setFloat:self.customSideInset
                    forKey:@"customSideInset"];
    [userDefaults setFloat:self.customVerticalSpacing
                    forKey:@"customVerticalSpacing"];
    [self layoutIconsNow];
    _pfEditingEnabled = NO;
}
%new 
-(void)updateTopInset:(CGFloat)arg1
{
    self.customTopInset = arg1;
    [self layoutIconsNow];
}
%new 
-(void)updateLeftOffset:(CGFloat)arg1
{
    self.transform = CGAffineTransformIdentity;
    self.transform = CGAffineTransformMakeTranslation(arg1,0);
    self.customLeftOffset = arg1;
}
-(void)setTransform:(CGAffineTransform)transform {
    transform = CGAffineTransformIdentity;
    %orig(CGAffineTransformIdentity);
    transform = CGAffineTransformMakeTranslation(self.customLeftOffset,0);
    %orig(CGAffineTransformMakeTranslation(self.customLeftOffset,0));
}
%new 
-(void)updateVerticalSpacing:(CGFloat)arg1 
{
    self.customVerticalSpacing = arg1;
    [self layoutIconsNow];
}
%new
-(void)updateSideInset:(CGFloat)arg1
{
    self.customSideInset = arg1;
    [self layoutIconsNow];
}
-(CGFloat)verticalIconPadding 
{
    CGFloat x = %orig;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:x
                  forKey:@"defaultVerticalSpacing"];
    return self.customVerticalSpacing;
}
-(CGFloat)sideIconInset
{   
    CGFloat x = %orig;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:x
                  forKey:@"defaultSideInset"];
    return self.customSideInset;
}
-(CGFloat)topIconInset
{
    CGFloat x = %orig;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:x
                  forKey:@"defaultTopInset"];
    return self.customTopInset;
}

%end

@interface SBCoverSheetWindow : UIView
@end

%hook SBCoverSheetWindow

-(void)setHidden:(BOOL)arg 
{
    if (arg) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceIsUnlocked object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceIsLocked object:nil];
    }
    %orig(arg);
}

%end

@interface UIStatusBar_Modern : UIView
@end 

%hook UIStatusBar_Modern
-(void)layoutSubviews
{
    //gross 
    %orig;
    self.userInteractionEnabled = NO;
}
-(void)setUserInteractionEnabled:(BOOL)arg1 {
    arg1 = NO;
    %orig(NO);
}
-(BOOL)userInteractionEnabled
{
    return NO;
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