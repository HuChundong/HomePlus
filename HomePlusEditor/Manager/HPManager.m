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
#include "HomePlus.h"
#include "HPMonitor.h"
#include "HPConfig.h"

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
        [self loadCurrentLoadout];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeDisabledNotificationName object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveNotification:) name:kEditingModeEnabledNotificationName object:nil];
    }

    return self;
}

- (void)recieveNotification:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:kEditingModeEnabledNotificationName]) {
        [self loadCurrentLoadout]; // do both
    } else {
        [self saveCurrentLoadout];
    }
}
- (void)saveCurrentLoadoutName
{
    //[[NSUserDefaults standardUserDefaults] synchronize];
    [[NSUserDefaults standardUserDefaults] setObject:self.currentLoadoutName
                                               forKey:@"HPCurrentLoadout"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadSavedCurrentLoadoutName
{
    //[[NSUserDefaults standardUserDefaults] synchronize];
    self.currentLoadoutName = [[NSUserDefaults standardUserDefaults] stringForKey:@"HPCurrentLoadout"] ?: @"Default";
    //[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveCurrentLoadout
{
    self.useUserDefaults = YES;
    if (self.useUserDefaults)
        [self saveLoadoutToUserDefaults:self.currentLoadoutName];
    else
        [self saveLoadoutToFilesystem:self.currentLoadoutName];
}

- (void)loadCurrentLoadout
{
    self.useUserDefaults = YES;
    if (self.useUserDefaults)
        self.config = [self loadConfigFromUserDefaultSystem:self.currentLoadoutName];
    else
        self.config = [self loadConfigFromFilesystem:self.currentLoadoutName];
}

-(HPConfig *)loadConfigFromFilesystem:(NSString *)name 
{/*
    NSMutableDictionary *currentLoadoutData;
    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", name];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[HPMonitor sharedMonitor] logItem:[NSString stringWithFormat:@"Loading loadout with name %@", name]];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"HomePlus/Loadouts/%@%@", name, @".plist"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];

    @try {
        NSError *error = nil; // This so that we can access the error if something goes wrong
        NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
        NSDictionary *myDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:JSONData];
        currentLoadoutData = [myDictionary mutableCopy];
        // Load the file into an NSData object called JSONData
    }
    @catch (NSException *ex) {
        @try{
            currentLoadoutData = [self createDictionaryDefaultStructure];
            [self saveLoadout:name];


            NSError *error = nil; // This so that we can access the error if something goes wrong
            NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
            NSDictionary *myDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:JSONData];
            currentLoadoutData = [myDictionary mutableCopy];
            // Load the file into an NSData object called JSONData
        }
        @catch (NSException *ex) {
            NSLog(@"HPC: LOADING ANYTHING AT ALL FAILED :P");
            currentLoadoutData = [self createDictionaryDefaultStructure];
        }
    }

    if (currentLoadoutData[@"SBIconLocationRoot0"] == nil)
    {
        NSMutableDictionary *currentLoadoutData = [self createDictionaryDefaultStructure];
    }
    HPConfig *config = [[HPConfig alloc] init];
    [config setCurrentLoadoutData:currentLoadoutData];


    config.currentShouldHideIconLabels = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"]]
                                        : NO;
    config.currentShouldHideIconBadges = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"]]
                                        : NO;
    config.currentShouldHideIconLabelsInFolders = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"]]
                                        : NO;
    config.currentLoadoutShouldHideDockBG = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"DockBG"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"DockBG"]]
                                        : NO;
    config.currentLoadoutModernDock = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"ModernDock"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"ModernDock"]]
                                        : NO;
*/
    self.vRowUpdates = [[NSUserDefaults standardUserDefaults] objectForKey:@"HPvRowUpdates"] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:@"HPvRowUpdates"]
                                        : YES;
    self.switcherDisables = [[NSUserDefaults standardUserDefaults] objectForKey:@"HPswitcherDisables"] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:@"HPswitcherDisables"]
                                        : YES;
    self.useUserDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:@"HPuseUserDefaults"] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:@"HPuseUserDefaults"]
                                        : YES;
    return nil;
}

