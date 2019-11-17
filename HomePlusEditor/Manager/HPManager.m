//
// HPManager.m
// HomePlus
//
// Data Manager
//
// Created Oct 2019
// Author: Kritanta
//

#include "HPManager.h"
#include "HPMonitor.h"

@implementation HPManager

+ (instancetype)sharedManager
{
    static HPManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}
- (instancetype)init
{
    self = [super init];

    if (self) {
        [self loadSavedCurrentLoadoutName];
        [self loadLoadout:self.currentLoadoutName];
    }

    return self;
}

- (void)saveCurrentLoadoutName
{
    [[HPMonitor sharedMonitor] logItem:@"Saving current loadout name"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSUserDefaults standardUserDefaults] setObject:self.currentLoadoutName
                                               forKey:@"HPCurrentLoadout"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadSavedCurrentLoadoutName
{
    [[HPMonitor sharedMonitor] logItem:@"Loading saved loadout name"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.currentLoadoutName = [[NSUserDefaults standardUserDefaults] stringForKey:@"HPCurrentLoadout"] ?: @"Default";
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveCurrentLoadout
{
    [[HPMonitor sharedMonitor] logItem:@"Saving current loadout"];
    [self saveLoadout:self.currentLoadoutName];
}

- (void)loadCurrentLoadout
{
    [self saveCurrentLoadout];
    [[HPMonitor sharedMonitor] logItem:@"Loading current loadout"];
    [self loadLoadout:self.currentLoadoutName];
}

-(void)loadLoadout:(NSString *)name 
{
    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", self.currentLoadoutName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.currentShouldHideIconLabels = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"]]
                                        : NO;
    self.currentShouldHideIconBadges = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"]]
                                        : NO;
    self.currentShouldHideIconLabelsInFolders = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"]]
                                        : NO;
    self.currentLoadoutShouldHideDockBG = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"DockBG"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"DockBG"]]
                                        : NO;
    self.currentLoadoutModernDock = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"ModernDock"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"ModernDock"]]
                                        : NO;

    [[HPMonitor sharedMonitor] logItem:[NSString stringWithFormat:@"Loading loadout with name %@", name]];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"HomePlus/Loadouts/%@%@", name, @".plist"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];

    @try {
        NSError *error = nil; // This so that we can access the error if something goes wrong
        NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
        NSDictionary *myDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:JSONData];
        self.currentLoadoutData = [myDictionary mutableCopy];
        // Load the file into an NSData object called JSONData
    }
    @catch (NSException *ex) {
        @try{
            self.currentLoadoutData = [self createDictionaryDefaultStructure];
            [self saveLoadout:name];


            NSError *error = nil; // This so that we can access the error if something goes wrong
            NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
            NSDictionary *myDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:JSONData];
            self.currentLoadoutData = [myDictionary mutableCopy];
            // Load the file into an NSData object called JSONData
        }
        @catch (NSException *ex) {
            NSLog(@"HPC: LOADING ANYTHING AT ALL FAILED :P");
            self.currentLoadoutData = [self createDictionaryDefaultStructure];
        }
    }

    if (self.currentLoadoutData[@"SBIconLocationRoot0"] == nil)
    {
        self.currentLoadoutData = [self createDictionaryDefaultStructure];
    }
    self.currentLoadoutLoaded = YES;
    self.vRowUpdates = [[self.currentLoadoutData valueForKey:@"vRowUpdates"] boolValue];
    self.switcherDisables = [[self.currentLoadoutData valueForKey:@"switcherDisables"] boolValue];
}
- (void)saveLoadout:(NSString *)name 
{
    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", self.currentLoadoutName];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    [userDefaults setBool:self.currentShouldHideIconLabels
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"] ];
    [userDefaults setBool:self.currentShouldHideIconBadges
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"] ];
    [userDefaults setBool:self.currentShouldHideIconLabelsInFolders
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"] ];
    [userDefaults setBool:self.currentLoadoutShouldHideDockBG
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"DockBG"] ];
    [userDefaults setBool:self.currentLoadoutModernDock
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"ModernDock"] ];

    [[NSUserDefaults standardUserDefaults] synchronize];
    [[HPMonitor sharedMonitor] logItem:[NSString stringWithFormat:@"Saving loadout with name %@", name]];

    self.currentLoadoutData[@"vRowUpdates"] = @(self.vRowUpdates);
    self.currentLoadoutData[@"switcherDisables"] = @(self.switcherDisables);

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:[documentsDirectory stringByAppendingPathComponent:@"HomePlus/Loadouts"] withIntermediateDirectories:YES attributes:nil error:&error]) {
        // An error has occurred, do something to handle it
    }

    NSString *fileName = [NSString stringWithFormat:@"HomePlus/Loadouts/%@%@", name, @".plist"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];

    NSError *writeError = nil;
    NSData *data= [NSKeyedArchiver archivedDataWithRootObject:[self.currentLoadoutData copy]];

    BOOL success = [data writeToFile:filePath options:0 error:&writeError];
}
- (NSMutableDictionary *)createDictionaryDefaultStructure
{

    [[HPMonitor sharedMonitor] logItem:@"Retrieving Default Loadout Scheme"];
    NSMutableDictionary *rootFolderDefaultsPageZero = [@{
        @"topOffset" : @0.0,
        @"leftOffset": @0.0,
        @"verticalSpacing": @0.0,
        @"horizontalSpacing": @0.0,
        @"iconSize": @60.0,
        @"iconRotation": @0.0,
        @"rows": @5,
        @"columns":@4,
        @"labels":@NO,
        @"badges":@NO
    } mutableCopy];
    NSMutableDictionary *dockDefaults = [@{
        @"topOffset" : @0.0,
        @"leftOffset": @0.0,
        @"verticalSpacing": @0.0,
        @"horizontalSpacing": @0.0,
        @"iconSize": @60.0,
        @"iconRotation": @0.0,
        @"rows": @1,
        @"columns": @4,
        @"labels":@NO,
        @"badges":@NO,
        @"bg":@NO
    } mutableCopy];
    NSMutableDictionary *floatyFolderDefaults = [@{
        @"topOffset" : @0.0,
        @"leftOffset": @0.0,
        @"verticalSpacing": @0.0,
        @"horizontalSpacing": @0.0,
        @"iconSize": @60.0,
        @"iconRotation": @0.0,
        @"rows": @3,
        @"columns": @3,
        @"labels":@NO,
        @"badges":@NO,
        @"iconbg":@NO
    } mutableCopy];
    NSMutableDictionary *defaultDictionaryStructure = [@{
        @"valuesInitialized": @NO,
        @"switcherDisables": @YES,
        @"vRowUpdates": @YES,
        @"hideLabels": @NO,
        @"hideBadges": @NO,
        @"hideFolderLabels": @NO,
        // The 0 after root indicates page
        // 0 will be the default loadout.
        @"SBIconLocationRoot0":rootFolderDefaultsPageZero,
        @"SBIconLocationDock":dockDefaults,
        @"SBIconLocationFolder":floatyFolderDefaults
    } mutableCopy];
    return defaultDictionaryStructure;
}

