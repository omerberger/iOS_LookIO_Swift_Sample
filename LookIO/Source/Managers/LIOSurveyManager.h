//
//  LIOSurveyManager.h
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

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
}

+ (LIOSurveyManager *)sharedSurveyManager;
- (void)populateSurveyWithTemplateDictionary:(NSDictionary *)aDict type:(LIOSurveyManagerSurveyType)surveyType;

@property(nonatomic, readonly) NSString *preChatHeader, *postChatHeader;
@property(nonatomic, readonly) LIOSurveyTemplate *preChatTemplate, *postChatTemplate;

@end