- (HPConfig *)loadConfigFromUserDefaultSystem:(NSString *)name
{
    /*
    [[HPMonitor sharedMonitor] logItem:@"Creating dictionary from legacy loadout system."];
    NSString *location = @"Root";
    NSString *prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", location, name];
    NSMutableDictionary *rootFolderSettingsPageZero = [@{
        @"topOffset" : @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"]] ?:0.0),
        @"leftOffset": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"]] ?:0.0),
        @"verticalSpacing": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"]] ?:0.0),
        @"horizontalSpacing": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"]] ?:0.0),
        @"iconSize": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"]] ?: 60.0),
        @"iconRotation": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rotation"]] ?:0.0),
        @"rows": @([[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"]] ?:5),
        @"columns":@([[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"]] ?:4)
    } mutableCopy];
    location = @"Dock";
    prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", location, name];
    NSMutableDictionary *dockSettings = [@{
        @"topOffset" : @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"]] ?:0.0),
        @"leftOffset": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"]] ?:0.0),
        @"verticalSpacing": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"]] ?:0.0),
        @"horizontalSpacing": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"]] ?:0.0),
        @"iconSize": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"]] ?: 60.0),
        @"iconRotation": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rotation"]] ?:0.0),
        @"rows": @([[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"]] ?:1),
        @"columns":@([[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"]] ?:4)
    } mutableCopy];
    location = @"Folder";
    prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", location, name];
    NSMutableDictionary *folderSettings = [@{
        @"topOffset" : @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"]] ?:0.0),
        @"leftOffset": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"]] ?:0.0),
        @"verticalSpacing": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"]] ?:0.0),
        @"horizontalSpacing": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"]] ?:0.0),
        @"iconSize": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"]] ?: 60.0),
        @"iconRotation": @([[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rotation"]] ?:0.0),
        @"rows": @([[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"]] ?:3),
        @"columns":@([[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"]] ?:3)
    } mutableCopy];
    NSMutableDictionary *currentLoadoutData = [@{
        @"valuesInitialized": @NO,
        @"switcherDisables": @YES,
        @"vRowUpdates": @YES,
        // The 0 after root indicates page
        // 0 will be the default loadout.
        @"SBIconLocationRoot0":rootFolderSettingsPageZero,
        @"SBIconLocationDock":dockSettings,
        @"SBIconLocationFolder":folderSettings
    } mutableCopy];

    HPConfig *config = [[HPConfig alloc] init];
    [config setCurrentLoadoutData:currentLoadoutData];

    prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme",  name];
    config.currentShouldHideIconLabels = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"]]
                                        : NO;
    config.currentShouldHideIconBadges = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"]]
                                        : NO;
    config.currentShouldHideIconLabelsInFolders = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"]]
                                        : NO;
    config.currentLoadoutShouldHideDockBG = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"DockBG"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"DockBG"]]
                                        : NO;
    config.currentLoadoutModernDock = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", prefix, @"ModernDock"]] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", prefix, @"ModernDock"]]
                                        : NO;
                                        */
    self.vRowUpdates = [[NSUserDefaults standardUserDefaults] objectForKey:@"HPvRowUpdates"] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:@"HPvRowUpdates"]
                                        : YES;
    self.switcherDisables = [[NSUserDefaults standardUserDefaults] objectForKey:@"HPswitcherDisables"] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:@"HPswitcherDisables"]
                                        : YES;
    self.useUserDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:@"HPuseUserDefaults"] 
                                        ? [[NSUserDefaults standardUserDefaults] boolForKey:@"HPuseUserDefaults"]
                                        : YES;

    return nil;
}