- (void)resetCurrentLoadoutToDefaults
{
    [[HPMonitor sharedMonitor] logItem:@"Retrieving default loadout"];
    self.currentLoadoutData = [self createDictionaryDefaultStructure];
    [self saveCurrentLoadout];
}
- (BOOL)currentLoadoutShouldHideIconLabelsForLocation:(NSString *)location
{
    [[HPMonitor sharedMonitor] logItem:@"Getting Icon Labels"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        return self.currentShouldHideIconLabels;
    }
    else 
    {
        return self.currentShouldHideIconLabelsInFolders;
    }
}

- (BOOL)currentLoadoutShouldHideIconBadgesForLocation:(NSString *)location
{
    [[HPMonitor sharedMonitor] logItem:@"Getting Icon badges"];
    return self.currentShouldHideIconBadges;
}

- (UIEdgeInsets)currentLoadoutInsetsForLocation:(NSString *)location pageIndex:(NSInteger)index withOriginal:(UIEdgeInsets)x
{
    [[HPMonitor sharedMonitor] logItem:@"Getting pregen loadout insets"];
        if (![self currentLoadoutLeftInsetForLocation:location pageIndex:index] == 0)
        {
            return UIEdgeInsetsMake(
                x.top + [[HPManager sharedManager] currentLoadoutTopInsetForLocation:location pageIndex:index],
                [[HPManager sharedManager] currentLoadoutLeftInsetForLocation:location pageIndex:index],
                x.bottom - [[HPManager sharedManager] currentLoadoutTopInsetForLocation:location pageIndex:index] + [[HPManager sharedManager] currentLoadoutVerticalSpacingForLocation:location pageIndex:index]*-2, // * 2 because regularly it was too slow
                x.right - [[HPManager sharedManager] currentLoadoutLeftInsetForLocation:location pageIndex:index] + [[HPManager sharedManager] currentLoadoutHorizontalSpacingForLocation:location pageIndex:index]*-2
            );
        }
        else
        {
            return UIEdgeInsetsMake(
                x.top + [[HPManager sharedManager] currentLoadoutTopInsetForLocation:location pageIndex:index],
                x.left + [[HPManager sharedManager] currentLoadoutHorizontalSpacingForLocation:location pageIndex:index],
                x.bottom - [[HPManager sharedManager] currentLoadoutTopInsetForLocation:location pageIndex:index] + [[HPManager sharedManager] currentLoadoutVerticalSpacingForLocation:location pageIndex:index]*2, // * 2 because regularly it was too slow
                x.right + [[HPManager sharedManager] currentLoadoutHorizontalSpacingForLocation:location pageIndex:index]
            );
        }
    

}

