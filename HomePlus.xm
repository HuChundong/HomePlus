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

#include <UIKit/UIKit.h>
#include "EditorManager.h"
#include "HPManager.h"
#include "HPUtility.h"
#include "HomePlus.h"
#import <AudioToolbox/AudioToolbox.h>
#import <IconSupport/ISIconSupport.h>
#include <dlfcn.h>
#include <spawn.h>

// Quick empty implementations for custom UIViews
// I use these solely to make things easier to find in Flex
//      and maybe they will come in useful later
@implementation HPTouchKillerHitboxView
@end

@implementation HPHitboxView
@end

@implementation HPHitboxWindow
@end

#pragma mark Global Values

// Preference globals
static BOOL _pfTweakEnabled = YES;
// static BOOL _pfBatterySaver = NO; // Planned LPM Reduced Animation State
static BOOL _pfGestureDisabled = YES;
static NSInteger _pfActivationGesture = 1;
//static CGFloat _pfEditingScale = 0.7;

// Values we use everywhere during runtime. 
// These should be *avoided* wherever possible
// We can likely interface managers to handle these without too much overhead
static BOOL _rtEditingEnabled = NO;
static BOOL _rtConfigured = NO;
static BOOL _rtKickedUp = NO;
static BOOL _rtIconSupportInjected = NO;
// On <iOS 13 we need to reload the icon view initially several times to update our changes :)
static int _rtIconViewInitialReloadCount = 0;

// Tweak compatability stuff. 
// See the %ctor at the bottom of the file for more info
static BOOL _tcDockyInstalled = NO;

// Views to shrink with pan gesture
static UIView *wallpaperView = nil;
static UIView *homeWindow = nil;
static UIView *floatingDockWindow = nil;
static UIView *mockBackgroundView = nil;

// Gesture recognizer to enable whenever kDisableEditingMode is hit.
static UIPanGestureRecognizer *_rtGestureRecognizer = nil;
static HPHitboxWindow *_rtHitboxWindow = nil;

// Global for the preference dict. Not used outside of reloadPrefs() but its cool to have
NSDictionary *prefs = nil;

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//
//
// Tweak Hooks
// I'd eventually like to split these into individual files
// That'd require a custom preprocessor, though, as .xmi is kind of broken
//
//
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//
// Universal hooks
// These are applied regardless of version
// #pragma Universal
//
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

%group Universal

#pragma mark HomeScreen Window

%hook SBHomeScreenWindow

// Contains the Icon Lists
// Also where we inject the editor into springboard

- (id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    id o = %orig(arg1, arg2, arg3, arg4, arg5);

    if (!_pfTweakEnabled)
    {
        return o;
    } 

    homeWindow = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kicker:) name:kEditorKickViewsUp object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kicker:) name:kEditorKickViewsBack object:nil];

    // Create editor view and inject into springboard when this loads
    // Its in the perfect spot. Dont do this anywhere else 
    [self createManagers];

    return o;
}

%new 
- (void)kicker:(NSNotification *)notification
{
    CGAffineTransform transform = self.transform;

    [UIView animateWithDuration:0.4f// this matches it as closely as possible with the kicker in the editorviewcontroller
                                    // Maybe in the future I can find a way to animate them both at the same time. 
                                    // As for right now, I'm not quite sure :p
    animations:
    ^{
        // Why all this complex math? Why not CGAffineTransformIdentity?
        // We're shrinking the view 30% while all of this happens
        // So instead of using Identity, we basically verify its doing the right thing several times
        // This helps prevent bad notification calls, or pretty much anything else weird that might happen
        //      from making the view go off screen completely, requiring a reload 

        self.transform = (([[notification name] isEqualToString:kEditorKickViewsUp])                 // If we should move the view up
                        && !_rtKickedUp)                                                             //   And it isn't kicked up already (first verifiction)
                                ? CGAffineTransformTranslate(transform, 0, 
                                        (transform.ty == 0                                           //      If 0, move it up            (second verification)
                                            ? 0 - ([[UIScreen mainScreen] bounds].size.height * 0.7f) //      move up
                                            : 0.0f                                                   //      if its not 0, make it 0     (second v.)
                                        ))                                                           
                                : CGAffineTransformTranslate(transform, 0, 
                                        (transform.ty == 0                                           // If we should move it back 
                                            ? 0                                                      //   If it's 0, keep it as 0
                                            : ([[UIScreen mainScreen] bounds].size.height * 0.7f)     //     else, move it back.
                                        ));                                                          
    }]; 
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    
    if (enabled) 
    {
        [[EditorManager sharedManager] showEditorView];
    }
    else
    {
        [[EditorManager sharedManager] hideEditorView];
    }
}

%new 
- (void)createManagers
{
    // Managers are created after the HomeScreen view is initialized
    // This makes sure the EditorView is *directly* above the HS view
    //      so, we can float things and obscure the view if needed.
    // It also lets the user use CC/NC/any of that fun stuff while editing

    if (!_pfTweakEnabled || _pfGestureDisabled) 
    {
        return;
    }

    HPEditorWindow *view = [[EditorManager sharedManager] editorView];
    [[[UIApplication sharedApplication] keyWindow] addSubview:view];
    HPEditorWindow *tview = [[EditorManager sharedManager] tutorialView];
    [[[UIApplication sharedApplication] keyWindow] addSubview:tview];

    [HPManager sharedManager];

    // This is commented out but needs to be implemented at some point
    //[self configureDefaultsIfNotYetConfigured];
    
}

%end


#pragma mark Scalable Views

%hook _SBWallpaperWindow 

// This hook copies a lot of the hooks from the HomeScreenWindow hook
// Although, it does not do anything related to the managers
// This exists so we can shrink the wallpaper alongside the icon list
// Documentation for anything this does can be found in the SBHomeScreenWindow hook

- (id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    id o = %orig(arg1, arg2, arg3, arg4, arg5);
    
    if (!_pfTweakEnabled)
    {
        return o;
    } 
    
    wallpaperView = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kicker:) name:kEditorKickViewsUp object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kicker:) name:kEditorKickViewsBack object:nil];

    return o;
}

%new 
- (void)kicker:(NSNotification *)notification
{
    CGAffineTransform transform = self.transform;

    [UIView animateWithDuration:.4
    animations:
    ^{
        self.transform = (([[notification name] isEqualToString:kEditorKickViewsUp])              
                        && !_rtKickedUp)                                                           
                                ? CGAffineTransformTranslate(transform, 0.0f, 
                                        (transform.ty == 0.0f                                          
                                            ? 0.0f - ([[UIScreen mainScreen] bounds].size.height * 0.7f) 
                                            : 0.0f                                                  
                                        ))                                                           
                                : CGAffineTransformTranslate(transform, 0, 
                                        (transform.ty == 0.0
                                            ? 0.0f                                                    
                                            : ([[UIScreen mainScreen] bounds].size.height * 0.7f)
                                        )); 
    }]; 
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    // Set a corner radius on notched devices to make things look cleaner
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    _rtEditingEnabled = enabled;
    BOOL notched = [HPUtility isCurrentDeviceNotched];
    CGFloat cR = notched ? 35 : 0;
    self.layer.cornerRadius = enabled ? cR : 0;
}

%end


%hook SBFStaticWallpaperImageView

// Whenever a wallpaper image is created for the homescreen, pass it to the manager
// We then use this FB/UIRootWindow in the tweak to give the awesome blurred bg UI feel

- (void)setImage:(UIImage *)img 
{
    %orig(img);
    [[EditorManager sharedManager] loadUpImagesFromWallpaper:img];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateBackgroundObject" object:nil];
}

%end


#pragma mark Dock BG Handling

%hook SBDockView

// This is what we need to hook to hide the dock background cleanly
// This tidbit works across versions, so we can call it in the base group (%init)

- (id)initWithDockListView:(id)arg1 forSnapshot:(BOOL)arg2 
{
    id x = %orig;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutSubviews) name:@"HPLayoutDockView" object:nil];

    return x;
}

- (void)layoutSubviews
{
    %orig;

    UIView *bgView = MSHookIvar<UIView *>(self, "_backgroundView"); 

    // Dont use UserDefaults like this. Use the bool api. I am lazy. 
    bgView.alpha = [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultHideDock"]?:0 == 1 ? 0 : 1;
    bgView.hidden = [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultHideDock"]?:0 == 1 ? YES : NO;
}

%end


#pragma mark Editor Exit Listeners

%hook SBCoverSheetWindow

// This is the lock screen // drag down thing
// Pulling it down will disable the editor view

- (BOOL)becomeFirstResponder 
{
    BOOL x = %orig;

    if (_pfTweakEnabled && [(SpringBoard*)[UIApplication sharedApplication] isShowingHomescreen] && _rtEditingEnabled) 
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
        _rtEditingEnabled = NO;
    }

    return x;
}

%end


%hook SBMainSwitcherWindow

// Whenever the user swipes up to enable the switcher, close the editor view. 
// It's optional, since it makes the bottom half hard to use on HomeGesture Phones
//      on really small phones with HomeGesture

- (void)setHidden:(BOOL)arg
{
    %orig(arg);

    if (_rtEditingEnabled && [[HPManager sharedManager] switcherDisables]) 
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
    }
}

%end


#pragma mark Reload Icon Model

%hook SBIconModel

// The "Magic Method"
// This'll essentially reconstruct the layout of icons,
//      allowing us to update rows/columns without a respring

