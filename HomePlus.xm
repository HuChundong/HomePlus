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
// GLOBALS

#pragma mark Imports

#include <UIKit/UIKit.h>
#include "EditorManager.h"
#include "HPManager.h"
#include "HPUtility.h"
#include "HomePlus.h"
#import <AudioToolbox/AudioToolbox.h>
#import <IconSupport/ISIconSupport.h>

#pragma mark Global Values

// Preference globals
static BOOL _pfTweakEnabled = YES;
// static BOOL _pfBatterySaver = NO; // Planned LPM Reduced Animation State
static BOOL _pfGestureDisabled = YES;
static NSInteger _pfActivationGesture = 1;
static CGFloat _pfEditingScale = 0.7;

// Values we use everywhere during runtime. 
// These should be *avoided* wherever possible
// We can likely interface managers to handle these without too much overhead
static BOOL _rtEditingEnabled = NO;
static BOOL _rtConfigured = NO;
static BOOL _rtKickedUp = NO;
static BOOL _rtInjected = NO;
static BOOL _rtIconSupportInjected = NO;

// Tweak compatability stuff. 
// See the %ctor at the bottom of the file for more info
static BOOL _tcDockyInstalled = NO;

// Global for the preference dict. Not used outside of reloadPrefs() but its cool to have
NSDictionary *prefs = nil;

# pragma mark Implementations
// Implementations for custom classes injected
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

@interface SBHomeScreenWindow (HomePlus)
- (void)configureDefaultsIfNotYetConfigured;
@end

%hook SBHomeScreenWindow

// Contains the "App List" and all that fun stuff.

%property (nonatomic, retain) HPHitboxView *hp_hitbox;
%property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;

- (id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    id o = %orig(arg1, arg2, arg3, arg4, arg5);

    if (!_pfTweakEnabled)
    {
        // This if statement should go in every class of this tweak. 
        return o;
    } 

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

    [UIView animateWithDuration:.3 // this matches it as closely as possible with the kicker in the editorviewcontroller
                                   // Maybe in the future I can find a way to animate them both at the same time. 
                                   // As for right now, I'm not quite sure :p
    animations:
    ^{
        // Why all this complex math? Why not CGAffineTransformIdentity?
        // We're shrinking the view 30% while all of this happens
        // So instead of using Identity, we basically verify its doing the right thing several times
        // This helps prevent bad notification calls, or pretty much anything else weird that might happen
        //      from making the view go off screen completely, requiring a respring 

        self.transform = (([[notification name] isEqualToString:kEditorKickViewsUp])                        // If we should move the view up
                        && !_rtKickedUp)                                                                   //   And it isn't kicked up already (first verifiction)
                                    ? CGAffineTransformTranslate(transform, 0, (transform.ty == 0           //      If 0, move it up            (second verification)
                                                    ? 0- ([[UIScreen mainScreen] bounds].size.height * 0.7) //      move up
                                                    : 0.0))                                                 //      if its not 0, make it 0     (second v.)
                                    : CGAffineTransformTranslate(transform, 0, (transform.ty == 0           // If we should move it back 
                                                    ? 0                                                     //   If it's 0, keep it as 0
                                                    : ([[UIScreen mainScreen] bounds].size.height * 0.7))); //     else, move it back. 
    }]; 
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);

    // Set a corner radius value for notched devices to make the shrinking effect feel much more realistic
    CGFloat cR = [HPUtility isCurrentDeviceNotched] ? 35 : 0;
    
    if (enabled) 
    {
        // Add our decorations
        // If we're enabling, we want to add these before the shrinking starts
        self.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.layer.borderWidth = 1;
        self.layer.cornerRadius = cR;
    }
    else
    {
        // Disable the editor view
        [[EditorManager sharedManager] toggleEditorView];
    }

    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.transform = (enabled 
                            ? CGAffineTransformMakeScale(_pfEditingScale, _pfEditingScale) 
                            : CGAffineTransformIdentity);
        } 
        completion:^(BOOL finished)
        {
            // Once we're done shrinking the view, toggle the editor
            if (enabled) 
            {
                // Enable the editor view
                [[EditorManager sharedManager] toggleEditorView];
            } 
            else 
            {   // If we're not enabling, remove the decorations after the view has been set to normal size
                // Remove all the decorations now that we're back to normal. 
                self.layer.borderColor = [[UIColor clearColor] CGColor];
                self.layer.borderWidth = 0;
                self.layer.cornerRadius = 0;
            }
        }
    ];
}

