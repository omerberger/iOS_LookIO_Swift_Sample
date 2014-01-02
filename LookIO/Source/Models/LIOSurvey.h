//
//  LIOSurvey.h
//  LookIO
//
//  Created by Yaron Karasik on 12/31/13.
//
//

#import <Foundation/Foundation.h>

#import "LIOSurveyQuestion.h"

typedef enum
{
    LIOSurveyTypePrechat = 0,
    LIOSurveyTypePostchat,
    LIOSurveyTypeOffline
} LIOSurveyType;

@interface LIOSurvey : NSObject

@property (nonatomic, assign) LIOSurveyType surveyType;

@property (nonatomic, strong) NSArray *questions;

@property (nonatomic, assign) NSInteger lastCompletedQuestionIndex;
@property (nonatomic, assign) NSInteger lastSeenQuestionIndex;

- (id)initWithSurveyDictionary:(NSDictionary *)aDictionary surveyType:(LIOSurveyType)surveyType;
- (id)initWithDefaultOfflineSurveyWithResponse:(NSString *)response;

- (void)registerAnswerObject:(id)anAnswerObj withQuestionIndex:(NSInteger)anIndex;
- (id)answerObjectForQuestionIndex:(NSInteger)anIndex;
- (BOOL)responsesRequired;
- (int)nextQuestionWithResponseRequired;
- (void)clearAllResponses;
- (int)realIndexWithLogicOfQuestionAtIndex:(NSInteger)anIndex;
- (int)numberOfQuestionsWithLogic;
- (BOOL)shouldShowQuestion:(NSInteger)index;
- (NSDictionary*)responseDict;

- (LIOSurveyQuestion *)questionForIntroView;

@end