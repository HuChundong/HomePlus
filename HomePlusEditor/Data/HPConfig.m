#import "HPConfig.h"
#import "HPMonitor.h"
// Deprecated class, was a nice try
// remove soon.
@implementation HPConfig 

- (BOOL)currentLoadoutShouldHideIconLabelsForLocation:(NSString *)location
{
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
    return self.currentShouldHideIconBadges;
}

- (UIEdgeInsets)currentLoadoutInsetsForLocation:(NSString *)location pageIndex:(NSInteger)index withOriginal:(UIEdgeInsets)x
{
        if (![self currentLoadoutLeftInsetForLocation:location pageIndex:index] == 0)
        {
            return UIEdgeInsetsMake(
                x.top + [self currentLoadoutTopInsetForLocation:location pageIndex:index],
                [self currentLoadoutLeftInsetForLocation:location pageIndex:index],
                x.bottom - [self currentLoadoutTopInsetForLocation:location pageIndex:index] + [self currentLoadoutVerticalSpacingForLocation:location pageIndex:index]*-2, // * 2 because regularly it was too slow
                x.right - [self currentLoadoutLeftInsetForLocation:location pageIndex:index] + [self currentLoadoutHorizontalSpacingForLocation:location pageIndex:index]*-2
            );
        }
        else
        {
            return UIEdgeInsetsMake(
                x.top + [self currentLoadoutTopInsetForLocation:location pageIndex:index],
                x.left + [self currentLoadoutHorizontalSpacingForLocation:location pageIndex:index],
                x.bottom - [self currentLoadoutTopInsetForLocation:location pageIndex:index] + [self currentLoadoutVerticalSpacingForLocation:location pageIndex:index]*2, // * 2 because regularly it was too slow
                x.right + [self currentLoadoutHorizontalSpacingForLocation:location pageIndex:index]
            );
        }
    

}

- (NSUInteger)currentLoadoutColumnsForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
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
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    if (locationDict == nil) return 4; // Failsafe, if dictionary somehow still doesn't exist
    NSInteger dVal = [[locationDict valueForKey:@"columns"] integerValue];
    if (dVal <= 0) dVal = 4; // Failsafe, if user was fucking with things they shouldn't be or I screwed up
    r = (NSUInteger)dVal;

    return r;
}

- (NSUInteger)currentLoadoutRowsForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
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
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    NSInteger dVal = [[locationDict valueForKey:@"rows"] integerValue];
    if (dVal <= 0) dVal = 6; // Failsafe, if user was fucking with things they shouldn't be or I screwed up
    r = (NSUInteger)dVal;
    return r;
}

- (CGFloat)currentLoadoutTopInsetForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    NSLog(@"Icon change called for %@ at i%d", location, index);
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    return [[locationDict valueForKey:@"topOffset"] floatValue];
}

- (CGFloat)currentLoadoutLeftInsetForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    return [[locationDict valueForKey:@"leftOffset"] floatValue];
}

- (CGFloat)currentLoadoutScaleForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
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
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    return [[locationDict valueForKey:@"iconRotation"] floatValue];
}

- (CGFloat)currentLoadoutVerticalSpacingForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    return [[locationDict valueForKey:@"verticalSpacing"] floatValue];
}

- (CGFloat)currentLoadoutHorizontalSpacingForLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    NSMutableDictionary *locationDict = [self.currentLoadoutData objectForKey:location];
    return [[locationDict valueForKey:@"horizontalSpacing"] floatValue];
}

- (void)setCurrentLoadoutShouldHideIconLabels:(BOOL)arg forLocation:(NSString *)location 
{
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
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    self.currentLoadoutData[location][@"columns"] = @(arg);
}

- (void)setCurrentLoadoutRows:(NSInteger)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    self.currentLoadoutData[location][@"rows"] = @(arg);
}

- (void)setCurrentLoadoutScale:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    self.currentLoadoutData[location][@"iconScale"] = @(arg);
}

- (void)setCurrentLoadoutRotation:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    self.currentLoadoutData[location][@"iconRotation"] = @(arg);
}

- (void)setCurrentLoadoutTopInset:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    //self.currentLoadoutData[location][@"topOffset"] = @(arg);
    NSMutableDictionary *locationDict = self.currentLoadoutData[location];
    [locationDict setObject:@(arg) forKey:@"topOffset"];
    self.currentLoadoutData[location] = locationDict;
    
}

- (void)setCurrentLoadoutLeftInset:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    self.currentLoadoutData[location][@"leftOffset"] = @(arg);
}

- (void)setCurrentLoadoutVerticalSpacing:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    self.currentLoadoutData[location][@"verticalSpacing"] = @(arg);
}

- (void)setCurrentLoadoutHorizontalSpacing:(CGFloat)arg forLocation:(NSString *)location pageIndex:(NSUInteger)index
{
    if ([location isEqualToString:@"SBIconLocationRoot"]) 
    {
        location =  [NSString stringWithFormat:@"%@%d", location, 0];
    }
    self.currentLoadoutData[location][@"horizontalSpacing"] = @(arg);
}

@end