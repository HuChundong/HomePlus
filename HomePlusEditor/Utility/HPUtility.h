
#import <sys/utsname.h>
@interface HPUtility : NSObject
+(BOOL)isCurrentDeviceNotched;
+(NSString *)deviceName;
@end