//
// HPEditorViewController.m
// HomePlus
//
// Most of the UI code goes here. This handles all of the views that are brought up. 
// Although it isn't the manager, think of this as the home-base for everything that happens
//      once the editor view is activated.
// 
// Created Oct 2019 
// Authors: Kritanta
//

#include "HPEditorViewController.h"
#include "HPOffsetControllerView.h"
#include "HPSpacingControllerView.h"
#include "HPIconCountControllerView.h"
#include "HPScaleControllerView.h"
#include "../../HomePlus.h"
#include "HPUtility.h"
#include "../Manager/EditorManager.h"
#include "../Manager/HPManager.h"
#include "../Utility/HPResources.h"
#include "../Settings/HPSettingsTableViewController.h"
#include "HPEditorViewNavigationTabBar.h"
#include "../Utility/OBSlider.h"
#include <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>


@implementation HPEditorViewNavigationTabBar
@end

@interface HPEditorViewController () 
@property (nonatomic, readwrite, strong) HPControllerView *offsetControlView;
@property (nonatomic, readwrite, strong) HPControllerView *spacingControlView;
@property (nonatomic, readwrite, strong) HPControllerView *iconCountControlView;
@property (nonatomic, readwrite, strong) HPControllerView *scaleControlView;
@property (nonatomic, readwrite, strong) HPControllerView *settingsView;
@property (nonatomic, readwrite, strong) HPEditorViewNavigationTabBar *tabBar;

@property (nonatomic, readwrite, strong) HPSettingsTableViewController *tableViewController;

@property (nonatomic, readwrite, strong) UIView *tapBackView;

@property (nonatomic, retain) HPControllerView *activeView;
@property (nonatomic, retain) UIButton *activeButton;

@property (nonatomic, retain) UIButton *offsetButton;
@property (nonatomic, retain) UIButton *spacerButton;
@property (nonatomic, retain) UIButton *iconCountButton;
@property (nonatomic, retain) UIButton *scaleButton;
@property (nonatomic, retain) UIButton *settingsButton;
@property (nonatomic, retain) UIButton *rootButton;
@property (nonatomic, retain) UIButton *dockButton;
@property (nonatomic, retain) UIButton *topResetButton;
@property (nonatomic, retain) UIButton *bottomResetButton;
@property (nonatomic, retain) UIButton *settingsDoneButton;

@property (nonatomic, retain) UILabel *leftOffsetLabel;

@property (nonatomic, assign) BOOL viewKickedUp;

@end

#pragma mark Constants

/* 
 * Oh boy. So, to get the UI to translate well to other devices, I gotthe
 *      exact measurements on my X, and then whipped out a calculator. These
 *      are the values it gave me. Assume any of them are * by device screen w/h
 *
 * In hindsight, this is inefficient and, the smaller the screen gets, the less
 *       reliable it is. Fortunately, it all still works on the smallest screen that
 *       this tweak can run on (SE)
 * 
*/

// TODO: Finish turning these offsets into constants and maybe #def them instead in a header. 

const CGFloat MENU_BUTTON_TOP_ANCHOR = 0.197; 
const CGFloat MENU_BUTTON_SIZE = 40.0;

const CGFloat RESET_BUTTON_SIZE = 25.0;

const CGFloat LEFT_SCREEN_BUFFER = 0.146;

const CGFloat TOP_CONTAINER_TOP_ANCHOR = 0.036;
const CGFloat CONTAINER_HEIGHT = 0.123;

const CGFloat TABLE_HEADER_HEIGHT = 0.458;


@implementation HPEditorViewController
@synthesize topOffsetSlider, sideOffsetSlider, verticalSpacingSlider, horizontalSpacingSlider, 
            rootIconListViewsToUpdate, topOffsetValueInput, bottomOffsetValueInput,
            topSpacingValueInput, bottomSpacingValueInput, rowsSlider, columnsSlider, scaleSlider,
            rotationSlider;

