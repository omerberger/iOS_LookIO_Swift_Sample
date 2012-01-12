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

@interface LIOControlButtonView : UIView
{
    UILabel *label;
    UIColor *tintColor, *textColor, *fillColor, *shadowColor;
    NSString *labelText;
    LIOTimerProxy *fadeTimer;
    
    id<LIOControlButtonViewDelegate> delegate;
}

@property(nonatomic, retain) UIColor *tintColor, *textColor;
@property(nonatomic, retain) NSString *labelText;
@property(nonatomic, readonly) UILabel *label;
@property(nonatomic, assign) id<LIOControlButtonViewDelegate> delegate;

- (void)startFadeTimer;
- (void)stopFadeTimer;

@end