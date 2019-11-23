//
// HPEditorViewController.m
// HomePlus
//
// Most of the UI code goes here. This handles all of the views that are brought up. 
// Although it isn't the manager, think of this as the home-base for everything that happens
//      once the editor view is activated.
//
// This needs to be categorized at some point. 
// 
// Created Oct 2019 
// Authors: Kritanta
//

#include "HPEditorViewController.h"
#include "HPControllerView.h"
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


@implementation HPControllerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}
@end

@implementation HPEditorViewController
@synthesize topOffsetSlider, sideOffsetSlider, verticalSpacingSlider, horizontalSpacingSlider, 
            rootIconListViewsToUpdate, topOffsetValueInput, bottomOffsetValueInput,
            topSpacingValueInput, bottomSpacingValueInput;

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
    self.offsetButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 47.5,
                                         MENU_BUTTON_TOP_ANCHOR * [[UIScreen mainScreen] bounds].size.height,
                                         MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    
    if (!excludeForDocky) [self.view addSubview:self.offsetButton];
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

    self.spacerButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 47.5,
                                         (MENU_BUTTON_TOP_ANCHOR * [[UIScreen mainScreen] bounds].size.height) + MENU_BUTTON_SIZE,
                                         MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    // Lower alpha on the rest. 
    // TODO: const these
    self.spacerButton.alpha = 0.5;
    
    if (!excludeForDocky) [self.view addSubview:self.spacerButton];


    self.iconCountButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.iconCountButton addTarget:self 
            action:@selector(handleIconCountButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.iconCountButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *iCImage = [HPResources iconCountImage];
    [self.iconCountButton setImage:iCImage forState:UIControlStateNormal];
    self.iconCountButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 47.5,
                                            (MENU_BUTTON_TOP_ANCHOR * [[UIScreen mainScreen] bounds].size.height) + MENU_BUTTON_SIZE * 2,
                                            MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    self.iconCountButton.alpha = 0.5;
    
    if (!excludeForDocky) [self.view addSubview:self.iconCountButton];


    self.scaleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.scaleButton addTarget:self 
            action:@selector(handleScaleButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.scaleButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *sImage = [HPResources scaleImage];
    [self.scaleButton setImage:sImage forState:UIControlStateNormal];
    self.scaleButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 47.5,
                                            (MENU_BUTTON_TOP_ANCHOR * [[UIScreen mainScreen] bounds].size.height) + MENU_BUTTON_SIZE * (excludeForDocky ? 0 : 3),
                                            MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    self.scaleButton.alpha = (excludeForDocky ? 1 : 0.5);
    [self.view addSubview:self.scaleButton];
    
    self.settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.settingsButton addTarget:self 
            action:@selector(handleSettingsButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.settingsButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *settingsImage = [HPResources settingsImage];
    [self.settingsButton setImage:settingsImage forState:UIControlStateNormal];
    self.settingsButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 47.5,
                                           (MENU_BUTTON_TOP_ANCHOR * [[UIScreen mainScreen] bounds].size.height) + MENU_BUTTON_SIZE * (excludeForDocky ? 1 : 4),
                                           MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    self.settingsButton.alpha = 0.5;
    
    [self.view addSubview:self.settingsButton];

    self.rootButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rootButton addTarget:self 
            action:@selector(handleRootButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.rootButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *rootImage = [HPResources rootImage];
    [self.rootButton setImage:rootImage forState:UIControlStateNormal];
    self.rootButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 47.5,
                                           (MENU_BUTTON_TOP_ANCHOR * [[UIScreen mainScreen] bounds].size.height) + MENU_BUTTON_SIZE * 7,
                                           MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    self.rootButton.alpha = 1;
    [self.view addSubview:self.rootButton];

    self.dockButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.dockButton addTarget:self 
            action:@selector(handleDockButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.dockButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *dockImage = [HPResources dockImage];
    [self.dockButton setImage:dockImage forState:UIControlStateNormal];
    self.dockButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 47.5,
                                           (MENU_BUTTON_TOP_ANCHOR * [[UIScreen mainScreen] bounds].size.height) + MENU_BUTTON_SIZE * 8,
                                           MENU_BUTTON_SIZE, MENU_BUTTON_SIZE);
    self.dockButton.alpha = 0.5;
    [self.view addSubview:self.dockButton];

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

    [self.view addSubview:[self tapBackView]];
    self.tapBackView.hidden = NO;
    
    self.activeButton = self.offsetButton;

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

        BOOL notched = [HPUtility isCurrentDeviceNotched];

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

        NSString *x = @"";
        if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
        else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock";
        else x = @"Folder";

        _offsetControlView = [[HPControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

        _offsetControlView.topView = [
            [UIView alloc] initWithFrame: CGRectMake(LEFT_SCREEN_BUFFER * [[UIScreen mainScreen] bounds].size.width,
                                                    TOP_CONTAINER_TOP_ANCHOR * [[UIScreen mainScreen] bounds].size.height, 
                                                    [[UIScreen mainScreen] bounds].size.width, 
                                                    CONTAINER_HEIGHT * [[UIScreen mainScreen] bounds].size.height )];

        UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (0.706) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        [topLabel setText:@"Top Offset: "];
        topLabel.textColor=[UIColor whiteColor];
        topLabel.textAlignment=NSTextAlignmentCenter;

        self.topOffsetValueInput = [[UITextField alloc] initWithFrame:CGRectMake((0.730) * [[UIScreen mainScreen] bounds].size.width, (0.048) * [[UIScreen mainScreen] bounds].size.height, (0.1333) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height)];
        
        [self.topOffsetValueInput addTarget:self
                action:@selector(topOffsetValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];

        self.topOffsetValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.topOffsetValueInput.textColor = [UIColor whiteColor];

        UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];

        [keyboardToolbar sizeToFit];



        UIButton *tminusButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 5, 40, 30)];
        [tminusButton setTitle:@"+/-" forState:UIControlStateNormal];
        [tminusButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [tminusButton addTarget:self action:@selector(invertTopOffsetValue) forControlEvents:UIControlEventTouchUpInside];


        UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self.topOffsetValueInput action:@selector(resignFirstResponder)];
        keyboardToolbar.items = @[flexBarButton, doneBarButton];
        self.topOffsetValueInput.inputAccessoryView = keyboardToolbar;
        [self.topOffsetValueInput.inputAccessoryView addSubview:tminusButton];

        self.topOffsetSlider = [[OBSlider alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.7) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        [self.topOffsetSlider addTarget:self action:@selector(topOffsetSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.topOffsetSlider setBackgroundColor:[UIColor clearColor]];
        self.topOffsetSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.topOffsetSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.topOffsetSlider.minimumValue = -100;
        self.topOffsetSlider.maximumValue = [[UIScreen mainScreen] bounds].size.height;
        self.topOffsetSlider.continuous = YES;
        self.topOffsetSlider.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"TopInset"]];
        [_offsetControlView addSubview:_offsetControlView.topView];
        [_offsetControlView.topView addSubview:topLabel];
        [_offsetControlView.topView addSubview:self.topOffsetSlider];
        self.topOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", self.topOffsetSlider.value];
        [_offsetControlView.topView addSubview:topOffsetValueInput];


        _offsetControlView.bottomView = [[UIView alloc] initWithFrame:CGRectMake((0.146) * [[UIScreen mainScreen] bounds].size.width, (0.862) * [[UIScreen mainScreen] bounds].size.height, (1) * [[UIScreen mainScreen] bounds].size.width, (0.123) * [[UIScreen mainScreen] bounds].size.height)];

        UILabel *sideLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (0.706) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [sideLabel setText:@"Left Offset"];
        sideLabel.textColor=[UIColor whiteColor];
        sideLabel.textAlignment=NSTextAlignmentCenter;


        self.bottomOffsetValueInput = [[UITextField alloc] initWithFrame:CGRectMake((0.730) * [[UIScreen mainScreen] bounds].size.width, (0.048) * [[UIScreen mainScreen] bounds].size.height, 50, 30)];
        [self.bottomOffsetValueInput addTarget:self
                action:@selector(bottomOffsetValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];
        
        [self.bottomOffsetValueInput addTarget:self
                action:@selector(bottomOffsetEditingStarted)
                forControlEvents:UIControlEventEditingDidBegin];

        self.bottomOffsetValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.bottomOffsetValueInput.textColor = [UIColor whiteColor];

        UIToolbar* bkeyboardToolbar = [[UIToolbar alloc] init];

        [bkeyboardToolbar sizeToFit];

        UIButton *minusButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 5, 40, 30)];
        [minusButton setTitle:@"+/-" forState:UIControlStateNormal];
        [minusButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [minusButton addTarget:self action:@selector(invertBottomOffsetValue) forControlEvents:UIControlEventTouchUpInside];

        UIBarButtonItem *bflexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *bdoneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self action:@selector(bottomOffsetEditingEnded)];
        bkeyboardToolbar.items = @[bflexBarButton, bdoneBarButton];
        self.bottomOffsetValueInput.inputAccessoryView = bkeyboardToolbar;

        [self.bottomOffsetValueInput.inputAccessoryView addSubview:minusButton];

        self.sideOffsetSlider = [[OBSlider alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.700) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [self.sideOffsetSlider addTarget:self action:@selector(sideOffsetSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.sideOffsetSlider setBackgroundColor:[UIColor clearColor]];
        self.sideOffsetSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.sideOffsetSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.sideOffsetSlider.minimumValue = -400.0;
        self.sideOffsetSlider.maximumValue = 400.0;
        self.sideOffsetSlider.continuous = YES;
        self.sideOffsetSlider.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"LeftInset"]];
        [_offsetControlView addSubview:_offsetControlView.bottomView];
        [_offsetControlView.bottomView addSubview:sideLabel];
        [_offsetControlView.bottomView addSubview:self.sideOffsetSlider];
        self.bottomOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", self.sideOffsetSlider.value];
        [_offsetControlView.bottomView addSubview:self.bottomOffsetValueInput];

        // note
        self.leftOffsetLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height + 30, (0.706) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [self.leftOffsetLabel setText:@"Set to 0 to enable auto-centered\n Horizontal Spacing"];
        [self.leftOffsetLabel setFont:[UIFont systemFontOfSize:11]];
        self.leftOffsetLabel.numberOfLines = 2;
        self.leftOffsetLabel.textColor=[UIColor whiteColor];
        self.leftOffsetLabel.textAlignment=NSTextAlignmentCenter;
        [_offsetControlView.bottomView addSubview:self.leftOffsetLabel];
    }
    return _offsetControlView;
}
- (void)bottomOffsetEditingStarted 
{   
    //[self.bottomOffsetValueInput becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusKickWindowsUp" object:nil];
    CGAffineTransform transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:0.4 
    animations:
    ^{
        self.view.transform = CGAffineTransformTranslate(transform, 0, (0-([[UIScreen mainScreen] bounds].size.height * 0.5)));
    }]; 
    self.viewKickedUp = YES;
}
- (void)bottomOffsetEditingEnded
{
    [self.bottomOffsetValueInput resignFirstResponder];
        [UIView animateWithDuration:0.4 
        animations:
        ^{  
            self.view.transform = CGAffineTransformIdentity;   
        }
        completion:^(BOOL finished) 
        {    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusKickWindowsBack" object:nil];
            [UIView animateWithDuration:0.4 
                animations:
                ^{  
                    
                    [self.view setBackgroundColor:[UIColor clearColor]];  
                }
            ];
        }
    ]; 
    self.viewKickedUp = NO;
}
-(void)invertBottomOffsetValue
{
    if ([self.bottomOffsetValueInput.text hasPrefix:@"-"])
    {
        self.bottomOffsetValueInput.text = [self.bottomOffsetValueInput.text substringFromIndex:1];
    }
    else
    {
        self.bottomOffsetValueInput.text = [NSString stringWithFormat:@"-%@",self.bottomOffsetValueInput.text];
    }
    [self bottomOffsetValueDidChange:self.bottomOffsetValueInput];
}
-(void)invertTopOffsetValue
{
    if ([self.topOffsetValueInput.text hasPrefix:@"-"])
    {
        self.topOffsetValueInput.text = [self.topOffsetValueInput.text substringFromIndex:1];
    }
    else
    {
        self.topOffsetValueInput.text = [NSString stringWithFormat:@"-%@",self.topOffsetValueInput.text];
    }
    [self topOffsetValueDidChange:self.topOffsetValueInput];
}
- (HPControllerView *)iconCountControlView
{
    if (!_iconCountControlView) 
    {

        NSString *x = @"";
        if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
        else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock";
        else x = @"Folder";
        _iconCountControlView = [[HPControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

        _iconCountControlView.topView = [
            [UIView alloc] initWithFrame:
                            CGRectMake(LEFT_SCREEN_BUFFER * [[UIScreen mainScreen] bounds].size.width,
                            TOP_CONTAINER_TOP_ANCHOR * [[UIScreen mainScreen] bounds].size.height, 
                            [[UIScreen mainScreen] bounds].size.width, 
                            CONTAINER_HEIGHT * [[UIScreen mainScreen] bounds].size.height )];

        UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -10, (0.706) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        [topLabel setText:@"Rows:"];
        topLabel.textColor=[UIColor whiteColor];
        topLabel.textAlignment=NSTextAlignmentCenter;

        self.topIconCountValueInput =[[UITextField alloc] initWithFrame:CGRectMake(([[UIScreen mainScreen] bounds].size.width / 2) - (((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2) - LEFT_SCREEN_BUFFER * [[UIScreen mainScreen] bounds].size.width + 7, (0.048) * [[UIScreen mainScreen] bounds].size.height, (0.1333) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height)];
        [self.topIconCountValueInput addTarget:self
                action:@selector(topIconCountValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];
        self.topIconCountValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.topIconCountValueInput.textColor = [UIColor whiteColor];

        UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];

        [keyboardToolbar sizeToFit];
        UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self.topIconCountValueInput action:@selector(resignFirstResponder)];
        keyboardToolbar.items = @[flexBarButton, doneBarButton];
        self.topIconCountValueInput.inputAccessoryView = keyboardToolbar;

        self.rowsSlider = [[OBSlider alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.7) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        
        [self.rowsSlider addTarget:self action:@selector(rowsSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.rowsSlider setBackgroundColor:[UIColor clearColor]];
        self.rowsSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.rowsSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.rowsSlider.minimumValue = 1;
        self.rowsSlider.maximumValue = kMaxRowAmount;
        self.rowsSlider.continuous = YES;
        self.rowsSlider.value = (CGFloat)[[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Rows"]];
        
        [_iconCountControlView addSubview:_iconCountControlView.topView];
        [_iconCountControlView.topView addSubview:topLabel];
        [_iconCountControlView.topView addSubview:self.rowsSlider];
        self.rowsSlider.alpha = 0.0;
        UIButton *rowMin = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [rowMin addTarget:self 
                action:@selector(rowMinus)
        forControlEvents:UIControlEventTouchUpInside];
        [rowMin setTitle:@"-" forState:UIControlStateNormal];
        rowMin.frame = CGRectMake(0, (0.0369) *  [[UIScreen mainScreen] bounds].size.height, ((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) - ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2 , 40.0);
        [_iconCountControlView.topView addSubview:rowMin];

        UIButton *rowPlu = [UIButton buttonWithType:UIButtonTypeCustom];
        [rowPlu addTarget:self 
                action:@selector(rowPlus)
        forControlEvents:UIControlEventTouchUpInside];
        [rowPlu setTitle:@"+" forState:UIControlStateNormal];
        rowPlu.frame = CGRectMake(((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) + ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2, (0.0369) *  [[UIScreen mainScreen] bounds].size.height, ((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) - ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2 , 40.0);
        
        [_iconCountControlView.topView addSubview:rowPlu];
        
        self.topIconCountValueInput.text = [NSString stringWithFormat:@"%.0f", self.rowsSlider.value];
        [_iconCountControlView.topView addSubview:self.topIconCountValueInput];


        _iconCountControlView.bottomView = [[UIView alloc] initWithFrame:CGRectMake((0.146) * [[UIScreen mainScreen] bounds].size.width, (0.862) * [[UIScreen mainScreen] bounds].size.height, (1) * [[UIScreen mainScreen] bounds].size.width, (0.123) * [[UIScreen mainScreen] bounds].size.height)];


        UILabel *sideLabel =  [[UILabel alloc] initWithFrame:CGRectMake(0, -10, (0.706) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [sideLabel setText:@"Columns: "];
        sideLabel.textColor=[UIColor whiteColor];
        sideLabel.textAlignment=NSTextAlignmentCenter;


        self.bottomIconCountValueInput = [[UITextField alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width / 2 -  ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2 - LEFT_SCREEN_BUFFER * [[UIScreen mainScreen] bounds].size.width + 7, (0.0480) * [[UIScreen mainScreen] bounds].size.height, 50, 30)];
        [self.bottomIconCountValueInput addTarget:self
                action:@selector(bottomIconCountValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];
        [self.bottomIconCountValueInput addTarget:self
                action:@selector(bottomIconCountEditingStarted)
                forControlEvents:UIControlEventEditingDidBegin];
        self.bottomIconCountValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.bottomIconCountValueInput.textColor = [UIColor whiteColor];

        UIToolbar* bkeyboardToolbar = [[UIToolbar alloc] init];

        [bkeyboardToolbar sizeToFit];
        UIBarButtonItem *bflexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *bdoneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self action:@selector(bottomIconCountEditingEnded)];
        bkeyboardToolbar.items = @[bflexBarButton, bdoneBarButton];
        self.bottomIconCountValueInput.inputAccessoryView = bkeyboardToolbar;

        self.columnsSlider =[[OBSlider alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.7) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [self.columnsSlider addTarget:self action:@selector(columnsSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.columnsSlider setBackgroundColor:[UIColor clearColor]];
        self.columnsSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.columnsSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.columnsSlider.minimumValue = 1.0;
        self.columnsSlider.maximumValue = kMaxColumnAmount;
        self.columnsSlider.continuous = YES;
        self.columnsSlider.value = (CGFloat)[[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Columns"]];
        [_iconCountControlView addSubview:_iconCountControlView.bottomView];
        self.bottomIconCountValueInput.text = [NSString stringWithFormat:@"%.0f", self.columnsSlider.value];
        [_iconCountControlView.bottomView addSubview:sideLabel];
        [_iconCountControlView.bottomView addSubview:self.columnsSlider];
        self.columnsSlider.alpha = 0.0;
        UIButton *colMin = [UIButton buttonWithType:UIButtonTypeCustom];
        [colMin addTarget:self 
                action:@selector(columnMinus)
        forControlEvents:UIControlEventTouchUpInside];
        [colMin setTitle:@"-" forState:UIControlStateNormal];
        colMin.frame = CGRectMake(0, (0.0369) *   [[UIScreen mainScreen] bounds].size.height, ((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) - ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2 , 40.0);
        [_iconCountControlView.bottomView addSubview:colMin];

        UIButton *colPlu = [UIButton buttonWithType:UIButtonTypeCustom];
        [colPlu addTarget:self 
                action:@selector(columnPlus)
        forControlEvents:UIControlEventTouchUpInside];
        [colPlu setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.06]];
        [colMin setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.06]];
        [rowPlu setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.06]];
        [rowMin setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.06]];
        colPlu.layer.cornerRadius = 10;
        colPlu.clipsToBounds = YES;
        colMin.layer.cornerRadius = 10;
        colMin.clipsToBounds = YES;
        rowMin.layer.cornerRadius = 10;
        rowMin.clipsToBounds = YES;
        rowPlu.layer.cornerRadius = 10;
        rowPlu.clipsToBounds = YES;
        [colPlu setTitle:@"+" forState:UIControlStateNormal];
        colPlu.frame = CGRectMake(((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) + (((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2), (0.0369) *  [[UIScreen mainScreen] bounds].size.height, ((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) - ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2 , 40.0);
        [_iconCountControlView.bottomView addSubview:colPlu];
        [_iconCountControlView.bottomView addSubview:self.bottomIconCountValueInput];
    }
    return _iconCountControlView;
}

- (void)bottomIconCountEditingStarted 
{   
    //[self.bottomIconCountValueInput becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusKickWindowsUp" object:nil];
    CGAffineTransform transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:0.4 
    animations:
    ^{
        self.view.transform = CGAffineTransformTranslate(transform, 0, (0-([[UIScreen mainScreen] bounds].size.height * 0.5)));
    }]; 
    self.viewKickedUp = YES;
}
- (void)bottomIconCountEditingEnded
{
    [self.bottomIconCountValueInput resignFirstResponder];
        [UIView animateWithDuration:0.4 
        animations:
        ^{  
            self.view.transform = CGAffineTransformIdentity;   
        }
        completion:^(BOOL finished) 
        {    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusKickWindowsBack" object:nil];
            [UIView animateWithDuration:0.4 
                animations:
                ^{  
                    
                    [self.view setBackgroundColor:[UIColor clearColor]];  
                }
            ];
        }
    ]; 
    self.viewKickedUp = NO;
}
#pragma mark spacing
- (HPControllerView *)spacingControlView
{
    if (!_spacingControlView) 
    {

        NSString *x = @"";
        if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
        else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock";
        else x = @"Folder";
        _spacingControlView = [[HPControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

        _spacingControlView.topView =[[UIView alloc] initWithFrame:
                CGRectMake((.146 * [[UIScreen mainScreen] bounds].size.width), (0.036) * [[UIScreen mainScreen] bounds].size.height, (1 * [[UIScreen mainScreen] bounds].size.width), (0.123 * [[UIScreen mainScreen] bounds].size.height))];

        UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (0.706) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        [topLabel setText:@"Vertical Spacing: "];
        topLabel.textColor=[UIColor whiteColor];
        topLabel.textAlignment=NSTextAlignmentCenter;

        self.topSpacingValueInput = [[UITextField alloc] initWithFrame:CGRectMake((0.730) * [[UIScreen mainScreen] bounds].size.width, (0.0480) * [[UIScreen mainScreen] bounds].size.height, (0.1333) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height)];
        [self.topSpacingValueInput addTarget:self
                action:@selector(topSpacingValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];
        self.topSpacingValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.topSpacingValueInput.textColor = [UIColor whiteColor];

        UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];

        [keyboardToolbar sizeToFit];


        UIButton *minusButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 5, 40, 30)];
        [minusButton setTitle:@"+/-" forState:UIControlStateNormal];
        [minusButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [minusButton addTarget:self action:@selector(invertTopSpacingValue) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self.topSpacingValueInput action:@selector(resignFirstResponder)];
        keyboardToolbar.items = @[flexBarButton, doneBarButton];
        self.topSpacingValueInput.inputAccessoryView = keyboardToolbar;
        [self.topSpacingValueInput.inputAccessoryView addSubview:minusButton];

        self.verticalSpacingSlider = [[OBSlider alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.7) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        [self.verticalSpacingSlider addTarget:self action:@selector(verticalSpacingSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.verticalSpacingSlider setBackgroundColor:[UIColor clearColor]];
        self.verticalSpacingSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.verticalSpacingSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.verticalSpacingSlider.minimumValue = -400.0;
        self.verticalSpacingSlider.maximumValue = 400.0;
        self.verticalSpacingSlider.continuous = YES;
        self.verticalSpacingSlider.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"VerticalSpacing"]];
        [_spacingControlView addSubview:_spacingControlView.topView];
        [_spacingControlView.topView addSubview:topLabel];
        [_spacingControlView.topView addSubview:self.verticalSpacingSlider];
        self.topSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", self.verticalSpacingSlider.value];
        [_spacingControlView.topView addSubview:self.topSpacingValueInput];


        _spacingControlView.bottomView = [[UIView alloc] initWithFrame:CGRectMake((0.146) * [[UIScreen mainScreen] bounds].size.width, (0.862) * [[UIScreen mainScreen] bounds].size.height, (1) * [[UIScreen mainScreen] bounds].size.width, (0.123) * [[UIScreen mainScreen] bounds].size.height)];


        UILabel *sideLabel =  [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (0.706) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [sideLabel setText:@"Horizontal Spacing: "];
        sideLabel.textColor=[UIColor whiteColor];
        sideLabel.textAlignment=NSTextAlignmentCenter;


        self.bottomSpacingValueInput = [[UITextField alloc] initWithFrame:CGRectMake((0.730) * [[UIScreen mainScreen] bounds].size.width, (0.0480) * [[UIScreen mainScreen] bounds].size.height, 50, 30)];
        [self.bottomSpacingValueInput addTarget:self
                action:@selector(bottomSpacingValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];
        [self.bottomSpacingValueInput addTarget:self
                action:@selector(bottomSpacingEditingStarted)
                forControlEvents:UIControlEventEditingDidBegin];
        self.bottomSpacingValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.bottomSpacingValueInput.textColor = [UIColor whiteColor];

        UIToolbar* bkeyboardToolbar = [[UIToolbar alloc] init];

        [bkeyboardToolbar sizeToFit];

        UIButton *minusButtonb = [[UIButton alloc] initWithFrame:CGRectMake(15, 5, 40, 30)];
        [minusButtonb setTitle:@"+/-" forState:UIControlStateNormal];
        [minusButtonb setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [minusButtonb addTarget:self action:@selector(invertBottomSpacingValue) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *bflexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *bdoneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self action:@selector(bottomSpacingEditingEnded)];
        bkeyboardToolbar.items = @[bflexBarButton, bdoneBarButton];
        self.bottomSpacingValueInput.inputAccessoryView = bkeyboardToolbar;
        [self.bottomSpacingValueInput.inputAccessoryView addSubview:minusButtonb];

        self.horizontalSpacingSlider = [[OBSlider alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.7) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [self.horizontalSpacingSlider addTarget:self action:@selector(horizontalSpacingSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.horizontalSpacingSlider setBackgroundColor:[UIColor clearColor]];
        self.horizontalSpacingSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.horizontalSpacingSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.horizontalSpacingSlider.minimumValue = -100.0;
        self.horizontalSpacingSlider.maximumValue = 200.0;
        self.horizontalSpacingSlider.continuous = YES;
        self.horizontalSpacingSlider.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"SideInset"]];
        [_spacingControlView addSubview:_spacingControlView.bottomView];
        self.bottomSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", self.horizontalSpacingSlider.value];
        [_spacingControlView.bottomView addSubview:sideLabel];
        [_spacingControlView.bottomView addSubview:self.horizontalSpacingSlider];
        [_spacingControlView.bottomView addSubview:self.bottomSpacingValueInput];
    }
    return _spacingControlView;
}

- (void)bottomSpacingEditingStarted 
{   
    //[self.bottomSpacingValueInput becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusKickWindowsUp" object:nil];
    CGAffineTransform transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:0.4 
    animations:
    ^{
        self.view.transform = CGAffineTransformTranslate(transform, 0, (0-([[UIScreen mainScreen] bounds].size.height * 0.5)));
    }]; 
    self.viewKickedUp = YES;
}
- (void)bottomSpacingEditingEnded
{
    [self.bottomSpacingValueInput resignFirstResponder];
        [UIView animateWithDuration:0.4 
        animations:
        ^{  // TODO: make kicker notif just move the rootwindow up.
            self.view.transform = CGAffineTransformIdentity; [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusKickWindowsBack" object:nil];  
        }
        completion:^(BOOL finished) 
        {    
            [UIView animateWithDuration:0.4 
                animations:
                ^{  
                    
                    [self.view setBackgroundColor:[UIColor clearColor]];  
                }
            ];
        }
    ]; 
    self.viewKickedUp = NO;
}

-(void)invertTopSpacingValue
{
    if ([self.topSpacingValueInput.text hasPrefix:@"-"])
    {
        self.topSpacingValueInput.text = [self.topSpacingValueInput.text substringFromIndex:1];
    }
    else
    {
        self.topSpacingValueInput.text = [NSString stringWithFormat:@"-%@",self.topSpacingValueInput.text];
    }
    [self topSpacingValueDidChange:self.topSpacingValueInput];
}
-(void)invertBottomSpacingValue
{
    if ([self.bottomSpacingValueInput.text hasPrefix:@"-"])
    {
        self.bottomSpacingValueInput.text = [self.bottomSpacingValueInput.text substringFromIndex:1];
    }
    else
    {
        self.bottomSpacingValueInput.text = [NSString stringWithFormat:@"-%@",self.bottomSpacingValueInput.text];
    }
    [self bottomSpacingValueDidChange:self.bottomSpacingValueInput];
}

- (HPControllerView *)scaleControlView 
{
    if (!_scaleControlView) 
    {

        NSString *x = @"";
        if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
        else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock";
        else x = @"Folder";
        _scaleControlView = [[HPControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

        _scaleControlView.topView = [
            [UIView alloc] initWithFrame: CGRectMake(LEFT_SCREEN_BUFFER * [[UIScreen mainScreen] bounds].size.width,
                                                    TOP_CONTAINER_TOP_ANCHOR * [[UIScreen mainScreen] bounds].size.height, 
                                                    [[UIScreen mainScreen] bounds].size.width, 
                                                    CONTAINER_HEIGHT * [[UIScreen mainScreen] bounds].size.height )];

        UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (0.706) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        [topLabel setText:@"Icon Scale:"];
        topLabel.textColor=[UIColor whiteColor];
        topLabel.textAlignment=NSTextAlignmentCenter;

        self.topScaleValueInput = [[UITextField alloc] initWithFrame:CGRectMake((0.730) * [[UIScreen mainScreen] bounds].size.width, (0.048) * [[UIScreen mainScreen] bounds].size.height, (0.1333) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height)];
        
        [self.topScaleValueInput addTarget:self
                action:@selector(topScaleValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];

        self.topScaleValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.topScaleValueInput.textColor = [UIColor whiteColor];

        UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];

        [keyboardToolbar sizeToFit];
        UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self.topScaleValueInput action:@selector(resignFirstResponder)];
        keyboardToolbar.items = @[flexBarButton, doneBarButton];
        self.topScaleValueInput.inputAccessoryView = keyboardToolbar;

        self.scaleSlider = [[OBSlider alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.7) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        [self.scaleSlider addTarget:self action:@selector(scaleSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scaleSlider setBackgroundColor:[UIColor clearColor]];
        self.scaleSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.scaleSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.scaleSlider.minimumValue = 1.0;
        self.scaleSlider.maximumValue = 100.0;
        self.scaleSlider.continuous = YES;
        self.scaleSlider.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Scale"]];
        [_scaleControlView addSubview:_scaleControlView.topView];
        [_scaleControlView.topView addSubview:topLabel];
        [_scaleControlView.topView addSubview:self.scaleSlider];
        self.topScaleValueInput.text = [NSString stringWithFormat:@"%.0f", self.scaleSlider.value];
        [_scaleControlView.topView addSubview:self.topScaleValueInput];


        BOOL _tcDockyInstalled = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/me.nepeta.docky.list"];
        BOOL excludeForDocky = (_tcDockyInstalled && [[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]);

        _scaleControlView.bottomView = [[UIView alloc] initWithFrame:CGRectMake((0.146) * [[UIScreen mainScreen] bounds].size.width, (0.862) * [[UIScreen mainScreen] bounds].size.height, (1) * [[UIScreen mainScreen] bounds].size.width, (0.123) * [[UIScreen mainScreen] bounds].size.height)];

        UILabel *sideLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, (0.706) * [[UIScreen mainScreen] bounds].size.width, 50)];
        if (!excludeForDocky)
        {
             [sideLabel setText:@""];
        }
        else 
        {
            [sideLabel setText:@"Docky Compatibility Mode Enabled \n Most of the dock configuration is now disabled"];
            [sideLabel setFont:[UIFont systemFontOfSize:12]];
            sideLabel.numberOfLines = 2;
        }
        sideLabel.textColor=[UIColor whiteColor];
        sideLabel.textAlignment=NSTextAlignmentCenter;
        [_scaleControlView.bottomView addSubview:sideLabel];
        [_scaleControlView addSubview:_scaleControlView.bottomView];

    }
    return _scaleControlView;
}
- (void)bottomScaleEditingStarted 
{   
    //[self.bottomScaleValueInput becomeFirstResponder];
    CGAffineTransform transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:0.4 
    animations:
    ^{
        self.view.transform = CGAffineTransformTranslate(transform, 0, (0-([[UIScreen mainScreen] bounds].size.height * 0.5)));
    }]; 
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusKickWindowsUp" object:nil];
    self.viewKickedUp = YES;
}
- (void)bottomScaleEditingEnded
{
    [self.bottomScaleValueInput resignFirstResponder];
    [UIView animateWithDuration:0.4 
        animations:
        ^{  
            self.view.transform = CGAffineTransformIdentity;   
        }
        completion:^(BOOL finished) 
        {    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusKickWindowsBack" object:nil];
            [UIView animateWithDuration:0.4 
                animations:
                ^{  
                    
                    [self.view setBackgroundColor:[UIColor clearColor]];  
                }
            ];
        }
    ]; 

    self.viewKickedUp = NO;
}

#pragma mark util
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
    if ([[[HPManager sharedManager] config] currentLoadoutColumnsForLocation:[[EditorManager sharedManager] editingLocation] pageIndex:0] == 4 && notched && (kCFCoreFoundationVersionNumber < 1600)) 
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
        self.topOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self topOffsetValueDidChange:self.topOffsetValueInput];
    }
    else if (self.activeButton == self.spacerButton)
    {
        CGFloat def = 0.0;
        self.topSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self topSpacingValueDidChange:self.topSpacingValueInput];
    }
    else if (self.activeButton == self.iconCountButton)
    {
        CGFloat def = 5.0;
        self.rowsSlider.value = def;
        [self rowsSliderChanged:self.rowsSlider];
    }
    else if (self.activeButton == self.scaleButton)
    {
        CGFloat def = 60.0;
        self.topScaleValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self topScaleValueDidChange:self.topScaleValueInput];
    }
}
- (void)handleBottomResetButtonPress:(UIButton*)sender 
{
    AudioServicesPlaySystemSound(1519);
    if (self.activeButton == self.offsetButton) 
    {
        CGFloat def = 0.0;
        self.bottomOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self bottomOffsetValueDidChange:self.bottomOffsetValueInput];
    }
    else if (self.activeButton == self.spacerButton)
    {
        CGFloat def = 0.0;
        self.bottomSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self bottomSpacingValueDidChange:self.bottomSpacingValueInput];
    }
    else if (self.activeButton == self.iconCountButton)
    {
        CGFloat def =  4.0;
        self.columnsSlider.value = def;
        [self columnsSliderChanged:self.columnsSlider];
    }
    else if (self.activeButton == self.scaleButton)
    {
        CGFloat def = 0.0;
        self.bottomScaleValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self bottomScaleValueDidChange:self.bottomScaleValueInput];
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
    [self bottomOffsetEditingEnded];
    [self bottomIconCountEditingEnded];
    [self bottomSpacingEditingEnded];
    [self.topIconCountValueInput resignFirstResponder];
    [self.topOffsetValueInput resignFirstResponder];
    [self.topSpacingValueInput resignFirstResponder];
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

#pragma mark Text Fields

- (void)topOffsetValueDidChange :(UITextField *) textField
{
    self.topOffsetSlider.value = [[textField text] floatValue];
    [self topOffsetSliderChanged:self.topOffsetSlider];
}
- (void)bottomOffsetValueDidChange:(UITextField *)textField
{
    self.sideOffsetSlider.value = [[textField text] floatValue];
    [self sideOffsetSliderChanged:self.sideOffsetSlider];
}
- (void)topScaleValueDidChange :(UITextField *) textField
{
    self.scaleSlider.value = [[textField text] floatValue];
    [self scaleSliderChanged:self.scaleSlider];
}
- (void)bottomScaleValueDidChange:(UITextField *)textField
{
    self.rotationSlider.value = [[textField text] floatValue];
    [self rotationSliderChanged:self.rotationSlider];
}
- (void)topSpacingValueDidChange:(UITextField *)textField
{
    self.verticalSpacingSlider.value = [[textField text] floatValue];
    [self verticalSpacingSliderChanged:self.verticalSpacingSlider];
}
- (void)bottomSpacingValueDidChange:(UITextField *)textField 
{
    self.horizontalSpacingSlider.value = [[textField text] floatValue];
    [self horizontalSpacingSliderChanged:self.horizontalSpacingSlider];
}
- (void)topIconCountValueDidChange:(UITextField *)textField
{
    self.rowsSlider.value = [[textField text] floatValue];
    [self rowsSliderChanged:self.rowsSlider];
}
- (void)bottomIconCountValueDidChange:(UITextField *)textField 
{
    self.columnsSlider.value = [[textField text] floatValue];
    [self columnsSliderChanged:self.columnsSlider];
}
# pragma mark Spacing Sliders

- (void)verticalSpacingSliderChanged:(OBSlider *)sender
{
    NSString *x = @"";
    if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
    else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock";
    else x = @"Folder";
    [[NSUserDefaults standardUserDefaults]  setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"VerticalSpacing"]];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }    
    self.topSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", sender.value];
}
- (void)horizontalSpacingSliderChanged:(OBSlider *)sender
{    
    NSString *x = @"";
    if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
    else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock";
    else x = @"Folder";
    [[NSUserDefaults standardUserDefaults]  setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"SideInset"]];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }
    self.bottomSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", sender.value];
}
- (void)topOffsetSliderChanged:(OBSlider *)sender
{
    NSString *x = @"";
    if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
    else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock"; 
    else x = @"Folder";
    [[NSUserDefaults standardUserDefaults]  setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"TopInset"]];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }    
    self.topOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", sender.value];
}
- (void)scaleSliderChanged:(OBSlider *)sender
{
    NSString *x = @"";
    if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
    else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock"; 
    else x = @"Folder";
    [[NSUserDefaults standardUserDefaults]  setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"Scale"]];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
        for (UIView *icon in [view allSubviews]) 
        {
            [icon layoutSubviews];
        }
    }
    self.topScaleValueInput.text = [NSString stringWithFormat:@"%.0f", sender.value];
}
- (void)rotationSliderChanged:(OBSlider *)sender
{
    NSString *x = @"";
    if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
    else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock"; 
    else x = @"Folder";
    [[NSUserDefaults standardUserDefaults]  setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"Rotation"]];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }    
    self.bottomScaleValueInput.text = [NSString stringWithFormat:@"%.0f", sender.value];
}
- (void)sideOffsetSliderChanged:(OBSlider *)sender
{
    NSString *x = @"";
    if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
    else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock"; 
    else x = @"Folder";
    [[NSUserDefaults standardUserDefaults]  setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"LeftInset"]];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }    
    self.bottomOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", sender.value];
}
- (void)rowPlus
{
    if (self.rowsSlider.value != kMaxRowAmount) self.rowsSlider.value = self.rowsSlider.value + 1.0;
    [self rowsSliderChanged:self.rowsSlider];
}
- (void)rowMinus
{
    if (self.rowsSlider.value != 1.0) self.rowsSlider.value = self.rowsSlider.value - 1.0;
    [self rowsSliderChanged:self.rowsSlider];
}
- (void)rowsSliderChanged:(OBSlider *)sender
{
    AudioServicesPlaySystemSound(1519);
    if ([self.topIconCountValueInput.text isEqual:[NSString stringWithFormat:@"%.0f", (CGFloat)((NSInteger)(floor([sender value])))]]) return;
    
    NSString *x = @"";
    if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
    else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock"; 
    else x = @"Folder";
    [[NSUserDefaults standardUserDefaults]  setInteger:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"Rows"]];

    [[NSNotificationCenter defaultCenter] postNotificationName:kGetUpdatedValues object:nil];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        // Animation code credit to Cuboid authors
        [UIView animateWithDuration:(0.15) delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [view layoutIconsNow];
        } completion:NULL];
    }    

    [[NSNotificationCenter defaultCenter] postNotificationName:@"HPResetIconViews" object:nil];
    if ([[HPManager sharedManager] vRowUpdates])
    {
        self.activeButton = self.spacerButton;
        [self handleTopResetButtonPress:self.topResetButton];
        self.activeButton = self.iconCountButton;
    }
    
    self.topIconCountValueInput.text = [NSString stringWithFormat:@"%.0f", (CGFloat)((NSInteger)(floor([sender value])))];
}
- (void)columnPlus
{
    if (self.columnsSlider.value != kMaxColumnAmount) self.columnsSlider.value = self.columnsSlider.value + 1.0;
    [self columnsSliderChanged:self.columnsSlider];
}
- (void)columnMinus
{
    if (self.columnsSlider.value != 1.0) self.columnsSlider.value = self.columnsSlider.value - 1.0;
    [self columnsSliderChanged:self.columnsSlider];
}
- (void)columnsSliderChanged:(OBSlider *)sender
{   
    AudioServicesPlaySystemSound(1519);
    if ([self.bottomIconCountValueInput.text isEqual:[NSString stringWithFormat:@"%.0f", (CGFloat)((NSInteger)(floor([sender value])))]]) return;
    
    NSString *x = @"";
    if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
    else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock"; 
    else x = @"Folder";
    [[NSUserDefaults standardUserDefaults]  setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"Columns"]];

    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        // Animation code credit to cuboid authors
        [UIView animateWithDuration:(0.15) delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [view layoutIconsNow];
        } completion:NULL];
    }    
    self.bottomIconCountValueInput.text = [NSString stringWithFormat:@"%.0f", (CGFloat)((NSInteger)(floor([sender value])))];
}

#pragma mark UIViewController overrides

- (BOOL)shouldAutorotate 
{
    return NO;
}


@end
