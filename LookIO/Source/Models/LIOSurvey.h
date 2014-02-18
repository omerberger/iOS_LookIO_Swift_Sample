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

#define LIOSurveyViewControllerIndexForIntroPage   -1

@interface LIOSurvey : NSObject

@property (nonatomic, assign) LIOSurveyType surveyType;

@property (nonatomic, strong) NSArray *questions;

@property (nonatomic, assign) NSInteger lastCompletedQuestionIndex;
@property (nonatomic, assign) NSInteger lastSeenQuestionIndex;

- (id)initWithSurveyDictionary:(NSDictionary *)aDictionary surveyType:(LIOSurveyType)surveyType;
- (id)initWithDefaultOfflineSurveyWithResponse:(NSString *)response;

- (void)registerAnswerObject:(id)anAnswerObj withQuestionIndex:(NSInteger)anIndex;
- (void)clearAnswerForQuestionIndex:(NSInteger)anIndex;

- (id)answerObjectForQuestionIndex:(NSInteger)anIndex;
- (BOOL)allMandatoryQuestionsAnswered;
- (NSInteger)nextQuestionWithResponseRequired;
- (void)clearAllResponses;
- (NSInteger)realIndexWithLogicOfQuestionAtIndex:(NSInteger)anIndex;
- (NSInteger)numberOfQuestionsWithLogic;
- (BOOL)shouldShowQuestion:(NSInteger)index;
- (NSDictionary*)responseDict;
- (LIOSurveyQuestion *)questionForIntroView;
- (BOOL)anyQuestionsAnswered;
- (BOOL)isQuestionWithIndexLastQuestion:(NSInteger)anIndex;

@end