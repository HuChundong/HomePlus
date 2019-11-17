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
// GLOBALS

#pragma mark Imports

#include <UIKit/UIKit.h>
#include "EditorManager.h"
#include "HPManager.h"
#include "HomePlus.h"
#import <AudioToolbox/AudioToolbox.h>
#import <IconSupport/ISIconSupport.h>

#pragma mark Global Values
// Preference globals
static BOOL _pfTweakEnabled = YES;
// TODO: Low Power Mode no animation mode
// static BOOL _pfBatterySaver = NO;
static BOOL _pfGestureDisabled = NO;
static NSInteger _pfActivationGesture = 1;
static CGFloat _pfEditingScale = 0.7;

// Values we use everywhere during runtime. 
static BOOL _rtEditingEnabled = NO;
static BOOL _rtConfigured = NO;
static BOOL _rtKickedUp = NO;
static BOOL _rtnotched = NO;
static BOOL _rtInjected = NO;
static BOOL _rtIconSupportInjected = NO;

static UIImage *_rtBackgroundImage;

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
        self.transform = (up && !_rtKickedUp) ? CGAffineTransformTranslate(transform, 0, (transform.ty == 0 ? 0- ([[UIScreen mainScreen] bounds].size.height * 0.7) : 0.0)) : CGAffineTransformTranslate(transform, 0, (transform.ty == 0 ? 0 : ([[UIScreen mainScreen] bounds].size.height * 0.7)));
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
            {
                notched = YES;
                break;
            }
            case 2688:
            {
                notched = YES;
                break;
            }
            case 1792:
            {
                notched = YES;
                break;
            }
            default:
            {
                notched = NO;
                break;
            }
        }
    }   
    CGFloat cR = notched ? 40 : 0;
    
    if (enabled) 
    {
        self.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.layer.borderWidth = 1;
        self.layer.cornerRadius = cR;
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
                self.layer.borderColor = [[UIColor whiteColor] CGColor];
                self.layer.borderWidth = 1;
                self.layer.cornerRadius = cR;
            } else 
            {
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
        self.transform = (up && !_rtKickedUp) ? CGAffineTransformTranslate(transform, 0, (transform.ty == 0 ? 0- ([[UIScreen mainScreen] bounds].size.height * 0.7) : 0.0)) : CGAffineTransformTranslate(transform, 0, (transform.ty == 0 ? 0 : ([[UIScreen mainScreen] bounds].size.height * 0.7)));
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
@interface SBFStaticWallpaperImageView : UIImageView 
@end
%hook SBFStaticWallpaperImageView
- (void)setImage:(UIImage *)img 
{
    %orig(img);
    _rtBackgroundImage = img;
}

%end

#pragma mark 
#pragma mark -- Floaty Dock Thing

%hook SBMainScreenActiveInterfaceOrientationWindow

/* 
 * Floaty Dock scaling.
 * Note: In iOS 13, this was replaced w/ SBFloatingDockWindow (i think), *although*
 *          said class is a subclass of this class now, so this hook will still work perfectly. 
*/
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


#pragma mark 
#pragma mark -- Floaty Dock Thing
@interface FBRootWindow : UIView 
- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage;
@end
%hook FBRootWindow

/* 
 * iOS 12
 * TODO: Finish this stuff up
*/
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
- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage {

    //  Create our blurred image
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];


    CIFilter* blackGenerator = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    CIColor* black = [CIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:.5];
    [blackGenerator setValue:black forKey:@"inputColor"];
    CIImage* blackImage = [blackGenerator valueForKey:@"outputImage"];

    //Second, apply that black
    CIFilter *compositeFilter = [CIFilter filterWithName:@"CIMultiplyBlendMode"];
    [compositeFilter setValue:blackImage forKey:@"inputImage"];
    [compositeFilter setValue:inputImage forKey:@"inputBackgroundImage"];
    CIImage *darkenedImage = [compositeFilter outputImage];

    //Third, blur the image
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setDefaults];
    [blurFilter setValue:@(15.0) forKey:@"inputRadius"];
    [blurFilter setValue:darkenedImage forKey:kCIInputImageKey];
    CIImage *blurredImage = [blurFilter outputImage];

    CGImageRef cgimg = [context createCGImage:blurredImage fromRect:inputImage.extent];
    UIImage *blurredAndDarkenedImage = [UIImage imageWithCGImage:cgimg];
    CGImageRelease(cgimg);

    return blurredAndDarkenedImage;
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    _rtEditingEnabled = enabled;
    
    if (enabled)
    {
        self.backgroundColor = [UIColor colorWithPatternImage:[self blurredImageWithImage:_rtBackgroundImage]];
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
        }];
    }

}

