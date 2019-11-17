#import <UIKit/UIKit.h>
@interface HPManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, retain) NSString *currentLoadoutName;

@property (nonatomic, assign) BOOL currentLoadoutLoaded;
@property (nonatomic, retain) NSMutableDictionary *currentLoadoutData;

@property (nonatomic, assign) BOOL switcherDisables;
@property (nonatomic, assign) BOOL vRowUpdates;
@property (nonatomic, assign) BOOL resettingIconLayout;
@property (nonatomic, assign) BOOL pendingRespring;

@property (nonatomic, assign) BOOL currentShouldHideIconLabels;
@property (nonatomic, assign) BOOL currentShouldHideIconBadges;
@property (nonatomic, assign) BOOL currentShouldHideIconLabelsInFolders;

@property (nonatomic, assign) BOOL currentLoadoutModernDock;
@property (nonatomic, assign) BOOL currentLoadoutShouldHideDockBG;


- (BOOL)switcherDisables;
- (BOOL)resettingIconLayout;
- (void)loadSavedCurrentLoadoutName;
- (void)saveCurrentLoadoutName;
- (void)saveLoadout:(NSString *)name;
- (void)saveCurrentLoadout;
- (void)loadCurrentLoadout;
- (void)loadLoadout:(NSString *)name;
- (void)resetCurrentLoadoutToDefaults;
- (void)setSwitcherDisables:(BOOL)arg;
- (void)setResettingIconLayout:(BOOL)arg;


- (BOOL)currentLoadoutShouldHideIconLabelsForLocation:(NSString *)location;
- (BOOL)currentLoadoutShouldHideIconBadgesForLocation:(NSString *)location;

- (UIEdgeInsets)currentLoadoutInsetsForLocation:(NSString *)location pageIndex:(NSInteger)index withOriginal:(UIEdgeInsets)x;

- (NSUInteger)currentLoadoutColumnsForLocation:(NSString *)location pageIndex:(NSUInteger)index;

- (NSUInteger)currentLoadoutRowsForLocation:(NSString *)location pageIndex:(NSUInteger)index;

- (CGFloat)currentLoadoutTopInsetForLocation:(NSString *)location pageIndex:(NSUInteger)index;
- (CGFloat)currentLoadoutLeftInsetForLocation:(NSString *)location pageIndex:(NSUInteger)index;

- (CGFloat)currentLoadoutScaleForLocation:(NSString *)location pageIndex:(NSUInteger)index;

- (CGFloat)currentLoadoutRotationForLocation:(NSString *)location pageIndex:(NSUInteger)index;

- (CGFloat)currentLoadoutVerticalSpacingForLocation:(NSString *)location pageIndex:(NSUInteger)index;

- (CGFloat)currentLoadoutHorizontalSpacingForLocation:(NSString *)location pageIndex:(NSUInteger)index;
- (void)setCurrentLoadoutShouldHideIconLabels:(BOOL)arg forLocation:(NSString *)location;

- (void)setCurrentLoadoutShouldHideIconBadges:(BOOL)arg forLocation:(NSString *)location;

- (void)setCurrentLoadoutColumns:(NSInteger)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index;
- (void)setCurrentLoadoutRows:(NSInteger)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index;
- (void)setCurrentLoadoutScale:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index;

- (void)setCurrentLoadoutRotation:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index;
- (void)setCurrentLoadoutTopInset:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index;
- (void)setCurrentLoadoutLeftInset:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index;
- (void)setCurrentLoadoutVerticalSpacing:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index;
- (void)setCurrentLoadoutHorizontalSpacing:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index;

/* Legacy */


- (void)loadLoadoutFromLegacySystem:(NSString *)name;


@end