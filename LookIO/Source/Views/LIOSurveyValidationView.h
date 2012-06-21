//
//  LIOSurveyValidationView.h
//  LookIO
//
//  Created by Joseph Toscano on 6/20/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LIOSurveyValidationView : UIView
{
    UILabel *label;
    UIImageView *cautionSign;
}

@property(nonatomic, readonly) UILabel *label;

@end