%end

#pragma mark 
#pragma mark -- Floaty Dock Thing
@interface UIRootSceneWindow : UIView 
- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage;
@end

%hook UIRootSceneWindow

/* 
 * iOS 13
 * TODO: Finish this stuff up
*/
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
- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage {

    //  Create our blurred image
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];


    CIFilter* blackGenerator = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    CIColor* black = [CIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:.5];
    [blackGenerator setValue:black forKey:@"inputColor"];
    CIImage* blackImage = [blackGenerator valueForKey:@"outputImage"];

    //Second, apply that black
    CIFilter *compositeFilter = [CIFilter filterWithName:@"CIMultiplyBlendMode"];
    [compositeFilter setValue:blackImage forKey:@"inputImage"];
    [compositeFilter setValue:inputImage forKey:@"inputBackgroundImage"];
    CIImage *darkenedImage = [compositeFilter outputImage];

    //Third, blur the image
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setDefaults];
    [blurFilter setValue:@(15.0) forKey:@"inputRadius"];
    [blurFilter setValue:darkenedImage forKey:kCIInputImageKey];
    CIImage *blurredImage = [blurFilter outputImage];

    CGImageRef cgimg = [context createCGImage:blurredImage fromRect:inputImage.extent];
    UIImage *blurredAndDarkenedImage = [UIImage imageWithCGImage:cgimg];
    CGImageRelease(cgimg);

    return blurredAndDarkenedImage;
}

%new
- (void)recieveNotification:(NSNotification *)notification
{
    BOOL enabled = ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]);
    _rtEditingEnabled = enabled;
    
    if (enabled)
    {
        self.backgroundColor = [UIColor colorWithPatternImage:[self blurredImageWithImage:_rtBackgroundImage]];
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

@interface SBDockView : UIView
@property (nonatomic, retain) UIView *backgroundView;
@end
%hook SBDockView
-(id)initWithDockListView:(id)arg1 forSnapshot:(BOOL)arg2 
{
    id x = %orig;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutSubviews) name:@"HPLayoutDockView" object:nil];
    return x;
}
-(void)layoutSubviews
{
    %orig;
	UIView *bgView = MSHookIvar<UIView *>(self, "_backgroundView"); 
    bgView.alpha = [[HPManager sharedManager] currentLoadoutShouldHideDockBG] ? 0 : 1;
    bgView.hidden =  [[HPManager sharedManager] currentLoadoutShouldHideDockBG] ;
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

%hook SBMainSwitcherWindow
- (void)setHidden:(BOOL)arg
{
    %orig(arg);

    if (_rtEditingEnabled && [[HPManager sharedManager] switcherDisables]) 
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeDisabledNotificationName object:nil];
    }
}

%end

static void *observer = NULL;


%hook SBIconModel
- (id)initWithStore:(id)arg applicationDataSource:(id)arg2
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

//
//
// IOS 12
// #pragma mark iOS 12
//
//

// IOS 11/12
%group iOS12

%hook UITraitCollection
- (CGFloat)displayCornerRadius {
	return (!_rtnotched && [[HPManager sharedManager] currentLoadoutModernDock]) ? 6 : %orig;
}
%end

%hook SBRootFolderView


