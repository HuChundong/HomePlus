#import "HPEditorWindow.h"
#import "HPEditorViewController.h"
@interface EditorManager : NSObject 
+ (instancetype)sharedManager;
@property (nonatomic, readonly, strong) HPEditorWindow *editorView;
@property (nonatomic, readonly, strong) HPEditorViewController *editorViewController;


-(HPEditorWindow *)editorView;
-(HPEditorViewController *)editorViewController;
-(void)resetAllValuesToDefaults;
-(void)showEditorView;
-(void)hideEditorView;
-(void)toggleEditorView;

@end