#include "HPSpacingControllerView.h"
#include "EditorManager.h"

@implementation HPSpacingControllerView

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

    self.topLabel.text = @"Vertical Spacing";
    self.bottomLabel.text = @"Horizontal Spacing";



    self.topControl.minimumValue = -400;
    self.topControl.maximumValue = 400;

    self.bottomControl.minimumValue = -100.0;
    self.bottomControl.maximumValue = 200.0;    

    
    self.topControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"VerticalSpacing"]];
    self.topTextField.text = [NSString stringWithFormat:@"%.0f", self.topControl.value];
    self.bottomControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@%@%@", @"HPThemeDefault", x, @"SideInset"]];
    self.bottomTextField.text = [NSString stringWithFormat:@"%.0f", self.bottomControl.value];
}

- (void)topSliderUpdated:(UISlider *)sender
{
    NSString *x = [[[EditorManager sharedManager] editingLocation] substringFromIndex:14];

    [[NSUserDefaults standardUserDefaults] setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"VerticalSpacing"]];
    self.topTextField.text = [NSString stringWithFormat:@"%.0f", sender.value];

    [super topSliderUpdated:sender];
}

- (void)bottomSliderUpdated:(UISlider *)sender
{
    NSString *x = [[[EditorManager sharedManager] editingLocation] substringFromIndex:14];

    [[NSUserDefaults standardUserDefaults] setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"SideInset"]];
    self.bottomTextField.text = [NSString stringWithFormat:@"%.0f", sender.value];

    [super bottomSliderUpdated:sender];
}


@end