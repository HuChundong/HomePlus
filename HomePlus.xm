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
#define kEditorKickViewsUp @"HomePlusKickWindowsUp"
#define kEditorKickViewsBack @"HomePlusKickWindowsBack"
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
static CGFloat _pfEditingScale = 0.7;

// Runtime Globals
static BOOL _rtEditingEnabled = NO;
static BOOL _rtKickedUp = NO;
static BOOL _rtnotched = NO;

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

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kicker:) name:kEditorKickViewsUp object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kicker:) name:kEditorKickViewsBack object:nil];

    [self createManagers];

    return o;
}

%new 
- (void)kicker:(NSNotification *)notification
{
    BOOL up = ([[notification name] isEqualToString:kEditorKickViewsUp]);
    CGAffineTransform transform = self.transform;

    [UIView animateWithDuration:.3 
    animations:
    ^{
        self.transform = (up && !_rtKickedUp) ? CGAffineTransformTranslate(transform, 0, (transform.ty == 0 ? 0-([[UIScreen mainScreen] bounds].size.height * 0.6) : 0.0)) : CGAffineTransformTranslate(transform, 0, (transform.ty == 0 ? 0 : ([[UIScreen mainScreen] bounds].size.height * 0.6)));
    }]; 
    
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
    _rtnotched = notched;
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

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kicker:) name:kEditorKickViewsUp object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kicker:) name:kEditorKickViewsBack object:nil];

    return o;
}

%new 
- (void)kicker:(NSNotification *)notification
{
    BOOL up = ([[notification name] isEqualToString:kEditorKickViewsUp]);
    CGAffineTransform transform = self.transform;
    [UIView animateWithDuration:.3 
    animations:
    ^{
        self.transform = (up && !_rtKickedUp) ? CGAffineTransformTranslate(transform, 0, (transform.ty == 0 ? 0-([[UIScreen mainScreen] bounds].size.height * 0.6) : 0.0)) : CGAffineTransformTranslate(transform, 0, (transform.ty == 0 ? 0 : ([[UIScreen mainScreen] bounds].size.height * 0.6)));
    }]; 
}
%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    _rtEditingEnabled = enabled;
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
    _rtnotched = notched;
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
 * TODO: Finish this stuff up
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
    _rtEditingEnabled = enabled;
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

%hook SBIconModel
-(id)initWithStore:(id)arg applicationDataSource:(id)arg2
{
    id x = %orig(arg, arg2);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:@"HPResetIconViews" object:nil];
    return x;
}
%new 

- (void)recieveNotification:(NSNotification *)notification
{
    @try {
        [self layout];
    } 
    @catch (NSException *exception) {
        NSLog(@"SBICONMODEL CRASH: %@", exception);
    }
}
%end

%hook SBRootFolderView


-(id)initWithFolder:(id)arg1 orientation:(NSInteger)arg2 viewMap:(id)arg3 context:(id)arg4 {
	if ((self = %orig(arg1, arg2, arg3, arg4))) {

	}

    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:@"HPResetIconViews" object:nil];
	return self;
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
        [self resetIconListViews];
}
%end
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
    _rtEditingEnabled = NO;
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

- (CGSize)alignmentIconSize 
{
    CGSize o = %orig;
    CGFloat s = [[HPManager sharedManager] currentLoadoutScale];
    return o;
    //return CGSizeMake(s, (o.height/o.width) * s);
}
- (CGSize)defaultIconSize
{
    CGSize o = %orig;
    return o;//CGSizeMake(s, (o.height/o.width) * s);
}
- (CGFloat)horizontalIconPadding {
	CGFloat x = %orig;
    if (!_pfTweakEnabled) {
        return x;
    }
    BOOL buggedSpacing = [[HPManager sharedManager] currentLoadoutColumns] == 4 && _rtnotched;
    BOOL leftInsetZeroed = [[HPManager sharedManager] currentLoadoutLeftInset] == 0.0;
    if (leftInsetZeroed) {
        return x;
    }
    else
    {
        return [[HPManager sharedManager] currentLoadoutHorizontalSpacing];
    }
    /*
    if (!buggedSpacing && leftInsetZeroed) {
        return x;
    }
    else if (leftInsetZeroed && !_rtnotched) {
        return [[HPManager sharedManager] currentLoadoutHorizontalSpacing];
    }
    else if (buggedSpacing && !leftInsetZeroed) {
        return -100.0;
    }
    else if (buggedSpacing && leftInsetZeroed) {
        return -100.0;
    }
    else if (!buggedSpacing && !leftInsetZeroed) {
        return [[HPManager sharedManager] currentLoadoutHorizontalSpacing];
    }*/

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
    if (!self.configured || !_pfTweakEnabled)
    {
        return x;
    }
    // I need to do a write-up on all of this sometime.
    // at ToW, this is confusing and hard to explain. 
    BOOL buggedSpacing = [[HPManager sharedManager] currentLoadoutColumns] == 4 && _rtnotched;
    BOOL leftInsetZeroed = [[HPManager sharedManager] currentLoadoutLeftInset] == 0.0;
    if (leftInsetZeroed) 
    {
        return [[HPManager sharedManager] currentLoadoutHorizontalSpacing];
    }
    else
    {
        return [[HPManager sharedManager] currentLoadoutLeftInset];
    }
    /*
    if (!buggedSpacing && !leftInsetZeroed) 
    {
        return [[HPManager sharedManager] currentLoadoutLeftInset];
    }
    else if (!leftInsetZeroed && !_rtnotched) 
    {
        return [[HPManager sharedManager] currentLoadoutLeftInset];
    }
    else if (buggedSpacing && !leftInsetZeroed)
    {
        return [[HPManager sharedManager] currentLoadoutHorizontalSpacing];
    }
    else if (!buggedSpacing && leftInsetZeroed)
    {
        return [[HPManager sharedManager] currentLoadoutHorizontalSpacing];
    }
    else if (buggedSpacing && leftInsetZeroed) 
    {
        return [[HPManager sharedManager] currentLoadoutHorizontalSpacing];
    }*/
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
/*
-(CGSize)iconImageVisibleSize 
{
    CGSize o = %orig;
    CGFloat s = [[HPManager sharedManager] currentLoadoutScale];
    return CGSizeMake(s, (o.height/o.width) * s);
}*/
%end
%hook SBIconImageView
-(void)setFrame:(CGRect)arg { // 60 / 2 - scale
    %orig(CGRectMake(arg.origin.x + ((arg.size.width / 2 ) - [[HPManager sharedManager] currentLoadoutScale]/2), arg.origin.y + ((arg.size.height / 2 ) - [[HPManager sharedManager] currentLoadoutScale]/2), [[HPManager sharedManager] currentLoadoutScale], [[HPManager sharedManager] currentLoadoutScale]*(74/60)));
    [[NSUserDefaults standardUserDefaults] setFloat:arg.size.width
                                                forKey:@"defaultScale"];
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
    if ([(SpringBoard*)[UIApplication sharedApplication] isShowingHomescreen] && _rtEditingEnabled) 
    {
        AudioServicesPlaySystemSound(1520);
        AudioServicesPlaySystemSound(1520);
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
        _rtEditingEnabled = NO;
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
    BOOL enabled = !_rtEditingEnabled;

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
    _rtEditingEnabled = enabled;
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
    BOOL enabled = !_rtEditingEnabled;

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
    _rtEditingEnabled = enabled;
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

%hook SBMainSwitcherWindow
-(void)setHidden:(BOOL)arg
{
    %orig(arg);
    if (_rtEditingEnabled && [[HPManager sharedManager] switcherDisables]) 
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
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