//
// HPManager.m
// HomePlus
//
// Handles values for the customizations made.
//
// Created Oct 2019
// Author: Kritanta
//

#include "HPManager.h"
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
    [self loadSavedCurrentLoadoutName];
    [self loadLoadout:self.currentLoadout];
    return self;
}

- (void)saveCurrentLoadoutName
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSUserDefaults standardUserDefaults] setObject:self.currentLoadout
                                               forKey:@"HPCurrentLoadout"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadSavedCurrentLoadoutName
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.currentLoadout = [[NSUserDefaults standardUserDefaults] stringForKey:@"HPCurrentLoadout"] ?: @"Default";
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveCurrentLoadout
{
    [self saveLoadout:self.currentLoadout];
}

- (void)loadCurrentLoadout
{
    [self loadLoadout:self.currentLoadout];
}

- (void)saveLoadout:(NSString *)name
{


    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", name];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    [userDefaults setBool:self.switcherDisables
                    forKey:@"HPSettingSwitcherDisables" ];
    [userDefaults setBool:self.vRowUpdates
                    forKey:@"HPSettingVRowUpdates" ];
    [userDefaults setBool:self.currentShouldHideIconLabels
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"] ];
    [userDefaults setBool:self.currentShouldHideIconBadges
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"] ];
    [userDefaults setBool:self.currentShouldHideIconLabelsInFolders
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"] ];
    [userDefaults setFloat:self.currentTopInset
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"TopInset"] ];
    [userDefaults setFloat:self.currentLeftInset
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"LeftInset"] ];
    [userDefaults setFloat:self.currentHSpacing
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"SideInset"] ];
    [userDefaults setFloat:self.currentVSpacing
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"VerticalSpacing"] ];
    [userDefaults setFloat:self.currentScale
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Scale"] ];
    [userDefaults setFloat:self.currentRotation
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rotation"] ];
    [userDefaults setInteger:self.currentColumns
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Columns"] ];
    [userDefaults setInteger:self.currentRows
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"Rows"] ];
    [userDefaults synchronize];
}

- (void)loadLoadout:(NSString *)name
{
    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", name];
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

- (void)resetCurrentLoadoutToDefaults
{
    NSString *prefix = [NSString stringWithFormat:@"%@%@", @"HPTheme", self.currentLoadout];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    /*
    self.currentTopInset = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultTopInset"] ?: 0.0;
    self.currentLeftInset = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultLeftInset"] ?: 0.0;
    self.currentHSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultHSpacing"] ?: 0.0;
    self.currentVSpacing = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultVSpacing"] ?: 0.0;
    [self saveCurrentLoadout];
    */
    
    [userDefaults setBool:NO
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabels"] ];
    [userDefaults setBool:NO
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconBadges"] ];
    [userDefaults setBool:NO
                    forKey:[NSString stringWithFormat:@"%@%@", prefix, @"IconLabelsF"] ];
    self.currentShouldHideIconLabels = NO;
    self.currentShouldHideIconBadges = NO;
    self.currentShouldHideIconLabelsInFolders = NO;
    [self saveCurrentLoadout];
    [self saveCurrentLoadout];
}
- (BOOL)currentLoadoutShouldHideIconLabels
{
    return self.currentShouldHideIconLabels;
}

- (BOOL)currentLoadoutShouldHideIconBadges
{
    return self.currentShouldHideIconBadges;
}

- (BOOL)currentLoadoutShouldHideIconLabelsInFolders
{
    return self.currentShouldHideIconLabelsInFolders;
}

- (NSUInteger)currentLoadoutColumns
{
    NSUInteger r;
    r = (NSUInteger)self.currentColumns;
    return r;
}

- (NSUInteger)currentLoadoutRows
{
    NSUInteger r;
    r = (NSUInteger)self.currentRows;
    return r;
}

- (CGFloat)currentLoadoutTopInset
{
    return self.currentTopInset;
}

- (CGFloat)currentLoadoutLeftInset
{
    return self.currentLeftInset;
}

- (CGFloat)currentLoadoutScale
{
    return self.currentScale;
}

- (CGFloat)currentLoadoutRotation
{
    return self.currentRotation;
}

- (CGFloat)currentLoadoutVerticalSpacing
{
    return self.currentVSpacing;
}

- (CGFloat)currentLoadoutHorizontalSpacing
{
    return self.currentHSpacing;
}

- (void)setCurrentLoadoutShouldHideIconLabels:(BOOL)arg
{
    self.currentShouldHideIconLabels = arg;
}

- (void)setCurrentLoadoutShouldHideIconBadges:(BOOL)arg
{
    self.currentShouldHideIconBadges = arg;
}

- (void)setCurrentLoadoutShouldHideIconLabelsInFolders:(BOOL)arg
{
    self.currentShouldHideIconLabelsInFolders = arg;
}

- (void)setCurrentLoadoutColumns:(NSInteger)arg
{
    self.currentColumns = arg;
}

- (void)setCurrentLoadoutRows:(NSInteger)arg
{
    self.currentRows = arg;
}

- (void)setCurrentLoadoutScale:(CGFloat)arg
{
    self.currentScale = arg;
}

- (void)setCurrentLoadoutRotation:(CGFloat)arg
{
    self.currentRotation = arg;
}

- (void)setCurrentLoadoutTopInset:(CGFloat)arg
{
    self.currentTopInset = arg;
}

- (void)setCurrentLoadoutLeftInset:(CGFloat)arg
{
    self.currentLeftInset = arg;
}

- (void)setCurrentLoadoutVerticalSpacing:(CGFloat)arg
{
    self.currentVSpacing = arg;
}

- (void)setCurrentLoadoutHorizontalSpacing:(CGFloat)arg
{
    self.currentHSpacing = arg;
}

@end