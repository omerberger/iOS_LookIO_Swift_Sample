//
//  LIOControlButtonView.h
//  LookIO
//
//  Created by Joseph Toscano on 11/1/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOControlButtonView, LIOTimerProxy;

@protocol LIOControlButtonViewDelegate
- (void)controlButtonViewWasTapped:(LIOControlButtonView *)aControlButton;
@end

typedef enum
{
    LIOControlButtonViewModeDefault,
    LIOControlButtonViewModePending
} LIOControlButtonViewMode;

@interface LIOControlButtonView : UIView
{
    UILabel *label;
    UIColor *tintColor, *textColor, *fillColor, *shadowColor, *borderColor;
    NSString *labelText;
    UIImageView *innerShadow;
    UIActivityIndicatorView *spinner;
    LIOControlButtonViewMode currentMode;
    
    id<LIOControlButtonViewDelegate> delegate;
}

@property(nonatomic, retain) UIColor *tintColor, *textColor;
@property(nonatomic, retain) NSString *labelText;
@property(nonatomic, readonly) UILabel *label;
@property(nonatomic, assign) LIOControlButtonViewMode currentMode;
@property(nonatomic, readonly) UIActivityIndicatorView *spinner;
@property(nonatomic, assign) id<LIOControlButtonViewDelegate> delegate;

- (void)updateButtonForChatTheme;

@end