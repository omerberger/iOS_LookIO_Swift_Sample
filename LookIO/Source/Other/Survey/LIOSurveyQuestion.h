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
    LIOSurveyQuestionDisplayTypeText,
    LIOSurveyQuestionDisplayTypePicker,
    LIOSurveyQuestionDisplayTypeMultiselect,
    LIOSurveyQuestionDisplayTypeSwitch
} LIOSurveyQuestionDisplayType;

typedef enum
{
    LIOSurveyQuestionValidationTypeAlphanumeric,
    LIOSurveyQuestionValidationTypeNumeric,
    LIOSurveyQuestionValidationTypeEmail,
    LIOSurveyQuestionValidationTypeRegexp
} LIOSurveyQuestionValidationType;

@interface LIOSurveyQuestion : NSObject
{
    int questionId;
    BOOL mandatory;
    int order;
    NSString *label;
    int logicId;
    NSString *validationRegexp;
    LIOSurveyQuestionDisplayType displayType;
    LIOSurveyQuestionValidationType validationType;
    NSArray *pickerEntries;
}

@property(nonatomic, assign) int questionId;
@property(nonatomic, assign) BOOL mandatory;
@property(nonatomic, assign) int order;
@property(nonatomic, retain) NSString *label;
@property(nonatomic, assign) int logicId;
@property(nonatomic, assign) LIOSurveyQuestionDisplayType displayType;
@property(nonatomic, assign) LIOSurveyQuestionValidationType validationType;
@property(nonatomic, retain) NSArray *pickerEntries;
@property(nonatomic, retain) NSString *validationRegexp;

@end