- (id)initWithFolder:(id)arg1 orientation:(NSInteger)arg2 viewMap:(id)arg3 context:(id)arg4 {
	if ((self = %orig(arg1, arg2, arg3, arg4))) {

	}
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissSpotlightIfVisible) name:kEditingModeEnabledNotificationName object:nil];
	return self;
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

- (void)layoutSubviews 
{
    %orig;

    if (!self.configured) 
    {
        [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
        self.configured = YES;
        _rtConfigured = YES;
    }
    if (!_rtInjected)
    {
        _rtInjected = YES;
        [self layoutIconsNow];
    }
    
}
%new 
-(NSString *)newIconLocation
{ // mimic cleaner iOS 13 format
    if ([self iconLocation] == 1)
    {
        // home screen
        return @"SBIconLocationRoot";
    } 
    else if ([self iconLocation] == 3) 
    {
        // folder
        return @"SBIconLocationDock";
    }
    else if ([self iconLocation] == 6) 
    {
        // folder
        return @"SBIconLocationFolder";
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

- (void)layoutIconsNow 
{
    %orig;

    if (!_pfTweakEnabled)
    {
        return;
    }
    
    double labelAlpha = [[HPManager sharedManager] currentLoadoutShouldHideIconLabelsForLocation:@"SBIconLocationRoot"] ? 0.0 : 1.0;
    [self setIconsLabelAlpha:labelAlpha];
}

- (CGFloat)horizontalIconPadding {
	CGFloat x = %orig;

    if (!_pfTweakEnabled || !self.configured || [[HPManager sharedManager] resettingIconLayout]) 
    {
        return x;
    }

    BOOL buggedSpacing = [[HPManager sharedManager] currentLoadoutColumnsForLocation:[self newIconLocation] pageIndex:0] == 4 && _rtnotched;
    BOOL leftInsetZeroed = [[HPManager sharedManager] currentLoadoutLeftInsetForLocation:[self newIconLocation] pageIndex:0] == 0.0;
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
            return [[HPManager sharedManager] currentLoadoutHorizontalSpacingForLocation:[self newIconLocation] pageIndex:0];
        }
    }
    else 
    {
        /*
         * For some odd reason, this behaviour gets reversed on iOS 11. 
         * 
        */

        return [[HPManager sharedManager] currentLoadoutHorizontalSpacingForLocation:[self newIconLocation] pageIndex:0];
    }
}

- (CGFloat)verticalIconPadding 
{
    CGFloat x = %orig;
    if (!self.configured || [[HPManager sharedManager] resettingIconLayout]) return x;

    [[NSUserDefaults standardUserDefaults] setFloat:x
                                                forKey:@"defaultVSpacing"];

    return _pfTweakEnabled ? x+[[HPManager sharedManager] currentLoadoutVerticalSpacingForLocation:[self newIconLocation] pageIndex:0] : x;
}

- (CGFloat)sideIconInset
{   
    CGFloat x = %orig;
    if (!self.configured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }
    // I need to do a write-up on all of this sometime.
    // at ToW, this is confusing and hard to explain. 
    BOOL buggedSpacing = [[HPManager sharedManager] currentLoadoutColumnsForLocation:[self newIconLocation] pageIndex:0] == 4 && _rtnotched;
    BOOL leftInsetZeroed = [[HPManager sharedManager] currentLoadoutLeftInsetForLocation:[self newIconLocation] pageIndex:0] == 0.0;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 12.0)
    {
        if (leftInsetZeroed || buggedSpacing) 
        {
            return x + [[HPManager sharedManager] currentLoadoutHorizontalSpacingForLocation:[self newIconLocation] pageIndex:0];
        }
        else
        {
            return [[HPManager sharedManager] currentLoadoutLeftInsetForLocation:[self newIconLocation] pageIndex:0];
        }
    }
    else
    {
        return [[HPManager sharedManager] currentLoadoutLeftInsetForLocation:[self newIconLocation] pageIndex:0];
    }
}

