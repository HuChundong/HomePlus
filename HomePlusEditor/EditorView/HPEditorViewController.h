#import <UIKit/UIKit.h>
#import "HomePlus.h"
#import "OBSlider.h"
#import "HPControllerView.h"
#import "HPSettingsTableViewController.h"
#import "HPEditorViewNavigationTabBar.h"

@protocol HPEditorViewControllerDelegate;


@interface HPEditorViewController : UIViewController 

@property (nonatomic, strong) id <HPEditorViewControllerDelegate> delegate;

@property (nonatomic, readonly, strong) HPControllerView *offsetControlView;
@property (nonatomic, readonly, strong) HPControllerView *spacingControlView;
@property (nonatomic, readonly, strong) HPControllerView *iconCountControlView;
@property (nonatomic, readonly, strong) HPControllerView *scaleControlView;
@property (nonatomic, readonly, strong) HPControllerView *settingsView;

@property (nonatomic, readonly, strong) HPEditorViewNavigationTabBar *tabBar;
@property (nonatomic, readonly, strong) HPSettingsTableViewController *tableViewController;

@property (nonatomic, retain) NSMutableArray *rootIconListViewsToUpdate;


- (void)reload;
- (void)resetAllValuesToDefaults;
- (void)addRootIconListViewToUpdate:(SBRootIconListView *)view;
- (void)handleDoneSettingsButtonPress:(UIButton*)sender;
- (void)layoutAllSpringboardIcons;
-(void)transitionViewsToActivationPercentage:(CGFloat)amount;
-(void)transitionViewsToActivationPercentage:(CGFloat)amount withDuration:(CGFloat)duration ;
@end

@protocol HPEditorViewControllerDelegate <NSObject>

- (void)editorViewControllerDidFinish:(HPEditorViewController *)editorViewController;

@end