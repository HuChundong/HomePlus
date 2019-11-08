@interface SBIconModel : NSObject 
-(void)layout;
@end
@interface SBIconListModel : NSObject
@property (nonatomic, assign) NSUInteger maxNumberOfIcons;
@end
@interface SBIconViewMap : NSObject
@property (nonatomic, retain) SBIconModel *iconModel;
@end


@interface SBEditingDoneButton : UIButton
@end

@interface SBRootFolderView
@property (nonatomic, retain) SBEditingDoneButton *doneButton;
-(void)resetIconListViews;
@end

@interface SBRootFolderController
-(void)doneButtonTriggered:(id)button; 
@property (nonatomic, retain) SBIconViewMap *iconViewMap;
@property (nonatomic, retain) SBRootFolderView *contentView;
@end
@interface SBRootIconListView : UIView
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
-(void)layoutIconsNow;
-(CGFloat)sideIconInset;
- (CGFloat)verticalIconPadding;
-(CGFloat)topIconInset;
- (CGSize)defaultIconSize;
- (void)updateRC;
@property (nonatomic, retain) NSArray *allSubviews;
@property (nonatomic, retain) SBIconViewMap *viewMap;
@property (nonatomic, retain) SBIconListModel *model;
- (NSUInteger)iconRowsForSpacingCalculation;
+ (NSUInteger)maxIcons;
- (SBRootFolderController *)_viewControllerForAncestor;
@end

@interface HPHitboxView : UIView 
@end 

@interface HPTouchKillerHitboxView : HPHitboxView 
@end 

@interface HPHitboxWindow : UIWindow 
@end 

@interface FBSystemGestureView : UIView
-(void)createTopLeftHitboxView;
-(void)createFullScreenDragUpView;
@property (nonatomic, retain) HPHitboxView *hp_hitbox;
@property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;
@end

@interface SBHomeScreenWindow : UIView
-(void)createManagers;
@property (nonatomic, retain) HPHitboxView *hp_hitbox;
@property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;
@end

@interface SpringBoard : UIApplication
-(BOOL)isShowingHomescreen;
@end

@interface _SBWallpaperWindow : UIView 
@end

@interface SBMainScreenActiveInterfaceOrientationWindow : UIView
@end

@interface SBIconView : UIView
@property (nonatomic, retain) UIView *labelView;
@property (nonatomic, assign) CGFloat iconAccessoryAlpha;
-(void)setLabelAccessoryViewHidden:(BOOL)arg;
-(NSInteger)location;
@end

@interface SBIconLabelImageParameters : NSObject
@property(readonly, nonatomic) long long iconLocation; 
@end

@interface SBIconLabelImage : UIImage
@property(readonly, copy, nonatomic) SBIconLabelImageParameters *parameters; 
@end

@interface SBIconLegibilityLabelView : UIView
@property(retain, nonatomic) UIImage *image;
@end