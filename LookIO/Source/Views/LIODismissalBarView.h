//
//  LIODismissalBarView.h
//  LookIO
//
//  Created by Joseph Toscano on 3/6/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIODismissalBarView, LIOAnimatedKeyboardIcon;

@protocol LIODismissalBarViewDelegate
- (void)dismissalBarViewButtonWasTapped:(LIODismissalBarView *)aView;
@end

@interface LIODismissalBarView : UIView
{
    LIOAnimatedKeyboardIcon *keyboardIcon;
    UIView *separator;
    UILabel *dismissLabel;
    BOOL keyboardIconActive;
    id<LIODismissalBarViewDelegate> delegate;
}

@property(nonatomic, assign) id<LIODismissalBarViewDelegate> delegate;
@property(nonatomic, assign, getter=isKeyboardIconActive) BOOL keyboardIconActive;

@end