#include <UIKit/UIKit.h>
#include "OBSlider.h"

#define kLeftScreenBuffer 0.146
#define kTopContainerTopAnchor 0.036
#define kContainerHeight 0.123


@interface HPControllerView : UIView

@property (nonatomic, retain) UIView *topView;
@property (nonatomic, retain) UIView *bottomView;

@property (nonatomic, retain) UILabel *topLabel;
@property (nonatomic, retain) OBSlider *topControl;
@property (nonatomic, retain) UITextField *topTextField;

@property (nonatomic, retain) UILabel *bottomLabel;
@property (nonatomic, retain) OBSlider *bottomControl;
@property (nonatomic, retain) UITextField *bottomTextField;

- (void)layoutControllerView;

- (void)topSliderUpdated:(UISlider *)slider;
- (void)bottomSliderUpdated:(UISlider *)slider;

- (void)topTextFieldUpdated:(UITextField *)textField;
- (void)invertTopTextField;

- (void)bottomTextFieldBeganEditing:(UITextField *)textField;
- (void)bottomTextFieldEndedEditing:(UITextField *)textField;
- (void)bottomTextFieldUpdated:(UITextField *)textField;

-(void)invertBottomTextField;

@end
