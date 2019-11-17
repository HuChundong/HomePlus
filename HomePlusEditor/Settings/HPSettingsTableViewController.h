#import <UIKit/UIKit.h>

@interface HPSettingsTableViewController<UIAlertViewDelegate> : UITableViewController
-(void)opened;
- (NSString*) deviceName;
@end