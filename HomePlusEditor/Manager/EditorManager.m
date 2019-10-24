#include "EditorManager.h"
#include "HPEditorWindow.h"
#include "HPEditorViewController.h"

@interface EditorManager () <HPEditorViewControllerDelegate>
@property (nonatomic, readwrite, strong) HPEditorViewController *editorViewController;
@property (nonatomic, readwrite, strong) HPEditorWindow *editorView;
@end

@implementation EditorManager 
+(instancetype)sharedManager
{
    static EditorManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}
-(instancetype)init
{
    self = [super init];
    return self;
}
-(HPEditorWindow *)editorView 
{
    if (!_editorView) {
        _editorView = [[HPEditorWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        _editorView.rootViewController = self.editorViewController;
    }
    return _editorView;
}
-(HPEditorViewController *)editorViewController 
{
    if (!_editorViewController) {
        _editorViewController = [[HPEditorViewController alloc] init];
        _editorViewController.delegate = self;
    }

    return _editorViewController;
}
-(void)showEditorView 
{
    _editorView.alpha = 0;
    _editorView.hidden = NO;
    [UIView animateWithDuration:.2 animations:^{
        _editorView.alpha = 1;
    }];
}
-(void)hideEditorView
{
    _editorView.hidden = YES;
}
-(void)toggleEditorView
{
    if (_editorView.hidden) {
        [self showEditorView];
    } else {
        [self hideEditorView];
    }
}
-(void)resetAllValuesToDefaults 
{
    [[self editorViewController] resetAllValuesToDefaults];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomePlusEditingModeDisabled" object:nil];
    [self hideEditorView];
}
- (void)editorViewControllerDidFinish:(HPEditorViewController *)editorViewController {
    NSLog(@"filler");
}
@end

