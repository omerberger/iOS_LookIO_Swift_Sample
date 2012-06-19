//
//  LIOSurveyManager.h
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

// User defaults keys
#define LIOSurveyManagerLastKnownPreChatSurveyDictKey   @"LIOSurveyManagerLastKnownPreChatSurveyDictKey"
#define LIOSurveyManagerLastKnownPostChatSurveyDictKey  @"LIOSurveyManagerLastKnownPostChatSurveyDictKey"

@class LIOSurveyManager, LIOSurveyTemplate;

typedef enum
{
    LIOSurveyManagerSurveyTypePre,
    LIOSurveyManagerSurveyTypePost
} LIOSurveyManagerSurveyType;

@interface LIOSurveyManager : NSObject
{
    NSString *preChatHeader, *postChatHeader;
    LIOSurveyTemplate *preChatTemplate, *postChatTemplate;
    NSMutableDictionary *preChatResponses, *postChatResponses;
}

+ (LIOSurveyManager *)sharedSurveyManager;
- (void)populateTemplateWithDictionary:(NSDictionary *)aDict type:(LIOSurveyManagerSurveyType)surveyType;
- (void)registerAnswerString:(NSString *)anAnswerString forSurveyType:(LIOSurveyManagerSurveyType)surveyType withQuestionIndex:(int)anIndex;
- (NSString *)answerStringForSurveyType:(LIOSurveyManagerSurveyType)surveyType withQuestionIndex:(int)anIndex;
- (BOOL)responsesRequiredForSurveyType:(LIOSurveyManagerSurveyType)surveyType;

@property(nonatomic, readonly) NSString *preChatHeader, *postChatHeader;
@property(nonatomic, readonly) LIOSurveyTemplate *preChatTemplate, *postChatTemplate;


@end