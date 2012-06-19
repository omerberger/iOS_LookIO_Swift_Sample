//
//  LIOSurveyManager.m
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyManager.h"
#import "LIOSurveyTemplate.h"
#import "LIOSurveyQuestion.h"
#import "LIOSurveyPickerEntry.h"
#import "LIOSurveyLogicProp.h"

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
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        NSDictionary *savedPreChatDict = [userDefaults objectForKey:LIOSurveyManagerLastKnownPreChatSurveyDictKey];
        if (savedPreChatDict)
            [self populateTemplateWithDictionary:savedPreChatDict type:LIOSurveyManagerSurveyTypePre];
        
        NSDictionary *savedPostChatDict = [userDefaults objectForKey:LIOSurveyManagerLastKnownPostChatSurveyDictKey];
        if (savedPostChatDict)
            [self populateTemplateWithDictionary:savedPostChatDict type:LIOSurveyManagerSurveyTypePost];
        
        preChatResponses = [[NSMutableDictionary alloc] init];
        postChatResponses = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [preChatHeader release];
    [postChatHeader release];
    [preChatTemplate release];
    [postChatTemplate release];
    [preChatResponses release];
    [postChatResponses release];
    
    [super dealloc];
}

- (void)registerAnswerString:(NSString *)anAnswerString forSurveyType:(LIOSurveyManagerSurveyType)surveyType withQuestionIndex:(int)anIndex
{
    if (LIOSurveyManagerSurveyTypePre == surveyType)
    {
        [preChatResponses setObject:anAnswerString forKey:[NSNumber numberWithInt:anIndex]];
    }
    else
    {
        [postChatResponses setObject:anAnswerString forKey:[NSNumber numberWithInt:anIndex]];
    }
}

- (NSString *)answerStringForSurveyType:(LIOSurveyManagerSurveyType)surveyType withQuestionIndex:(int)anIndex
{
    if (LIOSurveyManagerSurveyTypePre == surveyType)
    {
        return [preChatResponses objectForKey:[NSNumber numberWithInt:anIndex]];
    }
    else
    {
        return [postChatResponses objectForKey:[NSNumber numberWithInt:anIndex]];
    }
}

- (void)populateTemplateWithDictionary:(NSDictionary *)aDict type:(LIOSurveyManagerSurveyType)surveyType
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        [userDefaults setObject:aDict forKey:LIOSurveyManagerLastKnownPreChatSurveyDictKey];
    else
        [userDefaults setObject:aDict forKey:LIOSurveyManagerLastKnownPostChatSurveyDictKey];
    
    NSString *headerString = [aDict objectForKey:@"header"];
    
    LIOSurveyTemplate *newTemplate = [[LIOSurveyTemplate alloc] init];
    NSArray *questionsArray = [aDict objectForKey:@"questions"];
    NSMutableArray *questions = [NSMutableArray array];
    for (NSDictionary *aQuestionDict in questionsArray)
    {
        LIOSurveyQuestion *newQuestion = [[[LIOSurveyQuestion alloc] init] autorelease];
        newQuestion.questionId = [[aQuestionDict objectForKey:@"id"] intValue];
        newQuestion.mandatory = [[aQuestionDict objectForKey:@"mandatory"] boolValue];
        newQuestion.order = [[aQuestionDict objectForKey:@"order"] intValue];
        newQuestion.label = [aQuestionDict objectForKey:@"label"];
        newQuestion.logicId = [[aQuestionDict objectForKey:@"logicId"] intValue];
        
        NSString *typeString = [aQuestionDict objectForKey:@"type"];
        if ([typeString isEqualToString:@"picker"])
            newQuestion.displayType = LIOSurveyQuestionDisplayTypePicker;
        else if ([typeString isEqualToString:@"multiselect"])
            newQuestion.displayType = LIOSurveyQuestionDisplayTypeMultiselect;
        else if ([typeString isEqualToString:@"switch"])
            newQuestion.displayType = LIOSurveyQuestionDisplayTypeSwitch;
        else
            newQuestion.displayType = LIOSurveyQuestionDisplayTypeText;
        
        NSString *validationString = [aQuestionDict objectForKey:@"validationType"];
        if ([validationString isEqualToString:@"alphanumeric"])
            newQuestion.validationType = LIOSurveyQuestionValidationTypeAlphanumeric;
        else if ([validationString isEqualToString:@"numeric"])
            newQuestion.validationType = LIOSurveyQuestionValidationTypeNumeric;
        else if ([validationString isEqualToString:@"email"])
            newQuestion.validationType = LIOSurveyQuestionValidationTypeEmail;
        else
            newQuestion.validationType = LIOSurveyQuestionValidationTypeRegexp;
        
        if (LIOSurveyQuestionDisplayTypePicker == newQuestion.displayType || LIOSurveyQuestionDisplayTypePicker == newQuestion.displayType)
        {
            NSArray *entryArray = [aQuestionDict objectForKey:@"entries"];
            for (NSDictionary *anEntryDict in entryArray)
            {
                LIOSurveyPickerEntry *newPickerEntry = [[[LIOSurveyPickerEntry alloc] init] autorelease];
                newPickerEntry.initiallyChecked = [[anEntryDict objectForKey:@"checked"] boolValue];
                newPickerEntry.label = [anEntryDict objectForKey:@"value"];
                
                NSDictionary *logicDict = [anEntryDict objectForKey:@"logic"];
                for (NSString *aKey in logicDict)
                {
                    LIOSurveyLogicProp *newLogicProp = [[[LIOSurveyLogicProp alloc] init] autorelease];
                    if ([aKey isEqualToString:@"showLogicId"])
                        newLogicProp.propType = LIOSurveyLogicPropTypeShow;
                    
                    newLogicProp.targetLogicId = [[logicDict objectForKey:aKey] intValue];
                }
            }
        }
    }
    
    newTemplate.questions = questions;
    
    if (LIOSurveyManagerSurveyTypePre == surveyType)
    {
        [preChatHeader release];
        preChatHeader = [headerString retain];
        
        [preChatTemplate release];
        preChatTemplate = newTemplate;
    }
    else
    {
        [postChatHeader release];
        postChatHeader = [headerString retain];
        
        [postChatTemplate release];
        postChatTemplate = newTemplate;
    }
}

@end