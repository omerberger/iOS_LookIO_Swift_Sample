//
//  LPInputBarView.h
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import <UIKit/UIKit.h>

static NSString * const LIOObservingInputAccessoryViewSuperviewFrameDidChangeNotification = @"LIOObservingInputAccessoryViewSuperviewFrameDidChangeNotification";

#define LIOInputBarViewHeightIphone 50.0
#define LIOInputBarViewHeightIpad   70.0

@interface LIOObservingInputAccessoryView : UIView

@end

@class LPInputBarView;

@protocol LPInputBarViewDelegte <NSObject>

- (void)inputBarViewSendButtonWasTapped:(LPInputBarView *)inputBarView;
- (void)inputBarViewPlusButtonWasTapped:(LPInputBarView *)inputBarView;
- (void)inputBarViewKeyboardSendButtonWasTapped:(LPInputBarView *)inputBarView;
- (void)inputBarTextFieldDidBeginEditing:(LPInputBarView *)inputBarView;
- (void)inputBarTextFieldDidEndEditing:(LPInputBarView *)inputBarView;
- (void)inputBarDidStartTyping:(LPInputBarView *)inputBarView;
- (void)inputBarDidStopTyping:(LPInputBarView *)inputBarView;
- (void)inputBar:(LPInputBarView *)inputBar wantsNewHeight:(CGFloat)height;
- (void)inputBarStartedTyping:(LPInputBarView *)inputBar;
- (void)inputBarEndedTyping:(LPInputBarView *)inputBar;

@end

@interface LPInputBarView : UIView 

@property (nonatomic, assign) id <LPInputBarViewDelegte> delegate;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIButton *plusButton;

- (void)rotatePlusButton;
- (void)unrotatePlusButton;

- (void)clearTextView;

@end