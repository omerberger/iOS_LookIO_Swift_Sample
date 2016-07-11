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
    LIOSurveyQuestionDisplayTypeIntro = 0,
    LIOSurveyQuestionDisplayTypeTextField,
    LIOSurveyQuestionDisplayTypePicker,
    LIOSurveyQuestionDisplayTypeMultiselect,
    LIOSurveyQuestionDisplayTypeSwitch,
    LIOSurveyQuestionDisplayTypeTextArea
} LIOSurveyQuestionDisplayType;

typedef enum
{
    LIOSurveyQuestionValidationTypeAlphanumeric,
    LIOSurveyQuestionValidationTypeNumeric,
    LIOSurveyQuestionValidationTypeEmail,
    LIOSurveyQuestionValidationTypeRegexp
} LIOSurveyQuestionValidationType;

@interface LIOSurveyQuestion : NSObject

@property (nonatomic, assign) NSInteger questionId;
@property (nonatomic, assign) BOOL mandatory;
@property (nonatomic, assign) NSInteger order;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, assign) NSInteger logicId;
@property (nonatomic, assign) LIOSurveyQuestionDisplayType displayType;
@property (nonatomic, assign) LIOSurveyQuestionValidationType validationType;
@property (nonatomic, strong) NSArray *pickerEntries;
@property (nonatomic, strong) NSMutableArray *selectedIndices;
@property (nonatomic, copy) NSString* lastKnownValue;

- (BOOL)shouldUseStarRatingView;
- (NSArray*)pickerEntryTitles;

@end