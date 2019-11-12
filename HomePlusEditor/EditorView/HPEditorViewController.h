#import <UIKit/UIKit.h>
#import "HomePlus.h"
#import "OBSlider.h"
#import "HPControllerView.h"
#import "HPSettingsTableViewController.h"
#import "HPEditorViewNavigationTabBar.h"

@protocol HPEditorViewControllerDelegate;


@interface HPEditorViewController : UIViewController 
{
    IBOutlet OBSlider *topOffsetSlider;
    IBOutlet OBSlider *sideOffsetSlider;
    IBOutlet OBSlider *horizontalSpacingSlider;
    IBOutlet OBSlider *verticalSpacingSlider;
    IBOutlet OBSlider *rowsSlider;
    IBOutlet OBSlider *columnsSlider;
    IBOutlet OBSlider *scaleSlider;
    IBOutlet OBSlider *rotationSlider;
}


@property (nonatomic, strong) id <HPEditorViewControllerDelegate> delegate;

@property (nonatomic, readonly, strong) HPControllerView *offsetControlView;

@property (nonatomic, retain) IBOutlet OBSlider *topOffsetSlider;
@property (nonatomic, retain) IBOutlet OBSlider *sideOffsetSlider;

@property (nonatomic, retain) UITextField *topOffsetValueInput;
@property (nonatomic, retain) UITextField *bottomOffsetValueInput;


@property (nonatomic, readonly, strong) HPControllerView *spacingControlView;

@property (nonatomic, retain) IBOutlet OBSlider *verticalSpacingSlider;
@property (nonatomic, retain) IBOutlet OBSlider *horizontalSpacingSlider;

@property (nonatomic, retain) UITextField *topSpacingValueInput;
@property (nonatomic, retain) UITextField *bottomSpacingValueInput;


@property (nonatomic, readonly, strong) HPControllerView *iconCountControlView;

@property (nonatomic, retain) IBOutlet OBSlider *rowsSlider;
@property (nonatomic, retain) IBOutlet OBSlider *columnsSlider;

@property (nonatomic, retain) UITextField *topIconCountValueInput;
@property (nonatomic, retain) UITextField *bottomIconCountValueInput;


@property (nonatomic, readonly, strong) HPControllerView *scaleControlView;

@property (nonatomic, retain) IBOutlet OBSlider *scaleSlider;
@property (nonatomic, retain) IBOutlet OBSlider *rotationSlider;

@property (nonatomic, retain) UITextField *topScaleValueInput;
@property (nonatomic, retain) UITextField *bottomScaleValueInput;


@property (nonatomic, readonly, strong) HPControllerView *settingsView;
@property (nonatomic, readonly, strong) UIView *tapBackView;
@property (nonatomic, readonly, strong) HPEditorViewNavigationTabBar *tabBar;
@property (nonatomic, readonly, strong) HPSettingsTableViewController *tableViewController;

@property (nonatomic, retain) NSMutableArray *rootIconListViewsToUpdate;

- (void)resetAllValuesToDefaults;
- (void)addRootIconListViewToUpdate:(SBRootIconListView *)view;
- (void)handleDoneSettingsButtonPress:(UIButton*)sender;

@end

@protocol HPEditorViewControllerDelegate <NSObject>

- (void)editorViewControllerDidFinish:(HPEditorViewController *)editorViewController;


@end