@interface HPManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) NSString *currentLoadout;

@property (nonatomic, assign) NSInteger currentColumns;
@property (nonatomic, assign) NSInteger currentRows;
@property (nonatomic, assign) CGFloat currentTopInset;
@property (nonatomic, assign) CGFloat currentLeftInset;
@property (nonatomic, assign) CGFloat currentVSpacing;
@property (nonatomic, assign) CGFloat currentHSpacing;

@property (nonatomic, assign) BOOL currentShouldHideIconLabels;
@property (nonatomic, assign) BOOL currentShouldHideIconBadges;
@property (nonatomic, assign) BOOL currentShouldHideIconLabelsInFolders;

- (void)loadSavedCurrentLoadoutName;
- (void)saveCurrentLoadoutName;
- (void)saveLoadout:(NSString *)name;
- (void)saveCurrentLoadout;
- (void)loadCurrentLoadout;
- (void)loadLoadout:(NSString *)name;
- (void)resetCurrentLoadoutToDefaults;
- (BOOL)currentLoadoutShouldHideIconLabels;
- (BOOL)currentLoadoutShouldHideIconBadges;
- (BOOL)currentLoadoutShouldHideIconLabelsInFolders;
- (NSUInteger)currentLoadoutColumns;
- (NSUInteger)currentLoadoutRows;
- (CGFloat)currentLoadoutTopInset;
- (CGFloat)currentLoadoutLeftInset;
- (CGFloat)currentLoadoutVerticalSpacing;
- (CGFloat)currentLoadoutHorizontalSpacing;
- (void)setCurrentLoadoutShouldHideIconLabels:(BOOL)arg;
- (void)setCurrentLoadoutShouldHideIconBadges:(BOOL)arg;
- (void)setCurrentLoadoutShouldHideIconLabelsInFolders:(BOOL)arg;
- (void)setCurrentLoadoutColumns:(NSInteger)arg;
- (void)setCurrentLoadoutRows:(NSInteger)arg;
- (void)setCurrentLoadoutTopInset:(CGFloat)arg;
- (void)setCurrentLoadoutLeftInset:(CGFloat)arg;
- (void)setCurrentLoadoutVerticalSpacing:(CGFloat)arg;
- (void)setCurrentLoadoutHorizontalSpacing:(CGFloat)arg;

@end