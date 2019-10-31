@interface HPManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) NSString *currentLoadout;

@property (nonatomic, assign) NSInteger currentColumns;
@property (nonatomic, assign) NSInteger currentRows;
@property (nonatomic, assign) CGFloat currentTopInset;
@property (nonatomic, assign) CGFloat currentLeftInset;
@property (nonatomic, assign) CGFloat currentVSpacing;
@property (nonatomic, assign) CGFloat currentHSpacing;

@property (nonatomic, assign) BOOL currentShouldShowIconLabels;

-(void)loadSavedCurrentLoadoutName;
-(void)saveCurrentLoadoutName;
-(void)saveLoadout:(NSString *)name;
-(void)saveCurrentLoadout;
-(void)loadLoadout:(NSString *)name;
-(BOOL)currentLoadoutShouldShowIconLabels;
-(NSUInteger)currentLoadoutColumns;
-(NSUInteger)currentLoadoutRows;
-(CGFloat)currentLoadoutTopInset;
-(CGFloat)currentLoadoutLeftInset;
-(CGFloat)currentLoadoutVerticalSpacing;
-(CGFloat)currentLoadoutHorizontalSpacing;
-(void)setCurrentLoadoutShouldShowIconLabels:(BOOL)arg;
-(void)setCurrentLoadoutColumns:(NSInteger)arg;
-(void)setCurrentLoadoutRows:(NSInteger)arg;
-(void)setCurrentLoadoutTopInset:(CGFloat)arg;
-(void)setCurrentLoadoutLeftInset:(CGFloat)arg;
-(void)setCurrentLoadoutVerticalSpacing:(CGFloat)arg;
-(void)setCurrentLoadoutHorizontalSpacing:(CGFloat)arg;

@end