- (NSUInteger)currentLoadoutColumnsForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Getting columns"];
    NSUInteger r;
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    if ([self.currentLoadoutData objectForKey:location] == nil) [self loadCurrentLoadout];
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    if (locationDict == nil) return 4; // Failsafe, if dictionary somehow still doesn't exist
    NSInteger dVal = [[locationDict valueForKey:@"columns"] integerValue];
    if (dVal <= 0) dVal = 4; // Failsafe, if user was fucking with things they shouldn't be or I screwed up
    r = (NSUInteger)dVal;

    return r;
}

- (NSUInteger)currentLoadoutRowsForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Getting Rows"];
    NSUInteger r;
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    if ([self.currentLoadoutData objectForKey:location] == nil) [self loadCurrentLoadout];
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    if (locationDict == nil) return 4; // Failsafe, if dictionary somehow still doesn't exist
    NSInteger dVal = [[locationDict valueForKey:@"rows"] integerValue];
    if (dVal <= 0) dVal = 4; // Failsafe, if user was fucking with things they shouldn't be or I screwed up
    r = (NSUInteger)dVal;
    return r;
}

- (CGFloat)currentLoadoutTopInsetForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Getting Top Inset"];
    NSLog(@"Icon change called for %@ at i%d", location, index);
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    if ([self.currentLoadoutData objectForKey:location] == nil) [self loadCurrentLoadout];
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    if (locationDict == nil) return 0.0; // Failsafe, if dictionary somehow still doesn't exist
    CGFloat dVal = [[locationDict valueForKey:@"topOffset"] floatValue];
    return dVal;
}

- (CGFloat)currentLoadoutLeftInsetForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Getting Left Inset"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    if ([self.currentLoadoutData objectForKey:location] == nil) [self loadCurrentLoadout];
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    if (locationDict == nil) return 0.0; // Failsafe, if dictionary somehow still doesn't exist
    CGFloat dVal = [[locationDict valueForKey:@"leftOffset"] floatValue];
    return dVal;
}

- (CGFloat)currentLoadoutScaleForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Getting Scale"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    if ([self.currentLoadoutData objectForKey:location] == nil) [self loadCurrentLoadout];
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    if (locationDict == nil) return 60.0; // Failsafe, if dictionary somehow still doesn't exist
    CGFloat dVal = [[locationDict valueForKey:@"iconScale"] floatValue];
    if (dVal == 0)
    {
        [self setCurrentLoadoutScale:60.0 forLocation:location pageIndex:0];
        return 60.0;
    }

    return dVal;
}

- (CGFloat)currentLoadoutRotationForLocation:(NSString *)location pageIndex:(NSUInteger)index
{

    [[HPMonitor sharedMonitor] logItem:@"Getting Rotation"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    if ([self.currentLoadoutData objectForKey:location] == nil) [self loadCurrentLoadout];
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    if (locationDict == nil) return 0.0; // Failsafe, if dictionary somehow still doesn't exist
    CGFloat dVal = [[locationDict valueForKey:@"iconRotation"] floatValue];
    return dVal;
}

- (CGFloat)currentLoadoutVerticalSpacingForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Getting VSpacing"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    if ([self.currentLoadoutData objectForKey:location] == nil) [self loadCurrentLoadout];
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    if (locationDict == nil) return 0.0; // Failsafe, if dictionary somehow still doesn't exist
    CGFloat dVal = [[locationDict valueForKey:@"verticalSpacing"] floatValue];
    return dVal;
}

