
@interface SBRootIconListView : UIView
@property (nonatomic, assign) CGFloat customTopInset;
@property (nonatomic, assign) CGFloat customLeftOffset;
@property (nonatomic, assign) CGFloat customSideInset;
@property (nonatomic, assign) CGFloat customVerticalSpacing;
-(void)updateTopInset:(CGFloat)arg1;
-(void)updateSideInset:(CGFloat)arg1;

-(void)resetValuesToDefaults;
-(void)updateVerticalSpacing:(CGFloat)arg1;
-(void)updateLeftOffset:(CGFloat)arg1;
-(void)recieveNotification:(NSNotification *)notification;
-(void)layoutIconsNow;
// ext
-(CGFloat)sideIconInset;
-(CGFloat)topIconInset;
@end


@interface HPHitboxView : UIView 

@end 


@interface HPHitboxWindow : UIWindow 

@end 

@interface SBHomeScreenWindow : UIView
-(void)createEditorView;
@property (nonatomic, retain) HPHitboxView *hp_hitbox;
@property (nonatomic, retain) HPHitboxWindow *hp_hitbox_window;
@end

@interface _SBWallpaperWindow : UIView 
@end
