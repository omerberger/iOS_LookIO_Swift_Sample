//
//  LIOSurvey.h
//  LookIO
//
//  Created by Yaron Karasik on 12/31/13.
//
//

#import <Foundation/Foundation.h>
#import "LIOSurveyTemplate.h"

@interface LIOSurvey : NSObject

- (id)initWithSurveyDictionary:(NSDictionary *)aDictionary;
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

@end