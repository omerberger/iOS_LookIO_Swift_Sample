//
//  LIOSurveyManager.m
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyManager.h"

static LIOSurveyManager *sharedSurveyManager = nil;

@implementation LIOSurveyManager

@synthesize preChatHeader, postChatHeader, preChatTemplate, postChatTemplate;

+ (LIOSurveyManager *)sharedSurveyManager
{
    if (nil == sharedSurveyManager)
        sharedSurveyManager = [[LIOSurveyManager alloc] init];
    
    return sharedSurveyManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
    }
    
    return self;
}

/*
 {
    "type": "survey",
    "header": string // Title of survey to display to user.
    "questions": [
        "id": integer,    // Unique id of this question.
        "mandatory": bool,    // Is this question required?
        "order": integer,    // Question sequence.
        "label": string,    // The question string to display to the user.
        "logicId": integer,    // Id for dynamic hiding of questions.
        "type": enum('picker', 'multiselect', 'switch', 'text'),    // The display type of the question.
        "validationType": enum('alphanumeric', 'numeric', 'email'),    // Client-side validation to perform.
        "lastKnownValue": string,    // Last-known response to this question, if any.
        "entry": [    // Entry objects represent entries in a picker.
        {
            "checked": bool,    // Should this entry be selected initially?
            "value": string,    // Display string of this entry.
            "logic":
            {
                "showLogicId": integer,    // If this entry is selected, show the question where (logicId == showLogicId).
                ... other logic propositions...
            },
        },
        ... other entries...
        ],
    ... other questions...
    ]
}
*/
- (void)populateSurveyWithTemplateDictionary:(NSDictionary *)aDict type:(LIOSurveyManagerSurveyType)surveyType
{
    NSString *headerString = [aDict objectForKey:@"header"];
    
    
    
    if (LIOSurveyManagerSurveyTypePre == surveyType)
    {
        [preChatHeader release];
        preChatHeader = [headerString retain];
    }
    else
    {
        [postChatHeader release];
        postChatHeader = [headerString retain];
    }
}

@end