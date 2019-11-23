
#import <sys/utsname.h>
@interface HPUtility : NSObject
+(BOOL)isCurrentDeviceNotched;
+(NSString *)deviceName;
+ (UIImage*)imageByCombiningImage:(UIImage*)firstImage withImage:(UIImage*)secondImage;
@end