- (CGFloat)topIconInset
{
    CGFloat x = %orig;

    if (!self.configured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }
    
    return x + [[HPManager sharedManager] currentLoadoutTopInsetForLocation:[self newIconLocation] pageIndex:0];
}

+ (NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1
{
	NSInteger x = %orig(arg1);

    if (!_rtConfigured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }

	return [[HPManager sharedManager] currentLoadoutColumnsForLocation:@"SBIconLocationRoot" pageIndex:0];
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

	return [[HPManager sharedManager] currentLoadoutRowsForLocation:@"SBIconLocationRoot" pageIndex:0];
}

%new 
- (NSUInteger)iconRowsForHomePlusCalculations
{
    return [[self class] iconRowsForInterfaceOrientation:69];
}

- (NSUInteger)iconRowsForSpacingCalculation
{
	NSInteger x = %orig;

    if (!self.configured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }

	return [[HPManager sharedManager] currentLoadoutRowsForLocation:[self newIconLocation] pageIndex:0];
}

%end


%hook SBIconLegibilityLabelView

- (void)setHidden:(BOOL)arg1 
{
    BOOL hide = NO;
    if (((SBIconLabelImage *)self.image).parameters.iconLocation  == 1)
    {
        // home screen
        hide = [[HPManager sharedManager] currentLoadoutShouldHideIconLabelsForLocation:@"SBIconLocationRoot"];
    } 
    else if (((SBIconLabelImage *)self.image).parameters.iconLocation == 6) 
    {
        // folder
        hide = [[HPManager sharedManager] currentLoadoutShouldHideIconLabelsForLocation:@"SBIconLocationFolder"];
    }
    hide = (hide || arg1);

	%orig(hide);
}

%end
/*
%hook UITraitCollection
- (CGFloat)displayCornerRadius {
	// Hack to get modern dock on all devices
	return !_rtnotched ? 6 : %orig;
}
%end
*/
@interface SBDockIconListView : SBRootIconListView
@end
%hook SBDockIconListView

%property (nonatomic, assign) BOOL configured;
- (void)layoutSubviews 
{
    %orig;

    if (!self.configured) 
    {
        [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];
        self.configured = YES;
    }
}

+ (NSUInteger)maxIcons {
    return [[HPManager sharedManager] currentLoadoutColumnsForLocation:@"SBIconLocationDock" pageIndex:0];
}


-(NSUInteger)iconsInRowForSpacingCalculation {
    return [[HPManager sharedManager] currentLoadoutColumnsForLocation:@"SBIconLocationDock" pageIndex:0];
}
- (CGFloat)horizontalIconPadding {
	CGFloat x = %orig;

    if (!_pfTweakEnabled || !self.configured || [[HPManager sharedManager] resettingIconLayout]) 
    {
        return x;
    }

    BOOL buggedSpacing = [[HPManager sharedManager] currentLoadoutColumnsForLocation:@"SBIconLocationDock" pageIndex:0] == 4 && _rtnotched;
    BOOL leftInsetZeroed = [[HPManager sharedManager] currentLoadoutLeftInsetForLocation:@"SBIconLocationDock" pageIndex:0] == 0.0;
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
            return [[HPManager sharedManager] currentLoadoutHorizontalSpacingForLocation:@"SBIconLocationDock" pageIndex:0];
        }
    }
    else 
    {
        /*
         * For some odd reason, this behaviour gets reversed on iOS 11. 
         * 
        */

        return [[HPManager sharedManager] currentLoadoutHorizontalSpacingForLocation:@"SBIconLocationDock" pageIndex:0];
    }
}

- (CGFloat)verticalIconPadding 
{
    CGFloat x = %orig;
    if (!self.configured || [[HPManager sharedManager] resettingIconLayout]) return x;

    [[NSUserDefaults standardUserDefaults] setFloat:x
                                                forKey:@"defaultVSpacing"];

    return _pfTweakEnabled ? x+[[HPManager sharedManager] currentLoadoutVerticalSpacingForLocation:@"SBIconLocationDock" pageIndex:0] : x;
}

