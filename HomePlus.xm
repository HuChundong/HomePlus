//
// HomePlus.xm
// HomePlus
//
// Collection of the hooks needed to get this tweak working
//
// Get comfortable with Ternary Operators, I use them liberally and religiously 
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
static NSInteger _pfActivationGesture = 1;
static BOOL _pfEditingEnabled = NO;
static CGFloat _pfEditingScale = 0.7;

CGFloat customTopInset = 0;
CGFloat customSideInset = 0;


NSDictionary *prefs = nil;

# pragma mark Implementations

@implementation HPTouchKillerHitboxView
- (BOOL)deliversTouchesForGesturesToSuperview
{
    return (![(SpringBoard*)[UIApplication sharedApplication] isShowingHomescreen]);
}
@end
@implementation HPHitboxView
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

- (id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    /* 
     * This is the initialization method typically used for SBHomeScreenWindow
     * 
     * Add notification listeners and create managers after the class is initialized normally
    */
    id o = %orig(arg1, arg2, arg3, arg4, arg5);

    if (!_pfTweakEnabled)
    {
        return o;
    } 

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    [self createManagers];

    return o;
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    BOOL notched = NO;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height)
        {
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
    CGFloat cR = notched ? 40 : 0;
    
    if (enabled) 
    {
        self.layer.borderColor = enabled 
            ? [[UIColor whiteColor] CGColor] 
            : [[UIColor clearColor] CGColor];

        self.layer.borderWidth = enabled ? 1 : 0;
        self.layer.cornerRadius = enabled ? cR : 0;
    }
    else
    {
        [[EditorManager sharedManager] toggleEditorView];
    }
    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.transform = (enabled ? CGAffineTransformMakeScale(_pfEditingScale, _pfEditingScale) : CGAffineTransformIdentity);
        } 
        completion:^(BOOL finished)
        {
            if (enabled) 
            {
                [[EditorManager sharedManager] toggleEditorView];
            }
            self.layer.borderColor = enabled 
                ? [[UIColor whiteColor] CGColor] 
                : [[UIColor clearColor] CGColor];
            self.layer.borderWidth = enabled ? 1 : 0;
            self.layer.cornerRadius = enabled ? cR : 0;
        }
    ];
}

%new 
- (void)createManagers
{
    /*
     * We create the managers in this particular class because, at the time of initalization, the keyWindow is in the
     *      best location for adding the editor view as a subview.
    */

    if (!_pfTweakEnabled) {
        return;
    }

    HPEditorWindow *view = [[EditorManager sharedManager] editorView];
    [[[UIApplication sharedApplication] keyWindow] addSubview:view];

    HPManager *manager = [HPManager sharedManager];
}


%end

#pragma mark 
#pragma mark -- _SBWallpaperWindow

%hook _SBWallpaperWindow 
- (id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    /*
     * Solely for scaling the wallpaper with the rest of the view
    */
    id o = %orig(arg1, arg2, arg3, arg4, arg5);
    
    if (!_pfTweakEnabled)
    {
        return o;
    } 

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    return o;
}
%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    _pfEditingEnabled = enabled;
    BOOL notched = NO;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) 
        {
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

    CGFloat cR = notched ? 40 : 0;

    if (enabled) 
    {
        self.layer.cornerRadius = enabled ? cR : 0;
    }

    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.transform = (enabled ? CGAffineTransformMakeScale(_pfEditingScale, _pfEditingScale) : CGAffineTransformIdentity);
        }
        completion:^(BOOL finished)
        {
            self.layer.cornerRadius = enabled ? cR : 0;
        }
    ];
}
%end

#pragma mark 
#pragma mark -- Floaty Dock Thing

%hook SBMainScreenActiveInterfaceOrientationWindow

/* 
 * Floaty Dock scaling.
*/
- (id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    id o = %orig(arg1, arg2, arg3, arg4, arg5);

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    return o;
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    _pfEditingEnabled = enabled;
    BOOL notched = NO;

    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
    {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) 
        {
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

    if (enabled) 
    {
        self.layer.cornerRadius = enabled ? cR : 0;
    }

    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.transform = (enabled ? CGAffineTransformMakeScale(_pfEditingScale, _pfEditingScale) : CGAffineTransformIdentity);
        } 
        completion:^(BOOL finished) 
        {
            self.layer.cornerRadius = enabled ? cR : 0;
        }
    ];

}
%end


%hook SBRootFolderController
/*
 * Disable Icon wiggle upon loading edit view.
*/
- (void)viewDidLoad
{
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableWiggle:) name:kDisableWiggleTrigger object:nil];
}
%new 
- (void)disableWiggle:(NSNotification *)notification 
{
    [self doneButtonTriggered:self.contentView.doneButton];
}
%end

@interface _NSCompositeLayoutXAxisAnchor : NSObject
- (NSArray *)_childAnchors;
@end

@interface NSLayoutXAxisAnchor ()
- (_NSCompositeLayoutXAxisAnchor *)offsetBy:(CGFloat)arg;
@end

