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
#include "../../HomePlus.h"
#include "../Manager/EditorManager.h"
#include "../Manager/HPManager.h"
#include "../Utility/HPUtilities.h"
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
@property (nonatomic, readwrite, strong) HPControllerView *settingsView;
@property (nonatomic, readwrite, strong) HPEditorViewNavigationTabBar *tabBar;

@property (nonatomic, readwrite, strong) HPSettingsTableViewController *tableViewController;


@property (nonatomic, readwrite, strong) UIView *tapBackView;

@property (nonatomic, retain) HPControllerView *activeView;
@property (nonatomic, retain) UIButton *activeButton;

@property (nonatomic, retain) UIButton *offsetButton;
@property (nonatomic, retain) UIButton *spacerButton;
@property (nonatomic, retain) UIButton *iconCountButton;
@property (nonatomic, retain) UIButton *settingsButton;
@property (nonatomic, retain) UIButton *topResetButton;
@property (nonatomic, retain) UIButton *bottomResetButton;
@property (nonatomic, retain) UIButton *settingsDoneButton;

@end


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

    [self.view addSubview:[self offsetControlView]];
    [self.view addSubview:[self spacingControlView]];
    [self.view addSubview:[self iconCountControlView]];
    [self.view addSubview:[self settingsView]];
    [self loadControllerView:[self offsetControlView]];
    [self spacingControlView].alpha = 0;
    [self iconCountControlView].alpha = 0;
    [self settingsView].alpha = 0;

    self.offsetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.offsetButton addTarget:self 
            action:@selector(handleOffsetButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.offsetButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *offsetImage = [HPUtilities offsetImage];
    [self.offsetButton setImage:offsetImage forState:UIControlStateNormal];
    self.offsetButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 47.5, (0.197) * [[UIScreen mainScreen] bounds].size.height, 40.0, 40.0);
    [self.view addSubview:self.offsetButton];

    self.spacerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.spacerButton addTarget:self 
            action:@selector(handleSpacerButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.spacerButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *spacerImage = [HPUtilities spacerImage];
    [self.spacerButton setImage:spacerImage forState:UIControlStateNormal];
    self.spacerButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 47.5,((0.197) * [[UIScreen mainScreen] bounds].size.height) + 40, 40.0, 40.0);
    self.spacerButton.alpha = 0.7;
    [self.view addSubview:self.spacerButton];


    self.iconCountButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.iconCountButton addTarget:self 
            action:@selector(handleIconCountButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.iconCountButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *iCImage = [HPUtilities iconCountImage];
    [self.iconCountButton setImage:iCImage forState:UIControlStateNormal];
    self.iconCountButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 47.5,((0.197) * [[UIScreen mainScreen] bounds].size.height) + 80, 40.0, 40.0);
    self.iconCountButton.alpha = 0.7;
    [self.view addSubview:self.iconCountButton];

    self.settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.settingsButton addTarget:self 
            action:@selector(handleSettingsButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.settingsButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *settingsImage = [HPUtilities settingsImage];
    [self.settingsButton setImage:settingsImage forState:UIControlStateNormal];
    self.settingsButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 47.5,((0.197) * [[UIScreen mainScreen] bounds].size.height) + 120, 40.0, 40.0);
    self.settingsButton.alpha = 0.7;
    [self.view addSubview:self.settingsButton];

    self.topResetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.topResetButton addTarget:self 
            action:@selector(handleTopResetButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.topResetButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    UIImage *rsImage = [HPUtilities resetImage];
    [self.topResetButton setImage:rsImage forState:UIControlStateNormal];
    self.topResetButton.frame = CGRectMake(20,(0.036) * [[UIScreen mainScreen] bounds].size.height + 40, 25.0, 25.0);
    self.topResetButton.alpha = 1;
    [self.view addSubview:self.topResetButton];

    self.bottomResetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.bottomResetButton addTarget:self 
            action:@selector(handleBottomResetButtonPress:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.bottomResetButton addTarget:self
            action:@selector(buttonPressDown:)
            forControlEvents:UIControlEventTouchDown];
    [self.bottomResetButton setImage:rsImage forState:UIControlStateNormal];
    self.bottomResetButton.frame = CGRectMake(20,(0.862) * [[UIScreen mainScreen] bounds].size.height + 40, 25.0, 25.0);
    self.bottomResetButton.alpha = 1;
    [self.view addSubview:self.bottomResetButton];


    [self.view addSubview:[self tapBackView]];
    self.tapBackView.hidden = NO;
    
    self.activeButton = self.offsetButton;

}
- (void)buttonPressDown:(UIButton*)sender
{
    // AudioServicesPlaySystemSound(1519);
}
- (void)handleSettingsButtonPress:(UIButton*)sender
{
    [[HPManager sharedManager] loadCurrentLoadout];
    [self loadControllerView:[self settingsView]];
    self.activeButton.userInteractionEnabled = YES; 

    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.settingsButton.alpha = 0;
            self.spacerButton.alpha = 0;
            self.offsetButton.alpha = 0;
            self.iconCountButton.alpha = 0;
            self.topResetButton.alpha = 0;
            self.bottomResetButton.alpha = 0;
        }
    ];
    [[self tableViewController] opened];

    self.activeButton = sender;
    self.tapBackView.hidden = YES;
}
- (void)handleDoneSettingsButtonPress:(UIButton*)sender
{

    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }

    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.settingsButton.alpha = 0.7;
            self.spacerButton.alpha = 0.7;
            self.iconCountButton.alpha = 0.7;
            self.offsetButton.alpha = 1;
            self.topResetButton.alpha = 1;
            self.bottomResetButton.alpha = 1;
        }
    ];

    self.tapBackView.hidden = NO;

    [self handleOffsetButtonPress:self.offsetButton];
}
- (void)handleOffsetButtonPress:(UIButton*)sender 
{
    [self loadControllerView:[self offsetControlView]];

    self.activeButton.userInteractionEnabled = YES; 
    [UIView animateWithDuration:.2 
        animations:
        ^{
            sender.alpha = 1;
        }
    ];
    self.activeButton = sender; 
    sender.userInteractionEnabled = NO; 
    self.tapBackView.hidden = NO;
}

