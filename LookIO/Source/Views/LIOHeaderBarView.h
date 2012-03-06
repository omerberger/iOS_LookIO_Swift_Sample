//
//  LIOHeaderBarView.h
//  LookIO
//
//  Created by Joseph Toscano on 1/20/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOHeaderBarView;

@protocol LIOHeaderBarViewDelegate
- (void)headerBarViewAboutButtonWasTapped:(LIOHeaderBarView *)aView;
- (void)headerBarViewPlusButtonWasTapped:(LIOHeaderBarView *)aView;
@end

typedef enum
{
    LIOHeaderBarViewModeNone,
    LIOHeaderBarViewModeMinimal,
    LIOHeaderBarViewModeFull
} LIOHeaderBarViewMode;

@interface LIOHeaderBarView : UIView
{
    UIView *tappableBackground;
    UIView *separator;
    LIOHeaderBarViewMode mode;
    UIButton *moreButton, *plusButton;
    UILabel *adLabel;
    UIImageView *tinyLogo;
    id<LIOHeaderBarViewDelegate> delegate;
}

@property(nonatomic, readonly) LIOHeaderBarViewMode mode;
@property(nonatomic, assign) id<LIOHeaderBarViewDelegate> delegate;

- (void)switchToMode:(LIOHeaderBarViewMode)aMode animated:(BOOL)animated;
- (void)rejiggerLayout;

@end