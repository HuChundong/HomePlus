#import "HPEditorWindow.h"
#import "HPEditorViewController.h"
@interface EditorManager : NSObject 

+ (instancetype)sharedManager;
@property (nonatomic, retain) NSString *editingLocation;
@property (nonatomic, readonly, strong) HPEditorWindow *editorView;
@property (nonatomic, readonly, strong) HPEditorViewController *editorViewController;

@property (nonatomic, retain) UIImage *wallpaper;
-(UIImage *)bdBackgroundImage;
-(UIImage *)blurredMoreBGImage;

-(HPEditorWindow *)editorView;
-(HPEditorViewController *)editorViewController;
-(void)resetAllValuesToDefaults;
-(void)showEditorView;
-(void)hideEditorView;
-(void)toggleEditorView;

@end