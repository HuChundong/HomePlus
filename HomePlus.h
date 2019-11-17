#define kMaxColumnAmount 14
#define kMaxRowAmount 14


#define kUniqueLogIdentifier @"HPD"

#define kEditingModeChangedNotificationName @"HomePlusEditingModeChanged"
#define kEditingModeEnabledNotificationName @"HomePlusEditingModeEnabled"
#define kEditingModeDisabledNotificationName @"HomePlusEditingModeDisabled"
#define kEditorKickViewsUp @"HomePlusKickWindowsUp"
#define kEditorKickViewsBack @"HomePlusKickWindowsBack"
#define kDeviceIsLocked @"HomePlusDeviceIsLocked"
#define kDeviceIsUnlocked @"HomePlusDeviceIsUnlocked"
#define kWiggleActive @"HomePlusWiggleActive"
#define kWiggleInactive @"HomePlusWiggleInactive"
#define kDisableWiggleTrigger @"HomePlusDisableWiggle"
#define kHighlightViewNotificationName @"HomePlusHighlightRelevantView"
#define kFadeFloatingDockNotificationName @"HomePlusFadeFloatingDock"
#define kShowFloatingDockNotificationName @"HomePlusShowFloatingDock"
#define kReloadIconScaleNotificationName @"HomePlusReloadIconScale"
#define kGetUpdatedValues @"HomePlusUpdateValues"

#define kIdentifier @"me.kritanta.homeplusprefs"
#define kSettingsChangedNotification (CFStringRef)@"me.kritanta.homeplusprefs/settingschanged"
#define kSettingsPath @"/var/mobile/Library/Preferences/me.kritanta.homeplusprefs.plist"

@interface SBFloatyFolderScrollView : UIView 
@end 


@interface SBIconModel : NSObject 
- (void)layout;
@end
@interface SBIconListModel : NSObject
@property (nonatomic, assign) NSUInteger maxNumberOfIcons;
@end
@interface SBIconViewMap : NSObject
@property (nonatomic, retain) SBIconModel *iconModel;
@end


@interface SBIconListGridLayoutConfiguration
@property (nonatomic, assign) NSString *iconLocation;
@property (nonatomic, retain) NSDictionary *managerValues;
@property (nonatomic, assign) UIEdgeInsets customInsets;
-(void)getLatestValuesFromManager;
- (NSString *)locationIfKnown;
-(NSUInteger)numberOfPortraitColumns;
-(NSUInteger)numberOfPortraitRows;
-(UIEdgeInsets)portraitLayoutInsets;
@end

@interface SBIconListLayout : NSObject
- (SBIconListGridLayoutConfiguration *)layoutConfiguration;
@end
@interface SBIconListFlowLayout : SBIconListLayout
@end

@interface SBEditingDoneButton : UIButton
@end

@interface SBRootFolderView
@property (nonatomic, retain) SBEditingDoneButton *doneButton;
- (void)resetIconListViews;
@end

@interface SBRootFolderController
- (void)doneButtonTriggered:(id)button; 
@property (nonatomic, retain) SBIconViewMap *iconViewMap;
@property (nonatomic, retain) SBRootFolderView *contentView;
@end
@interface SBRootIconListView : UIView

@property (nonatomic, retain) NSDictionary *managerValues;
-(void)getLatestValuesFromManager;
-(NSString *)newIconLocation;
-(NSInteger)iconLocation;
- (CGFloat)horizontalIconPadding ;
@property (nonatomic, assign) CGFloat customTopInset;
@property (nonatomic, assign) CGFloat customLeftOffset;
@property (nonatomic, assign) CGFloat customSideInset;
@property (nonatomic, assign) CGFloat customVerticalSpacing;
@property (nonatomic, assign) CGFloat customRows;
@property (nonatomic, assign) CGFloat customColumns;
@property (nonatomic, assign) BOOL configured;
@property (nonatomic, assign) CGRect typicalFrame;
- (void)setIconsLabelAlpha:(double)arg1;
-(void)updateTopInset:(CGFloat)arg1;
-(void)updateSideInset:(CGFloat)arg1;
-(void)resetValuesToDefaults;
-(void)updateVerticalSpacing:(CGFloat)arg1;
-(void)updateLeftOffset:(CGFloat)arg1;
-(void)recieveNotification:(NSNotification *)notification;
-(void)updateCustomRows:(CGFloat)arg1;
-(void)updateCustomColumns:(CGFloat)arg1;
- (NSUInteger)iconRowsForHomePlusCalculations;
-(void)layoutIconsNow;
-(CGFloat)sideIconInset;
- (CGFloat)verticalIconPadding;
-(CGFloat)topIconInset;
- (CGSize)defaultIconSize;
-(void)setLayoutReversed:(BOOL)arg;
- (void)updateRC;
@property (nonatomic, retain) NSArray *allSubviews;
@property (nonatomic, retain) SBIconViewMap *viewMap;
@property (nonatomic, retain) SBIconListModel *model;
- (NSUInteger)iconRowsForSpacingCalculation;
+ (NSUInteger)maxIcons;
+ (NSUInteger)iconRowsForInterfaceOrientation:(NSInteger)arg1;
+ (NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1;
- (SBRootFolderController *)_viewControllerForAncestor;
@end
@interface SBIconListView : SBRootIconListView
- (NSString *)iconLocation;
@property(readonly, nonatomic) _Bool automaticallyAdjustsLayoutMetricsToFit;
- (NSArray *)getDefaultValues;
- (SBIconListFlowLayout *)layout;
@end

@interface HPHitboxView : UIView 
@end 

@interface HPTouchKillerHitboxView : HPHitboxView 
@end 

@interface HPHitboxWindow : UIWindow 
@end 

@interface FBSystemGestureView : UIView
- (void)createTopLeftHitboxView;
- (void)createFullScreenDragUpView;
@property (nonatomic, retain) HPHitboxView *hp_hitbox;
@property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;
@end

@interface UISystemGestureView : UIView
- (void)createTopLeftHitboxView;
- (void)createFullScreenDragUpView;
@property (nonatomic, retain) HPHitboxView *hp_hitbox;
@property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;
@end

@interface SBHomeScreenWindow : UIView
- (void)createManagers;
@property (nonatomic, retain) HPHitboxView *hp_hitbox;
@property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;
@end

@interface SpringBoard : UIApplication
- (BOOL)isShowingHomescreen;
@end

@interface _SBWallpaperWindow : UIView 
@end

@interface SBMainScreenActiveInterfaceOrientationWindow : UIView
@end

@interface SBIconView : UIView
@property (nonatomic, retain) UIView *labelView;
@property (nonatomic, assign) CGFloat iconAccessoryAlpha;
-(NSString *)newIconLocation;
- (void)setLabelAccessoryViewHidden:(BOOL)arg;
- (NSString *)location;
- (void)_applyIconLabelAlpha:(CGFloat)a;
@end

@interface SBIconLabelImageParameters : NSObject
@property(readonly, nonatomic) long long iconLocation; 
@end

@interface SBIconLabelImage : UIImage
@property(readonly, copy, nonatomic) SBIconLabelImageParameters *parameters; 
@end

@interface SBIconLegibilityLabelView : UIView
@property(retain, nonatomic) UIImage *image;
@property (retain, nonatomic) SBIconView *iconView;
@end

@interface SBIconBadgeView : UIView 
@property (nonatomic, retain) SBIconListLayout *listLayout;
@end