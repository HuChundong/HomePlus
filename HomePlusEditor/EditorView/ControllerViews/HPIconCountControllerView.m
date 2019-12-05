#include "HPIconCountControllerView.h"
#include "EditorManager.h"

@implementation HPIconCountControllerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) 
    {
        [self layoutControllerView];
    }

    return self;
}

-(void)layoutControllerView
{
    [super layoutControllerView];

    NSString *x = @"";
    if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationRoot"]) x = @"Root";
    else if ([[[EditorManager sharedManager] editingLocation] isEqualToString:@"SBIconLocationDock"]) x = @"Dock";
    else x = @"Folder";

    self.topLabel.text = @"Rows";
    self.bottomLabel.text = @"Columns";

    self.topLabel.frame = CGRectMake(0, -10, (0.706) * [[UIScreen mainScreen] bounds].size.width, (0.0615) * [[UIScreen mainScreen] bounds].size.height);
    self.bottomLabel.frame = CGRectMake(0, -10, (0.706) * [[UIScreen mainScreen] bounds].size.width, 50);

    self.topTextField.frame = CGRectMake(([[UIScreen mainScreen] bounds].size.width / 2) - (((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2) - kLeftScreenBuffer * [[UIScreen mainScreen] bounds].size.width + 7, (0.048) * [[UIScreen mainScreen] bounds].size.height, (0.1333) * [[UIScreen mainScreen] bounds].size.width, (0.0369) * [[UIScreen mainScreen] bounds].size.height);
    self.bottomTextField.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width / 2 -  ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2 - kLeftScreenBuffer * [[UIScreen mainScreen] bounds].size.width + 7, (0.0480) * [[UIScreen mainScreen] bounds].size.height, 50, 30);

    self.topControl.minimumValue = 1;
    self.topControl.maximumValue = 14;

    self.bottomControl.minimumValue = 1;
    self.bottomControl.maximumValue = 14;

    self.topControl.alpha = 0;
    self.bottomControl.alpha = 0;

    UIButton *rowMin = [UIButton buttonWithType:UIButtonTypeCustom];
        
    [rowMin addTarget:self 
            action:@selector(rowMinus)
    forControlEvents:UIControlEventTouchUpInside];
    [rowMin setTitle:@"-" forState:UIControlStateNormal];

    rowMin.frame = CGRectMake(0, (0.0369) *  [[UIScreen mainScreen] bounds].size.height, ((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) - ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2 , 40.0);
    [self.topView addSubview:rowMin];

    UIButton *rowPlu = [UIButton buttonWithType:UIButtonTypeCustom];

    [rowPlu addTarget:self 
            action:@selector(rowPlus)
    forControlEvents:UIControlEventTouchUpInside];
    [rowPlu setTitle:@"+" forState:UIControlStateNormal];

    rowPlu.frame = CGRectMake(((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) + ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2, (0.0369) *  [[UIScreen mainScreen] bounds].size.height, ((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) - ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2 , 40.0);
    
    [self.topView addSubview:rowPlu];

    UIButton *colMin = [UIButton buttonWithType:UIButtonTypeCustom];

    [colMin addTarget:self 
            action:@selector(columnMinus)
    forControlEvents:UIControlEventTouchUpInside];
    [colMin setTitle:@"-" forState:UIControlStateNormal];
    colMin.frame = CGRectMake(0, (0.0369) *   [[UIScreen mainScreen] bounds].size.height, ((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) - ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2 , 40.0);
    [self.bottomView addSubview:colMin];

    UIButton *colPlu = [UIButton buttonWithType:UIButtonTypeCustom];
    [colPlu addTarget:self 
            action:@selector(columnPlus)
    forControlEvents:UIControlEventTouchUpInside];

    [colPlu setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.06]];
    [colMin setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.06]];
    [rowPlu setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.06]];
    [rowMin setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.06]];

    colPlu.layer.cornerRadius = 10;
    colPlu.clipsToBounds = YES;
    colMin.layer.cornerRadius = 10;
    colMin.clipsToBounds = YES;
    rowMin.layer.cornerRadius = 10;
    rowMin.clipsToBounds = YES;
    rowPlu.layer.cornerRadius = 10;
    rowPlu.clipsToBounds = YES;

    [colPlu setTitle:@"+" forState:UIControlStateNormal];
    colPlu.frame = CGRectMake(((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) + (((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2), (0.0369) *  [[UIScreen mainScreen] bounds].size.height, ((0.7) * [[UIScreen mainScreen] bounds].size.width / 2) - ((0.0369) * [[UIScreen mainScreen] bounds].size.height) / 2 , 40.0);
        
    [self.bottomView addSubview:colPlu];

    self.topControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Rows"]];
    self.topTextField.text = [NSString stringWithFormat:@"%.0f", self.topControl.value];
    self.bottomControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"Columns"]];
    self.bottomTextField.text = [NSString stringWithFormat:@"%.0f", self.bottomControl.value];

}

- (void)rowMinus
{
    self.topControl.value -= 1;
    [self topSliderUpdated:self.topControl];
}

- (void)rowPlus
{
    self.topControl.value += 1;
    [self topSliderUpdated:self.topControl];
}

- (void)columnMinus
{
    self.bottomControl.value -= 1;
    [self bottomSliderUpdated:self.bottomControl];
}

- (void)columnPlus 
{
    self.bottomControl.value += 1;
    [self bottomSliderUpdated:self.bottomControl];
}

- (void)topSliderUpdated:(UISlider *)sender
{
    NSString *x = [[[EditorManager sharedManager] editingLocation] substringFromIndex:14];

    [[NSUserDefaults standardUserDefaults]  setInteger:sender.value
            forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"Rows"]];
 
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HPResetIconViews" object:nil];
    self.topTextField.text = [NSString stringWithFormat:@"%.0f", (CGFloat)((NSInteger)(floor([sender value])))];
}

- (void)bottomSliderUpdated:(UISlider *)sender
{
    NSString *x = [[[EditorManager sharedManager] editingLocation] substringFromIndex:14];

    [[NSUserDefaults standardUserDefaults]  setFloat:sender.value
            forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"Columns"]];
    if ([x isEqualToString:@"Dock"]) [[NSNotificationCenter defaultCenter] postNotificationName:@"HPResetIconViews" object:nil];
    
    // Animation code credit to cuboid authors
    [UIView animateWithDuration:(0.15) delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HPResetIconViews" object:nil];
    } completion:NULL];
       
    self.bottomTextField.text = [NSString stringWithFormat:@"%.0f", (CGFloat)((NSInteger)(floor([sender value])))];
}


@end