%new 
- (void)createManagers
{
    // Managers are created after the HomeScreen view is initialized
    // This makes sure the EditorView is *directly* above the HS view
    //      so, we can float things and obscure the view if needed.
    // It also lets the user use CC/NC/any of that fun stuff while editing

    if (!_pfTweakEnabled) 
    {
        return;
    }
    BOOL notched = [HPUtility isCurrentDeviceNotched];
    HPEditorWindow *view = [[EditorManager sharedManager] editorView];
    [[[UIApplication sharedApplication] keyWindow] addSubview:view];

    HPManager *manager = [HPManager sharedManager];
    //[self configureDefaultsIfNotYetConfigured];
    
}

%new 
- (void)configureDefaultsIfNotYetConfigured
{
    // yes, i typed this by hand
    // yes, my hands are sore    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *location = @"Root";
    NSString *name = @"Default";
    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", name];
    [userDefaults setBool:NO
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"] ];
    [userDefaults setBool:NO
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"] ];
    [userDefaults setBool:NO
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"] ];
    [userDefaults setBool:NO
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"DockBG"] ];
    [userDefaults setBool:NO
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"ModernDock"] ];

    prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", location, name];
    [userDefaults setInteger:4
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"] ];
    [userDefaults setInteger:6// get default for phone
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"] ];
    [userDefaults setFloat:60.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rotation"] ];

    location = @"Dock";
    prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", location, name];
    [userDefaults setInteger:4.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"] ];
    [userDefaults setInteger:1.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"] ];
    [userDefaults setFloat:60.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rotation"] ];
    
    
    location = @"Folder";
    prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", location, name];
    [userDefaults setInteger:3 // THIS NEEDS TO BE SET BECAUSE FOLDERS ARE ACTUALLY MODIFIED BY THE TWEAK
                               // FOLDERS WILL CRASH SB IF MODIFIED TILL I ACTUALLY WRITE A PROPER IMPLEMENTATION
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"] ];
    [userDefaults setInteger:3
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"] ];
    [userDefaults setFloat:60.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"] ];
    [userDefaults setFloat:0.0
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rotation"] ];

}

%end

#pragma mark 
#pragma mark -- _SBWallpaperWindow

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
        self.transform = (up && !_rtKickedUp) 
                        ? CGAffineTransformTranslate(transform, 0, (transform.ty == 0 
                                                ? 0 - ([[UIScreen mainScreen] bounds].size.height * 0.7) 
                                                : 0.0)) 
                        : CGAffineTransformTranslate(transform, 0, (transform.ty == 0 
                                                ? 0 
                                                : ([[UIScreen mainScreen] bounds].size.height * 0.7)));
    }]; 
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    _rtEditingEnabled = enabled;
    BOOL notched = [HPUtility isCurrentDeviceNotched];
    CGFloat cR = notched ? 40 : 0;

    if (enabled) 
    {
        self.layer.cornerRadius = enabled ? cR : 0;
    }

    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.transform = (enabled 
                            ? CGAffineTransformMakeScale(_pfEditingScale, _pfEditingScale) 
                            : CGAffineTransformIdentity);
        }
        completion:^(BOOL finished)
        {
            self.layer.cornerRadius = enabled ? cR : 0;
        }
    ];
}
%end

@interface SBFStaticWallpaperImageView : UIImageView 
@end
%hook SBFStaticWallpaperImageView

// Whenever a wallpaper image is created for the homescreen, pass it to the manager
// We then use this FB/UIRootWindow in the tweak to give the awesome blurred bg UI feel
- (void)setImage:(UIImage *)img 
{
    %orig(img);
    [[EditorManager sharedManager] setWallpaper:img];
}

%end

#pragma mark 
#pragma mark -- Floaty Dock Thing

%hook SBMainScreenActiveInterfaceOrientationWindow

// Scale floaty docks with the rest of the views
// For some (maybe dumb, maybe not) reason, they get their own oddly named window
// on iOS 13, the window is renamed, but it subclasses this one, so we're still good
//      (for now)
// This mostly mocks the handling of SBHomeScreenWindow, most documentation can be found there
- (id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5
{
    id o = %orig(arg1, arg2, arg3, arg4, arg5);

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kFadeFloatingDockNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fader:) name:kShowFloatingDockNotificationName object:nil];

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
        completion:^(BOOL finished) 
        {
        }
    ];
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

    self.userInteractionEnabled = !enabled;

    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.transform = (enabled ? CGAffineTransformMakeScale(_pfEditingScale, _pfEditingScale) : CGAffineTransformIdentity);
        } 
        completion:^(BOOL finished) 
        {
        }
    ];

}

%end


@interface FBRootWindow : UIView 
@end

%hook FBRootWindow

// iOS 12 - Dynamic editor background based on wallpaper
// We use this to set the background image for the editor

- (id)initWithDisplay:(id)arg
{
    id o = %orig(arg);
    // Any of these might get called,
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    return o;
}

- (id)initWithDisplayConfiguration:(id)arg
{
    id o = %orig(arg);
    // so,
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    return o;
}

- (id)initWithScreen:(id)arg
{
    id o = %orig(arg);
    // make sure we get all of them :)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    return o;
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    // Whenever editing is enabled or disabled,
    // Show/hide the background image accordingly 
    // This prevents unexpected behavior. 
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    _rtEditingEnabled = enabled;
    
    if (enabled)
    {
        self.backgroundColor = [UIColor colorWithPatternImage:[[EditorManager sharedManager] bdBackgroundImage]];
    }
    else 
    {
        // We need to run some commands with a delay
        // I am incredibly lazy someone please fix this
        // Set alpha to 99%
        self.alpha = 0.99;
        [UIView animateWithDuration:.4
            animations:
            ^{
                self.alpha = 1; // Spend .4 seconds doing nothing of value
            } 
            completion:^(BOOL finished) 
            {
                // Remove the background image when the editor view is closed
                // Prevents unexpected behavior
                self.backgroundColor = [UIColor blackColor];
                self.transform = CGAffineTransformIdentity;
            }
        ];
    }
}

%end

@interface SBDockView : UIView

@property (nonatomic, retain) UIView *backgroundView;

@end

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
    // Reminder that, if you're building this for simulator,
    //      hooking ivars requires importing the substrate headers
	UIView *bgView = MSHookIvar<UIView *>(self, "_backgroundView"); 
    // "gross why are you using ints like booleans"
    //      userDefault implementation of bools is ugly as fuck and a pain to check for validity
    //      I personally prefer this. You should handle bools properly when working with a team.
    bgView.alpha = [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultHideDock"]?:0 == 1 ? 0 : 1;
    bgView.hidden =  [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultHideDock"]?:0 == 1 ? YES : NO;
}
%end

%hook SBCoverSheetWindow

// This is the lock screen // drag down thing
// Pulling it down will disable the editor view

- (BOOL)becomeFirstResponder 
{
    %orig;
    if (_pfTweakEnabled && [(SpringBoard*)[UIApplication sharedApplication] isShowingHomescreen] && _rtEditingEnabled) 
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
        _rtEditingEnabled = NO;
    }
}

%end

%hook SBMainSwitcherWindow

// Whenever the user swipes up to enable the switcher, close the editor view. 
// It's optional, since it makes half of the shit impossible to use
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

%hook UITraitCollection
- (CGFloat)displayCornerRadius 
{
    // This is why I love my ternary 
	return (![HPUtility isCurrentDeviceNotched]                                                                 // Dont do this on notched devices, no need
                    && [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultModernDock"]?:0 == 1   // If we're supposed to force modern dock
                                                                    ? 6                                         // Setting this to a non-0 value forced modern dock
                                                                    : %orig );                                  // else just orig it. 
}
%end

//
//
// iOS 12 AND BEFORE
// #pragma iOS 12
//
//

%group iOS12


%hook SBRootFolderView

// Root folder view
// Mainly just need to interact with a few things here for quality-of-life features

- (id)initWithFolder:(id)arg1 orientation:(NSInteger)arg2 viewMap:(id)arg3 context:(id)arg4 {
	if ((self = %orig(arg1, arg2, arg3, arg4))) {

	}
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissSpotlightIfVisible) name:kEditingModeEnabledNotificationName object:nil];
	return self;
}

%end


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

- (void)layoutSubviews 
{
    %orig;

    if (!self.configured) 
    {
        [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];
        self.configured = YES;
        _rtConfigured = YES;
    }
    if (!_rtInjected)
    {
        _rtInjected = YES;
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
    [self setIconsLabelAlpha:1.0];
}

- (CGFloat)horizontalIconPadding {
	CGFloat x = %orig;

    if (!_pfTweakEnabled || !self.configured || [[HPManager sharedManager] resettingIconLayout]) 
    {
        return x;
    }

    BOOL buggedSpacing = ((([[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootColumns"]?:4) == 4) && ([[HPUtility deviceName] isEqualToString:@"iPhone X"])); // Afaik, the "Boxy" bug only happens on iOS 12 iPX w/ 4 columns
                                                                                  // We dont need to check version because we're in a group block
                                                                                  //    that only executes on iOS 12 and below
                         

    BOOL leftInsetZeroed = ([[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootLeftInset"]?:0.0) == 0.0; // Enable more intuitive behavior 
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 12.0)
    {
        // This gets confusing and is the result of a lot of experimentation
        if (buggedSpacing)
        {
            return -100.0; // When the boxy bug happens, its triggered by this value being more than 0
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
            return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootSideInset"]?:0.0;
        }
    }
    else 
    {
        // on iOS 11, do things Boxy style. I need to do further testing to see if iOS 11 supports the cool
        //      calculations we used on iOS 12
        return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootSideInset"]?:0.0;
    }
}

- (CGFloat)verticalIconPadding 
{
    CGFloat x = %orig;
    if (!self.configured || !_pfTweakEnabled) return x;
    // simple, doesn't need explaining. 
    return x+[[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootVerticalSpacing"]?:0.0;
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
                         

    BOOL leftInsetZeroed = ([[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootLeftInset"]?:0.0) == 0.0; // Enable more intuitive behavior 

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 12.0)
    {
        if (leftInsetZeroed || buggedSpacing) 
        {
            return x + [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootSideInset"]?:0;  // Here's the fix I found for the iPX 4col bug
                                                                                                            // Essentially, we can create the "HSpacing"/Side Inset
                                                                                                            //      by returning it here (along w/ hIP returning -100)
        }
        else
        {
            return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootLeftInset"]?:0;      // Otherwise, return the Left Inset for here, on normal devices
        }
    }
    else
    {
        return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootLeftInset"]?:0; // Just return Left Inset on iOS 12
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
    return x + [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultRootTopInset"]?:0;
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

	return [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootRows"]?:x;
}

%end


%hook SBIconLegibilityLabelView

// Icon labels

- (void)setHidden:(BOOL)arg1 
{
    BOOL hide = NO;
    if (((SBIconLabelImage *)self.image).parameters.iconLocation == 1) // this works, somehow. 
    {
        // home screen
        hide = [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootLabels"]?:0 == 1;
    } 
    else if (((SBIconLabelImage *)self.image).parameters.iconLocation == 6)
    {
        // folder
        hide = [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootLabelsFolders"]?:0 == 1;
    }
    hide = (hide || arg1);

	%orig(hide);
}

%end

@interface SBDockIconListView : SBRootIconListView
@end

%hook SBDockIconListView

// Hook our dock icon list view
// For documentation on hooked methos see SbRootIconListView (ios 12)

%property (nonatomic, assign) BOOL configured;
- (void)layoutSubviews 
{
    %orig;

    if (_tcDockyInstalled) return; // This line goes everywhere here
                                   // If Docky is detected, dont change a thing. 
    if (!self.configured) 
    {
        [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];
        self.configured = YES;
    }
}

+ (NSUInteger)maxIcons {
    if (_tcDockyInstalled) return %orig;
    return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockColumns"]?:4;
}


- (NSUInteger)iconsInRowForSpacingCalculation {
    if (_tcDockyInstalled) return %orig;
    return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockColumns"]?:4;
}
- (CGFloat)horizontalIconPadding {

	CGFloat x = %orig;
    if (_tcDockyInstalled) return %orig;
    if (!_pfTweakEnabled || !self.configured) 
    {
        return x;
    }

    BOOL buggedSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockColumns"]?:4 == 4 && [[HPUtility deviceName] isEqualToString:@"iPhone X"];
    BOOL leftInsetZeroed = [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockLeftInset"]?:0 == 0.0;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 12.0)
    {
        if (buggedSpacing)
        {
            return -100.0;
        }
        if (leftInsetZeroed) {
            return x;
        }
        else
        {
            return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockSideInset"]?:0;
        }
    }
    else 
    {
        return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockSideInset"]?:0;
    }
}

- (CGFloat)verticalIconPadding 
{
    CGFloat x = %orig;
    if (!self.configured || _tcDockyInstalled || !_pfTweakEnabled) return x;

    return x + [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockVerticalSpacing"]?:0;
}

- (CGFloat)sideIconInset
{   
    CGFloat x = %orig;
    if (_tcDockyInstalled) return %orig;
    if (!self.configured || !_pfTweakEnabled)
    {
        return x;
    }
    BOOL buggedSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockColumns"]?:4 == 4 
                                        && [[HPUtility deviceName] isEqualToString:@"iPhone X"];
    BOOL leftInsetZeroed = [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockLeftInset"]?:0 == 0.0;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 12.0)
    {
        if (leftInsetZeroed || buggedSpacing) 
        {
            return x + [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockSideInset"]?:0;
        }
        else
        {
            return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockLeftInset"]?:0;
        }
    }
    else
    {
        return [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockSideInset"]?:0;
    }
}
- (CGFloat)topIconInset
{
    CGFloat x = %orig;
    if (_tcDockyInstalled) return %orig;

    if (!self.configured || !_pfTweakEnabled)
    {
        return x;
    }
    
    return x + [[NSUserDefaults standardUserDefaults] floatForKey:@"HPThemeDefaultDockTopInset"]?:0;
}

+ (NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1
{
	NSInteger x = %orig(arg1);
    if (_tcDockyInstalled) return %orig;

    if (!_rtConfigured || !_pfTweakEnabled)
    {
        return x;
    }

	return [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultDockColumns"]?:4;
}

- (NSUInteger)iconsInColumnForSpacingCalculation
{
	NSInteger x = %orig;

    if (_tcDockyInstalled) return %orig;
    if (!_rtConfigured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }

	return [[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultDockRows"]?:1;
}
%end

%hook SBIconView 

- (void)layoutSubviews 
{
	%orig;
    if (!_pfTweakEnabled) return;
    NSInteger loc = MSHookIvar<NSInteger>(self, "_iconLocation");
    NSString *x = @"";
    switch ( loc )
    {
        case 1: x = @"Root";
        case 3: x = @"Dock";
        case 6: x = @"Folder";
        default: x = @"Root";
    }
    CGFloat sx = ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Scale"]]?:60) / 60.0;
    [self.layer setSublayerTransform:CATransform3DMakeScale(sx, sx, 1)];
}

%end

%hook SBIconBadgeView

- (void)setHidden:(BOOL)arg
{    
    NSString *x = @"Icon";
    if (_pfTweakEnabled && [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Badges"]] )
    {
        %orig(YES);
    }
    else {
        %orig(arg);
    }
}
- (BOOL)isHidden 
{    
    NSString *x = @"Icon";
    if (_pfTweakEnabled && [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Badges"]])
    {
        return YES;
    }
    return %orig;
}
- (CGFloat)alpha
{    
    NSString *x = @"Icon";
    CGFloat a = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Badges"]] ? 0.0 : %orig;
    return a;
}
- (void)setAlpha:(CGFloat)arg
{   
    NSString *x = @"Icon";

    %orig([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Badges"]] ? 0.0 : arg);
}
%end

%hook FBSystemGestureView

//
// System Gesture View for <= iOS 12
// Create the drag down gesture bits here. 
//

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
    if (_pfActivationGesture != 1 || _pfGestureDisabled) 
    {
        return;
    }
    BOOL enabled = !_rtEditingEnabled;

    if (enabled)
    {
        AudioServicesPlaySystemSound(1520);
        [[NSNotificationCenter defaultCenter] postNotificationName:kDisableWiggleTrigger object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeEnabledNotificationName object:nil];
    }
    else 
    {
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

    if (!self.hp_hitbox_window && _pfTweakEnabled && !_pfGestureDisabled) 
    {
        [self createTopLeftHitboxView];
        [self createFullScreenDragUpView];
    }
}

%end

// End iOS 12 Grouping

%end

//
//
// IOS 13
//
//
//

#pragma mark iOS 13
%group iOS13

// IOS 13


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
	    NSUInteger rows = [self numberOfPortraitRows];
	    NSUInteger columns = [self numberOfPortraitColumns];
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
    if (_tcDockyInstalled && (x<=2 || x==100))return %orig;
    if (!_rtConfigured && _pfTweakEnabled) return kMaxRowAmount;

	return _pfTweakEnabled ? [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"Rows"]]?:x : (NSUInteger)x;
}

- (NSUInteger)numberOfPortraitColumns
{
	NSInteger x = %orig; // Reminder: Any tweak that comes before HomePlus alphabetically will get to this func before we do 
                         //           What this means is that we're not getting the iOS value in some cases. We also get the values from other tweaks, 
                         //           And to ensure compatibility, we need to thoroughly check the value %orig gives us. 

    if (_tcDockyInstalled && (x == 5 || x==100) // If Docky is changing the values (I wrote docky's latest version, I know what its going to give)

                          || ([self numberOfPortraitRows] == 1 && x !=4) // or if another tweak is screwing with column values.
                                                                         // We only check here for dock values. I'm not making this compatible with HS layout tweaks, that's silly. 

                          || (!self.iconLocation) // If we dont know our icon location yet (give it the original value so we can figure out the location based on original values)
                                                  // We can assume at this point that its an iOS original value since we've checked it against 5 icon dock tweaks and such. 

                          || (!_pfTweakEnabled)) 
                        
    {
        return x;
    }

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
        NSUInteger rows = [self numberOfPortraitRows];
	    NSUInteger columns = [self numberOfPortraitColumns];
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
        return [self portraitLayoutInsets];
    }

    if (!([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"LeftInset"]]?:0) == 0)
    {
        return UIEdgeInsetsMake(
            x.top + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"TopInset"]]?:0),
            [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"LeftInset"]]?:0,
            x.bottom - ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"TopInset"]]?:0) + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"VerticalSpacing"]]?:0) *-2, // * 2 because regularly it was too slow
            x.right - ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"LeftInset"]]?:0) + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"SideInset"]]?:0) *-2
        );
    }
    else
    {
        return UIEdgeInsetsMake(
            x.top + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"TopInset"]]?:0) ,
            x.left + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"SideInset"]]?:0)*-2,
            x.bottom - ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"TopInset"]]?:0) + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"VerticalSpacing"]]?:0) *-2, // * 2 because regularly it was too slow
            x.right + ([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", [self locationIfKnown], @"SideInset"]]?:0)*-2
        );
    }
}

%end


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

%end 


%hook SBIconLegibilityLabelView


- (void)setHidden:(BOOL)arg
{
    if (_pfTweakEnabled && NO)
    {
        %orig(YES);
    }
    else {
        %orig(arg);
    }
}
- (BOOL)isHidden 
{
    if (_pfTweakEnabled && NO)
    {
        return YES;
    }
    return %orig;
}
- (CGFloat)alpha
{
    CGFloat a =  NO ? 0.0 : %orig;
    return a;
}
- (void)setAlpha:(CGFloat)arg
{
    %orig(arg);
}

%end

%hook SBIconBadgeView

- (void)setHidden:(BOOL)arg
{
    if (_pfTweakEnabled && NO)
    {
        %orig(YES);
    }
    else {
        %orig(arg);
    }
}
- (BOOL)isHidden 
{
    if (_pfTweakEnabled && NO)
    {
        return YES;
    }
    return %orig;
}
- (CGFloat)alpha
{
    CGFloat a = %orig;
    return a;
}
- (void)setAlpha:(CGFloat)arg
{
    %orig(arg);
}
%end

%hook SBHomeScreenSpotlightViewController

- (id)initWithDelegate:(id)arg 
{
    id x = %orig(arg);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissSearchView) name:kEditingModeEnabledNotificationName object:nil];
    return x;
}

%end 


@interface UIRootSceneWindow : UIView 
@end

%hook UIRootSceneWindow

//
// iOS 13 - Dynamic editor background
// We use this to set the background image for the editor
//

- (id)initWithDisplay:(id)arg
{
    id o = %orig(arg);

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    return o;
}

- (id)initWithDisplayConfiguration:(id)arg
{
    id o = %orig(arg);

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    return o;
}

- (id)initWithScreen:(id)arg
{
    id o = %orig(arg);

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];

    return o;
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    _rtEditingEnabled = enabled;
    
    if (enabled)
    {
        self.backgroundColor = [UIColor colorWithPatternImage:[[EditorManager sharedManager] bdBackgroundImage]];
    }
    else 
    {
        self.alpha = 0.99;
        [UIView animateWithDuration:.4
            animations:
            ^{
                self.alpha = 1; // give animation something to do
            } 
            completion:^(BOOL finished) 
            {
            self.backgroundColor = [UIColor blackColor];
            self.transform = CGAffineTransformIdentity;
            }
        ];
    }

}

%end

@interface UISystemGestureView (HomePlus)
- (void)_addGestureRecognizer:(id)arg atEnd:(BOOL)arg2;
@end

%hook UISystemGestureView

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
    if (_pfActivationGesture != 1 || _pfGestureDisabled) 
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
        [[EditorManager sharedManager] setEditingLocation:@"SBIconLocationRoot"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kHighlightViewNotificationName object:nil];

    }
    else 
    {
        AudioServicesPlaySystemSound(1520);
        AudioServicesPlaySystemSound(1520);
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
        [[EditorManager sharedManager] setEditingLocation:@"SBIconLocationNone"]; // this can be anything that isn't a real one
        [[NSNotificationCenter defaultCenter] postNotificationName:kHighlightViewNotificationName object:nil];
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
    UISwipeGestureRecognizer *swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(BX_toggleEditingMode)];
    [swipeUpGesture setDirection:UISwipeGestureRecognizerDirectionUp];

    [self _addGestureRecognizer: swipeUpGesture atEnd:YES];

}