#pragma mark -- SBRootIconListView

%hook SBRootIconListView 

%property (nonatomic, assign) BOOL configured;

/*
- (id)initWithModel:(id)arg1 orientation:(id)arg2 viewMap:(id)arg3 {
    id o = %orig(arg1, arg2, arg3);

    return o;
}
*/
- (void)layoutSubviews 
{
    %orig;

    if (!self.configured) 
    {
        [self layoutIconsNow];
        // Configure our reset-to-default values based on what the phone gives us.
        [[NSUserDefaults standardUserDefaults] setFloat:[self topIconInset]
                                                forKey:@"defaultTopInset"];
        [[NSUserDefaults standardUserDefaults] setFloat:0.0
                                                forKey:@"defaultLeftInset"];
        [[NSUserDefaults standardUserDefaults] setFloat:[self sideIconInset]
                                                forKey:@"defaultHSpacing"];
        [[NSUserDefaults standardUserDefaults] setFloat:[self verticalIconPadding]
                                                forKey:@"defaultVSpacing"];
        [[NSUserDefaults standardUserDefaults] setInteger:4
                                                forKey:@"defaultColumns"];
        [[NSUserDefaults standardUserDefaults] setInteger:[self iconRowsForSpacingCalculation]
                                                forKey:@"defaultRows"];

        [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
        [self layoutIconsNow];
        self.configured = YES;
    }
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    if (!([[notification name] isEqualToString:kEditingModeEnabledNotificationName])) 
    {
        [[HPManager sharedManager] saveCurrentLoadoutName];
        [[HPManager sharedManager] saveCurrentLoadout];
        [self layoutIconsNow];
    }
}

%new
- (void)resetValuesToDefaults 
{
    [[HPManager sharedManager] resetCurrentLoadoutToDefaults];
    [self layoutIconsNow];
    _pfEditingEnabled = NO;
    [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];
    [self layoutIconsNow];
}

- (void)layoutIconsNow 
{
    %orig;

    if (!_pfTweakEnabled)
    {
        return;
    }
    
    double labelAlpha = [[HPManager sharedManager] currentLoadoutShouldHideIconLabels] ? 0.0 : 1.0;
    [self setIconsLabelAlpha:labelAlpha];
}
- (CGFloat)horizontalIconPadding {
	CGFloat x = %orig;

    return (_pfTweakEnabled && [[HPManager sharedManager] currentLoadoutLeftInset] != 0.0) ? [[HPManager sharedManager] currentLoadoutHorizontalSpacing] : x;
}
- (CGFloat)verticalIconPadding 
{
    CGFloat x = %orig;
    [[NSUserDefaults standardUserDefaults] setFloat:x
                                                forKey:@"defaultVSpacing"];

    return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutVerticalSpacing] : x;
}

- (CGFloat)sideIconInset
{   
    CGFloat x = %orig;
    if (!self.configured)
    {
        return x;
    }
    return (_pfTweakEnabled && [[HPManager sharedManager] currentLoadoutLeftInset] != 0.0) ? [[HPManager sharedManager] currentLoadoutLeftInset] : [[HPManager sharedManager] currentLoadoutHorizontalSpacing];
}

- (CGFloat)topIconInset
{
    CGFloat x = %orig;
    if (!self.configured)
    {
        return x;
    }
    
    return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutTopInset] : x;
}

+ (NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1
{
	NSInteger x = %orig(arg1);

	return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutColumns] : x;
}

+ (NSUInteger)iconRowsForInterfaceOrientation:(NSInteger)arg1
{
	NSInteger x = %orig(arg1);

	return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutRows] : x;
}

- (NSUInteger)iconRowsForSpacingCalculation
{
	NSInteger x = %orig;
    if (!self.configured)
    {
        return x;
    }

	return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutRows] : x;
}
%end


%hook SBIconLegibilityLabelView

- (void)setHidden:(BOOL)arg1 
{
    BOOL hide = NO;
    if (((SBIconLabelImage *)self.image).parameters.iconLocation  == 1)
    {
        // home screen
        hide = [[HPManager sharedManager] currentLoadoutShouldHideIconLabels];
    } 
    else if (((SBIconLabelImage *)self.image).parameters.iconLocation == 6) 
    {
        // folder
        hide = [[HPManager sharedManager] currentLoadoutShouldHideIconLabelsInFolders];
    }
    hide = (hide || arg1);

	%orig(hide);
}

%end


%hook SBIconView 

- (void)layoutSubviews 
{
	%orig;
    BOOL hideThis = NO;
	switch ( [self location] ) 
    {
        case 1: 
        {
            hideThis = [[HPManager sharedManager] currentLoadoutShouldHideIconLabels];
            break;
        }
        case 6: 
        {
            hideThis = [[HPManager sharedManager] currentLoadoutShouldHideIconLabelsInFolders];
        }
        default: 
        {
            hideThis = [[HPManager sharedManager] currentLoadoutShouldHideIconLabels];
            break;
        }
    }
    [self setLabelAccessoryViewHidden:hideThis];
    self.iconAccessoryAlpha = [[HPManager sharedManager] currentLoadoutShouldHideIconBadges] ? 0.0 : 1.0;
}