- (void)saveLoadoutToUserDefaults:(NSString *)name 
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    /*
    NSString *location = @"Root";
    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", name];
    [userDefaults setBool:self.config.currentShouldHideIconLabels
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"] ];
    [userDefaults setBool:self.config.currentShouldHideIconBadges
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"] ];
    [userDefaults setBool:self.config.currentShouldHideIconLabelsInFolders
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"] ];
    [userDefaults setBool:self.config.currentLoadoutShouldHideDockBG
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"DockBG"] ];
    [userDefaults setBool:self.config.currentLoadoutModernDock
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"ModernDock"] ];

    prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", location, name];
    // Easier to use the API I built to get these values than raw dictionary calls in all honesty. 
    [userDefaults setInteger:[self.config currentLoadoutColumnsForLocation:@"SBIconLocationRoot" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"] ];
    [userDefaults setInteger:[self.config currentLoadoutRowsForLocation:@"SBIconLocationRoot" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"] ];
    [userDefaults setFloat:[self.config currentLoadoutTopInsetForLocation:@"SBIconLocationRoot" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"] ];
    [userDefaults setFloat:[self.config currentLoadoutLeftInsetForLocation:@"SBIconLocationRoot" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"] ];
    [userDefaults setFloat:[self.config currentLoadoutHorizontalSpacingForLocation:@"SBIconLocationRoot" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"] ];
    [userDefaults setFloat:[self.config currentLoadoutVerticalSpacingForLocation:@"SBIconLocationRoot" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"] ];
    [userDefaults setFloat:[self.config currentLoadoutScaleForLocation:@"SBIconLocationRoot" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"] ];
    [userDefaults setFloat:[self.config currentLoadoutRotationForLocation:@"SBIconLocationRoot" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rotation"] ];

    location = @"Dock";
    prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", location, name];
    [userDefaults setInteger:[self.config currentLoadoutColumnsForLocation:@"SBIconLocationDock" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"] ];
    [userDefaults setInteger:[self.config currentLoadoutRowsForLocation:@"SBIconLocationDock" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"] ];
    [userDefaults setFloat:[self.config currentLoadoutTopInsetForLocation:@"SBIconLocationDock" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"] ];
    [userDefaults setFloat:[self.config currentLoadoutLeftInsetForLocation:@"SBIconLocationDock" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"] ];
    [userDefaults setFloat:[self.config currentLoadoutHorizontalSpacingForLocation:@"SBIconLocationDock" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"] ];
    [userDefaults setFloat:[self.config currentLoadoutVerticalSpacingForLocation:@"SBIconLocationDock" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"] ];
    [userDefaults setFloat:[self.config currentLoadoutScaleForLocation:@"SBIconLocationDock" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"] ];
    [userDefaults setFloat:[self.config currentLoadoutRotationForLocation:@"SBIconLocationDock" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rotation"] ];
    
    
    location = @"Folder";
    prefix = [NSString stringWithFormat:@"%@%@%@", @"HPTheme", location, name];
    [userDefaults setInteger:[self.config currentLoadoutColumnsForLocation:@"SBIconLocationFolder" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"] ];
    [userDefaults setInteger:[self.config currentLoadoutRowsForLocation:@"SBIconLocationFolder" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"] ];
    [userDefaults setFloat:[self.config currentLoadoutTopInsetForLocation:@"SBIconLocationFolder" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"] ];
    [userDefaults setFloat:[self.config currentLoadoutLeftInsetForLocation:@"SBIconLocationFolder" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"] ];
    [userDefaults setFloat:[self.config currentLoadoutHorizontalSpacingForLocation:@"SBIconLocationFolder" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"] ];
    [userDefaults setFloat:[self.config currentLoadoutVerticalSpacingForLocation:@"SBIconLocationFolder" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"] ];
    [userDefaults setFloat:[self.config currentLoadoutScaleForLocation:@"SBIconLocationFolder" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"] ];
    [userDefaults setFloat:[self.config currentLoadoutRotationForLocation:@"SBIconLocationFolder" pageIndex:0]
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rotation"] ];


    [userDefaults setBool:self.useUserDefaults
                    forKey:@"HPuseUserDefaults"];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveLoadoutToFilesystem:(NSString *)name 
{
    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", name];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    [userDefaults setBool:self.config.currentShouldHideIconLabels
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"] ];
    [userDefaults setBool:self.config.currentShouldHideIconBadges
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"] ];
    [userDefaults setBool:self.config.currentShouldHideIconLabelsInFolders
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"] ];
    [userDefaults setBool:self.config.currentLoadoutShouldHideDockBG
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"DockBG"] ];
    [userDefaults setBool:self.config.currentLoadoutModernDock
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"ModernDock"] ];
*/

    [userDefaults setBool:self.useUserDefaults
                    forKey:@"HPuseUserDefaults"];

    //[[NSUserDefaults standardUserDefaults] synchronize];
    [[HPMonitor sharedMonitor] logItem:[NSString stringWithFormat:@"Saving loadout with name %@", name]];

    self.config.currentLoadoutData[@"vRowUpdates"] = @(self.vRowUpdates);
    self.config.currentLoadoutData[@"switcherDisables"] = @(self.switcherDisables);

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
    NSData *data= [NSKeyedArchiver archivedDataWithRootObject:[self.config.currentLoadoutData copy]];

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
        @"columns":@4
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
        @"iconbg":@NO
    } mutableCopy];
    NSMutableDictionary *defaultDictionaryStructure = [@{
        @"valuesInitialized": @NO,
        @"switcherDisables": @YES,
        @"vRowUpdates": @YES,
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
    self.config.currentLoadoutData = [self createDictionaryDefaultStructure];
    [self saveCurrentLoadout];
}

@end

