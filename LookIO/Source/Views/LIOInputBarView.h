//
//  LIOInputBarView.h
//  LookIO
//
//  Created by Joseph Toscano on 12/7/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOInputBarView, LIONotificationArea, LIOTimerProxy;

@protocol LIOInputBarViewDelegate
- (void)inputBarView:(LIOInputBarView *)aView didChangeNumberOfLines:(NSInteger)numLinesDelta;
- (void)inputBarView:(LIOInputBarView *)aView didChangeDesiredHeight:(CGFloat)desiredHeight;
- (void)inputBarView:(LIOInputBarView *)aView didReturnWithText:(NSString *)aString;
- (void)inputBarViewDidTypeStuff:(LIOInputBarView *)aView;
- (void)inputBarViewDidTapAdArea:(LIOInputBarView *)aView;
- (void)inputBarViewDidStopPulseAnimation:(LIOInputBarView *)aView;
- (void)inputBarViewDidTapAttachButton:(LIOInputBarView *)aView;
@end

// Misc. constants
#define LIOInputBarViewMaxLinesPortrait     4
#define LIOInputBarViewMaxLinesLandscape    2
#define LIOInputBarViewMaxTextLength        150
#define LIOInputBarViewMaxTextLength_iPad   300
#define LIOInputBarViewMinHeight            41.0
#define LIOInputBarViewMinHeightPad         54.0

@interface LIOInputBarView : UIView <UITextViewDelegate>
{
    //UILabel *adLabel;
    //UIImageView *adLogo;
    //UIView *adArea;
    UIButton *sendButton, *attachButton;
    UITextView *inputField;
    UIImageView *inputFieldBackground, *inputFieldBackgroundGlowing;
    CGFloat singleLineHeight;
    NSInteger totalLines;
    CGFloat desiredHeight;
    UILabel *characterCount;
    UILabel *placeholderText;
    LIONotificationArea *notificationArea;
    LIOTimerProxy *pulseTimer;
    id<LIOInputBarViewDelegate> delegate;
}

- (void)revealNotificationString:(NSString *)aString withAnimatedKeyboard:(BOOL)animated permanently:(BOOL)permanent;
- (void)startPulseAnimation;
- (void)stopPulseAnimation;
- (void)forceAcceptanceOfAutocorrect;

@property(nonatomic, assign) id<LIOInputBarViewDelegate> delegate;
@property(nonatomic, readonly) CGFloat singleLineHeight;
@property(nonatomic, readonly) UITextView *inputField;
@property(nonatomic, readonly) CGFloat desiredHeight;
@property(nonatomic, readonly) UIView *adArea;
@property(nonatomic, readonly) LIONotificationArea *notificationArea;
@property(nonatomic, readonly) UIButton *attachButton;

@end
