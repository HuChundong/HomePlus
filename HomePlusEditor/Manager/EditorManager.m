//
// EditorManager.m
// HomePlus
//
// Manager for the Editor Views. Creates the editor and hides/shows it
//
// Created Oct 2019
// Author: Kritanta
//


#include "EditorManager.h"
#include "HPEditorWindow.h"
#include "HPEditorViewController.h"

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
@property (nonatomic, retain) UIButton *settingsDoneButton;

@end


@interface EditorManager () <HPEditorViewControllerDelegate>

@property (nonatomic, readwrite, strong) HPEditorViewController *editorViewController;
@property (nonatomic, readwrite, strong) HPEditorWindow *editorView;

@end

@implementation EditorManager 

+ (instancetype)sharedManager
{
    static EditorManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (HPEditorWindow *)editorView 
{
    if (!_editorView) 
    {
        _editorView = [[HPEditorWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        _editorView.rootViewController = self.editorViewController;
    }
    return _editorView;
}

- (HPEditorViewController *)editorViewController 
{
    if (!_editorViewController) 
    {
        _editorViewController = [[HPEditorViewController alloc] init];
        _editorViewController.delegate = self;
    }

    return _editorViewController;
}

- (void)showEditorView 
{
    [self editorViewController];
    [self editorView];
    _editorView.alpha = 0;
    _editorView.hidden = NO;
    [UIView animateWithDuration:.2 
        animations:
        ^{
            _editorView.alpha = 1;
        }
    ];
}

- (void)hideEditorView
{
    [_editorViewController handleDoneSettingsButtonPress:_editorViewController.settingsDoneButton];
    _editorView.hidden = YES;
}

- (void)toggleEditorView
{
    if (_editorView.hidden) 
    {
        [self showEditorView];
    } 
    else 
    {
        [self hideEditorView];
    }
}

- (void)resetAllValuesToDefaults 
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusEditingModeDisabled" object:nil];
    [self hideEditorView];
    NSMutableArray *views = _editorViewController.rootIconListViewsToUpdate;
    _editorView = nil;
    _editorViewController = nil;
    _editorViewController = [[HPEditorViewController alloc] init];
    _editorViewController.delegate = self;
    _editorView = [[HPEditorWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _editorView.rootViewController = self.editorViewController;
    [[self editorViewController] resetAllValuesToDefaults];

    for (SBRootIconListView *view in views) 
    {
        [view resetValuesToDefaults];
    }
}

- (void)editorViewControllerDidFinish:(HPEditorViewController *)editorViewController 
{

}
@end

