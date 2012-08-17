//
//  LIOSurveyValidationView.h
//  LookIO
//
//  Created by Joseph Toscano on 6/20/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOSurveyValidationView;

@protocol LIOSurveyValidationViewDelegate
- (void)surveyValidationViewDidFinishDismissalAnimation:(LIOSurveyValidationView *)aView;
@end

@interface LIOSurveyValidationView : UIView
{
    UILabel *label;
    UIImageView *cautionSign;
    UIImageView *backgroundImage;
    BOOL verticallyMirrored;
    id<LIOSurveyValidationViewDelegate> delegate;
}

@property(nonatomic, readonly) UILabel *label;
@property(nonatomic, assign) BOOL verticallyMirrored;
@property(nonatomic, assign) id<LIOSurveyValidationViewDelegate> delegate;

- (void)showAnimated;
- (void)hideAnimated;

@end