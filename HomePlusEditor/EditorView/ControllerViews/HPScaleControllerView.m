#include "HPScaleControllerView.h"
#include "EditorManager.h"

@implementation HPScaleControllerView

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

    self.topLabel.text = @"Icon Scale";
    self.bottomLabel.text = @"Icon Alpha";

    self.topControl.minimumValue = 1;
    self.topControl.maximumValue = 100;

    self.bottomControl.minimumValue = 0;
    self.bottomControl.maximumValue = 100.0;


    self.topControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"Scale"]];
    self.topTextField.text = [NSString stringWithFormat:@"%.0f", [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"Scale"]]];
    self.bottomControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"IconAlpha"]];
    self.bottomTextField.text = [NSString stringWithFormat:@"%.0f", [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"IconAlpha"]]];
    
}

- (void)topSliderUpdated:(UISlider *)sender
{
    NSString *x = [[[EditorManager sharedManager] editingLocation] substringFromIndex:14];

    [[NSUserDefaults standardUserDefaults] setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"Scale"]];
    self.topTextField.text = [NSString stringWithFormat:@"%.0f", sender.value];

    [[[EditorManager sharedManager] editorViewController] layoutAllSpringboardIcons];
}

- (void)bottomSliderUpdated:(UISlider *)sender
{
    NSString *x = [[[EditorManager sharedManager] editingLocation] substringFromIndex:14];

    [[NSUserDefaults standardUserDefaults] setFloat:sender.value
                forKey:[NSString stringWithFormat:@"HPThemeDefault%@%@", x, @"IconAlpha"]];
    self.bottomTextField.text = [NSString stringWithFormat:@"%.0f", sender.value];

    [super bottomSliderUpdated:sender];
    [[[EditorManager sharedManager] editorViewController] layoutAllSpringboardIcons];
}


@end