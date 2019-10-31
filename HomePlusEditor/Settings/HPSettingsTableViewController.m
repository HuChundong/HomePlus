//
// HPSettingsTableViewController.m
// HomePlus
//
// Settings (UITable)View Controller. Load stuff and call changes here. 
//
// Created Oct 2019
// Author: Kritanta
//


#include "HPSettingsTableViewController.h"
#include <UIKit/UIKit.h>
#include "EditorManager.h"
#include "HPUtilities.h"
#include "HPManager.h"

const int RESET_VALUES = 1;

#pragma mark UIViewController

@implementation HPSettingsTableViewController


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"HomePlus Settings";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat topPadding = window.safeAreaInsets.top;

    //CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    //self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y+topPadding, self.tableView.frame.size.width, self.tableView.frame.size.height-topPadding);

    //self.tableView.bounds = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y+topPadding, self.tableView.frame.size.width, self.tableView.frame.size.height-topPadding);
    UIView *bg = [[UIView alloc] init];
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        bg.backgroundColor = [UIColor clearColor];

        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        //always fill the view
        blurEffectView.frame = self.view.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [bg addSubview:blurEffectView]; //if you have more UIViews, use an insertSubview API to place it where needed
    } else {
        bg.backgroundColor = [UIColor blackColor];
    }

    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0,0,[[UIScreen mainScreen] bounds].size.width,(0.428*[[UIScreen mainScreen] bounds].size.width)-topPadding-20)];
    self.tableView.tableHeaderView = tableHeaderView;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = bg;

    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    self.navigationController.navigationBar.translucent = NO;
    NSDictionary *attributes = @{
                                 NSUnderlineStyleAttributeName: @0,
                                 NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:17]
                                 };
    [self.navigationController.navigationBar setTitleTextAttributes: attributes];

    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

#pragma mark - 


- (void)donePressed:(id)sender
{
    //[self.delegate globalsViewControllerDidFinish:self];
}

#pragma mark Table Data Helpers


- (NSString *)titleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) return(@"Reset Values");
    return (@"");
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    NSString *sectionName;
    switch (section) {
        case 0:
            sectionName = NSLocalizedString(@"Icons", @"Icons");
            break;
        case 1:
            sectionName = NSLocalizedString(@"Reset", @"Reset");
            break;
        default:
            sectionName = @"";
            break;
    }    
    return sectionName;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch( [indexPath section] ) {
        case 0: {
            switch ( [indexPath row] ){
                case 0: {
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
                    if( cell == nil ) {
                        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"SwitchCell"];
                        cell.textLabel.text = @"Show Icon Labels";
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                        cell.accessoryView = switchView;
                        [switchView setOn:[[HPManager sharedManager] currentLoadoutShouldShowIconLabels] animated:NO];
                        [switchView addTarget:self action:@selector(iconLabelSwitchChanged:) forControlEvents:UIControlEventValueChanged];

                        [cell.layer setCornerRadius:10];

                        [cell setBackgroundColor: [UIColor colorWithRed:10.0/255.0 green:10.0/255.0 blue:10.0/255.0 alpha:0.7]];//rgb(38, 37, 42)];
                        //Border Color and Width
                        [cell.layer setBorderColor:[UIColor blackColor].CGColor];
                        [cell.layer setBorderWidth:0];

                        //Set Text Col
                        cell.textLabel.textColor = [UIColor whiteColor];//[prefs colorForKey:@"textTint"];
                        cell.detailTextLabel.textColor = [UIColor whiteColor];//[prefs colorForKey:@"textTint"];

                        cell.clipsToBounds = YES;
                        }
                        return cell;
                }
            }
            
        }
        case 1: {
            switch ( [indexPath row] ) {
                case 0: {
                    static NSString *CellIdentifier = @"Cell";
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                    if (!cell) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
                    }
                    
                    cell.textLabel.text = [self titleForRowAtIndexPath:indexPath];
                    
                    [cell.layer setCornerRadius:10];

                    [cell setBackgroundColor: [UIColor colorWithRed:10.0/255.0 green:10.0/255.0 blue:10.0/255.0 alpha:0.7]];//rgb(38, 37, 42)];
                    //Border Color and Width
                    [cell.layer setBorderColor:[UIColor blackColor].CGColor];
                    [cell.layer setBorderWidth:0];

                    //Set Text Col
                    cell.textLabel.textColor = [UIColor whiteColor];//[prefs colorForKey:@"textTint"];
                    cell.detailTextLabel.textColor = [UIColor whiteColor];//[prefs colorForKey:@"textTint"];

                    cell.clipsToBounds = YES;
                    cell.hidden = NO;

                    return cell;
                }
            }
        }
        break;
    }
    return nil;
}

-(void)iconLabelSwitchChanged:(id)sender {
    UISwitch *switchControl = sender;
    [[HPManager sharedManager] setCurrentLoadoutShouldShowIconLabels:switchControl.on];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 0) [[EditorManager sharedManager] resetAllValuesToDefaults];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    view.tintColor = [UIColor clearColor];

    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];

    // Another way to set the background color
    // Note: does not preserve gradient effect of original header
    // header.contentView.backgroundColor = [UIColor blackColor];
}

@end
