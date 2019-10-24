#import <UIKit/UIKit.h>
#import "HomePlus.h"
#import "OBSlider.h"
#import "HPSettingsTableViewController.h"
#import "HPEditorViewNavigationTabBar.h"

@interface HPControllerView : UIView
@property (nonatomic, retain) UIView *topView;
@property (nonatomic, retain) UIView *bottomView;
@end



@protocol HPEditorViewControllerDelegate;

@interface HPEditorViewController : UIViewController {
    IBOutlet OBSlider *topOffsetSlider;
    IBOutlet OBSlider *sideOffsetSlider;
    IBOutlet OBSlider *horizontalSpacingSlider;
    IBOutlet OBSlider *verticalSpacingSlider;
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


@property (nonatomic, readonly, strong) HPControllerView *settingsView;
@property (nonatomic, readonly, strong) UIView *tapBackView;
@property (nonatomic, readonly, strong) HPEditorViewNavigationTabBar *tabBar;

@property (nonatomic, retain) NSMutableArray *rootIconListViewsToUpdate;

-(void)resetAllValuesToDefaults;
-(void)addRootIconListViewToUpdate:(SBRootIconListView *)view;

@end

@protocol HPEditorViewControllerDelegate <NSObject>

- (void)editorViewControllerDidFinish:(HPEditorViewController *)editorViewController;


@end