- (CGFloat)currentLoadoutHorizontalSpacingForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Getting HSpacing"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    if ([self.currentLoadoutData objectForKey:location] == nil) [self loadCurrentLoadout];
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    if (locationDict == nil) return 0.0; // Failsafe, if dictionary somehow still doesn't exist
    CGFloat dVal = [[locationDict valueForKey:@"horizontalSpacing"] floatValue];
    return dVal;
}

- (void)setCurrentLoadoutShouldHideIconLabels:(BOOL)arg forLocation:(NSString *)location 
{
    [[HPMonitor sharedMonitor] logItem:@"Setting Icon Labels"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {

        self.currentShouldHideIconLabels = arg;
    } 
    else 
    {
        self.currentShouldHideIconLabelsInFolders = arg;
    }
}

- (void)setCurrentLoadoutShouldHideIconBadges:(BOOL)arg forLocation:(NSString *)location 
{
    self.currentShouldHideIconBadges = arg;
}

- (void)setCurrentLoadoutColumns:(NSInteger)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Setting Columns"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    self.currentLoadoutData[location][@"columns"] = @(arg);
}

- (void)setCurrentLoadoutRows:(NSInteger)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Setting Rows"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    self.currentLoadoutData[location][@"rows"] = @(arg);
}

- (void)setCurrentLoadoutScale:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{

    [[HPMonitor sharedMonitor] logItem:@"Setting Scale"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    self.currentLoadoutData[location][@"iconScale"] = @(arg);
}

- (void)setCurrentLoadoutRotation:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Setting Rotation"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    self.currentLoadoutData[location][@"iconRotation"] = @(arg);
}

- (void)setCurrentLoadoutTopInset:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Setting Top Inset"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    //self.currentLoadoutData[location][@"topOffset"] = @(arg);
    NSMutableDictionary *locationDict = self.currentLoadoutData[location];
    [locationDict setObject:@(arg) forKey:@"topOffset"];
    self.currentLoadoutData[location] = locationDict;
    
}

- (void)setCurrentLoadoutLeftInset:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Setting Left Inset"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    self.currentLoadoutData[location][@"leftOffset"] = @(arg);
}

- (void)setCurrentLoadoutVerticalSpacing:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Setting VSpacing"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    self.currentLoadoutData[location][@"verticalSpacing"] = @(arg);
}

- (void)setCurrentLoadoutHorizontalSpacing:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    [[HPMonitor sharedMonitor] logItem:@"Setting HSpacing"];
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        if ([self.currentLoadoutData objectForKey:[NSString stringWithFormat:@"%@%d", location, index]] == nil) 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, 0];
        }
        else 
        {
            location =  [NSString stringWithFormat:@"%@%d", location, index];
        }
    }
    self.currentLoadoutData[location][@"horizontalSpacing"] = @(arg);
}


/* Legacy */
/*

- (void)loadLoadoutFromLegacySystem:(NSString *)name
{
    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", name];
    [[NSUserDefaults standardUserDefaults] synchronize];

    self.currentTopInset = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"]] ?:0.0;
    self.currentLeftInset = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"]] ?:0.0;
    self.currentHSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"]] ?:0.0;
    self.currentVSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"]] ?:0.0;
    self.currentScale = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"]] ?: 60.0;
    self.currentRotation = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rotation"]] ?:0.0;
    self.currentColumns = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"]] ?:4;
    self.currentRows = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"]] ?:6;
    self.switcherDisables = [[NSUserDefaults standardUserDefaults] objectForKey:@"HPSettingSwitcherDisables"]
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:@"HPSettingSwitcherDisables"]
                                        : YES;
    self.vRowUpdates = [[NSUserDefaults standardUserDefaults] objectForKey:@"HPSettingsVRowUpdates"]
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:@"HPSettingsVRowUpdates"]
                                        : YES;
    [[NSUserDefaults standardUserDefaults] synchronize];
}
*/
@end

