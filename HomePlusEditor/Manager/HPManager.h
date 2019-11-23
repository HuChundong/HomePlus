#import <UIKit/UIKit.h>
#import "HPConfig.h"
@interface HPManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, retain) HPConfig *config;

@property (nonatomic, retain) NSString *currentLoadoutName;

@property (nonatomic, assign) BOOL useUserDefaults;

@property (nonatomic, assign) BOOL switcherDisables;
@property (nonatomic, assign) BOOL vRowUpdates;
@property (nonatomic, assign) BOOL resettingIconLayout;
@property (nonatomic, assign) BOOL pendingRespring;


- (BOOL)switcherDisables;
- (BOOL)resettingIconLayout;
- (void)loadSavedCurrentLoadoutName;
- (void)saveCurrentLoadoutName;
- (void)saveLoadout:(NSString *)name;
- (void)saveCurrentLoadout;
- (void)loadCurrentLoadout;
-(HPConfig *)loadConfigFromFilesystem:(NSString *)name;
- (HPConfig *)loadConfigFromUserDefaultSystem:(NSString *)name;

- (void)saveLoadoutToUserDefaults:(NSString *)name;

- (void)saveLoadoutToFilesystem:(NSString *)name;

- (NSMutableDictionary *)createDictionaryDefaultStructure;

- (void)resetCurrentLoadoutToDefaults;

- (void)setResettingIconLayout:(BOOL)arg;


@end