//
//  LIOSurveyManager.h
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

// User defaults keys
#define LIOSurveyManagerLastKnownPreChatSurveyDictKey   @"LIOSurveyManagerLastPreChatSurveyDictKey"
#define LIOSurveyManagerLastKnownPostChatSurveyDictKey  @"LIOSurveyManagerLastPostChatSurveyDictKey"
#define LIOSurveyManagerLastKnownOfflineSurveyDictKey  @"LIOSurveyManagerLastOfflineSurveyDictKey"

@class LIOSurveyManager, LIOSurveyTemplate, LIOSurveyQuestion;

typedef enum
{
    LIOSurveyManagerSurveyTypePre,
    LIOSurveyManagerSurveyTypePost,
    LIOSurveyManagerSurveyTypeOffline
} LIOSurveyManagerSurveyType;

@interface LIOSurveyManager : NSObject
{
    NSString *preChatHeader, *postChatHeader, *offlineHeader;
    LIOSurveyTemplate *preChatTemplate, *postChatTemplate, *offlineTemplate;
    NSMutableDictionary *preChatResponses, *postChatResponses, *offlineResponses;
    int lastCompletedQuestionIndexPre, lastCompletedQuestionIndexPost, lastCompletedQuestionIndexOffline;
    BOOL preSurveyCompleted, offlineSurveyIsDefault;
}

+ (LIOSurveyManager *)sharedSurveyManager;
- (void)populateTemplateWithDictionary:(NSDictionary *)aDict type:(LIOSurveyManagerSurveyType)surveyType;
- (void)registerAnswerObject:(id)anAnswerObj forSurveyType:(LIOSurveyManagerSurveyType)surveyType withQuestionIndex:(int)anIndex;
- (id)answerObjectForSurveyType:(LIOSurveyManagerSurveyType)surveyType withQuestionIndex:(int)anIndex;
- (BOOL)responsesRequiredForSurveyType:(LIOSurveyManagerSurveyType)surveyType;
- (int)nextQuestionWithResponseRequiredForSurveyType:(LIOSurveyManagerSurveyType)surveyType;
- (void)clearAllResponsesForSurveyType:(LIOSurveyManagerSurveyType)surveyType;
- (int)numberOfQuestionsWithLogicForSurveyType:(LIOSurveyManagerSurveyType)surveyType;
- (BOOL)shouldShowQuestion:(int)index surveyType:(LIOSurveyManagerSurveyType)surveyType;
- (int)realIndexWithLogicOfQuestionAtIndex:(int)anIndex forSurveyType:(LIOSurveyManagerSurveyType)surveyType;
- (NSDictionary*)responseDictForSurveyType:(LIOSurveyManagerSurveyType)surveyType;
- (void)populateDefaultOfflineSurvey;

@property (nonatomic, readonly) NSString *preChatHeader, *postChatHeader, *offlineHeader;
@property (nonatomic, readonly) LIOSurveyTemplate *preChatTemplate, *postChatTemplate, *offlineTemplate;
@property (nonatomic, assign) int lastCompletedQuestionIndexPre, lastCompletedQuestionIndexPost, lastCompletedQuestionIndexOffline;
@property (nonatomic, assign) BOOL preSurveyCompleted, offlineSurveyIsDefault;

@end