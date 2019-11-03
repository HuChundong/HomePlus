//
// HomePlus.xm
// HomePlus
//
// Collection of the hooks needed to get this tweak working
//
// Pragma marks are formatted to look best in VSCode w/ mark jump
//
// Created Oct 2019
// Author: Kritanta
//



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
static BOOL _pfTweakEnabled = YES;
// static BOOL _pfBatterySaver = NO;
static BOOL _pfEditingEnabled = NO;
static CGFloat _pfEditingScale = 0.7;

CGFloat customTopInset = 0;
CGFloat customSideInset = 0;


NSDictionary *prefs = nil;

# pragma mark Implementations

@implementation HPHitboxView
-(BOOL)deliversTouchesForGesturesToSuperview
{
    return (![(SpringBoard*)[UIApplication sharedApplication] isShowingHomescreen]);
}
@end

@implementation HPHitboxWindow
@end
#pragma mark 
#pragma mark - Tweak -----
#pragma mark 
#pragma mark -- SBHomeScreenWindow

%hook SBHomeScreenWindow

%property (nonatomic, retain) HPHitboxView *hp_hitbox;
%property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;
-(id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    /* 
     * This is the initialization method typically used for SBHomeScreenWindow
     * 
     * Add notification listeners and create managers after the class is initialized normally
    */
    id o = %orig(arg1, arg2, arg3, arg4, arg5);

    if (!_pfTweakEnabled) return o;

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
-(void)createManagers
{
    /*
     * We create the managers in this particular class because, at the time of initalization, the keyWindow is in the
     *      best location for adding the editor view as a subview.
    */
    if (!_pfTweakEnabled) return;
    HPEditorWindow *view = [[EditorManager sharedManager] editorView];
    [[[UIApplication sharedApplication] keyWindow] addSubview:view];

    HPManager *manager = [HPManager sharedManager];
}


%end

#pragma mark 
#pragma mark -- _SBWallpaperWindow

%hook _SBWallpaperWindow 
-(id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    /*
     * Solely for scaling the wallpaper with the rest of the view
    */
    id o = %orig(arg1, arg2, arg3, arg4, arg5);
    
    if (!_pfTweakEnabled) return o;

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

#pragma mark 
#pragma mark -- Floaty Dock Thing

%hook SBMainScreenActiveInterfaceOrientationWindow

/* 
 * Floaty Dock scaling.
*/
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


%hook SBRootFolderController
/*
 * Disable Icon wiggle upon loading edit view.
*/
-(void)viewDidLoad
{
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableWiggle:) name:kDisableWiggleTrigger object:nil];
}
%new 
-(void)disableWiggle:(NSNotification *)notification 
{
    [self doneButtonTriggered:self.contentView.doneButton];
}
%end

#pragma mark -- SBRootIconListView

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
-(void)layoutIconsNow {
    %orig;
    if (!_pfTweakEnabled) return;
    double labelAlpha = [[HPManager sharedManager] currentLoadoutShouldShowIconLabels] ? 1.0 : 0.0;
    [self setIconsLabelAlpha:labelAlpha];
}
-(void)setIconsLabelAlpha:(double)arg1 {
    if (!_pfTweakEnabled) 
    {
        %orig(arg1);
        return;
    }
    double labelAlpha = [[HPManager sharedManager] currentLoadoutShouldShowIconLabels] ? arg1 : 0.0;
    %orig(labelAlpha);
}
-(CGFloat)verticalIconPadding 
{
    CGFloat x = %orig;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:x
                  forKey:@"defaultVSpacing"];
    return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutVerticalSpacing] : x;
}

-(CGFloat)sideIconInset
{   
    CGFloat x = %orig;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:x
                  forKey:@"defaultHSpacing"];
    return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutHorizontalSpacing] : x;
}

-(CGFloat)topIconInset
{
    CGFloat x = %orig;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:x
                  forKey:@"defaultTopInset"];
    return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutTopInset] : x;
}

+(NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1
{
	NSInteger x = %orig(arg1);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:x
                  forKey:@"defaultColumns"];
	return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutColumns] : x;
}

+(NSUInteger)iconRowsForInterfaceOrientation:(NSInteger)arg1
{
	NSInteger x = %orig(arg1);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:x
                  forKey:@"defaultRows"];
	return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutRows] : x;
}
-(NSUInteger)iconRowsForSpacingCalculation
{
	NSInteger x = %orig;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:x
                  forKey:@"defaultRows"];
	return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutRows] : x;
}
%end

%hook SBCoverSheetWindow

-(BOOL)becomeFirstResponder 
{
    %orig;
    if ([(SpringBoard*)[UIApplication sharedApplication] isShowingHomescreen] && _pfEditingEnabled) {
        AudioServicesPlaySystemSound(1520);
        AudioServicesPlaySystemSound(1520);
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
        NSLog(@"%@%@", kUniqueLogIdentifier, @": Sent Disable Notification");
        _pfEditingEnabled = NO;
    }
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
-(void)createHitboxView
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

-(void)layoutSubviews
{
    %orig;

    if (!self.hp_hitbox_window && _pfTweakEnabled) {
        [self createHitboxView];
    }
}

%end

#pragma mark Preferences
static void *observer = NULL;


static void reloadPrefs() {
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList) {
			prefs = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
			if (!prefs) {
				prefs = [NSDictionary new];
			}
			CFRelease(keyList);
		}
	} else {
		prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	}
}


static BOOL boolValueForKey(NSString *key, BOOL defaultValue) {
	return (prefs && [prefs objectForKey:key]) ? [[prefs objectForKey:key] boolValue] : defaultValue;
}

static void preferencesChanged() {
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);
	reloadPrefs();

	_pfTweakEnabled = boolValueForKey(@"HPEnabled", YES);
}

#pragma mark ctor

%ctor {
	preferencesChanged();

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        &observer,
		(CFNotificationCallback)preferencesChanged,
        (CFStringRef)@"me.kritanta.homeplus/settingschanged",
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}