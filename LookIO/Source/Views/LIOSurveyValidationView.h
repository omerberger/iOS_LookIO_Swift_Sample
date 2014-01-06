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

@property (nonatomic, assign) id<LIOSurveyValidationViewDelegate> delegate;
@property (nonatomic, strong) UILabel *label;

- (void)showAnimated;
- (void)hideAnimated;

@end