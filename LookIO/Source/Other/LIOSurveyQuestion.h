//
//  LIOSurveyQuestion.h
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    LIOSurveyQuestionDisplayTypePicker,
    LIOSurveyQuestionDisplayTypeMultiselect,
    LIOSurveyQuestionDisplayTypeSwitch,
    LIOSurveyQuestionDisplayTypeText
} LIOSurveyQuestionDisplayType;

@interface LIOSurveyQuestion : NSObject
{
    int questionId;
    BOOL mandatory;
    int order;
    NSString *label;
    int logicId;
    LIOSurveyQuestionDisplayType displayType;
}

@end