//
// HPOffsetControllerView.m
// 
// Control View for Editing Top/Left Offsets
//
// Author:  Kritanta
// Created: Dec 2019
//

#include "HPOffsetControllerView.h"
#include "EditorManager.h"

@implementation HPOffsetControllerView

/*
Properties: 
    @property (nonatomic, retain) UIView *topView;
    @property (nonatomic, retain) UIView *bottomView;

    @property (nonatomic, retain) UILabel *topLabel;
    @property (nonatomic, retain) OBSlider *topControl;
    @property (nonatomic, retain) UITextField *topTextField;

    @property (nonatomic, retain) UILabel *bottomLabel;
    @property (nonatomic, retain) OBSlider *bottomControl;
    @property (nonatomic, retain) UITextField *bottomTextField;
*/


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

    self.topLabel.text = @"Top Offset";
    self.bottomLabel.text = @"Left Offset";


    self.topControl.minimumValue = -100;
    self.topControl.maximumValue = [[UIScreen mainScreen] bounds].size.height;

    self.bottomControl.minimumValue = -400.0;
    self.bottomControl.maximumValue = 400.0;

    self.leftOffsetLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (0.0369) * [[UIScreen mainScreen] bounds].size.height + 30, (0.706) * [[UIScreen mainScreen] bounds].size.width, 50)];
    [self.leftOffsetLabel setText:@"Set to 0 to enable auto-centered\n Horizontal Spacing"];
    [self.leftOffsetLabel setFont:[UIFont systemFontOfSize:11]];
    self.leftOffsetLabel.numberOfLines = 2;
    self.leftOffsetLabel.textColor=[UIColor whiteColor];
    self.leftOffsetLabel.textAlignment=NSTextAlignmentCenter;
    [self.bottomView addSubview:self.leftOffsetLabel];
    
    
    self.topControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"TopInset"]];
    self.topTextField.text = [NSString stringWithFormat:@"%.0f", [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"TopInset"]]];
    self.bottomControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"LeftInset"]];
    self.bottomTextField.text = [NSString stringWithFormat:@"%.0f", [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"LeftInset"]]];
}

- (void)topSliderUpdated:(UISlider *)sender
{
    NSString *x = [[[EditorManager sharedManager] editingLocation] substringFromIndex:14];

    [[NSUserDefaults standardUserDefaults] setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"TopInset"]];
    self.topTextField.text = [NSString stringWithFormat:@"%.0f", sender.value];

    [super topSliderUpdated:sender];
}

- (void)bottomSliderUpdated:(UISlider *)sender
{
    NSString *x = [[[EditorManager sharedManager] editingLocation] substringFromIndex:14];

    [[NSUserDefaults standardUserDefaults] setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"LeftInset"]];
    self.bottomTextField.text = [NSString stringWithFormat:@"%.0f", sender.value];

    [super bottomSliderUpdated:sender];
}


@end