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
- (void)inputBarViewDidTapSettingsButton:(LIOInputBarView *)aView;
- (void)inputBarView:(LIOInputBarView *)aView didReturnWithText:(NSString *)aString;
- (void)inputBarViewDidTypeStuff:(LIOInputBarView *)aView;
@end

// Misc. constants
#define LIOInputBarViewMaxLinesPortrait     4
#define LIOInputBarViewMaxLinesLandscape    2
#define LIOInputBarViewMaxTextLength        500

@interface LIOInputBarView : UIView <UITextViewDelegate>
{
    UIButton *sendButton, *settingsButton;
    UIView *dividerLine;
    UITextView *inputField;
    UIImageView *inputFieldBackground;
    CGFloat singleLineHeight;
    NSInteger totalLines;
    id<LIOInputBarViewDelegate> delegate;
}

@property(nonatomic, assign) id<LIOInputBarViewDelegate> delegate;
@property(nonatomic, readonly) CGFloat singleLineHeight;
@property(nonatomic, readonly) UIButton *settingsButton;
@property(nonatomic, readonly) UITextView *inputField;

@end
