//
//  LIOControlButtonView.h
//  LookIO
//
//  Created by Joseph Toscano on 11/1/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    LIOControlButtonViewModeVertical,
    LIOControlButtonViewModeHorizontal
} LIOControlButtonViewMode;

typedef enum
{
    LIOControlButtonViewRoundedCornersModeDefault,
    LIOControlButtonViewRoundedCornersModeFlipped
} LIOControlButtonViewRoundedCornersMode;

@class LIOControlButtonView, LIOTimerProxy;

@protocol LIOControlButtonViewDelegate
- (void)controlButtonViewWasTapped:(LIOControlButtonView *)aControlButton;
@end

@interface LIOControlButtonView : UIView
{
    UILabel *label;
    UIColor *tintColor, *darkTintColor, *textColor;
    NSString *labelText;
    LIOTimerProxy *fadeTimer;
    LIOControlButtonViewMode currentMode;
    LIOControlButtonViewRoundedCornersMode roundedCornersMode;
    
    id<LIOControlButtonViewDelegate> delegate;
}

@property(nonatomic, retain) UIColor *tintColor, *textColor;
@property(nonatomic, retain) NSString *labelText;
@property(nonatomic, assign) LIOControlButtonViewMode currentMode;
@property(nonatomic, assign) LIOControlButtonViewRoundedCornersMode roundedCornersMode;
@property(nonatomic, assign) id<LIOControlButtonViewDelegate> delegate;

- (void)startFadeTimer;

@end