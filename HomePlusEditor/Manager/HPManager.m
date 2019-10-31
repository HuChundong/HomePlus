#include "HPManager.h"
@implementation HPManager
/*

@property (nonatomic, assign) NSUInteger currentColumns;
@property (nonatomic, assign) NSUInteger currentRows;
@property (nonatomic, assign) CGFloat currentTopInset;
@property (nonatomic, assign) CGFloat currentLeftInset;
@property (nonatomic, assign) CGFloat currentVSpacing;
@property (nonatomic, assign) CGFloat currentHSpacing;

*/


+(instancetype)sharedManager
{
    static HPManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

-(instancetype)init
{
    self = [super init];
    [self loadSavedCurrentLoadoutName];
    [self loadLoadout:self.currentLoadout];
    return self;
}
-(void)saveCurrentLoadoutName
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSUserDefaults standardUserDefaults] setObject:self.currentLoadout
                                               forKey:@"HPCurrentLoadout"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(void)loadSavedCurrentLoadoutName
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.currentLoadout = [[NSUserDefaults standardUserDefaults] stringForKey:@"HPCurrentLoadout"] ?: @"Default";
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(void)saveCurrentLoadout
{
    [self saveLoadout:self.currentLoadout];
}
-(void)saveLoadout:(NSString *)name
{

    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", name];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    [userDefaults setBool:self.currentShouldShowIconLabels
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"] ];
    [userDefaults setFloat:self.currentTopInset
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"] ];
    [userDefaults setFloat:self.currentLeftInset
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"] ];
    [userDefaults setFloat:self.currentHSpacing
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"] ];
    [userDefaults setFloat:self.currentVSpacing
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"] ];
    [userDefaults setInteger:self.currentColumns
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"] ];
    [userDefaults setInteger:self.currentRows
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"] ];
    [userDefaults synchronize];
}
-(void)loadLoadout:(NSString *)name
{
    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", name];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.currentShouldShowIconLabels = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"]] ?: YES;
    self.currentTopInset = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"]] ?:0.0;
    self.currentLeftInset = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"]] ?:0.0;
    self.currentHSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"]] ?:0.0;
    self.currentVSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"]] ?:0.0;
    self.currentColumns = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"]] ?:4;
    self.currentRows = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"]] ?:6;
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(BOOL)currentLoadoutShouldShowIconLabels
{
    return self.currentShouldShowIconLabels;
}
-(NSUInteger)currentLoadoutColumns
{
    NSUInteger r;
    r = (NSUInteger)self.currentColumns;
    return r;
}
-(NSUInteger)currentLoadoutRows
{
    NSUInteger r;
    r = (NSUInteger)self.currentRows;
    return r;
}
-(CGFloat)currentLoadoutTopInset
{
    return self.currentTopInset;
}
-(CGFloat)currentLoadoutLeftInset
{
    return self.currentLeftInset;
}
-(CGFloat)currentLoadoutVerticalSpacing
{
    return self.currentVSpacing;
}
-(CGFloat)currentLoadoutHorizontalSpacing
{
    return self.currentHSpacing;
}
-(void)setCurrentLoadoutShouldShowIconLabels:(BOOL)arg
{
    self.currentShouldShowIconLabels = arg;
}
-(void)setCurrentLoadoutColumns:(NSInteger)arg
{
    self.currentColumns = arg;
}
-(void)setCurrentLoadoutRows:(NSInteger)arg
{
    self.currentRows = arg;
}
-(void)setCurrentLoadoutTopInset:(CGFloat)arg
{
    self.currentTopInset = arg;
}
-(void)setCurrentLoadoutLeftInset:(CGFloat)arg
{
    self.currentLeftInset = arg;
}
-(void)setCurrentLoadoutVerticalSpacing:(CGFloat)arg
{
    self.currentVSpacing = arg;
}
-(void)setCurrentLoadoutHorizontalSpacing:(CGFloat)arg
{
    self.currentHSpacing = arg;
}
@end