- (CGFloat)sideIconInset
{   
    CGFloat x = %orig;
    if (!self.configured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }
    // I need to do a write-up on all of this sometime.
    // at ToW, this is confusing and hard to explain. 
    BOOL buggedSpacing = [[HPManager sharedManager] currentLoadoutColumnsForLocation:@"SBIconLocationDock" pageIndex:0] == 4 && _rtnotched;
    BOOL leftInsetZeroed = [[HPManager sharedManager] currentLoadoutLeftInsetForLocation:@"SBIconLocationDock" pageIndex:0] == 0.0;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 12.0)
    {
        if (leftInsetZeroed || buggedSpacing) 
        {
            return x + [[HPManager sharedManager] currentLoadoutHorizontalSpacingForLocation:@"SBIconLocationDock" pageIndex:0];
        }
        else
        {
            return [[HPManager sharedManager] currentLoadoutLeftInsetForLocation:@"SBIconLocationDock" pageIndex:0];
        }
    }
    else
    {
        return [[HPManager sharedManager] currentLoadoutLeftInsetForLocation:@"SBIconLocationDock" pageIndex:0];
    }
}
- (CGFloat)topIconInset
{
    CGFloat x = %orig;

    if (!self.configured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }
    
    return x + [[HPManager sharedManager] currentLoadoutTopInsetForLocation:@"SBIconLocationDock" pageIndex:0];
}