- (void)layoutSubviews
{
    %orig;

    if (!self.hp_hitbox_window && _pfTweakEnabled && !_pfGestureDisabled) 
    {
        [self createTopLeftHitboxView];
        [self createFullScreenDragUpView];
    }
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

@interface SBIconListView (HomePlus)
- (NSUInteger)iconRowsForCurrentOrientation;
@end

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
        self.configured = YES;
        _rtConfigured = YES;
    }
    
}

- (BOOL)automaticallyAdjustsLayoutMetricsToFit
{
    return (!_pfTweakEnabled);
}

%new 
- (BOOL)isDock
{
    NSLog(@"HPC: %@", [self iconLocation]);
    return ([[self iconLocation] isEqualToString:@"SBIconLocationDock"]);
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

- (void)layoutIconsNow 
{
    %orig;
    if (!_pfTweakEnabled)
    {
        return;
    }
}

- (NSUInteger)iconRowsForCurrentOrientation
{
    NSUInteger x = %orig;
    if (_tcDockyInstalled && (x<=2 || x==100)) return %orig;
    return [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Root", @"Rows"]] ;
}

- (NSUInteger)iconColumnsForCurrentOrientation
{
    if (_tcDockyInstalled && ([self iconRowsForCurrentOrientation]<=2 || [self iconRowsForCurrentOrientation]==100))return %orig;
    return [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Root", @"Columns"]] ;
}

%end

@interface SBDockIconListView (HomePlusXIII)
- (CGFloat)effectiveSpacingForNumberOfIcons:(NSUInteger)num;
- (NSUInteger)iconsInRowForSpacingCalculation;
- (NSUInteger)iconColumnsForCurrentOrientation;
- (id)layout;
@end

%hook SBDockIconListView 
/*
- (UIEdgeInsets)layoutInsets
{
    if (_tcDockyInstalled)return %orig;
    UIEdgeInsets x = %orig;
    if (!_pfTweakEnabled) return x;
    return [[[HPManager sharedManager] config] currentLoadoutInsetsForLocation:@"SBIconLocationDock" pageIndex:0 withOriginal:x];
}
*/
- (BOOL)automaticallyAdjustsLayoutMetricsToFit
{
    return (!_pfTweakEnabled);
}
- (CGFloat)horizontalIconPadding
{
    if (_tcDockyInstalled) return %orig;

    if (_pfTweakEnabled) return [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", @"Dock", @"SideInset"]];
    return %orig;
}
- (NSUInteger)iconRowsForCurrentOrientation
{
    if (_tcDockyInstalled) return %orig;

    SBIconListGridLayoutConfiguration *config = [[self layout] layoutConfiguration];
    return [config numberOfPortraitRows];
}
- (NSUInteger)iconColumnsForCurrentOrientation
{
    if (_tcDockyInstalled) return %orig;
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

// END iOS 13 Group

%end

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

    %init;

	if (kCFCoreFoundationVersionNumber < 1600) 
    {
        %init(iOS12);
	} 
    else 
    {
		%init(iOS13);
	}
}