//
//  LIONavigationBar.h
//  LookIO
//
//  Created by Joseph Toscano on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIONavigationBar;

@protocol LIONavigationBarDelegate
- (void)navigationBarDidTapLeftButton:(LIONavigationBar *)aBar;
- (void)navigationBarDidTapRightButton:(LIONavigationBar *)aBar;
@end

/*
typedef enum
{
    LIONavigationBarDisplayModeNormal,
    LIONavigationBarDisplayModeLandscapePhone
} LIONavigationBarDisplayMode;
*/

@interface LIONavigationBar : UIView
{
    UIImage *stretchableBackgroundPortrait, *stretchableBackgroundLandscape, *stretchableButtonPortrait, *stretchableButtonLandscape;
    UIImageView *backgroundImageView, *titleImageView;
    UILabel *titleLabel;
    UIButton *leftButton, *rightButton;
    NSString *leftButtonText, *rightButtonText;
    NSString *titleString;
    UIImage *titleImage;
    //LIONavigationBarDisplayMode displayMode;
    NSObject<LIONavigationBarDelegate> *delegate;
}

//@property(nonatomic, assign) LIONavigationBarDisplayMode displayMode;
@property(nonatomic, retain) NSString *leftButtonText, *rightButtonText;
@property(nonatomic, retain) NSString *titleString;
@property(nonatomic, retain) UIImage *titleImage;
@property(nonatomic, assign) NSObject<LIONavigationBarDelegate> *delegate;

@end