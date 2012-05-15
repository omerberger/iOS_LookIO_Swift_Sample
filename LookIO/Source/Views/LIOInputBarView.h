//
//  LIOInputBarView.h
//  LookIO
//
//  Created by Joseph Toscano on 12/7/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOInputBarView;

@protocol LIOInputBarViewDelegate
- (void)inputBarView:(LIOInputBarView *)aView didChangeNumberOfLines:(NSInteger)numLinesDelta;
- (void)inputBarView:(LIOInputBarView *)aView didChangeDesiredHeight:(CGFloat)desiredHeight;
- (void)inputBarView:(LIOInputBarView *)aView didReturnWithText:(NSString *)aString;
- (void)inputBarViewDidTypeStuff:(LIOInputBarView *)aView;
- (void)inputBarViewDidTapAdArea:(LIOInputBarView *)aView;
@end

// Misc. constants
#define LIOInputBarViewMaxLinesPortrait     4
#define LIOInputBarViewMaxLinesLandscape    2
#define LIOInputBarViewMaxTextLength        150
#define LIOInputBarViewMaxTextLength_iPad   300
#define LIOInputBarViewMinHeight            37.0
#define LIOInputBarViewMinHeightPad         50.0

@interface LIOInputBarView : UIView <UITextViewDelegate>
{
    UILabel *adLabel;
    UIImageView *adLogo;
    UIButton *sendButton;
    UITextView *inputField;
    UIImageView *inputFieldBackground;
    CGFloat singleLineHeight;
    NSInteger totalLines;
    CGFloat desiredHeight;
    UIView *adArea;
    UILabel *characterCount;
    UILabel *placeholderText;
    id<LIOInputBarViewDelegate> delegate;
}

@property(nonatomic, assign) id<LIOInputBarViewDelegate> delegate;
@property(nonatomic, readonly) CGFloat singleLineHeight;
@property(nonatomic, readonly) UITextView *inputField;
@property(nonatomic, readonly) CGFloat desiredHeight;
@property(nonatomic, readonly) UIView *adArea;

@end
