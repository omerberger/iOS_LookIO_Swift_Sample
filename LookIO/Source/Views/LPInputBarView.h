//
//  LPInputBarView.h
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import <UIKit/UIKit.h>

static NSString * const LIOObservingInputAccessoryViewSuperviewFrameDidChangeNotification = @"LIOObservingInputAccessoryViewSuperviewFrameDidChangeNotification";

@interface LIOObservingInputAccessoryView : UIView

@end

@class LPInputBarView;

@protocol LPInputBarViewDelegte <NSObject>

- (void)inputBarViewSendButtonWasTapped:(LPInputBarView *)inputBarView;
- (void)inputBarViewPlusButtonWasTapped:(LPInputBarView *)inputBarView;
- (void)inputBarViewKeyboardSendButtonWasTapped:(LPInputBarView *)inputBarView;
- (void)inputBarTextFieldDidBeginEditing:(LPInputBarView *)inputBarView;
- (void)inputBarTextFieldDidEndEditing:(LPInputBarView *)inputBarView;
- (void)inputBar:(LPInputBarView *)inputBar wantsNewHeight:(CGFloat)height;
- (void)inputBarStartedTyping:(LPInputBarView *)inputBar;
- (void)inputBarEndedTyping:(LPInputBarView *)inputBar;

@end

@interface LPInputBarView : UIView 

@property (nonatomic, assign) id <LPInputBarViewDelegte> delegate;
@property (nonatomic, strong) UITextView *textView;

- (void)rotatePlusButton;
- (void)unrotatePlusButton;

@end