+ (NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1
{
	NSInteger x = %orig(arg1);

    if (!_rtConfigured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }

	return [[HPManager sharedManager] currentLoadoutColumnsForLocation:@"SBIconLocationDock" pageIndex:0];
}

-(NSUInteger)iconsInColumnForSpacingCalculation
{
	NSInteger x = %orig;

    if (!_rtConfigured || !_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }

	return [[HPManager sharedManager] currentLoadoutColumnsForLocation:@"SBIconLocationDock" pageIndex:0];
}
%end

%hook SBIconView 
%new
-(NSString *)newIconLocation
{
	NSInteger loc = MSHookIvar<NSInteger>(self, "_iconLocation"); // hurr durr lets change the type of a variable but keep the name the same -apple
    if (loc == 1)
    {
        // home screen
        return @"SBIconLocationRoot";
    } 
    else if (loc == 3) 
    {
        // folder
        return @"SBIconLocationDock";
    }
    else if (loc == 6) 
    {
        // folder
        return @"SBIconLocationFolder";
    }
}
- (void)layoutSubviews 
{
	%orig;
    CGFloat sx = ([[HPManager sharedManager] currentLoadoutScaleForLocation:@"SBIconLocationRoot" pageIndex:0]) / 60.0;
    [self.layer setSublayerTransform:CATransform3DMakeScale(sx, sx, 1)];
}

%end

%hook SBIconBadgeView

-(void)setHidden:(BOOL)arg
{
    if (_pfTweakEnabled && [[HPManager sharedManager] currentLoadoutShouldHideIconBadgesForLocation:@"SBIconLocationRoot"])
    {
        %orig(YES);
    }
    else {
        %orig(arg);
    }
}
-(BOOL)isHidden 
{
    if (_pfTweakEnabled && [[HPManager sharedManager] currentLoadoutShouldHideIconBadgesForLocation:@"SBIconLocationRoot"])
    {
        return YES;
    }
    return %orig;
}
-(CGFloat)alpha
{
    CGFloat a = [[HPManager sharedManager] currentLoadoutShouldHideIconBadgesForLocation:@"SBIconLocationRoot"] ? 0.0 : %orig;
    return a;
}
-(void)setAlpha:(CGFloat)arg
{
    %orig([[HPManager sharedManager] currentLoadoutShouldHideIconBadgesForLocation:@"SBIconLocationRoot"] ? 0.0 : arg);
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

// End iOS 12 Grouping

%end

//
//
// IOS 13
//
//
//

%group iOS13


// IOS 13
%hook SBIconView
-(void)layoutSubviews
{
    %orig;
    CGFloat sx = ([[HPManager sharedManager] currentLoadoutScaleForLocation:[self location] pageIndex:0]) / 60.0;
    [self.layer setSublayerTransform:CATransform3DMakeScale(sx, sx, 1)];
}
-(BOOL)isLabelHidden
{
    BOOL x = %orig;
    BOOL hideThis = NO;
    hideThis = [[HPManager sharedManager] currentLoadoutShouldHideIconLabelsForLocation:[self location]];
    return (_pfTweakEnabled) ? hideThis : x;
} 


-(BOOL)isLabelAccessoryHidden
{
    BOOL x = %orig;
    BOOL hideThis = NO;
    hideThis = [[HPManager sharedManager] currentLoadoutShouldHideIconLabelsForLocation:[self location]];
    return (_pfTweakEnabled) ? hideThis : x;
}



%end 


%hook SBIconLegibilityLabelView


-(void)setHidden:(BOOL)arg
{
    if (_pfTweakEnabled && [[HPManager sharedManager] currentLoadoutShouldHideIconLabelsForLocation:[[self iconView] location]])
    {
        %orig(YES);
    }
    else {
        %orig(arg);
    }
}
-(BOOL)isHidden 
{
    if (_pfTweakEnabled && [[HPManager sharedManager] currentLoadoutShouldHideIconLabelsForLocation:[[self iconView] location]])
    {
        return YES;
    }
    return %orig;
}
-(CGFloat)alpha
{
    CGFloat a = [[HPManager sharedManager] currentLoadoutShouldHideIconLabelsForLocation:[[self iconView] location]] ? 0.0 : %orig;
    return a;
}
-(void)setAlpha:(CGFloat)arg
{
    %orig([[HPManager sharedManager] currentLoadoutShouldHideIconLabelsForLocation:[[self iconView] location]] ? 0.0 : arg);
}

%end

%hook SBIconBadgeView

-(void)setHidden:(BOOL)arg
{
    if (_pfTweakEnabled &&  [[HPManager sharedManager] currentLoadoutShouldHideIconBadgesForLocation:@"SBIconLocationRoot"])
    {
        %orig(YES);
    }
    else {
        %orig(arg);
    }
}
-(BOOL)isHidden 
{
    if (_pfTweakEnabled && [[HPManager sharedManager] currentLoadoutShouldHideIconBadgesForLocation:@"SBIconLocationRoot"])
    {
        return YES;
    }
    return %orig;
}
-(CGFloat)alpha
{
    CGFloat a =  [[HPManager sharedManager] currentLoadoutShouldHideIconBadgesForLocation:@"SBIconLocationRoot"] ? 0.0 : %orig;
    return a;
}
-(void)setAlpha:(CGFloat)arg
{
    %orig( [[HPManager sharedManager] currentLoadoutShouldHideIconBadgesForLocation:@"SBIconLocationRoot"] ? 0.0 : arg);
}
%end

%hook SBHomeScreenSpotlightViewController

-(id)initWithDelegate:(id)arg 
{
    id x = %orig(arg);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissSearchView) name:kEditingModeEnabledNotificationName object:nil];
    return x;
}

%end 


@interface SBIconController 
-(BOOL)resetHomeScreenLayout;
@end
@interface SBHIconManager
-(void)resetRootIconLists;
-(BOOL)relayout;
@end 
@interface SBHomeScreenViewController
@property (nonatomic, retain) SBHIconManager *iconManager;
@property (nonatomic, retain) SBIconController *iconController;
@end
%hook SBHomeScreenViewController


- (id)initWithCoder:(id)arg {
	if ((self = %orig(arg))) {

	}

    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:@"HPResetIconViews" object:nil];
	return self;
}

