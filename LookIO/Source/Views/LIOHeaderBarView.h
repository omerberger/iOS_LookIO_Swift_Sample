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
- (void)headerBarViewPlusButtonWasTapped:(LIOHeaderBarView *)aView;
@end

@interface LIOHeaderBarView : UIView
{
    UIView *tappableBackground;
    UIView *separator;
    UIButton *plusButton;
    UILabel *adLabel;
    UIImageView *tinyLogo;
    id<LIOHeaderBarViewDelegate> delegate;
}

@property(nonatomic, assign) id<LIOHeaderBarViewDelegate> delegate;

@end