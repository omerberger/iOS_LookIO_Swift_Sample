//
//  LIOControlButtonView.h
//  LookIO
//
//  Created by Joseph Toscano on 11/1/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOControlButtonView, LIOTimerProxy;

@protocol LIOControlButtonViewDelegate
- (void)controlButtonViewWasTapped:(LIOControlButtonView *)aControlButton;
@end

typedef enum
{
    LIOControllButtonViewModeDefault,
    LIOControllButtonViewModePending
} LIOControllButtonViewMode;

@interface LIOControlButtonView : UIView
{
    UILabel *label;
    UIColor *tintColor, *textColor, *fillColor, *shadowColor;
    NSString *labelText;
    LIOTimerProxy *fadeTimer;
    UIImageView *innerShadow;
    UIActivityIndicatorView *spinner;
    LIOControllButtonViewMode currentMode;
    
    id<LIOControlButtonViewDelegate> delegate;
}

@property(nonatomic, retain) UIColor *tintColor, *textColor;
@property(nonatomic, retain) NSString *labelText;
@property(nonatomic, readonly) UILabel *label;
@property(nonatomic, assign) LIOControllButtonViewMode currentMode;
@property(nonatomic, readonly) UIActivityIndicatorView *spinner;
@property(nonatomic, assign) id<LIOControlButtonViewDelegate> delegate;

- (void)startFadeTimer;
- (void)stopFadeTimer;

@end