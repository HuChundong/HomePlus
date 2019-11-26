
#import <sys/utsname.h>
@interface HPUtility : NSObject
+ (BOOL)isCurrentDeviceNotched;
+ (NSString *)deviceName;
+ (NSInteger)defaultRows;
+ (UIImage*)imageByCombiningImage:(UIImage*)firstImage withImage:(UIImage*)secondImage;
@end