- (void)viewDidLoad
{
    [super viewDidLoad];

    BOOL _tcDockyInstalled = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/me.nepeta.docky.list"];
    BOOL excludeForDocky = (_tcDockyInstalled && [[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]);
    // Load latest values from the manager. Crucial. 

    // Add subviews to self. Any time viewDidLoad is called manually, unload these view beforehand
    if (!excludeForDocky)
    {
        [self.view addSubview:[self offsetControlView]];
        [self.view addSubview:[self spacingControlView]];
        [self.view addSubview:[self iconCountControlView]];
    }
    [self.view addSubview:[self scaleControlView]];
    [self.view addSubview:[self settingsView]];
    // Load the view
    if (!excludeForDocky)
    {
        [self loadControllerView:[self offsetControlView]];
        [self scaleControlView].alpha = 0;
    }
    else 
    {
        [self loadControllerView:[self scaleControlView]];
    }
    // Set the alpha of the rest to 0
    [self spacingControlView].alpha = 0;
    [self iconCountControlView].alpha = 0;
    [self settingsView].alpha = 0;

    self.tabBar = [[HPEditorViewNavigationTabBar alloc] initWithFrame:CGRectMake(
                                        [[UIScreen mainScreen] bounds].size.width - 47.5,
                                         MENU_BUTTON_TOP_ANCHOR * [[UIScreen mainScreen] bounds].size.height,
                                         MENU_BUTTON_SIZE, MENU_BUTTON_SIZE*9)];

    // Side Navigation Bar
    // TODO: Add these as a subview of HPEditorViewNavigationTabBar and expand that class. 
    // TODO: Generate these with a switch-case generator
    self.offsetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.offsetButton addTarget:self 
            action:@selector(handleOffsetButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.offsetButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *offsetImage = [HPResources offsetImage];
    [self.offsetButton setImage:offsetImage forState:UIControlStateNormal];
    self.offsetButton.frame = CGRectMake(0,0, MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    
    if (!excludeForDocky) [self.tabBar addSubview:self.offsetButton];
    // Since the offset view will be the first loaded, we dont need to lower alpha
    //      on the button. 

    self.spacerButton = [UIButton buttonWithType:UIButtonTypeCustom];

    [self.spacerButton addTarget:self 
            action:@selector(handleSpacerButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];

    [self.spacerButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];

    UIImage *spacerImage = [HPResources spacerImage];
    [self.spacerButton setImage:spacerImage forState:UIControlStateNormal];

    self.spacerButton.frame = CGRectMake(0, 0 + MENU_BUTTON_SIZE, MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    // Lower alpha on the rest. 
    // TODO: const these
    self.spacerButton.alpha = 0.5;
    
    if (!excludeForDocky) [self.tabBar addSubview:self.spacerButton];

    self.iconCountButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.iconCountButton addTarget:self 
            action:@selector(handleIconCountButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.iconCountButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *iCImage = [HPResources iconCountImage];
    [self.iconCountButton setImage:iCImage forState:UIControlStateNormal];
    self.iconCountButton.frame = CGRectMake(0, 0 + MENU_BUTTON_SIZE * 2,  MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    self.iconCountButton.alpha = 0.5;
    
    if (!excludeForDocky) [self.tabBar addSubview:self.iconCountButton];


    self.scaleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.scaleButton addTarget:self 
            action:@selector(handleScaleButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.scaleButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *sImage = [HPResources scaleImage];
    [self.scaleButton setImage:sImage forState:UIControlStateNormal];
    self.scaleButton.frame = CGRectMake(0, 0 + MENU_BUTTON_SIZE * 3,  MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    self.scaleButton.alpha = (excludeForDocky ? 1 : 0.5);
    [self.tabBar addSubview:self.scaleButton];
    
    self.settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.settingsButton addTarget:self 
            action:@selector(handleSettingsButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.settingsButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *settingsImage = [HPResources settingsImage];
    [self.settingsButton setImage:settingsImage forState:UIControlStateNormal];
    self.settingsButton.frame = CGRectMake(0, 0 + MENU_BUTTON_SIZE * (excludeForDocky ? 1 : 4), MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    self.settingsButton.alpha = 0.5;
    
    [self.tabBar addSubview:self.settingsButton];

    self.rootButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rootButton addTarget:self 
            action:@selector(handleRootButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.rootButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *rootImage = [HPResources rootImage];
    [self.rootButton setImage:rootImage forState:UIControlStateNormal];
    self.rootButton.frame = CGRectMake(0, 0 + MENU_BUTTON_SIZE * 7, MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    self.rootButton.alpha = 1;
    [self.tabBar addSubview:self.rootButton];

    self.dockButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.dockButton addTarget:self 
            action:@selector(handleDockButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.dockButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *dockImage = [HPResources dockImage];
    [self.dockButton setImage:dockImage forState:UIControlStateNormal];
    self.dockButton.frame = CGRectMake(0, 0 + MENU_BUTTON_SIZE * 8,  MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    self.dockButton.alpha = 0.5;
    [self.tabBar addSubview:self.dockButton];
    [self.view addSubview:self.tabBar];

    self.topResetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.topResetButton addTarget:self 
            action:@selector(handleTopResetButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.topResetButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *rsImage = [HPResources resetImage];
    [self.topResetButton setImage:rsImage forState:UIControlStateNormal];
    self.topResetButton.frame = CGRectMake(20,(0.084) * [[UIScreen mainScreen] bounds].size.height, RESET_BUTTON_SIZE, RESET_BUTTON_SIZE);
    self.topResetButton.alpha = 0.8;
    [self.view addSubview:self.topResetButton];

    self.bottomResetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.bottomResetButton addTarget:self 
            action:@selector(handleBottomResetButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.bottomResetButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    [self.bottomResetButton setImage:rsImage forState:UIControlStateNormal];
    self.bottomResetButton.frame = CGRectMake(20,(0.912) * [[UIScreen mainScreen] bounds].size.height, RESET_BUTTON_SIZE, RESET_BUTTON_SIZE);
    self.bottomResetButton.alpha = 0.8;
    [self.view addSubview:self.bottomResetButton];

    self.tapBackView.hidden = NO;
    
    self.activeButton = self.offsetButton;

}

-(void)transitionViewsToActivationPercentage:(CGFloat)amount 
{ // amount being float 0<x<1

    CGFloat fullAmt = (([[UIScreen mainScreen] bounds].size.height) * 0.15);
    CGFloat topTranslation = 0-fullAmt + (amount * fullAmt);
    CGFloat bottomTranslation = fullAmt - (amount * fullAmt);
    self.activeView.topView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, topTranslation);
    self.activeView.bottomView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, bottomTranslation);
    self.topResetButton.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, topTranslation);
    self.bottomResetButton.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, bottomTranslation);
    self.tabBar.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, (50 - (50 * amount)), 0);
}
-(void)transitionViewsToActivationPercentage:(CGFloat)amount withDuration:(CGFloat)duration 
{
    [UIView animateWithDuration:duration
        animations:
        ^{  
            CGFloat fullAmt = (([[UIScreen mainScreen] bounds].size.height) * 0.15);
            CGFloat topTranslation = 0-fullAmt + (amount * fullAmt);
            CGFloat bottomTranslation = fullAmt - (amount * fullAmt);
            self.activeView.topView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, topTranslation);
            self.activeView.bottomView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, bottomTranslation);
            self.topResetButton.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, topTranslation);
            self.bottomResetButton.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, bottomTranslation);
            self.tabBar.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, (50 - (50 * amount)), 0);
        }
    ];
}
-(void)reload 
{
    [[EditorManager sharedManager] setEditingLocation:@"SBIconLocationRoot"];
    [[HPManager sharedManager] saveCurrentLoadout];

    [[self.view subviews]
        makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _spacingControlView = nil;
    _offsetControlView = nil;
    _settingsView = nil;
    _iconCountControlView = nil;
    _scaleControlView = nil;

    [self viewDidLoad];
}
#pragma mark Editing Location
- (void)handleDockButtonPress:(UIButton*)sender
{
    if (self.dockButton.alpha == 1) return;
    AudioServicesPlaySystemSound(1519);
    [[EditorManager sharedManager] setEditingLocation:@"SBIconLocationDock"];
    [[HPManager sharedManager] saveCurrentLoadout];

        [[self.view subviews]
            makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _spacingControlView = nil;
    _offsetControlView = nil;
    _settingsView = nil;
    _iconCountControlView = nil;
    _scaleControlView = nil;

    // Reload views
    [self viewDidLoad];

    self.dockButton.alpha = 1;
    self.rootButton.alpha = 0.5;

    [[NSNotificationCenter defaultCenter] postNotificationName:kHighlightViewNotificationName object:nil];
}

- (void)handleRootButtonPress:(UIButton*)sender
{
    if (self.rootButton.alpha == 1) return;
    AudioServicesPlaySystemSound(1519);
    [[EditorManager sharedManager] setEditingLocation:@"SBIconLocationRoot"];
    [[HPManager sharedManager] saveCurrentLoadout];
    [[self.view subviews]
        makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _spacingControlView = nil;
    _offsetControlView = nil;
    _settingsView = nil;
    _iconCountControlView = nil;
    _scaleControlView = nil;

    // Reload views
    [self viewDidLoad];

    self.rootButton.alpha = 1;
    self.dockButton.alpha = 0.5;

    [[NSNotificationCenter defaultCenter] postNotificationName:kHighlightViewNotificationName object:nil];
}

#pragma mark TapBackView

- (UIView *)tapBackView 
{
    if (!_tapBackView) 
    {   //uicontroleventtouchdownrepeat
        _tapBackView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action: @selector(handleTapOnView:)];                                 
        [singleTapRecognizer setNumberOfTouchesRequired:2];
        [_tapBackView addGestureRecognizer: singleTapRecognizer];
        _tapBackView.transform = CGAffineTransformMakeScale(0.7, 0.7);
    }
    return _tapBackView;
}
- (void)handleTapOnView:(id)sender
{

    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusEditingModeDisabled" object:nil];
    [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _spacingControlView = nil;
    _offsetControlView = nil;
    _settingsView = nil;
    [self viewDidLoad];
    [[EditorManager sharedManager] hideEditorView];
}

#pragma mark - HPControllerViews



#pragma mark Settings View

- (HPControllerView *)settingsView 
{
    if (!_settingsView) 
    {
        _settingsView = [[HPControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        UIView *settingsContainerView = self.tableViewController.view;
        _settingsView.topView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [_settingsView.topView addSubview:settingsContainerView];
        [_settingsView addSubview:_settingsView.topView];

        UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0,0,[[UIScreen mainScreen] bounds].size.width,(([[UIScreen mainScreen] bounds].size.width)/750)*300)];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width,(([[UIScreen mainScreen] bounds].size.width)/750)*300)];

        imageView.image = [EditorManager sharedManager].dynamicallyGeneratedSettingsHeaderImage;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [tableHeaderView addSubview:imageView];

        UIView *doneButtonContainerView = [[UIView alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width-80, ((([[UIScreen mainScreen] bounds].size.width)/750)*300)-40, [[UIScreen mainScreen] bounds].size.width/2, 40)];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self 
                action:@selector(handleDoneSettingsButtonPress:)
        forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"Done" forState:UIControlStateNormal];
        button.frame = CGRectMake(0, 0, 80, 40);
        [doneButtonContainerView addSubview:button];
        _settingsView.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0,0,[[UIScreen mainScreen] bounds].size.width,(TABLE_HEADER_HEIGHT*[[UIScreen mainScreen] bounds].size.width))];
        [_settingsView.bottomView addSubview:doneButtonContainerView];
        
        [_settingsView.topView addSubview:tableHeaderView];
        [_settingsView addSubview:_settingsView.bottomView];
    }
    _settingsView.hidden = NO;
    return _settingsView;
}

- (HPSettingsTableViewController *)tableViewController
{
    if (!_tableViewController) 
    {
        _tableViewController = [[HPSettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    return _tableViewController;
}
#pragma mark offset view
- (HPControllerView *)offsetControlView 
{
    if (!_offsetControlView) 
    {
        _offsetControlView = [[HPOffsetControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    return _offsetControlView;
}

- (HPControllerView *)spacingControlView
{
    if (!_spacingControlView) 
    {
        _spacingControlView = [[HPSpacingControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    return _spacingControlView;
}

- (HPControllerView *)iconCountControlView
{
    if (!_iconCountControlView) 
    {
        _iconCountControlView = [[HPIconCountControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    return _iconCountControlView;
}

#pragma mark spacing


- (HPControllerView *)scaleControlView 
{
    if (!_scaleControlView) 
    {
        _scaleControlView = [[HPScaleControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    return _scaleControlView;
}

- (void)addRootIconListViewToUpdate:(SBRootIconListView *)view
{
    if (!self.rootIconListViewsToUpdate) 
    {
        self.rootIconListViewsToUpdate = [[NSMutableArray alloc] init];
    }
    [self.rootIconListViewsToUpdate addObject:view];
}

- (void)resetAllValuesToDefaults 
{
    [[HPManager sharedManager] resetCurrentLoadoutToDefaults];
}

#pragma mark Button Handlers

- (void)buttonPressDown:(UIButton*)sender
{
    // AudioServicesPlaySystemSound(1519);
    // hack for the offset 4 column case
    self.bottomResetButton.enabled = YES;
}
- (void)handleSettingsButtonPress:(UIButton*)sender
{
    [self handleRootButtonPress:self.rootButton];
    [[HPManager sharedManager] saveCurrentLoadoutName];
    [[HPManager sharedManager] saveCurrentLoadout];
    [[HPManager sharedManager] loadCurrentLoadout]; // Will Save + Load

    [self loadControllerView:[self settingsView]];
    self.activeButton.userInteractionEnabled = YES; 

    [[NSNotificationCenter defaultCenter] postNotificationName:kFadeFloatingDockNotificationName object:nil];
    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.settingsButton.alpha = 0;
            self.spacerButton.alpha = 0;
            self.offsetButton.alpha = 0;
            self.iconCountButton.alpha = 0;
            self.scaleButton.alpha = 0;
            self.topResetButton.alpha = 0;
            self.bottomResetButton.alpha = 0;
            self.rootButton.alpha = 0;
            self.dockButton.alpha = 0;
        }
    ];
    [[self tableViewController] opened];

    self.activeButton = sender;
    self.tapBackView.hidden = YES;
}
- (void)handleDoneSettingsButtonPress:(UIButton*)sender
{
    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.settingsButton.alpha = 0.5;
            self.spacerButton.alpha = 0.5;
            self.iconCountButton.alpha = 0.5;
            self.scaleButton.alpha = 0.5;
            self.offsetButton.alpha = 1;
            self.topResetButton.alpha = 0.8;
            self.bottomResetButton.alpha = 0.8;
            self.rootButton.alpha = 1;
            self.dockButton.alpha = 0.5;
        }
    ];

    [[NSNotificationCenter defaultCenter] postNotificationName:kShowFloatingDockNotificationName object:nil];
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"HPResetIconViews" object:nil];

    self.tapBackView.hidden = NO;

    [self handleOffsetButtonPress:self.offsetButton];
}
- (void)handleOffsetButtonPress:(UIButton*)sender 
{
    [self loadControllerView:[self offsetControlView]];

    if (((([[NSUserDefaults standardUserDefaults] integerForKey:@"HPThemeDefaultRootColumns"]?:4) == 4) && ([[HPUtility deviceName] isEqualToString:@"iPhone X"])) && (kCFCoreFoundationVersionNumber < 1600)) 
    {
        self.leftOffsetLabel.text = @"Left Offset Disabled When\n4 Columns Selected on Notched Devices";
        self.bottomOffsetValueInput.enabled = NO;
        self.sideOffsetSlider.enabled = NO;
        self.bottomResetButton.enabled = NO;
    }
    else
    {
        self.leftOffsetLabel.text = @"Set to 0 to enable auto-centered\n Horizontal Spacing";
        self.bottomOffsetValueInput.enabled = YES;
        self.sideOffsetSlider.enabled = YES;
        self.bottomResetButton.enabled = YES;
    }

    self.activeButton.userInteractionEnabled = YES; 
    [UIView animateWithDuration:.2 
        animations:
        ^{
            sender.alpha = 1;
            self.bottomResetButton.alpha = 0.8;
        }
    ];
    self.activeButton = sender; 
    sender.userInteractionEnabled = NO; 
    self.tapBackView.hidden = NO;
}

- (void)handleScaleButtonPress:(UIButton*)sender 
{
    [self loadControllerView:[self scaleControlView]];

    self.activeButton.userInteractionEnabled = YES; 
    [UIView animateWithDuration:.2 
        animations:
        ^{
            sender.alpha = 1;
            self.bottomResetButton.alpha = 0;
        }
    ];
    self.activeButton = sender; 
    sender.userInteractionEnabled = NO; 
    self.tapBackView.hidden = NO;
}

- (void)handleTopResetButtonPress:(UIButton*)sender 
{
    AudioServicesPlaySystemSound(1519);
    if (self.activeButton == self.offsetButton) 
    {
        CGFloat def = 0.0;
        _offsetControlView.topTextField.text = [NSString stringWithFormat:@"%.0f", def];
        [_offsetControlView topTextFieldUpdated:_offsetControlView.topTextField];
    }
    else if (self.activeButton == self.spacerButton)
    {
        CGFloat def = 0.0;
        _spacingControlView.topTextField.text = [NSString stringWithFormat:@"%.0f", def];
        [_spacingControlView topTextFieldUpdated:_spacingControlView.topTextField];
    }
    else if (self.activeButton == self.iconCountButton)
    {
        CGFloat def = [HPUtility defaultRows];
        _iconCountControlView.topControl.value = def;
        [_iconCountControlView topSliderUpdated:_iconCountControlView.topControl];
    }
    else if (self.activeButton == self.scaleButton)
    {
        CGFloat def = 60.0;
        _scaleControlView.topTextField.text = [NSString stringWithFormat:@"%.0f", def];
        [_scaleControlView topTextFieldUpdated:_scaleControlView.topTextField];
    }
}
- (void)handleBottomResetButtonPress:(UIButton*)sender 
{
    AudioServicesPlaySystemSound(1519);
    if (self.activeButton == self.offsetButton) 
    {
        CGFloat def = 0.0;
        _offsetControlView.bottomTextField.text = [NSString stringWithFormat:@"%.0f", def];
        [_offsetControlView bottomTextFieldUpdated:_offsetControlView.bottomTextField];
    }
    else if (self.activeButton == self.spacerButton)
    {
        CGFloat def = 0.0;
        _spacingControlView.bottomTextField.text = [NSString stringWithFormat:@"%.0f", def];
        [_spacingControlView bottomTextFieldUpdated:_spacingControlView.bottomTextField];
    }
    else if (self.activeButton == self.iconCountButton)
    {
        CGFloat def = 4.0;
        _iconCountControlView.bottomControl.value = def;
        [_iconCountControlView bottomSliderUpdated:_iconCountControlView.bottomControl];
    }
    else if (self.activeButton == self.scaleButton)
    {
        CGFloat def = 100.0;
        _scaleControlView.bottomTextField.text = [NSString stringWithFormat:@"%.0f", def];
        [_scaleControlView bottomTextFieldUpdated:_scaleControlView.bottomTextField];
    }
}

- (void)handleSpacerButtonPress:(UIButton*)sender 
{
    [self loadControllerView:[self spacingControlView]];
    self.activeButton.userInteractionEnabled = YES; 

    [UIView animateWithDuration:.2 
        animations:
        ^{
            sender.alpha = 1;
            self.bottomResetButton.alpha = 0.8;
        }
    ];

    self.activeButton = sender;
    sender.userInteractionEnabled = NO; 
    self.tapBackView.hidden = NO;
}
- (void)handleIconCountButtonPress:(UIButton*)sender 
{
    [self loadControllerView:[self iconCountControlView]];
    self.activeButton.userInteractionEnabled = YES; 
    [UIView animateWithDuration:.2 
        animations:
        ^{
            sender.alpha = 1;
            self.bottomResetButton.alpha = 0.8;
        }
    ];
    self.activeButton = sender;
    sender.userInteractionEnabled = NO; 
    self.tapBackView.hidden = NO;
}
- (void)resignAllTextFields
{
    // TODO: THIS
}
- (void)loadControllerView:(HPControllerView *)arg1 
{
    [self resignAllTextFields];
    self.activeButton.alpha = 0.5;
    AudioServicesPlaySystemSound(1519);

    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.activeView.alpha = 0;
            arg1.alpha = 1;
        }
    ];

    self.activeView = arg1;
}

- (void)layoutAllSpringboardIcons
{
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
        for (UIView *icon in [view allSubviews]) 
        {
            [icon layoutSubviews];
        }
    }
}
#pragma mark UIViewController overrides

- (BOOL)shouldAutorotate 
{
    return NO;
}


@end