- (id)initWithStore:(id)arg applicationDataSource:(id)arg2
{
    id x = %orig(arg, arg2);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:@"HPResetIconViews" object:nil];

    return x;
}

%new 
- (void)recieveNotification:(NSNotification *)notification
{
    @try 
    {
        [self layout];
    } 
    @catch (NSException *exception) 
    {
        // Cant remember the details, but this method had a tendency to crash at times
        //      Make sure we dont cause a safe mode and instead just dont update layout

        // Lets make this an alert view in the future. 
        NSLog(@"SBICONMODEL CRASH: %@", exception);
    }
}

%end


#pragma mark Force Modern Dock

%hook UITraitCollection

// Force Modern Dock on non-A11+ Phones. 

- (CGFloat)displayCornerRadius 
{
    return ((![HPUtility isCurrentDeviceNotched]                                                                 // Dont do this on notched devices, no need
                && (([[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultModernDock"]?:0) == 1))  // If we're supposed to force modern dock
                        ? 6.0f                                                                                      // Setting this to a non-0 value forced modern dock
                        : %orig );                                                                               // else just orig it. 
}

%end


#pragma mark SpringBoard Hook 
#pragma mark FirstLoad/ShowingHomescreen

%hook SpringBoard 

- (BOOL)isShowingHomescreen
{
    if (!%orig)
    {
        if (_rtHitboxWindow)
        {
            _rtHitboxWindow.hidden = YES;
        }
    }
    else 
    {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 13.0f && _rtIconViewInitialReloadCount < 2)
        {
            _rtIconViewInitialReloadCount += 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HPResetIconViews" object:nil];
        }
        if (_rtHitboxWindow)
        {
            _rtHitboxWindow.hidden = NO;
        }
    }
    if (%orig && [[NSUserDefaults standardUserDefaults] integerForKey:@"HPTutorialGiven"] == 0)
    {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"HPTutorialGiven"];

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        NSString *location = @"Root";
        NSString *name = @"Default";

        NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", name];
        [userDefaults setBool:NO
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"]];
        [userDefaults setBool:NO
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"]];
        [userDefaults setBool:NO
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"]];
        [userDefaults setBool:NO
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"DockBG"]];
        [userDefaults setBool:NO
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"ModernDock"]];

        prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", name, location];
        [userDefaults setInteger:4
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"]];
        [userDefaults setInteger:[HPUtility defaultRows]
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"]];
        [userDefaults setFloat:60.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"]];
        [userDefaults setFloat:100.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconAlpha"]];

        location = @"Dock";
        prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", name, location];
        [userDefaults setInteger:4.0
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"]];
        [userDefaults setInteger:1.0
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"]];
        [userDefaults setFloat:60.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"]];
        [userDefaults setFloat:100.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconAlpha"]];
        
        location = @"Folder";
        prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", name, location];
        [userDefaults setInteger:3 // THIS NEEDS TO BE SET BECAUSE FOLDERS ARE ACTUALLY MODIFIED BY THE TWEAK
                                // FOLDERS WILL CRASH SB IF MODIFIED TILL I ACTUALLY WRITE A PROPER IMPLEMENTATION
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"]];
        [userDefaults setInteger:3
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"]];
        [userDefaults setFloat:60.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"]];
        [userDefaults setFloat:0.0f
                        forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconAlpha"]];

        [userDefaults synchronize];
        [[EditorManager sharedManager] showTutorialView];
    }
    return %orig;
}
%end


%end


// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//
// iOS 12 AND BEFORE
// #pragma iOS 12
//
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

%group iOS12

#pragma mark Version Specific Interfaces

@interface SBDockIconListView : SBRootIconListView
@end


#pragma mark Main Layout Handling

%hook SBRootIconListView 

%property (nonatomic, assign) BOOL configured;

- (void)layoutSubviews 
{
    %orig;

    if (!self.configured && _pfTweakEnabled) 
    {

        [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutIconsNow) name:@"HPlayoutIconViews" object:nil];

        self.configured = YES;
        _rtConfigured = YES;
    }
}

- (void)layoutIconsNow 
{
    %orig;

    if (!_pfTweakEnabled)
    {
        return;
    }
    
    // Trigger the icon label alpha function we hook
    [self setIconsLabelAlpha:1.0f];
}

- (CGFloat)horizontalIconPadding 
{
    CGFloat x = %orig;

    if (!_pfTweakEnabled || !self.configured || [[HPManager sharedManager] resettingIconLayout]) 
    {
        return x;
    }

    BOOL buggedSpacing = ((([[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootColumns"]?:4) == 4) 
                                && ([[HPUtility deviceName] isEqualToString:@"iPhone X"])); // Afaik, the "Boxy" bug only happens on iOS 12 iPX w/ 4 columns
                                                                                  // We dont need to check version because we're in a group block
                                                                                  //    that only executes on iOS 12 and below
                         

    BOOL leftInsetZeroed = ([[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootLeftInset"]?:0.0f) == 0.0f; // Enable more intuitive behavior 
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 12.0f)
    {
        // This gets confusing and is the result of a lot of experimentation
        if (buggedSpacing)
        {
            return -100.0f; // When the boxy bug happens, its triggered by this value being more than 0
                           //   From what I remember writing this, the lower the value, the more we can adjust the 
                           //   "Horizontal Spacing" aka "Side Inset"
        }
        if (leftInsetZeroed) 
        {
            // If the left inset is 0, return the original value here. Then, iOS will dynamically calculate this value based upon
            //    the Value of -(CGFloat)sideIconInset. This is hard to make clear with code, but the behavioral simplicity it gives
            //    is simply amazing. 
            return x; 
        }
        else
        {
            // In the event that Left Spacing is not zeroed, we'll do things Boxy style. 
            // What happens here is that this legitimately changes icon padding. 
            // It is near impossible to center; That is what some people want when they change
            // the left offset, so now, this function isn't dynamically calculated, its manually set by the user.
            return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootSideInset"]?:0.0f;
        }
    }
    else 
    {
        // on iOS 11, do things Boxy style. I need to do further testing to see if iOS 11 supports the cool
        //      calculations we used on iOS 12
        return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootSideInset"]?:0.0f;
    }
}

- (CGFloat)verticalIconPadding 
{
    CGFloat x = %orig;

    if (!self.configured || !_pfTweakEnabled) return x;
     
    return x+[[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootVerticalSpacing"]?:0.0f;
}

- (CGFloat)sideIconInset
{   
    // This is the other half of the complex stuff in horizontalIconPadding
    CGFloat x = %orig;

    if (!self.configured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }

    BOOL buggedSpacing = ((([[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootColumns"]?:4) == 4) && ([[HPUtility deviceName] isEqualToString:@"iPhone X"])); // Afaik, the "Boxy" bug only happens on iOS 12 iPX w/ 4 columns
                                                                                  // We dont need to check version because we're in a group block
                                                                                  //    that only executes on iOS 12 and below
                         

    BOOL leftInsetZeroed = ([[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootLeftInset"]?:0.0f) == 0.0f; // Enable more intuitive behavior 

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 12.0f)
    {
        if (leftInsetZeroed || buggedSpacing) 
        {
            return x + [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootSideInset"]?:0.0f;  // Here's the fix I found for the iPX 4col bug
                                                                                                            // Essentially, we can create the "HSpacing"/Side Inset
                                                                                                            //      by returning it here (along w/ hIP returning -100)
        }
        else
        {
            return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootLeftInset"]?:0.0f;      // Otherwise, return the Left Inset for here, on normal devices
        }
    }
    else
    {
        return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootLeftInset"]?:0.0f; // Just return Left Inset on iOS 12
    }  
}

- (CGFloat)topIconInset
{
    CGFloat x = %orig;

    if (!self.configured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }
    // These really shouldn't need much explaining
    // But fuck it; In boxy/cuboid and early versions of this tweak, i let users modify the value that was returned
    // Now, to make everything massively easier on both users and me, I return the original value and let the user
    //          add and subtract from that value. So, setting things to 0 means iOS defaults :)
    return x + [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootTopInset"]?:0.0f;
}

+ (NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1
{
    NSInteger x = %orig(arg1);

    if (!_rtConfigured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }
    
    // NSUInteger -> NSInteger doesn't require casts, just dont give it a negative value and its fine. 
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootColumns"]?:4;
}

+ (NSUInteger)iconRowsForInterfaceOrientation:(NSInteger)arg1
{
    NSInteger x = %orig(arg1);

    if (arg1==69)
    {
        return %orig(1);
    }

    if (!_rtConfigured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }

    return [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootRows"]?:x;
}

+ (NSUInteger)maxVisibleIconRowsInterfaceOrientation:(NSInteger)arg1
{
    // Allow more than 24 icons on the SB w/o a reload
    if (_pfTweakEnabled 
        && ([[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootRows"]?:[HPUtility defaultRows] == [HPUtility defaultRows])
        && (([[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootColumns"]?:4) == 4))
    {
        return %orig;
    }

    if (_pfTweakEnabled)
    {
        return ([[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootRows"] ?: [HPUtility defaultRows]);
    }

    return %orig;
}

%new 
- (NSUInteger)iconRowsForHomePlusCalculations
{
    // We use this to get the default row count from within the class. 
    // This same method can also be used to get the default from elsewhere. 
    return [[self class] iconRowsForInterfaceOrientation:69];
}

- (NSUInteger)iconRowsForSpacingCalculation
{
    NSInteger x = %orig;

    if (!self.configured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }

    return [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootRows"] ?: x;
}

%end


#pragma mark Dock Handling 

%hook SBDockIconListView

// Hook our dock icon list view
// For documentation on hooked methos see SbRootIconListView (ios 12)

%property (nonatomic, assign) BOOL configured;

- (void)layoutSubviews 
{
    %orig;

    if (_tcDockyInstalled || !_pfTweakEnabled) return; 

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"]) return %orig;

    if (!self.configured) 
    {
        [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];
        self.configured = YES;
    }
}

+ (NSUInteger)maxIcons 
{
    if (_tcDockyInstalled || (![[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"]) || !_pfTweakEnabled) return %orig;

    return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockColumns"] ?: 4.0f;
}

- (UIEdgeInsets)layoutInsets
{
    UIEdgeInsets x = %orig;

    if (!_pfTweakEnabled || (![[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"]))
    {
        return x;
    }
    
    if ((!([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"LeftInset"]]?:0.0f)) == 0.0f)
    {
        return UIEdgeInsetsMake(
            x.top + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"TopInset"]]?:0.0f),
            [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"LeftInset"]]?:0.0f,
            x.bottom - ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"TopInset"]]?:0.0f) + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"VerticalSpacing"]]?:0.0f) *-2, // * 2 because regularly it was too slow
            x.right - ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"LeftInset"]]?:0.0f) + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"SideInset"]]?:0.0f) *-2
        );
    }
    else
    {
        return UIEdgeInsetsMake(
            x.top + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"TopInset"]]?:0.0f) ,
            x.left + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"SideInset"]]?:0.0f)*-2,
            x.bottom - ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"TopInset"]]?:0.0f) + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"VerticalSpacing"]]?:0.0f) *-2, // * 2 because regularly it was too slow
            x.right + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"SideInset"]]?:0.0f)*-2
        );
    }
}

- (NSUInteger)iconsInRowForSpacingCalculation 
{
    if (_tcDockyInstalled || (![[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"])) return %orig;

    return [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultDockColumns"] ?: 4;
}

- (CGFloat)horizontalIconPadding 
{
    CGFloat x = %orig;

    if (_tcDockyInstalled || (![[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"]) || !_pfTweakEnabled || !self.configured) return %orig;

    BOOL buggedSpacing = ([[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultDockColumns"]?:4) == 4 && [[HPUtility deviceName] isEqualToString:@"iPhone X"];
    BOOL leftInsetZeroed = [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockLeftInset"]?:0.0f == 0.0f;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 12.0f)
    {
        if (buggedSpacing)
        {
            return -100.0f;
        }
        if (leftInsetZeroed) {
            return x;
        }
        else
        {
            return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockSideInset"]?:0.0f;
        }
    }
    else 
    {
        return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockSideInset"]?:0.0f;
    }
}

- (CGFloat)verticalIconPadding 
{
    CGFloat x = %orig;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"]) return %orig;
    if (!self.configured || _tcDockyInstalled || !_pfTweakEnabled) return x;

    return x + [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockVerticalSpacing"]?:0.0f;
}

- (CGFloat)sideIconInset
{   
    CGFloat x = %orig;

    if (_tcDockyInstalled || !([[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"])) return %orig;

    if (!self.configured || !_pfTweakEnabled)
    {
        return x;
    }

    BOOL buggedSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockColumns"]?:4 == 4 
                                        && [[HPUtility deviceName] isEqualToString:@"iPhone X"];
    BOOL leftInsetZeroed = [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockLeftInset"]?:0.0f == 0.0f;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 12.0f)
    {
        if (leftInsetZeroed || buggedSpacing) 
        {
            return x + [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockSideInset"]?:0.0f;
        }
        else
        {
            return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockLeftInset"]?:0.0f;
        }
    }
    else
    {
        return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockSideInset"]?:0.0f;
    }
}

- (CGFloat)topIconInset
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"] 
            || (_tcDockyInstalled)
            || !self.configured || !_pfTweakEnabled)
    {
        return %orig;
    } 

    CGFloat x = %orig;
    
    return x + [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockTopInset"] ?: 0.0f;
}

+ (NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1
{
    // Bad method name
    // This method returns rows
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"] 
            || _tcDockyInstalled || !_rtConfigured 
            || !_pfTweakEnabled) 
    {
        return %orig(arg1);
    }

    return [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultDockColumns"] ?: 4;
}

- (NSUInteger)iconsInColumnForSpacingCalculation
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"] 
        || _tcDockyInstalled || !_rtConfigured 
        || !_pfTweakEnabled) 
    {
        return %orig;
    }

    return [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultDockRows"]?:1;
}

%end


#pragma mark Icon Handling

%hook SBIconView 

// Icon Scale & Alpha

- (void)layoutSubviews 
{
    %orig;

    if (!_pfTweakEnabled) return;

    NSInteger loc = MSHookIvar<NSInteger>(self, "_iconLocation");
    NSString *x = @"";

    switch ( loc )
    {
        case 1: 
        {   
            x = @"Root";
            break;
        }
        case 3: 
        {
            x = @"Dock";
            break;
        }
        case 6: 
        {
            x = @"Folder";
            break;
        }
        default: 
        {
            x = @"Folder";
            break;
        }
    }

    CGFloat sx = ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Scale"]]?:60.0f) / 60.0f;
    [self.layer setSublayerTransform:CATransform3DMakeScale(sx, sx, 1)];

    [self setAlpha:self.alpha];
}

- (void)setAlpha:(CGFloat)alpha
{
    if (alpha != 1.0 || !_pfTweakEnabled)
    {
        %orig(alpha);
        return;
    }
    
    NSInteger loc = MSHookIvar<NSInteger>(self, "_iconLocation");
    NSString *x = @"";

    switch ( loc )
    {
        case 1: 
        {   
            x = @"Root";
            break;
        }
        case 3: 
        {
            x = @"Dock";
            break;
        }
        case 6: 
        {
            x = @"Folder";
            break;
        }
        default: 
        {
            x = @"Folder";
            break;
        }
    }
    %orig(([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"IconAlpha"]]?:100.0f) / 100.0f);
}

%end


%hook SBIconBadgeView

// Hide Icon Badges

- (void)setHidden:(BOOL)arg
{
    if (_pfTweakEnabled && [[NSUserDefaults standardUserDefaults] boolForKey:@"HPThemeDefaultIconBadges"])
    {
        %orig(YES);
    }
    else {
        %orig(arg);
    }
}

- (BOOL)isHidden 
{
    if (_pfTweakEnabled && [[NSUserDefaults standardUserDefaults] boolForKey:@"HPThemeDefaultIconBadges"])
    {
        return YES;
    }
    return %orig;
}

- (CGFloat)alpha
{    
    CGFloat a = (_pfTweakEnabled && [[NSUserDefaults standardUserDefaults] boolForKey:@"HPThemeDefaultIconBadges"]) ? 0.0 : %orig;

    return a;
}

- (void)setAlpha:(CGFloat)arg
{   
    %orig([[NSUserDefaults standardUserDefaults] boolForKey:@"HPThemeDefaultIconBadges"] ? 0.0 : arg);
}

%end


%hook SBIconLegibilityLabelView

// Hide Icon Labels

- (void)setHidden:(BOOL)arg1 
{
    BOOL hide = NO;

    if (((SBIconLabelImage *)self.image).parameters.iconLocation == 1) // this works, somehow. 
    {
        // home screen
        hide = [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultIconLabels"]?:0 == 1;
    } 
    else if (((SBIconLabelImage *)self.image).parameters.iconLocation == 6)
    {
        // folder
        hide = [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultIconLabelsF"]?:0 == 1;
    }

    // If we aren't hiding it but SB is, listen to springboard
    %orig((hide || arg1));
}

%end


#pragma mark End Icon Editing

%hook SBRootFolderController

// Disable Icon Wiggle when Editor is loaded

- (void)viewDidLoad
{
    %orig;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableWiggle:) name:kDisableWiggleTrigger object:nil];
}

%new 
- (void)disableWiggle:(NSNotification *)notification 
{
    // This works even devices without a done button
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) 
    {
        [self doneButtonTriggered:self.contentView.doneButton];
    }
}

%end


#pragma mark FloatyDock Handling

%hook SBMainScreenActiveInterfaceOrientationWindow

// Hide FloatyDock View when it is appropriate to do so

- (id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    id o = %orig(arg1, arg2, arg3, arg4, arg5);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kFadeFloatingDockNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kShowFloatingDockNotificationName object:nil];

    floatingDockWindow = self;

    return o;
}

- (id)initWithDebugName:(id)arg
{
    id o = %orig(arg);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kFadeFloatingDockNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kShowFloatingDockNotificationName object:nil];

    floatingDockWindow = self;
    
    return o;
}

%new 
- (void)fader:(NSNotification *)notification
{
    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.alpha = ([[notification name] isEqualToString:kFadeFloatingDockNotificationName]) ? 0 : 1;
        }
    ];
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);

    _rtEditingEnabled = enabled;

    self.userInteractionEnabled = !enabled;
}

%end


#pragma mark Dynamic Editor Background 

%hook FBRootWindow

// iOS 12 - Dynamic editor background based on wallpaper
// We use this to set the background image for the editor

- (id)initWithDisplay:(id)arg
{
    id o = %orig(arg);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:@"CreateBackgroundObject" object:nil];

    return o;
}

- (id)initWithDisplayConfiguration:(id)arg
{
    id o = %orig(arg);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:@"CreateBackgroundObject" object:nil];

    return o;
}

- (id)initWithScreen:(id)arg
{
    id o = %orig(arg);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:@"CreateBackgroundObject" object:nil];

    return o;
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    self.backgroundColor = [UIColor colorWithPatternImage:[EditorManager sharedManager].blurredAndDarkenedWallpaper];
}

%end


#pragma mark Gesture Handler

%hook FBSystemGestureView

//
// System Gesture View for <= iOS 12
// Create the drag down gesture bits here. 
//

%property (nonatomic, assign) BOOL hitboxViewExists;
%property (nonatomic, assign) BOOL editorOpened;
%property (nonatomic, assign) BOOL editorActivated;
%property (nonatomic, retain) HPHitboxView *hp_hitbox;
%property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;
%property (nonatomic, retain) HPHitboxView *hp_larger_hitbox;
%property (nonatomic, retain) HPHitboxWindow *hp_larger_window;
%property (nonatomic, assign) CGFloat hpPanAmount;
%property (nonatomic, assign) BOOL hitboxMaxed;

%new 
- (void)createTopLeftHitboxView
{
    self.editorOpened = NO;
    self.hitboxMaxed = NO;
    self.hp_hitbox_window = [[HPHitboxWindow alloc] initWithFrame:CGRectMake(0, 0,  ([HPUtility isCurrentDeviceNotched] ?120:80), ([HPUtility isCurrentDeviceNotched] ?40:20))];
    _rtHitboxWindow = self.hp_hitbox_window;
    self.hp_hitbox = [[UIView alloc] init];
    // This is useful for debugging hitbox locations on weird devices
    //self.hp_hitbox.backgroundColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.5];
    //self.hp_hitbox_window.backgroundColor = [UIColor.blueColor colorWithAlphaComponent:0.5];
    [self.hp_hitbox_window setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kFadeFloatingDockNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kShowFloatingDockNotificationName object:nil];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    _rtGestureRecognizer = pan;
    [self.hp_hitbox addGestureRecognizer:pan];

    CGFloat screenHeight = self.frame.size.height;
    CGFloat screenWidth = self.frame.size.width;

    self.hp_larger_window = [[HPHitboxWindow alloc] initWithFrame:CGRectMake( (0.15*screenWidth), (0.15*screenHeight), (0.7*screenWidth), (0.7*screenHeight))];
    self.hp_larger_hitbox = [[UIView alloc] init];
    self.hp_larger_hitbox.frame = CGRectMake(0,0, (0.7*screenWidth), (0.7*screenHeight));
    [self.hp_larger_window setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];
    [self.hp_larger_window addSubview:self.hp_larger_hitbox];
    [self addSubview:self.hp_larger_window];

    UIPanGestureRecognizer *pan2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [self.hp_larger_hitbox addGestureRecognizer:pan2];
    
    CGSize hitboxSize = CGSizeMake( ([HPUtility isCurrentDeviceNotched] ?120:80), ([HPUtility isCurrentDeviceNotched] ?40:20));
    self.hp_hitbox.frame = CGRectMake(0, 0, hitboxSize.width, hitboxSize.height);
    [self.hp_hitbox_window addSubview:self.hp_hitbox];
    [self addSubview:self.hp_hitbox_window];


    //self.hp_larger_hitbox.backgroundColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.5];
    //self.hp_larger_window.backgroundColor = [UIColor.redColor colorWithAlphaComponent:0.5];

    self.hp_hitbox_window.hidden = NO;
    self.hp_hitbox_window.userInteractionEnabled = YES;
    self.hp_larger_window.userInteractionEnabled = NO;
    self.hp_larger_window.hidden = YES;
}

%new 
-(void)recieveNotification:(NSNotification *)notification 
{
    wallpaperView.transform = CGAffineTransformMakeScale(1, 1);
    homeWindow.transform = CGAffineTransformMakeScale(1, 1);
    floatingDockWindow.transform = CGAffineTransformMakeScale(1, 1);
    homeWindow.layer.borderColor = [[UIColor clearColor] CGColor];
    homeWindow.layer.borderWidth = 0;
    homeWindow.layer.cornerRadius = 0;
    wallpaperView.layer.cornerRadius = 0;
    if (self.hitboxMaxed)
    {
        self.hitboxMaxed = NO;
        self.hp_hitbox_window.userInteractionEnabled = YES;
        self.hp_larger_window.userInteractionEnabled = NO;
        self.hp_larger_window.hidden = YES;
    }
    self.editorActivated = NO;
    self.editorOpened = NO;
}
%new 
-(void)fader:(NSNotification *)notification 
{
    if ([[notification name] isEqualToString:kFadeFloatingDockNotificationName])
    {
        self.hp_larger_window.hidden = YES;
        [self.hp_larger_window setValue:@YES forKey:@"deliversTouchesForGesturesToSuperview"];
    }
    else
    {
        self.hp_larger_window.hidden = NO;
        [self.hp_larger_window setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];
    }
}
%new 
-(void)move:(UIPanGestureRecognizer *)gestureRecognizer
{
    // Woo, Pan Recognizers.
    // I was basically SOL on getting any help coding this
    //      so I'll do my best to explain the math I ended up with :)

    
    // First off, I want the user to be able to drag down, and for their downward movement to match
    //          the scaling of the view
    // So since we're scaling the entire view to 70% of its original size, 
    //      that leaves 30%, or 15% on the top and bottom

    // So, get the exact pixel count that their finger needs to travel downward
    CGFloat maxAmt = [[UIScreen mainScreen] bounds].size.height * 0.15;

    // Call the method on the gesture recognizer to figure out how far they've traveled
    CGPoint translatedPoint = [gestureRecognizer translationInView:self.hp_hitbox];
    // Get the y value. This is what we care about
    CGFloat translation = translatedPoint.y;
    
    // Gah. So when a user drags up on the center view after the editor has been opened,
    //      `translation` will be negative; So, add maxAmt, so the math knows that we're starting
    //      at the maximum amount and working down from there
    if (self.editorOpened) translation = maxAmt + translation;

    // Copy the value to an instance variable. 
    // I think this is legacy behavior that can eventually be written out, but 
    //      it works just fine. 
    self.hpPanAmount = translation;

    // If it's over, max/min the value. 
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {

        if (self.hpPanAmount < 0) self.hpPanAmount = 0;
        if (self.hpPanAmount > maxAmt) self.hpPanAmount = maxAmt;
        if (!(self.hpPanAmount >= maxAmt * 0.4))
        {
            [[[EditorManager sharedManager] editorViewController] transitionViewsToActivationPercentage:0 withDuration:0.25];
            [UIView animateWithDuration:0.3
                animations:
                ^{  
                    wallpaperView.transform = CGAffineTransformMakeScale(1,1);
                    homeWindow.transform = CGAffineTransformMakeScale(1,1);
                    floatingDockWindow.transform = CGAffineTransformMakeScale(1,1);
                }
                completion:^(BOOL finished) 
                {
                    homeWindow.layer.borderColor = [[UIColor clearColor] CGColor];
                    homeWindow.layer.borderWidth = 0;
                    homeWindow.layer.cornerRadius = 0;
                    wallpaperView.layer.cornerRadius = 0;
                    if (self.editorActivated)
                    {
                        // If the editor was open, disable it and move the hitbox frame back 
                        // to the original spot
                        if (self.hitboxMaxed)
                        {
                            //self.hp_hitbox_window.frame = CGRectMake(0, 0, 60, 20);
                            //self.hp_hitbox.frame = CGRectMake(0, 0, 60, 20);
                            //self.hp_hitbox_window.transform = CGAffineTransformIdentity;
                        }

                        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
                        AudioServicesPlaySystemSound(1519);
                        self.editorActivated = NO;
                        self.editorOpened = NO;
                        self.hp_hitbox_window.userInteractionEnabled = YES;
                        self.hp_larger_window.userInteractionEnabled = NO;
                        self.hp_larger_window.hidden = YES;
                    }
                }
            ];

        }
        else 
        {
            [[[EditorManager sharedManager] editorViewController] transitionViewsToActivationPercentage:1 withDuration:0.25];
            [UIView animateWithDuration:0.3
                animations:
                ^{  
                    wallpaperView.transform = CGAffineTransformMakeScale(0.7,0.7);
                    homeWindow.transform = CGAffineTransformMakeScale(0.7,0.7);
                    floatingDockWindow.transform = CGAffineTransformMakeScale(0.7,0.7);
                    if ([[EditorManager sharedManager] tutorialActive])
                    {
                        [[EditorManager sharedManager] tutorialViewController].viewOne.alpha = 0;
                        [[EditorManager sharedManager] tutorialViewController].viewOne.center = CGPointMake([[EditorManager sharedManager] tutorialViewController].viewOne.center.x,261);
                    } 
                    
                }
                completion:^(BOOL finished) 
                {
                    if ([[EditorManager sharedManager] tutorialActive]) [[[EditorManager sharedManager] tutorialViewController] explainExit];
                    if ([[EditorManager sharedManager] tutorialActive]) [[EditorManager sharedManager] setTutorialActive:NO];
                    self.editorOpened = YES;
                    if (!self.hitboxMaxed)
                    {
                        self.hp_hitbox_window.userInteractionEnabled = NO;
                        self.hp_larger_window.userInteractionEnabled = YES;
                        self.hp_larger_window.hidden = NO;
                    }
                }
            ];
        }

        if (self.hpPanAmount == maxAmt) // if it has been capped, reset it to 0 as it has been disabled
        {
            self.hpPanAmount = 0;
        }
        return;
    }

    if (self.hpPanAmount < 0) self.hpPanAmount = 0; // bottom-cap the value


    // If they've moved beyond the initial point
    // enable the editor and do some math

    // We enable it at the start because we want to do the cool slide-in thing we 
    // call later

    if (self.hpPanAmount != 0)
    {
        if (!self.editorActivated)
        {
            // runs once. 
            [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeEnabledNotificationName object:nil];
            self.editorActivated = YES;
        }
        homeWindow.layer.borderColor = [[UIColor whiteColor] CGColor];
        homeWindow.layer.borderWidth = 1;
        homeWindow.layer.cornerRadius = [HPUtility isCurrentDeviceNotched] ? 35 : 0;
        wallpaperView.layer.cornerRadius = [HPUtility isCurrentDeviceNotched] ? 35 : 0;
    }
    else 
    {
        // If we're zeroed out, clear out the colors and stuff
        homeWindow.layer.borderColor = [[UIColor clearColor] CGColor];
        homeWindow.layer.borderWidth = 0;
        homeWindow.layer.cornerRadius = 0;
        wallpaperView.layer.cornerRadius = 0;
        /*
        if (self.editorOpened)
        {
            // If the editor was open, disable it and move the hitbox frame back 
            // to the original spot
            self.hp_hitbox_window.frame = CGRectMake(0, 0, 60, 20);
            self.hp_hitbox.frame = CGRectMake(0, 0, 60, 20);
            self.hp_hitbox_window.transform = CGAffineTransformIdentity;
            [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
            AudioServicesPlaySystemSound(1519);
            self.editorActivated = NO;
            self.editorOpened = NO;
        }*/
    }

    if (self.hpPanAmount >= maxAmt)
    {
        if (!self.hitboxMaxed)
        {
            self.hitboxMaxed = YES;
            self.hp_hitbox_window.userInteractionEnabled = NO;
            self.hp_larger_window.userInteractionEnabled = YES;
            self.hp_larger_window.hidden = NO;
        }
        if (self.editorOpened) 
        {
            // If the editor view is open, just cap it
            self.hpPanAmount = maxAmt; 
        }
        else 
        {
            self.hpPanAmount = maxAmt; // cap the value
            // If it hasn't been done yet, then create the new hitbox view that covers up the homescreen view
            self.editorOpened = YES;
            if ([[EditorManager sharedManager] tutorialActive]) [[[EditorManager sharedManager] tutorialViewController] explainExit];
            if ([[EditorManager sharedManager] tutorialActive]) [[EditorManager sharedManager] setTutorialActive:NO];
            AudioServicesPlaySystemSound(1519);
        }
    }

    // Fun thing: I wrote this method in the editorViewController to slide in all the views from the side. 
    // It uses math similar to what is below, but with translations instead of scale. 
    // Give it a float between 0 and 1 representing percentage of activation
    [[[EditorManager sharedManager] editorViewController] transitionViewsToActivationPercentage:self.hpPanAmount/maxAmt];

    // Math deconstructed:
    // 1 = originalScale
    // 0.3 = subtractionFromScale ; 0.7 is the scale we're going for, so originalScale - desiredScale = 0.3
    // (panAmount / maxAmt) = percentage of completion
    //
    // So, for example, lets say maxAmt is 240 and the user has dragged 120 pixels so far:
    // 1 - (0.3 * (120/240))
    // 1 - (0.3 * (1/2))
    // 1 - (0.15)
    // 0.85
    // which is halfway to completion, since the user has dragged halfway there

    // Now apply that awesome algebra to all the globals it needs applied to
    if ([[EditorManager sharedManager] tutorialActive])
    {
        [[EditorManager sharedManager] tutorialViewController].viewOne.alpha = 1-(self.hpPanAmount/maxAmt);
        [[EditorManager sharedManager] tutorialViewController].viewOne.center = CGPointMake([[EditorManager sharedManager] tutorialViewController].viewOne.center.x,61+self.hpPanAmount);
    }

    wallpaperView.transform = CGAffineTransformMakeScale(1-(0.3 * (self.hpPanAmount / maxAmt )), 1-(0.3 * (self.hpPanAmount / maxAmt )));
    homeWindow.transform = CGAffineTransformMakeScale(1-(0.3 * (self.hpPanAmount / maxAmt )), 1-(0.3 * (self.hpPanAmount / maxAmt )));
    floatingDockWindow.transform = CGAffineTransformMakeScale(1-(0.3 * (self.hpPanAmount / maxAmt )), 1-(0.3 * (self.hpPanAmount / maxAmt )));

    if (self.hpPanAmount == maxAmt) // if it has been capped, reset it to 0 as it has been disabled
    {
        self.hpPanAmount = 0;
    }
}

- (void)layoutSubviews
{
    %orig;

    if (!self.hp_hitbox_window && _pfTweakEnabled && !_pfGestureDisabled) 
    {
        [self createTopLeftHitboxView];
    }
}
%end

// End iOS 12 Grouping

%end


// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//
// IOS 13
// #pragma iOS 13
//
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


%group iOS13

#pragma mark Version Specific Interfaces

@interface SBIconListView (HomePlus)
- (NSUInteger)iconRowsForCurrentOrientation;
@end

@interface SBDockIconListView (HomePlusXIII)
- (CGFloat)effectiveSpacingForNumberOfIcons:(NSUInteger)num;
- (NSUInteger)iconsInRowForSpacingCalculation;
- (NSUInteger)iconColumnsForCurrentOrientation;
- (id)layout;
@end


#pragma mark Main Layout Handling

%hook SBIconListGridLayoutConfiguration 

//
// This is the grid layout config. 
// For now, we hook this to set L/T/V/H and part of page values
// All of the root pages share one of these. 
// Dock / Folders get their own. 
// Its not clearly identified which one owns this config, though
//

%property (nonatomic, assign) NSString *iconLocation;

%new 
- (NSString *)locationIfKnown
{
    if (self.iconLocation) return self.iconLocation;
    // Guess if it hasn't been set
    else 
    {
        NSUInteger rows = MSHookIvar<NSUInteger>(self, "_numberOfPortraitRows");
        NSUInteger columns = MSHookIvar<NSUInteger>(self, "_numberOfPortraitColumns"); 
        // dock
        if (rows <= 2 && columns == 4) // woo nested boolean logic 
        {
            self.iconLocation =  @"Dock";
        }
        else if (rows == 3 && columns == 3)
        {
            self.iconLocation =  @"Folder";
        }
        else 
        {
            self.iconLocation =  @"Root";
        }
    }
    return self.iconLocation;
}

- (NSUInteger)numberOfPortraitRows
{
    NSInteger x = %orig;

    if (!self.iconLocation) return x;

    if ([self.iconLocation isEqualToString:@"Dock"] && ([[NSUserDefaults standardUserDefaults] integerForKey:@"HPdockConfigEnabled"]?:1) == 0) return x;

    if (_tcDockyInstalled && (x<=2 || x==100))return %orig;

    if (!_rtConfigured && _pfTweakEnabled) return kMaxRowAmount;

    return _pfTweakEnabled ? [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"Rows"]]?:x : (NSUInteger)x;
}

- (NSUInteger)numberOfPortraitColumns
{
    NSInteger x = %orig; // Reminder: Any tweak that comes before HomePlus alphabetically will get to this func before we do 
                         //           What this means is that we're not getting the iOS value in some cases. We also get the values from other tweaks, 
                         //           And to ensure compatibility, we need to thoroughly check the value %orig gives us. 

    if ((_tcDockyInstalled && (x == 5 || x==100)) // If Docky is changing the values (I wrote docky's latest version, I know what its going to give)

                          || ([self numberOfPortraitRows] == 1 && x !=4) // or if another tweak is screwing with column values.
                                                                         // We only check here for dock values. I'm not making this compatible with HS layout tweaks, that's silly. 

                          || (!self.iconLocation) // If we dont know our icon location yet (give it the original value so we can figure out the location based on original values)
                                                  // We can assume at this point that its an iOS original value since we've checked it against 5 icon dock tweaks and such. 

                          || (!_pfTweakEnabled)) 
                        
    {
        return x;
    }

    if ([self.iconLocation isEqualToString:@"Dock"] && ([[NSUserDefaults standardUserDefaults] integerForKey:@"HPdockConfigEnabled"]?:1) == 0) return x;

    if (!_rtConfigured && _pfTweakEnabled) // Hack on iOS 13 to allow adding more columns and rows in real time.
                                           //   For some reason, we cant increase columns/rows in runtime (w/o respring), 
                                           //   but, we CAN decrease. SO, start with the max it'll allow,
                                           //   then everything else is decreasing from that max
    {
        return kMaxColumnAmount;
    }

    return [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"Columns"]]?:x;
}

- (UIEdgeInsets)portraitLayoutInsets
{
    UIEdgeInsets x = %orig;
    if (!_pfTweakEnabled)
    {
        return x;
    }
    if (!self.iconLocation)
    {
        NSUInteger rows = MSHookIvar<NSUInteger>(self, "_numberOfPortraitRows");
        NSUInteger columns = MSHookIvar<NSUInteger>(self, "_numberOfPortraitColumns"); 
        // dock
        if (rows <= 2 && columns == 4) // woo nested boolean logic 
        {
            self.iconLocation =  @"Dock";
        }
        else if (rows == 3 && columns == 3)
        {
            self.iconLocation =  @"Folder";
        }
        else 
        {
            self.iconLocation =  @"Root";
        }
    }

    if ([self.iconLocation isEqualToString:@"Folder"]) return x;

    if ([self.iconLocation isEqualToString:@"Dock"] && ([[NSUserDefaults standardUserDefaults] integerForKey:@"HPdockConfigEnabled"]?:1) == 0) return x;

    if ((!([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", self.iconLocation, @"LeftInset"]]?:0)) == 0)
    {
        return UIEdgeInsetsMake(
            x.top + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", self.iconLocation, @"TopInset"]]?:0),
            [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", self.iconLocation, @"LeftInset"]]?:0,
            x.bottom - ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", self.iconLocation, @"TopInset"]]?:0) + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"VerticalSpacing"]]?:0) *-2, // * 2 because regularly it was too slow
            x.right - ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", self.iconLocation, @"LeftInset"]]?:0) + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"SideInset"]]?:0) *-2
        );
    }
    else
    {
        return UIEdgeInsetsMake(
            x.top + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", self.iconLocation, @"TopInset"]]?:0) ,
            x.left + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", self.iconLocation, @"SideInset"]]?:0)*-2,
            x.bottom - ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", self.iconLocation, @"TopInset"]]?:0) + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"VerticalSpacing"]]?:0) *-2, // * 2 because regularly it was too slow
            x.right + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", self.iconLocation, @"SideInset"]]?:0)*-2
        );
    }
}

%end


%hook SBIconListView 

%property (nonatomic, assign) BOOL configured;

- (id)initWithModel:(id)arg1 orientation:(id)arg2 viewMap:(id)arg3 
{
    id o = %orig(arg1, arg2, arg3);

    return o;
}

- (void)layoutSubviews 
{
    %orig;

    if (!self.configured) 
    {
        [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(highlightView:) name:kHighlightViewNotificationName object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutIconsNow) name:@"HPlayoutIconViews" object:nil];
        self.configured = YES;
        _rtConfigured = YES;
    }
    
}

- (BOOL)automaticallyAdjustsLayoutMetricsToFit
{
    // Allows us to adjust dock
    return ((_pfTweakEnabled) ? NO : %orig);
}

%new
- (void)highlightView:(NSNotification *)notification 
{
    if ([[self iconLocation] isEqualToString:[[EditorManager sharedManager] editingLocation]])
    {
        self.layer.borderColor = [[UIColor colorWithRed:0.69 green:0.90 blue:0.80 alpha:1.0] CGColor];
        self.layer.borderWidth = 0;
    } 
    else
    {
        self.layer.borderColor = [[UIColor clearColor] CGColor];
        self.layer.borderWidth = 0;
    }
}

- (NSUInteger)iconRowsForCurrentOrientation
{
    if (_tcDockyInstalled && (%orig<=2 || %orig==100)) return %orig;
    NSString *x = [[self iconLocation] substringFromIndex:14];

    return [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Rows"]]?:%orig;
}

- (NSUInteger)iconColumnsForCurrentOrientation
{
    if (_tcDockyInstalled && ([self iconRowsForCurrentOrientation]<=2 || [self iconRowsForCurrentOrientation]==100))return %orig;
    NSString *x = [[self iconLocation] substringFromIndex:14];

    return [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Columns"]]?:%orig;
}

%end


%hook SBIconListFlowLayout

- (NSUInteger)numberOfRowsForOrientation:(NSInteger)arg1
{
    NSInteger x = %orig(arg1);
    
    if (_tcDockyInstalled && x <=1)return %orig;

    if (x==3)
    {
        return 3;
    }

    if (!_rtConfigured && _pfTweakEnabled) return kMaxRowAmount;

    return _pfTweakEnabled ? [[self layoutConfiguration] numberOfPortraitRows] : (NSUInteger)x;
}

- (NSUInteger)numberOfColumnsForOrientation:(NSInteger)arg1
{
    NSInteger x = %orig(arg1);

    if (x==3)
    {
        return 3;
    }

    if (!_rtConfigured && _pfTweakEnabled) return kMaxColumnAmount;

    return _pfTweakEnabled ? [[self layoutConfiguration] numberOfPortraitColumns] : (NSUInteger)x;
}

%end


#pragma mark Dock Handling

%hook SBDockIconListView 

- (UIEdgeInsets)layoutInsets
{
    if (_tcDockyInstalled)return %orig;
    UIEdgeInsets x = %orig;
    if (!_pfTweakEnabled) return x;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"]) return %orig;

    return [[[self layout] layoutConfiguration] portraitLayoutInsets];
}

- (BOOL)automaticallyAdjustsLayoutMetricsToFit
{
    return (!_pfTweakEnabled);
}
- (CGFloat)horizontalIconPadding
{
    if (_tcDockyInstalled) return %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"]) return %orig;
    if (_pfTweakEnabled) return [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"SideInset"]];

    return %orig;
}
- (NSUInteger)iconRowsForCurrentOrientation
{
    if (_tcDockyInstalled) return %orig;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"]) return %orig;

    SBIconListGridLayoutConfiguration *config = [[self layout] layoutConfiguration];
    return [config numberOfPortraitRows];
}
- (NSUInteger)iconColumnsForCurrentOrientation
{
    if (_tcDockyInstalled) return %orig;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HPdockConfigEnabled"]) return %orig;

    SBIconListGridLayoutConfiguration *config = [[self layout] layoutConfiguration];
    return [config numberOfPortraitColumns];
}
/*
-(CGPoint)originForIconAtCoordinate:(SBIconCoordinate)arg1 numberOfIcons:(NSUInteger)arg2 {
    if ([self iconRowsForCurrentOrientation] == 1 && [self iconColumnsForCurrentOrientation] == 4) return %orig;
/*
    CGSize size = CGSizeMake(60,60);
    iconSize = size;
    *
    return %orig;
    /*
    if (dockMode == 3) 
    {
        CGPoint orig = %orig;
        CGFloat x = infiniteSpacing;
        
        if (infinitePaging) {
            int max = (fiveIcons) ? 5 : 4;
            CGFloat offset = (dockScrollView.frame.size.width - max * (size.width + infiniteSpacing))/2;
            x = offset * (ceil((arg1.col - 1)/max)*2 + 1);
        }

        return CGPointMake(((size.width + infiniteSpacing) * (arg1.col - 1)) + x + infiniteSpacing/2, orig.y);
    }
    
    CGFloat top = [%c(SBRootFolderDockIconListView) defaultHeight] - size.height * 1.2;

    CGFloat x = (size.width + (fiveIcons ? 5 : 20)) * (arg1.col - 1) + (fiveIcons ? 25 : 35);
    CGFloat y = (size.height + [dockView dockHeightPadding]/2 + 15) * (arg1.row - 1) + top;
    
    if (ipx) {
        top = [%c(SBRootFolderDockIconListView) defaultHeight] - [dockView dockHeightPadding] - size.height * 1.2;
        y = (size.height + [dockView dockHeightPadding] + 2 + 15) * (arg1.row - 1) + top;
    }
    
    return CGPointMake(x, y);
    *
}*/
%end


#pragma mark Icon Handling

%hook SBIconView

- (void)layoutSubviews
{
    %orig;
    NSString *x = @"";
    if ([[self location] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
    else if ([[self location] isEqualToString:@"SBIconLocationDock"]) x = @"Dock";
    else x = @"Folder";

    CGFloat sx = ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Scale"]]?:60.0) / 60.0;
    [self.layer setSublayerTransform:CATransform3DMakeScale(sx, sx, 1)];
}

- (CGFloat)iconImageAlpha
{    
    NSString *x = @"";
    if ([[self location] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
    else if ([[self location] isEqualToString:@"SBIconLocationDock"]) x = @"Dock";
    else x = @"Folder";

    return (([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"IconAlpha"]]?:100.0f) / 100.0f);
}


%end 


%hook SBIconLegibilityLabelView

- (void)setHidden:(BOOL)arg
{
    @try
    {
        SBIconView *superv = (SBIconView *)self.superview;
        NSString *x = @"";

        if ([[superv location] isEqualToString:@"SBIconLocationRoot"]) x = @"";
        else if ([[superv location] isEqualToString:@"SBIconLocationFolder"]) x = @"F";

        if (_pfTweakEnabled && [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", @"HPThemeDefaultIconLabels", x]])
        {
            %orig(YES);
        }
        else {
            %orig(arg);
        }
    } 
    @catch (NSException *ex)
    {
        // Icon being dragged
        %orig(arg);
    }
}

- (BOOL)isHidden 
{
    @try 
    {
        SBIconView *superv = (SBIconView *)self.superview;
        NSString *x = @"";
        if ([[superv location] isEqualToString:@"SBIconLocationRoot"]) x = @"";
        else if ([[superv location] isEqualToString:@"SBIconLocationFolder"]) x = @"F";
        if (_pfTweakEnabled && [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", @"HPThemeDefaultIconLabels", x]])
        {
            return YES;
        }
        return %orig;
    } 
    @catch (NSException *ex)
    {
        // Icon being dragged
        return %orig;
    }
}

- (CGFloat)alpha
{
    @try 
    {
        SBIconView *superv = (SBIconView *)self.superview;
        NSString *x = @"";
        if ([[superv location] isEqualToString:@"SBIconLocationRoot"]) x = @"";
        else if ([[superv location] isEqualToString:@"SBIconLocationFolder"]) x = @"F";
        return (_pfTweakEnabled && [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", @"HPThemeDefaultIconLabels", x]]) ? 0.0 : %orig;
    } 
    @catch (NSException *ex)
    {
        // Icon Being Dragged
        return %orig;
    }
}

- (void)setAlpha:(CGFloat)arg
{
    @try 
    {
        SBIconView *superv = (SBIconView *)self.superview;
        NSString *x = @"";
        if ([[superv location] isEqualToString:@"SBIconLocationRoot"]) x = @"";
        else if ([[superv location] isEqualToString:@"SBIconLocationFolder"]) x = @"F";
        %orig((_pfTweakEnabled && [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", @"HPThemeDefaultIconLabels", x]]) ? 0.0 : arg);
    } 
    @catch (NSException *ex)
    {
        // Icon being dragged
        %orig(arg);
    }
}

%end


%hook SBIconBadgeView

- (void)setHidden:(BOOL)arg
{
    if (_pfTweakEnabled && [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultIconBadges"])
    {
        %orig(YES);
    }
    else {
        %orig(arg);
    }
}

- (BOOL)isHidden 
{
    if (_pfTweakEnabled && [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultIconBadges"])
    {
        return YES;
    }

    return %orig;
}

- (CGFloat)alpha
{
    return (([[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultIconBadges"]?:0) == 0) ? %orig : 0;
}

- (void)setAlpha:(CGFloat)arg
{
    %orig((([[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultIconBadges"]?:0) == 0) ? arg : 0);
}

%end


#pragma mark End Spotlight Search

%hook SBHomeScreenSpotlightViewController

- (id)initWithDelegate:(id)arg 
{
    id x = %orig(arg);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissSearchView) name:kEditingModeEnabledNotificationName object:nil];
    return x;
}

%end 


#pragma mark FloatyDock Handling

%hook SBFloatingDockWindow

// Scale floaty docks with the rest of the views
// For some (maybe dumb, maybe not) reason, they get their own oddly named window
// on iOS 13, the window is renamed, but it subclasses this one, so we're still good
//      (for now)
// This mostly mocks the handling of SBHomeScreenWindow, most documentation can be found there
- (id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    id o = %orig(arg1, arg2, arg3, arg4, arg5);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kFadeFloatingDockNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kShowFloatingDockNotificationName object:nil];

    floatingDockWindow = self;

    return o;
}

%new 
- (void)fader:(NSNotification *)notification
{
    // In the settings view and keyboard view, floatydock (annoyingly) sits above it. 
    // So we need to fade it at times using a notification. 
    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.alpha = ([[notification name] isEqualToString:kFadeFloatingDockNotificationName]) ? 0 : 1;
        }
    ];
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);

    _rtEditingEnabled = enabled;

    self.userInteractionEnabled = !enabled;
}

%end


#pragma mark Dynamic Window Background

%hook UIRootSceneWindow

//
// iOS 13 - Dynamic editor background
// We use this to set the background image for the editor
//

- (id)initWithDisplay:(id)arg
{
    id o = %orig(arg);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:@"CreateBackgroundObject" object:nil];

    return o;
}

- (id)initWithDisplayConfiguration:(id)arg
{
    id o = %orig(arg);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:@"CreateBackgroundObject" object:nil];

    return o;
}

- (id)initWithScreen:(id)arg
{
    id o = %orig(arg);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:@"CreateBackgroundObject" object:nil];

    return o;
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    self.backgroundColor = [UIColor colorWithPatternImage:[EditorManager sharedManager].blurredAndDarkenedWallpaper];
}

%end


#pragma mark Gesture Handler

%hook UISystemGestureView

// 
// iOS 13 view we inject our gesture recognizer into
// This *regularly* gets copy pasted over FBGestureView
// You will notice the same comments in both places
// That is why. 
//

%property (nonatomic, assign) BOOL hitboxViewExists;
%property (nonatomic, assign) BOOL editorOpened;
%property (nonatomic, assign) BOOL editorActivated;
%property (nonatomic, retain) HPHitboxView *hp_hitbox;
%property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;
%property (nonatomic, retain) HPHitboxView *hp_larger_hitbox;
%property (nonatomic, retain) HPHitboxWindow *hp_larger_window;
%property (nonatomic, assign) CGFloat hpPanAmount;
%property (nonatomic, assign) BOOL hitboxMaxed;

%new 
- (void)createTopLeftHitboxView
{
    NSLog(@"HomePlus: %@", NSStringFromCGRect(self.frame));

    self.editorOpened = NO;
    self.hitboxMaxed = NO;
    self.hp_hitbox_window = [[HPHitboxWindow alloc] initWithFrame:CGRectMake(0, 0, ([HPUtility isCurrentDeviceNotched] ?120:80), ([HPUtility isCurrentDeviceNotched] ?40:20))];
    _rtHitboxWindow = self.hp_hitbox_window;
    self.hp_hitbox = [[UIView alloc] init];
    // This is useful for debugging hitbox locations on weird devices
    //self.hp_hitbox.backgroundColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.5];
    //self.hp_hitbox_window.backgroundColor = [UIColor.blueColor colorWithAlphaComponent:0.5];
    [self.hp_hitbox_window setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kFadeFloatingDockNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kShowFloatingDockNotificationName object:nil];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    _rtGestureRecognizer = pan;
    [self.hp_hitbox addGestureRecognizer:pan];
    

    CGFloat screenHeight = self.frame.size.height;
    CGFloat screenWidth = self.frame.size.width;


    self.hp_larger_window = [[HPHitboxWindow alloc] initWithFrame:CGRectMake( (0.15*screenWidth), (0.15*screenHeight), (0.7*screenWidth), (0.7*screenHeight))];
    self.hp_larger_hitbox = [[UIView alloc] init];
    self.hp_larger_hitbox.frame = CGRectMake(0,0, (0.7*screenWidth), (0.7*screenHeight));
    [self.hp_larger_window setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];
    [self.hp_larger_window addSubview:self.hp_larger_hitbox];
    [self addSubview:self.hp_larger_window];

    UIPanGestureRecognizer *pan2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [self.hp_larger_hitbox addGestureRecognizer:pan2];
    
    CGSize hitboxSize = CGSizeMake( ([HPUtility isCurrentDeviceNotched] ?120:80), ([HPUtility isCurrentDeviceNotched] ?40:20));
    self.hp_hitbox.frame = CGRectMake(0, 0, hitboxSize.width, hitboxSize.height);
    [self.hp_hitbox_window addSubview:self.hp_hitbox];
    [self addSubview:self.hp_hitbox_window];


    //self.hp_larger_hitbox.backgroundColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.5];
    //self.hp_larger_window.backgroundColor = [UIColor.redColor colorWithAlphaComponent:0.5];

    self.hp_hitbox_window.hidden = NO;
    self.hp_hitbox_window.userInteractionEnabled = YES;
    self.hp_larger_window.userInteractionEnabled = NO;
    self.hp_larger_window.hidden = YES;
}

%new 
-(void)recieveNotification:(NSNotification *)notification 
{
    wallpaperView.transform = CGAffineTransformMakeScale(1, 1);
    homeWindow.transform = CGAffineTransformMakeScale(1, 1);
    floatingDockWindow.transform = CGAffineTransformMakeScale(1, 1);
    homeWindow.layer.borderColor = [[UIColor clearColor] CGColor];
    homeWindow.layer.borderWidth = 0;
    homeWindow.layer.cornerRadius = 0;
    wallpaperView.layer.cornerRadius = 0;
    if (self.hitboxMaxed)
    {
        self.hitboxMaxed = NO;
        self.hp_hitbox_window.userInteractionEnabled = YES;
        self.hp_larger_window.userInteractionEnabled = NO;
        self.hp_larger_window.hidden = YES;
    }
    self.editorActivated = NO;
    self.editorOpened = NO;
}
%new 
-(void)fader:(NSNotification *)notification 
{
    if ([[notification name] isEqualToString:kFadeFloatingDockNotificationName])
    {
        self.hp_larger_window.hidden = YES;
        [self.hp_larger_window setValue:@YES forKey:@"deliversTouchesForGesturesToSuperview"];
    }
    else
    {
        self.hp_larger_window.hidden = NO;
        [self.hp_larger_window setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];
    }
}
%new 
-(void)move:(UIPanGestureRecognizer *)gestureRecognizer
{
    // Woo, Pan Recognizers.
    // I was basically SOL on getting any help coding this
    //      so I'll do my best to explain the math I ended up with :)

    
    // First off, I want the user to be able to drag down, and for their downward movement to match
    //          the scaling of the view
    // So since we're scaling the entire view to 70% of its original size, 
    //      that leaves 30%, or 15% on the top and bottom

    // So, get the exact pixel count that their finger needs to travel downward
    CGFloat maxAmt = [[UIScreen mainScreen] bounds].size.height * 0.15;

    // Call the method on the gesture recognizer to figure out how far they've traveled
    CGPoint translatedPoint = [gestureRecognizer translationInView:self.hp_hitbox];
    // Get the y value. This is what we care about
    CGFloat translation = translatedPoint.y;
    
    // Gah. So when a user drags up on the center view after the editor has been opened,
    //      `translation` will be negative; So, add maxAmt, so the math knows that we're starting
    //      at the maximum amount and working down from there
    if (self.editorOpened) translation = maxAmt + translation;

    // Copy the value to an instance variable. 
    // I think this is legacy behavior that can eventually be written out, but 
    //      it works just fine. 
    self.hpPanAmount = translation;

    // If it's over, max/min the value. 
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {

        if (self.hpPanAmount < 0) self.hpPanAmount = 0;
        if (self.hpPanAmount > maxAmt) self.hpPanAmount = maxAmt;
        if (!(self.hpPanAmount >= maxAmt * 0.4))
        {
            [[[EditorManager sharedManager] editorViewController] transitionViewsToActivationPercentage:0 withDuration:0.25];
            [UIView animateWithDuration:0.3
                animations:
                ^{  
                    wallpaperView.transform = CGAffineTransformMakeScale(1,1);
                    homeWindow.transform = CGAffineTransformMakeScale(1,1);
                    floatingDockWindow.transform = CGAffineTransformMakeScale(1,1);
                }
                completion:^(BOOL finished) 
                {
                    homeWindow.layer.borderColor = [[UIColor clearColor] CGColor];
                    homeWindow.layer.borderWidth = 0;
                    homeWindow.layer.cornerRadius = 0;
                    wallpaperView.layer.cornerRadius = 0;
                    if (self.editorActivated)
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
                        AudioServicesPlaySystemSound(1519);
                        self.editorActivated = NO;
                        self.editorOpened = NO;
                        self.hp_hitbox_window.userInteractionEnabled = YES;
                        self.hp_larger_window.userInteractionEnabled = NO;
                        self.hp_larger_window.hidden = YES;
                    }
                }
            ];

        }
        else 
        {
            [[[EditorManager sharedManager] editorViewController] transitionViewsToActivationPercentage:1 withDuration:0.25];
            [UIView animateWithDuration:0.3
                animations:
                ^{  
                    wallpaperView.transform = CGAffineTransformMakeScale(0.7,0.7);
                    homeWindow.transform = CGAffineTransformMakeScale(0.7,0.7);
                    floatingDockWindow.transform = CGAffineTransformMakeScale(0.7,0.7);
                    if ([[EditorManager sharedManager] tutorialActive])
                    {
                        [[EditorManager sharedManager] tutorialViewController].viewOne.alpha = 0;
                        [[EditorManager sharedManager] tutorialViewController].viewOne.center = CGPointMake([[EditorManager sharedManager] tutorialViewController].viewOne.center.x,261);
                    } 
                    
                }
                completion:^(BOOL finished) 
                {
                    if ([[EditorManager sharedManager] tutorialActive]) [[[EditorManager sharedManager] tutorialViewController] explainExit];
                    if ([[EditorManager sharedManager] tutorialActive]) [[EditorManager sharedManager] setTutorialActive:NO];
                    self.editorOpened = YES;
                    if (!self.hitboxMaxed)
                    {
                        self.hp_hitbox_window.userInteractionEnabled = NO;
                        self.hp_larger_window.userInteractionEnabled = YES;
                        self.hp_larger_window.hidden = NO;
                    }
                }
            ];
        }

        if (self.hpPanAmount == maxAmt) // if it has been capped, reset it to 0 as it has been disabled
        {
            self.hpPanAmount = 0;
        }
        return;
    }

    if (self.hpPanAmount < 0) self.hpPanAmount = 0; // bottom-cap the value


    // If they've moved beyond the initial point
    // enable the editor and do some math

    // We enable it at the start because we want to do the cool slide-in thing we 
    // call later

    if (self.hpPanAmount != 0)
    {
        if (!self.editorActivated)
        {
            // runs once. 
            [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeEnabledNotificationName object:nil];
            self.editorActivated = YES;
        }
        homeWindow.layer.borderColor = [[UIColor whiteColor] CGColor];
        homeWindow.layer.borderWidth = 1;
        homeWindow.layer.cornerRadius = [HPUtility isCurrentDeviceNotched] ? 35 : 0;
        wallpaperView.layer.cornerRadius = [HPUtility isCurrentDeviceNotched] ? 35 : 0;
    }
    else 
    {
        // If we're zeroed out, clear out the colors and stuff
        homeWindow.layer.borderColor = [[UIColor clearColor] CGColor];
        homeWindow.layer.borderWidth = 0;
        homeWindow.layer.cornerRadius = 0;
        wallpaperView.layer.cornerRadius = 0;
    }

    if (self.hpPanAmount >= maxAmt)
    {
        if (!self.hitboxMaxed)
        {
            self.hitboxMaxed = YES;
            self.hp_hitbox_window.userInteractionEnabled = NO;
            self.hp_larger_window.userInteractionEnabled = YES;
            self.hp_larger_window.hidden = NO;
        }
        if (self.editorOpened) 
        {
            // If the editor view is open, just cap it
            self.hpPanAmount = maxAmt; 
        }
        else 
        {
            self.hpPanAmount = maxAmt; // cap the value
            // If it hasn't been done yet, then create the new hitbox view that covers up the homescreen view
            self.editorOpened = YES;
            if ([[EditorManager sharedManager] tutorialActive]) [[[EditorManager sharedManager] tutorialViewController] explainExit];
            if ([[EditorManager sharedManager] tutorialActive]) [[EditorManager sharedManager] setTutorialActive:NO];
            AudioServicesPlaySystemSound(1519);
        }
    }

    // Fun thing: I wrote this method in the editorViewController to slide in all the views from the side. 
    // It uses math similar to what is below, but with translations instead of scale. 
    // Give it a float between 0 and 1 representing percentage of activation
    [[[EditorManager sharedManager] editorViewController] transitionViewsToActivationPercentage:self.hpPanAmount/maxAmt];

    // Math deconstructed:
    // 1 = originalScale
    // 0.3 = subtractionFromScale ; 0.7 is the scale we're going for, so originalScale - desiredScale = 0.3
    // (panAmount / maxAmt) = percentage of completion
    //
    // So, for example, lets say maxAmt is 240 and the user has dragged 120 pixels so far:
    // 1 - (0.3 * (120/240))
    // 1 - (0.3 * (1/2))
    // 1 - (0.15)
    // 0.85
    // which is halfway to completion, since the user has dragged halfway there

    // Now apply that awesome algebra to all the globals it needs applied to
    if ([[EditorManager sharedManager] tutorialActive])
    {
        [[EditorManager sharedManager] tutorialViewController].viewOne.alpha = 1-(self.hpPanAmount/maxAmt);
        [[EditorManager sharedManager] tutorialViewController].viewOne.center = CGPointMake([[EditorManager sharedManager] tutorialViewController].viewOne.center.x,61+self.hpPanAmount);
    }

    wallpaperView.transform = CGAffineTransformMakeScale(1-(0.3 * (self.hpPanAmount / maxAmt )), 1-(0.3 * (self.hpPanAmount / maxAmt )));
    homeWindow.transform = CGAffineTransformMakeScale(1-(0.3 * (self.hpPanAmount / maxAmt )), 1-(0.3 * (self.hpPanAmount / maxAmt )));
    floatingDockWindow.transform = CGAffineTransformMakeScale(1-(0.3 * (self.hpPanAmount / maxAmt )), 1-(0.3 * (self.hpPanAmount / maxAmt )));

    if (self.hpPanAmount == maxAmt) // if it has been capped, reset it to 0 as it has been disabled
    {
        self.hpPanAmount = 0;
    }
}

- (void)layoutSubviews
{
    %orig;
    if (!self.hp_hitbox_window && _pfTweakEnabled && !_pfGestureDisabled) 
    {
        [self createTopLeftHitboxView];
    }
}

%end


// END iOS 13 Group

%end


// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//
//
// Preferences
// Please never add CephiePrefs
// #pragma Preferences
//
//
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


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
    _pfGestureDisabled = boolValueForKey(@"gesturedisabled", NO);

    if (kCFCoreFoundationVersionNumber < 1600) {
        _pfActivationGesture = 1;
    }
    else 
    {
        _pfActivationGesture = 1;
    }
    if (!_rtIconSupportInjected && boolValueForKey(@"iconsupport", NO))
    {
        @try {
            _rtIconSupportInjected = YES;
            dlopen("/Library/MobileSubstrate/DynamicLibraries/IconSupport.dylib", RTLD_NOW);
            [[objc_getClass("ISIconSupport") sharedInstance] addExtension:@"HomePlus"];
        }
        @catch (NSException *exception)
        {
            /*
            UIAlertController *alertController = [UIAlertController
                alertControllerWithTitle:@"!"
                message:@"IconSupport Not installed."
                preferredStyle:UIAlertControllerStyleAlert
            ];

            [self presentViewController:alertController animated:YES completion:NULL];
            */
        }
    }
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

    // Check if x tweak is installed.
    // This wont work if people pirate the tweak in question
    // *evil laugh*

    _tcDockyInstalled = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/me.nepeta.docky.list"];

    %init(Universal);

    if (kCFCoreFoundationVersionNumber < 1600) 
    {
        %init(iOS12);
    } 
    else 
    {
        %init(iOS13);
    }
}