%end

%hook SBFolderIconBackgroundView
- (void)setHidden:(BOOL)arg1 
{
    %orig(arg1);
}
%end

%hook SBCoverSheetWindow

- (BOOL)becomeFirstResponder 
{
    %orig;
    if ([(SpringBoard*)[UIApplication sharedApplication] isShowingHomescreen] && _pfEditingEnabled) 
    {
        AudioServicesPlaySystemSound(1520);
        AudioServicesPlaySystemSound(1520);
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
        _pfEditingEnabled = NO;
    }
}

%end

%hook FBSystemGestureView

%property (nonatomic, assign) BOOL hitboxViewExists;
%property (nonatomic, retain) HPHitboxView *hp_hitbox;
%property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;

%new
- (void)TL_toggleEditingMode
{
    if (![(SpringBoard*)[UIApplication sharedApplication] isShowingHomescreen]) 
    {
        return;
    }
    if (_pfActivationGesture != 1) 
    {
        return;
    }
    BOOL enabled = !_pfEditingEnabled;

    if (enabled)
    {
        AudioServicesPlaySystemSound(1520);
        AudioServicesPlaySystemSound(1520);
        [[NSNotificationCenter defaultCenter] postNotificationName:kDisableWiggleTrigger object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeEnabledNotificationName object:nil];
    }
    else 
    {
        AudioServicesPlaySystemSound(1520);
        AudioServicesPlaySystemSound(1520);
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
    }
    _pfEditingEnabled = enabled;
}
%new
- (void)BX_toggleEditingMode
{
    if (![(SpringBoard*)[UIApplication sharedApplication] isShowingHomescreen]) 
    {
        return;
    }
    if (_pfActivationGesture != 2) 
    {
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
- (void)createTopLeftHitboxView
{
    self.hp_hitbox_window = [[HPHitboxWindow alloc] initWithFrame:CGRectMake(0, 0, 60, 20)];

    self.hp_hitbox = [[HPTouchKillerHitboxView alloc] init];
    self.hp_hitbox.backgroundColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.001];
    [self.hp_hitbox setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];

    UISwipeGestureRecognizer *swipeDownGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(TL_toggleEditingMode)];
    [swipeDownGesture setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.hp_hitbox addGestureRecognizer: swipeDownGesture];

    UISwipeGestureRecognizer *swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(TL_toggleEditingMode)];
    [swipeUpGesture setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.hp_hitbox addGestureRecognizer: swipeUpGesture];

    CGSize hitboxSize = CGSizeMake(60, 20);

    self.hp_hitbox.frame = CGRectMake(0, 0, hitboxSize.width, hitboxSize.height);
    [self.hp_hitbox_window addSubview:self.hp_hitbox];
    [self addSubview:self.hp_hitbox_window];
    self.hp_hitbox_window.hidden = NO;
}
%new 
- (void)createFullScreenDragUpView
{
    HPHitboxWindow *hp_hitbox_window = [[HPHitboxWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    HPHitboxView *hp_hitbox = [[HPHitboxView alloc] init];
    hp_hitbox.backgroundColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.001];
    [hp_hitbox setValue:@YES forKey:@"deliversTouchesForGesturesToSuperview"];
    [hp_hitbox_window setValue:@YES forKey:@"deliversTouchesForGesturesToSuperview"];

    UISwipeGestureRecognizer *swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(BX_toggleEditingMode)];
    [swipeUpGesture setDirection:UISwipeGestureRecognizerDirectionUp];

    [hp_hitbox addGestureRecognizer: swipeUpGesture];


    hp_hitbox.frame = [[UIScreen mainScreen] bounds];
    [hp_hitbox_window addSubview:hp_hitbox];
    [self addSubview:hp_hitbox_window];
    hp_hitbox_window.hidden = YES;
}

- (void)layoutSubviews
{
    %orig;

    if (!self.hp_hitbox_window && _pfTweakEnabled) 
    {
        [self createTopLeftHitboxView];
        [self createFullScreenDragUpView];
    }
}

%end

#pragma mark Preferences
static void *observer = NULL;


static void reloadPrefs() 
{
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) 
    {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList) 
        {
			prefs = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
			if (!prefs) 
            {
				prefs = [NSDictionary new];
			}
			CFRelease(keyList);
		}
	} 
    else 
    {
		prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	}
}


static BOOL boolValueForKey(NSString *key, BOOL defaultValue) 
{
	return (prefs && [prefs objectForKey:key]) ? [[prefs objectForKey:key] boolValue] : defaultValue;
}

static void preferencesChanged() 
{
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);
	reloadPrefs();

	_pfTweakEnabled = boolValueForKey(@"HPEnabled", YES);
    _pfActivationGesture = [[prefs objectForKey:@"gesture"] intValue] ?: 1;
}

#pragma mark ctor

%ctor 
{
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