- (void)handleTopResetButtonPress:(UIButton*)sender 
{
    if (self.activeButton == self.offsetButton) 
    {
        CGFloat def = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultTopInset"] ?: 0.0;
        self.topOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self topOffsetValueDidChange:self.topOffsetValueInput];
    }
    else if (self.activeButton == self.spacerButton)
    {
        CGFloat def = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultVSpacing"] ?: 0.0;
        self.topSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self topSpacingValueDidChange:self.topSpacingValueInput];
    }
    else if (self.activeButton == self.iconCountButton)
    {
        CGFloat def = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultRows"] ?: 6.0;
        self.topIconCountValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self topIconCountValueDidChange:self.topIconCountValueInput];
    }
}
- (void)handleBottomResetButtonPress:(UIButton*)sender 
{

    if (self.activeButton == self.offsetButton) 
    {
        CGFloat def = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultLeftInset"] ?: 0.0;
        self.bottomOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self bottomOffsetValueDidChange:self.bottomOffsetValueInput];
    }
    else if (self.activeButton == self.spacerButton)
    {
        CGFloat def = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultHSpacing"] ?: 0.0;
        self.bottomSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self bottomSpacingValueDidChange:self.bottomSpacingValueInput];
    }
    else if (self.activeButton == self.iconCountButton)
    {
        CGFloat def = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultColumns"] ?: 6.0;
        self.bottomIconCountValueInput.text = [NSString stringWithFormat:@"%.0f", def];
        [self bottomIconCountValueDidChange:self.bottomIconCountValueInput];
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
        }
    ];
    self.activeButton = sender;
    sender.userInteractionEnabled = NO; 
    self.tapBackView.hidden = NO;
}
- (void)loadControllerView:(HPControllerView *)arg1 
{
    self.activeButton.alpha = 0.7;
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
- (UIView *)tapBackView 
{
    if (!_tapBackView) 
    {
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

    [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _spacingControlView = nil;
    _offsetControlView = nil;
    _settingsView = nil;
    [self viewDidLoad];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusEditingModeDisabled" object:nil];
    [[EditorManager sharedManager] hideEditorView];
}
#pragma mark HPControllerViews

- (HPControllerView *)settingsView {
    if (!_settingsView) 
    {
        _settingsView = [[HPControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        UIView *settingsContainerView = self.tableViewController.view;
        _settingsView.topView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [_settingsView.topView addSubview:settingsContainerView];
        [_settingsView addSubview:_settingsView.topView];

        UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0,0,[[UIScreen mainScreen] bounds].size.width,(0.458*[[UIScreen mainScreen] bounds].size.width))];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width,(0.458*[[UIScreen mainScreen] bounds].size.width))];
        imageView.image = [HPUtilities inAppBanner];
        [tableHeaderView addSubview:imageView];

        UIView *doneButtonContainerView = [[UIView alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width-80, (0.458*[[UIScreen mainScreen] bounds].size.width)-40, [[UIScreen mainScreen] bounds].size.width/2, 40)];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self 
                action:@selector(handleDoneSettingsButtonPress:)
        forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"Done" forState:UIControlStateNormal];
        button.frame = CGRectMake(0, 0,80, 40);
        [doneButtonContainerView addSubview:button];
        _settingsView.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0,0,[[UIScreen mainScreen] bounds].size.width,(0.458*[[UIScreen mainScreen] bounds].size.width))];
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
- (HPControllerView *)offsetControlView 
{
    if (!_offsetControlView) 
    {
        _offsetControlView = [[HPControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

        _offsetControlView.topView = [[UIView alloc] initWithFrame:
                CGRectMake((.146 * [[UIScreen mainScreen] bounds].size.width), (0.036) * [[UIScreen mainScreen] bounds].size.height, (.706 * [[UIScreen mainScreen] bounds].size.width), (0.123 * [[UIScreen mainScreen] bounds].size.height))];

        UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (0.706) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        [topLabel setText:@"Top Offset: "];
        topLabel.textColor=[UIColor whiteColor];
        topLabel.textAlignment=NSTextAlignmentCenter;

        self.topOffsetValueInput = [[UITextField alloc] initWithFrame:CGRectMake((0.613) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.1333) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height)];
        [self.topOffsetValueInput addTarget:self
                action:@selector(topOffsetValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];
        self.topOffsetValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.topOffsetValueInput.textColor = [UIColor whiteColor];

        UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];

        [keyboardToolbar sizeToFit];
        UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self.topOffsetValueInput action:@selector(resignFirstResponder)];
        keyboardToolbar.items = @[flexBarButton, doneBarButton];
        self.topOffsetValueInput.inputAccessoryView = keyboardToolbar;

        self.topOffsetSlider = [[OBSlider alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.586) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        [self.topOffsetSlider addTarget:self action:@selector(topOffsetSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.topOffsetSlider setBackgroundColor:[UIColor clearColor]];
        self.topOffsetSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.topOffsetSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.topOffsetSlider.minimumValue = 0.0;
        self.topOffsetSlider.maximumValue = [[UIScreen mainScreen] bounds].size.height;
        self.topOffsetSlider.continuous = YES;
        self.topOffsetSlider.value = [[HPManager sharedManager] currentLoadoutTopInset];
        [_offsetControlView addSubview:_offsetControlView.topView];
        [_offsetControlView.topView addSubview:topLabel];
        [_offsetControlView.topView addSubview:self.topOffsetSlider];
        self.topOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", self.topOffsetSlider.value];
        [_offsetControlView.topView addSubview:topOffsetValueInput];


        _offsetControlView.bottomView = [[UIView alloc] initWithFrame:CGRectMake((0.146) * [[UIScreen mainScreen] bounds].size.width, (0.862) * [[UIScreen mainScreen] bounds].size.height, (0.706) * [[UIScreen mainScreen] bounds].size.width, (0.123) * [[UIScreen mainScreen] bounds].size.height)];

        UILabel *sideLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (0.706) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [sideLabel setText:@"Left Offset"];
        sideLabel.textColor=[UIColor whiteColor];
        sideLabel.textAlignment=NSTextAlignmentCenter;


        self.bottomOffsetValueInput = [[UITextField alloc] initWithFrame:CGRectMake((0.613) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height, 50, 30)];
        [self.bottomOffsetValueInput addTarget:self
                action:@selector(bottomOffsetValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];
        self.bottomOffsetValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.bottomOffsetValueInput.textColor = [UIColor whiteColor];

        UIToolbar* bkeyboardToolbar = [[UIToolbar alloc] init];

        [bkeyboardToolbar sizeToFit];
        UIBarButtonItem *bflexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *bdoneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self.bottomOffsetValueInput action:@selector(resignFirstResponder)];
        bkeyboardToolbar.items = @[bflexBarButton, bdoneBarButton];
        self.bottomOffsetValueInput.inputAccessoryView = bkeyboardToolbar;


        self.sideOffsetSlider = [[OBSlider alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.586) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [self.sideOffsetSlider addTarget:self action:@selector(sideOffsetSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.sideOffsetSlider setBackgroundColor:[UIColor clearColor]];
        self.sideOffsetSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.sideOffsetSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.sideOffsetSlider.minimumValue = -400.0;
        self.sideOffsetSlider.maximumValue = 400.0;
        self.sideOffsetSlider.continuous = YES;
        self.sideOffsetSlider.value = [[HPManager sharedManager] currentLoadoutLeftInset];
        [_offsetControlView addSubview:_offsetControlView.bottomView];
        [_offsetControlView.bottomView addSubview:sideLabel];
        [_offsetControlView.bottomView addSubview:self.sideOffsetSlider];
        self.bottomOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", self.sideOffsetSlider.value];
        [_offsetControlView.bottomView addSubview:self.bottomOffsetValueInput];

        // note
        UILabel *sideULabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height + 30, (0.706) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [sideULabel setText:@"Set to 0 to enable auto-centered\n Horizontal Spacing"];
        [sideULabel setFont:[UIFont systemFontOfSize:11]];
        sideULabel.numberOfLines = 2;
        sideULabel.textColor=[UIColor whiteColor];
        sideULabel.textAlignment=NSTextAlignmentCenter;
        [_offsetControlView.bottomView addSubview: sideULabel];
    }
    return _offsetControlView;
}

- (HPControllerView *)iconCountControlView
{
    if (!_iconCountControlView) 
    {
        _iconCountControlView = [[HPControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

        _iconCountControlView.topView =[[UIView alloc] initWithFrame:
                CGRectMake((.146 * [[UIScreen mainScreen] bounds].size.width), (0.036) * [[UIScreen mainScreen] bounds].size.height, (.706 * [[UIScreen mainScreen] bounds].size.width), (0.123 * [[UIScreen mainScreen] bounds].size.height))];

        UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (0.706) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        [topLabel setText:@"Rows: "];
        topLabel.textColor=[UIColor whiteColor];
        topLabel.textAlignment=NSTextAlignmentCenter;

        self.topIconCountValueInput =[[UITextField alloc] initWithFrame:CGRectMake((0.613) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.1333) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height)];
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

        self.rowsSlider = [[OBSlider alloc] initWithFrame:CGRectMake(0, 30, 220, 50)];
        [self.rowsSlider addTarget:self action:@selector(rowsSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.rowsSlider setBackgroundColor:[UIColor clearColor]];
        self.rowsSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.rowsSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.rowsSlider.minimumValue = 1;
        self.rowsSlider.maximumValue = 14;
        self.rowsSlider.continuous = YES;
        self.rowsSlider.value = (CGFloat)[[HPManager sharedManager] currentLoadoutRows];
        [_iconCountControlView addSubview:_iconCountControlView.topView];
        [_iconCountControlView.topView addSubview:topLabel];
        [_iconCountControlView.topView addSubview:self.rowsSlider];
        self.topIconCountValueInput.text = [NSString stringWithFormat:@"%.0f", self.rowsSlider.value];
        [_iconCountControlView.topView addSubview:self.topIconCountValueInput];


        _iconCountControlView.bottomView = [[UIView alloc] initWithFrame:CGRectMake((0.146) * [[UIScreen mainScreen] bounds].size.width, (0.862) * [[UIScreen mainScreen] bounds].size.height, (0.706) * [[UIScreen mainScreen] bounds].size.width, (0.123) * [[UIScreen mainScreen] bounds].size.height)];


        UILabel *sideLabel =  [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (0.706) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [sideLabel setText:@"Columns: "];
        sideLabel.textColor=[UIColor whiteColor];
        sideLabel.textAlignment=NSTextAlignmentCenter;


        self.bottomIconCountValueInput = [[UITextField alloc] initWithFrame:CGRectMake((0.613) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height, 50, 30)];
        [self.bottomIconCountValueInput addTarget:self
                action:@selector(bottomIconCountValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];
        self.bottomIconCountValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.bottomIconCountValueInput.textColor = [UIColor whiteColor];

        UIToolbar* bkeyboardToolbar = [[UIToolbar alloc] init];

        [bkeyboardToolbar sizeToFit];
        UIBarButtonItem *bflexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *bdoneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self.bottomIconCountValueInput action:@selector(resignFirstResponder)];
        bkeyboardToolbar.items = @[bflexBarButton, bdoneBarButton];
        self.bottomIconCountValueInput.inputAccessoryView = bkeyboardToolbar;

        self.columnsSlider =[[OBSlider alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.586) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [self.columnsSlider addTarget:self action:@selector(columnsSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.columnsSlider setBackgroundColor:[UIColor clearColor]];
        self.columnsSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.columnsSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.columnsSlider.minimumValue = 1.0;
        self.columnsSlider.maximumValue = 14.0;
        self.columnsSlider.continuous = YES;
        self.columnsSlider.value = (CGFloat)[[HPManager sharedManager] currentLoadoutColumns];
        [_iconCountControlView addSubview:_iconCountControlView.bottomView];
        self.bottomIconCountValueInput.text = [NSString stringWithFormat:@"%.0f", self.columnsSlider.value];
        [_iconCountControlView.bottomView addSubview:sideLabel];
        [_iconCountControlView.bottomView addSubview:self.columnsSlider];
        [_iconCountControlView.bottomView addSubview:self.bottomIconCountValueInput];
    }
    return _iconCountControlView;
}

- (HPControllerView *)spacingControlView
{
    if (!_spacingControlView) 
    {
        _spacingControlView = [[HPControllerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

        _spacingControlView.topView =[[UIView alloc] initWithFrame:
                CGRectMake((.146 * [[UIScreen mainScreen] bounds].size.width), (0.036) * [[UIScreen mainScreen] bounds].size.height, (.706 * [[UIScreen mainScreen] bounds].size.width), (0.123 * [[UIScreen mainScreen] bounds].size.height))];

        UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (0.706) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height)];
        [topLabel setText:@"Vertical Spacing: "];
        topLabel.textColor=[UIColor whiteColor];
        topLabel.textAlignment=NSTextAlignmentCenter;

        self.topSpacingValueInput =[[UITextField alloc] initWithFrame:CGRectMake((0.613) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.1333) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height)];
        [self.topSpacingValueInput addTarget:self
                action:@selector(topSpacingValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];
        self.topSpacingValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.topSpacingValueInput.textColor = [UIColor whiteColor];

        UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];

        [keyboardToolbar sizeToFit];
        UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self.topSpacingValueInput action:@selector(resignFirstResponder)];
        keyboardToolbar.items = @[flexBarButton, doneBarButton];
        self.topSpacingValueInput.inputAccessoryView = keyboardToolbar;

        self.verticalSpacingSlider = [[OBSlider alloc] initWithFrame:CGRectMake(0, 30, 220, 50)];
        [self.verticalSpacingSlider addTarget:self action:@selector(verticalSpacingSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.verticalSpacingSlider setBackgroundColor:[UIColor clearColor]];
        self.verticalSpacingSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.verticalSpacingSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.verticalSpacingSlider.minimumValue = -100.0;
        self.verticalSpacingSlider.maximumValue = 200.0;
        self.verticalSpacingSlider.continuous = YES;
        self.verticalSpacingSlider.value = [[HPManager sharedManager] currentLoadoutVerticalSpacing];
        [_spacingControlView addSubview:_spacingControlView.topView];
        [_spacingControlView.topView addSubview:topLabel];
        [_spacingControlView.topView addSubview:self.verticalSpacingSlider];
        self.topSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", self.verticalSpacingSlider.value];
        [_spacingControlView.topView addSubview:self.topSpacingValueInput];


        _spacingControlView.bottomView = [[UIView alloc] initWithFrame:CGRectMake((0.146) * [[UIScreen mainScreen] bounds].size.width, (0.862) * [[UIScreen mainScreen] bounds].size.height, (0.706) * [[UIScreen mainScreen] bounds].size.width, (0.123) * [[UIScreen mainScreen] bounds].size.height)];


        UILabel *sideLabel =  [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (0.706) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [sideLabel setText:@"Horizontal Spacing: "];
        sideLabel.textColor=[UIColor whiteColor];
        sideLabel.textAlignment=NSTextAlignmentCenter;


        self.bottomSpacingValueInput = [[UITextField alloc] initWithFrame:CGRectMake((0.613) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height, 50, 30)];
        [self.bottomSpacingValueInput addTarget:self
                action:@selector(bottomSpacingValueDidChange:)
                forControlEvents:UIControlEventEditingChanged];
        self.bottomSpacingValueInput.keyboardType = UIKeyboardTypeNumberPad;
        self.bottomSpacingValueInput.textColor = [UIColor whiteColor];

        UIToolbar* bkeyboardToolbar = [[UIToolbar alloc] init];

        [bkeyboardToolbar sizeToFit];
        UIBarButtonItem *bflexBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil action:nil];
        UIBarButtonItem *bdoneBarButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:self.bottomSpacingValueInput action:@selector(resignFirstResponder)];
        bkeyboardToolbar.items = @[bflexBarButton, bdoneBarButton];
        self.bottomSpacingValueInput.inputAccessoryView = bkeyboardToolbar;

        self.horizontalSpacingSlider =[[OBSlider alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height, (0.586) * [[UIScreen mainScreen] bounds].size.width, 50)];
        [self.horizontalSpacingSlider addTarget:self action:@selector(horizontalSpacingSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.horizontalSpacingSlider setBackgroundColor:[UIColor clearColor]];
        self.horizontalSpacingSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.horizontalSpacingSlider.minimumTrackTintColor = [UIColor colorWithWhite:1.0 alpha: 0.9];
        self.horizontalSpacingSlider.minimumValue = -100.0;
        self.horizontalSpacingSlider.maximumValue = 200.0;
        self.horizontalSpacingSlider.continuous = YES;
        self.horizontalSpacingSlider.value = [[HPManager sharedManager] currentLoadoutHorizontalSpacing];
        [_spacingControlView addSubview:_spacingControlView.bottomView];
        self.bottomSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", self.horizontalSpacingSlider.value];
        [_spacingControlView.bottomView addSubview:sideLabel];
        [_spacingControlView.bottomView addSubview:self.horizontalSpacingSlider];
        [_spacingControlView.bottomView addSubview:self.bottomSpacingValueInput];
    }
    return _spacingControlView;
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
    [[self.view subviews]
        makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _spacingControlView = nil;
    _offsetControlView = nil;
    _settingsView = nil;
    _iconCountControlView = nil;
    [self viewDidLoad];
    [[EditorManager sharedManager] hideEditorView];
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
    [[HPManager sharedManager] setCurrentLoadoutVerticalSpacing: [sender value]];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }    
    self.topSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", sender.value];
}
- (void)horizontalSpacingSliderChanged:(OBSlider *)sender
{
    [[HPManager sharedManager] setCurrentLoadoutHorizontalSpacing: [sender value]];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }
    self.bottomSpacingValueInput.text = [NSString stringWithFormat:@"%.0f", sender.value];
}
- (void)topOffsetSliderChanged:(OBSlider *)sender
{
    [[HPManager sharedManager] setCurrentLoadoutTopInset: [sender value]];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }    
    self.topOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", sender.value];
}
- (void)sideOffsetSliderChanged:(OBSlider *)sender
{
    [[HPManager sharedManager] setCurrentLoadoutLeftInset: [sender value]];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }    
    self.bottomOffsetValueInput.text = [NSString stringWithFormat:@"%.0f", sender.value];
}
- (void)rowsSliderChanged:(OBSlider *)sender
{
    [[HPManager sharedManager] setCurrentLoadoutRows: (NSInteger)(floor([sender value]))];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }    
    self.topIconCountValueInput.text = [NSString stringWithFormat:@"%.0f", (CGFloat)((NSInteger)(floor([sender value])))];
}
- (void)columnsSliderChanged:(OBSlider *)sender
{
    [[HPManager sharedManager] setCurrentLoadoutColumns: (NSInteger)(floor([sender value]))];
    for (SBRootIconListView *view in self.rootIconListViewsToUpdate) 
    {
        [view layoutIconsNow];
    }    
    self.bottomIconCountValueInput.text = [NSString stringWithFormat:@"%.0f", (CGFloat)((NSInteger)(floor([sender value])))];
}

#pragma mark UIControllerView overrides

- (BOOL)shouldAutorotate 
{
    return NO;
}


@end