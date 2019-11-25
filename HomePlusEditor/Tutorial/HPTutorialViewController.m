#import "HPTutorialViewController.h"
#import "EditorManager.h"
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation HPTutorialViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.alpha = 1;
}

- (void)introView
{
    AudioServicesPlaySystemSound(1520);
    //[[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeEnabledNotificationName object:nil];
    self.viewOne = [[UIControl alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; 
    self.viewOne.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    UILabel *dragDown = [[UILabel alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height*0.1, [[UIScreen mainScreen] bounds].size.width, 80)];
    dragDown.numberOfLines = 2;
    dragDown.text = @"↖ Drag Down to Activate the view\nDragging down again closes it.";
    dragDown.textAlignment=NSTextAlignmentCenter;
    dragDown.textColor=[UIColor whiteColor];
    [self.view addSubview:self.viewOne];
    [self.viewOne addSubview:dragDown];

    UILabel *tapToContinue = [[UILabel alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height*0.7, [[UIScreen mainScreen] bounds].size.width, 80)];
    tapToContinue.text = @"Activate the editor to continue\n Close it to skip the tutorial.";
    tapToContinue.numberOfLines = 2;
    tapToContinue.textColor = [UIColor whiteColor];
    tapToContinue.textAlignment=NSTextAlignmentCenter;
    [self.viewOne addSubview:tapToContinue];

}
- (void)explainOffsets
{
    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.viewOne.alpha = 0.0;
        }
    ];

    AudioServicesPlaySystemSound(1520);
    //[[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeEnabledNotificationName object:nil];
    self.viewTwo = [[UIControl alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; 
    self.viewTwo.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    UILabel *dragDown = [[UILabel alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height*0.1, [[UIScreen mainScreen] bounds].size.width, 180)];
    dragDown.numberOfLines = 4;
    dragDown.text = @"↑ These are the control sliders\nThey allow you to change values in real time\nThey also support scrubbing\nlike the stock iOS video player";
    dragDown.textAlignment=NSTextAlignmentCenter;
    dragDown.textColor=[UIColor whiteColor];
    [self.view addSubview:self.viewTwo];
    [self.viewTwo addSubview:dragDown];

    UILabel *tapToContinue = [[UILabel alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height*0.7, [[UIScreen mainScreen] bounds].size.width, 80)];
    tapToContinue.text = @"Tap anywhere to continue\n Close the editor to skip this tutorial.";
    tapToContinue.numberOfLines = 2;
    tapToContinue.textColor = [UIColor whiteColor];
    tapToContinue.textAlignment=NSTextAlignmentCenter;
    [self.viewTwo addSubview:tapToContinue];

    //[self.viewTwo addTarget:self action:@selector(explainLocations:) forControlEvents:UIControlEventTouchUp];
}


- (void)explainLocations:(id)event
{
    [UIView animateWithDuration:.2 
        animations:
        ^{
            self.viewTwo.alpha = 0.0;
        }
    ];

    AudioServicesPlaySystemSound(1520);
    //[[NSNotificationCenter defaultCenter] postNotificationName:kEditingModeEnabledNotificationName object:nil];
    self.viewThree = [[UIControl alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; 
    self.viewThree.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    UILabel *dragDown = [[UILabel alloc] initWithFrame:CGRectMake(0, (0.197 * [[UIScreen mainScreen] bounds].size.height) + 40 * 6, [[UIScreen mainScreen] bounds].size.width-50, 180)];
    dragDown.numberOfLines = 3;
    dragDown.text = @"↑ These are the location buttons\nYou can choose to edit →\nthe main screen or dock here";
    dragDown.textAlignment=NSTextAlignmentRight;
    dragDown.textColor=[UIColor whiteColor];
    [self.view addSubview:self.viewThree];
    [self.viewThree addSubview:dragDown];

    UILabel *tapToContinue = [[UILabel alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height*0.7, [[UIScreen mainScreen] bounds].size.width, 80)];
    tapToContinue.text = @"Tap anywhere to continue\n Close the editor to skip this tutorial.";
    tapToContinue.numberOfLines = 2;
    tapToContinue.textColor = [UIColor whiteColor];
    tapToContinue.textAlignment=NSTextAlignmentCenter;
    [self.viewThree addSubview:tapToContinue];
}


@end