- (id)initWithIconController:(id)arg1 UIController:(id)arg2 {
	if ((self = %orig(arg1, arg2))) {

	}

    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:@"HPResetIconViews" object:nil];
	return self;
}


%new
- (void)recieveNotification:(NSNotification *)notification
{
    //[self.iconManager resetRootIconLists];
    //[self.iconManager relayout];
    //[self.iconController resetHomeScreenLayout];
}

%end

@interface UISystemGestureView (HomePlus)
-(void)_addGestureRecognizer:(id)arg atEnd:(BOOL)arg2;
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

    if (!self.hp_hitbox_window && _pfTweakEnabled) 
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


%hook SBIconListGridLayoutConfiguration 

%property (nonatomic, assign) NSString *iconLocation;

- (id)init {
    id x = %orig; 
    return x;
}
%new 
- (NSString *)locationIfKnown
{
    if (self.iconLocation) return self.iconLocation;
    // Guess if it hasn't been set
    else 
    {
        // dock
        if ([self numberOfPortraitRows] == 1 && [self numberOfPortraitColumns] == 4)
        {
            self.iconLocation =  @"SBIconLocationDock";
        }
        else if ([self numberOfPortraitRows] == 3 && [self numberOfPortraitColumns] == 3)
        {
            self.iconLocation =  @"SBIconLocationFolder";
        }
        else 
        {
            self.iconLocation =  @"SBIconLocationRoot";
        }
    }
    return self.iconLocation;
}
- (NSUInteger)numberOfPortraitRows
{
	NSInteger x = %orig;

    if (!self.iconLocation) return x;
    if ([[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }

    if (!_rtConfigured && _pfTweakEnabled) return kMaxRowAmount;

	return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutRowsForLocation:[self locationIfKnown] pageIndex:0] : (NSUInteger)x;
}

- (NSUInteger)numberOfPortraitColumns
{
	NSInteger x = %orig;

    if (!self.iconLocation) return x;
    if ([[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }

    if (!_rtConfigured && _pfTweakEnabled) return kMaxColumnAmount;

	return _pfTweakEnabled ? [[HPManager sharedManager] currentLoadoutColumnsForLocation:[self locationIfKnown] pageIndex:0]  : (NSUInteger)x;
}

- (void)setNumberOfPortraitRows:(NSUInteger)arg 
{
    if (!self.iconLocation)
    {
        %orig(arg);
        return;
    }
    NSUInteger x = (_pfTweakEnabled) ? [[HPManager sharedManager] currentLoadoutRowsForLocation:[self locationIfKnown] pageIndex:0] : arg;

    if (NO && !_rtConfigured && _pfTweakEnabled)
    {
        %orig(kMaxRowAmount);
        return;
    }
    %orig(x);
}

- (void)setNumberOfPortraitColumns:(NSUInteger)arg 
{
    if (!self.iconLocation)
    {
        %orig(arg);
        return;
    }
    NSUInteger x = (_pfTweakEnabled) ? [[HPManager sharedManager] currentLoadoutColumnsForLocation:[self locationIfKnown] pageIndex:0] : arg;

    if (!_rtConfigured && _pfTweakEnabled) 
    {
        %orig(kMaxColumnAmount);
        return;
    }

    %orig(x);
}

- (UIEdgeInsets)portraitLayoutInsets
{
    UIEdgeInsets x = %orig;

    if (!_pfTweakEnabled || [[HPManager sharedManager] resettingIconLayout])
    {
        return x;
    }

    if (!self.iconLocation) [self setIconLocation:[self locationIfKnown]];
    return [[HPManager sharedManager] currentLoadoutInsetsForLocation:[self locationIfKnown] pageIndex:0 withOriginal:x];
    
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
        [self layoutIconsNow];
        [[[EditorManager sharedManager] editorViewController] addRootIconListViewToUpdate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(highlightView:) name:kHighlightViewNotificationName object:nil];
        self.configured = YES;
        _rtConfigured = YES;

        [self layoutIconsNow];

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

%new
- (NSArray *)getDefaultValues
{

    [[HPManager sharedManager] setResettingIconLayout:YES]; 
    SBIconListGridLayoutConfiguration *config = [[self layout] layoutConfiguration];
    UIEdgeInsets defaultInsets = [config portraitLayoutInsets];
    NSUInteger pC = [config numberOfPortraitColumns];
    NSUInteger pR = [config numberOfPortraitRows];

    NSArray *fatArray = [NSArray arrayWithObjects:
                    [NSNumber numberWithFloat:defaultInsets.top],
                    [NSNumber numberWithFloat:defaultInsets.right],
                    [NSNumber numberWithFloat:defaultInsets.bottom],
                    [NSNumber numberWithFloat:defaultInsets.left],
                    [NSNumber numberWithInteger:pC],
                    [NSNumber numberWithInteger:pR],nil];

    [[HPManager sharedManager] setResettingIconLayout:NO]; 
    return fatArray;
}

- (void)layoutIconsNow 
{

    NSLog(@"HPC: %@", [self iconLocation]);
    %orig;
    if (!_pfTweakEnabled)
    {
        return;
    }
    
    double labelAlpha = [[HPManager sharedManager] currentLoadoutShouldHideIconLabelsForLocation:[self iconLocation]] ? 0.0 : 1.0;
    [self setIconsLabelAlpha:labelAlpha];

}


- (UIEdgeInsets)layoutInsetsForOrientation:(NSInteger)orientation
{
    UIEdgeInsets x = %orig(orientation);
    if (_pfTweakEnabled) return x;
    return [[HPManager sharedManager] currentLoadoutInsetsForLocation:[self iconLocation] pageIndex:0 withOriginal:x];
}
- (NSUInteger)iconRowsForCurrentOrientation
{
    
    return [[HPManager sharedManager] currentLoadoutRowsForLocation:[self iconLocation] pageIndex:0];
}
- (NSUInteger)iconColumnsForCurrentOrientation
{
    return [[HPManager sharedManager] currentLoadoutColumnsForLocation:[self iconLocation] pageIndex:0];
}
%end


@interface SBRootFolderDockIconListView : SBIconListView
-(CGFloat)effectiveSpacingForNumberOfIcons:(NSUInteger)num;
-(NSUInteger)iconsInRowForSpacingCalculation;
-(id)layout;
@end


%hook SBRootFolderDockIconListView 

- (UIEdgeInsets)layoutInsets
{
    UIEdgeInsets x = %orig;
    if (!_pfTweakEnabled) return x;
    return [[HPManager sharedManager] currentLoadoutInsetsForLocation:@"SBIconLocationDock" pageIndex:0 withOriginal:x];
}
-(CGFloat)automaticallyAdjustsLayoutMetricsToFit
{
    return (!_pfTweakEnabled);
}
-(CGFloat)horizontalIconPadding
{
    if (!_pfTweakEnabled) return [[HPManager sharedManager] currentLoadoutHorizontalSpacingForLocation:@"SBIconLocationDock" pageIndex:0];
    return %orig;
}
- (NSUInteger)iconRowsForCurrentOrientation
{
    SBIconListGridLayoutConfiguration *config = [[self layout] layoutConfiguration];
    return [config numberOfPortraitRows];
}
- (NSUInteger)iconColumnsForCurrentOrientation
{
    SBIconListGridLayoutConfiguration *config = [[self layout] layoutConfiguration];
    return [config numberOfPortraitColumns];
}
%end

// END iOS 13 Group

%end



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
        _pfActivationGesture = [[prefs objectForKey:@"gesture"] intValue] ?: 1;
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

    [[HPManager sharedManager] loadSavedCurrentLoadoutName];
    [[HPManager sharedManager] loadCurrentLoadout];

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        &observer,
		(CFNotificationCallback)preferencesChanged,
        (CFStringRef)@"me.kritanta.homeplus/settingschanged",
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );

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