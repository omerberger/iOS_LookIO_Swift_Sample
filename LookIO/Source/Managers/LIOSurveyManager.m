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
#import "LIOLogManager.h"
#import "LIOSurveyLogicItem.h"

static LIOSurveyManager *sharedSurveyManager = nil;

@implementation LIOSurveyManager

@synthesize preChatHeader, postChatHeader, offlineHeader, preChatTemplate, postChatTemplate, offlineTemplate, lastCompletedQuestionIndexPre, lastCompletedQuestionIndexPost, lastCompletedQuestionIndexOffline, preSurveyCompleted;

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
        /*
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        NSDictionary *savedPreChatDict = [userDefaults objectForKey:LIOSurveyManagerLastKnownPreChatSurveyDictKey];
        if (savedPreChatDict)
            [self populateTemplateWithDictionary:savedPreChatDict type:LIOSurveyManagerSurveyTypePre];
        NSDictionary *savedPostChatDict = [userDefaults objectForKey:LIOSurveyManagerLastKnownPostChatSurveyDictKey];
        if (savedPostChatDict)
            [self populateTemplateWithDictionary:savedPostChatDict type:LIOSurveyManagerSurveyTypePost];
         */
        
        preChatResponses = [[NSMutableDictionary alloc] init];
        postChatResponses = [[NSMutableDictionary alloc] init];
        offlineResponses = [[NSMutableDictionary alloc] init];
        
        lastCompletedQuestionIndexPre = lastCompletedQuestionIndexPost = lastCompletedQuestionIndexOffline = -1;
        
        preSurveyCompleted = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [preChatHeader release];
    [postChatHeader release];
    [offlineHeader release];
    
    [preChatTemplate release];
    [postChatTemplate release];
    [offlineTemplate release];
    
    [preChatResponses release];
    [postChatResponses release];
    [offlineResponses release];
    
    [super dealloc];
}

- (void)registerAnswerObject:(id)anAnswerObj forSurveyType:(LIOSurveyManagerSurveyType)surveyType withQuestionIndex:(int)anIndex
{
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        [preChatResponses setObject:anAnswerObj forKey:[NSNumber numberWithInt:anIndex]];
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        [postChatResponses setObject:anAnswerObj forKey:[NSNumber numberWithInt:anIndex]];
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        [offlineResponses setObject:anAnswerObj forKey:[NSNumber numberWithInt:anIndex]];
    
    [self rebuildLogicForSurveyType:surveyType];
    
}

- (void)rebuildLogicForSurveyType:(LIOSurveyManagerSurveyType)surveyType {
    LIOSurveyTemplate *aSurvey;

    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        aSurvey = postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        aSurvey = offlineTemplate;

    
    for (int i=0; i<aSurvey.questions.count; i++) {
        LIOSurveyQuestion* question = [aSurvey.questions objectAtIndex:i];
        
        if (question.displayType != LIOSurveyQuestionDisplayTypeText) {
    
            id aResponse = [[LIOSurveyManager sharedSurveyManager] answerObjectForSurveyType:surveyType withQuestionIndex:i];
    
            if (aResponse) {
                NSMutableArray* answersArray;
                
                if ([aResponse isKindOfClass:[NSString class]]) {
                    NSString* answerString = (NSString*)aResponse;
                    answersArray = [[[NSMutableArray alloc] initWithObjects:answerString, nil] autorelease];
                }
    
                if ([aResponse isKindOfClass:[NSArray class]])
                    answersArray = (NSMutableArray*)aResponse;
    
                // First let's disable all the logic items for the current question's picker entries, and also for questions
                // that are visible through these
                for (LIOSurveyPickerEntry* pickerEntry in question.pickerEntries)
                    for (LIOSurveyLogicItem* logicItem in pickerEntry.logicItems)
                        logicItem.enabled = NO;
    
                // Now let's enable the ones that match the current answers
    
                for (NSString* answer in answersArray)
                    for (LIOSurveyPickerEntry* pickerEntry in question.pickerEntries)
                        if ([pickerEntry.label isEqualToString:answer])
                            for (LIOSurveyLogicItem* logicItem in pickerEntry.logicItems)
                                logicItem.enabled = YES;
            }
        }
    }
}

- (id)answerObjectForSurveyType:(LIOSurveyManagerSurveyType)surveyType withQuestionIndex:(int)anIndex
{
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        return [preChatResponses objectForKey:[NSNumber numberWithInt:anIndex]];
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        return [postChatResponses objectForKey:[NSNumber numberWithInt:anIndex]];
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        return [offlineResponses objectForKey:[NSNumber numberWithInt:anIndex]];
}

- (BOOL)responsesRequiredForSurveyType:(LIOSurveyManagerSurveyType)surveyType
{
    LIOSurveyTemplate *aSurvey;
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        aSurvey = postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        aSurvey = offlineTemplate;
    
    int unansweredMandatoryQuestions = 0;
    for (int i=0; i<[aSurvey.questions count]; i++)
    {
        LIOSurveyQuestion *aQuestion = (LIOSurveyQuestion *)[aSurvey.questions objectAtIndex:i];
        id anAnswer = [self answerObjectForSurveyType:surveyType withQuestionIndex:i];
        if (aQuestion.mandatory && nil == anAnswer)
            unansweredMandatoryQuestions++;
    }
    
    return unansweredMandatoryQuestions;
}

- (int)nextQuestionWithResponseRequiredForSurveyType:(LIOSurveyManagerSurveyType)surveyType
{
    LIOSurveyTemplate *aSurvey;
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        aSurvey = postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        aSurvey = offlineTemplate;
    
    for (int i=0; i<[aSurvey.questions count]; i++)
    {
        LIOSurveyQuestion *aQuestion = (LIOSurveyQuestion *)[aSurvey.questions objectAtIndex:i];
        id anAnswer = [self answerObjectForSurveyType:surveyType withQuestionIndex:i];
        if (aQuestion.mandatory && nil == anAnswer)
            return i;
    }
    
    return -1;
}

- (void)clearAllResponsesForSurveyType:(LIOSurveyManagerSurveyType)surveyType
{
    LIOSurveyTemplate *aSurvey;
    NSMutableDictionary *responseDict;
    if (LIOSurveyManagerSurveyTypePre == surveyType) {
        aSurvey = preChatTemplate;
        responseDict = preChatResponses;
    }
    if (LIOSurveyManagerSurveyTypePost == surveyType) {
        aSurvey = postChatTemplate;
        responseDict = postChatResponses;
    }
    if (LIOSurveyManagerSurveyTypeOffline == surveyType) {
        aSurvey = offlineTemplate;
        responseDict = offlineResponses;
    }

    [responseDict removeAllObjects];

    NSArray* allLogicKeys = [aSurvey.logicDictionary allKeys];
    for (int i=0; i<allLogicKeys.count; i++) {
        NSNumber* key = [allLogicKeys objectAtIndex:i];
        LIOSurveyLogicItem* logicItem = [aSurvey.logicDictionary objectForKey:key];
        logicItem.enabled = NO;
    }
}

- (int)realIndexWithLogicOfQuestionAtIndex:(int)anIndex forSurveyType:(LIOSurveyManagerSurveyType)surveyType {
    LIOSurveyTemplate *aSurvey;
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        aSurvey = postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        aSurvey = offlineTemplate;
    
    int realIndex = 0;
    
    // For each question, we need to see if the target of any of the logic elements.
    // If it isn't, we should display it/count it
    // If it is, we need to make sure that the correct answer was selected, otherwise we hide it
    
    for (int i=0; i<aSurvey.questions.count; i++) {
        if (i == anIndex)
            return realIndex;

        BOOL shouldCountQuestion = YES;
        LIOSurveyQuestion* question = [aSurvey.questions objectAtIndex:i];
        
        // If the question is a target of any logic, it will be in the survey's logic dictionary
        LIOSurveyLogicItem* logicItem = [aSurvey.logicDictionary objectForKey:[NSNumber numberWithInt:question.logicId]];
        if (logicItem)
            if (!logicItem.enabled)
                shouldCountQuestion = NO;
        
        if (shouldCountQuestion)
            realIndex += 1;
        
    }
    
    return realIndex;
}

- (int)numberOfQuestionsWithLogicForSurveyType:(LIOSurveyManagerSurveyType)surveyType {
    LIOSurveyTemplate *aSurvey;
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        aSurvey = postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        aSurvey = offlineTemplate;
    
    int numberOfQuestions = 0;
    
    // For each question, we need to see if the target of any of the logic elements.
    // If it isn't, we should display it/count it
    // If it is, we need to make sure that the correct answer was selected, otherwise we hide it
    
    for (LIOSurveyQuestion* question in aSurvey.questions) {
        BOOL shouldShowQuestion = YES;

        // If the question is a target of any logic, it will be in the survey's logic dictionary
        LIOSurveyLogicItem* logicItem = [aSurvey.logicDictionary objectForKey:[NSNumber numberWithInt:question.logicId]];
        if (logicItem)
            if (!logicItem.enabled)
                shouldShowQuestion = NO;

        if (shouldShowQuestion)
            numberOfQuestions += 1;
    }

    return numberOfQuestions;
}

- (BOOL)shouldShowQuestion:(int)index surveyType:(LIOSurveyManagerSurveyType)surveyType {
    LIOSurveyTemplate *aSurvey;
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        aSurvey = postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        aSurvey = offlineTemplate;
    
    LIOSurveyQuestion* question = [aSurvey.questions objectAtIndex:index];
    BOOL shouldShowQuestion = YES;
        
    // If the question is a target of any logic, it will be in the survey's logic dictionary
    LIOSurveyLogicItem* logicItem = [aSurvey.logicDictionary objectForKey:[NSNumber numberWithInt:question.logicId]];
    if (logicItem)
        if (!logicItem.enabled)
            shouldShowQuestion = NO;
        
    return shouldShowQuestion;
}


- (void)populateTemplateWithDictionary:(NSDictionary *)aDict type:(LIOSurveyManagerSurveyType)surveyType
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Delete current survey if aDict is empty.
    if (0 == [aDict count])
    {
        if (LIOSurveyManagerSurveyTypePre == surveyType)
        {
            [userDefaults removeObjectForKey:LIOSurveyManagerLastKnownPreChatSurveyDictKey];
            
            [preChatHeader release];
            preChatHeader = nil;
            
            [preChatTemplate release];
            preChatTemplate = nil;
            
            [preChatResponses removeAllObjects];
        }
        if (LIOSurveyManagerSurveyTypePost == surveyType)
        {
            [userDefaults removeObjectForKey:LIOSurveyManagerLastKnownPostChatSurveyDictKey];
            
            [postChatHeader release];
            postChatHeader = nil;
            
            [postChatTemplate release];
            postChatTemplate = nil;
            
            [postChatResponses removeAllObjects];
        }
        if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        {
            [userDefaults removeObjectForKey:LIOSurveyManagerLastKnownOfflineSurveyDictKey];
            
            [offlineHeader release];
            offlineHeader = nil;
            
            [offlineTemplate release];
            offlineTemplate = nil;
            
            [offlineResponses removeAllObjects];
        }

        return;
    }
    
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        [userDefaults setObject:aDict forKey:LIOSurveyManagerLastKnownPreChatSurveyDictKey];
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        [userDefaults setObject:aDict forKey:LIOSurveyManagerLastKnownPostChatSurveyDictKey];
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        [userDefaults setObject:aDict forKey:LIOSurveyManagerLastKnownOfflineSurveyDictKey];
    
    NSString *headerString = [aDict objectForKey:@"header"];
    NSNumber *idNumber = [aDict objectForKey:@"id"];
    
    LIOSurveyTemplate *newTemplate = [[LIOSurveyTemplate alloc] init];
    NSDictionary *questionsDict = [aDict objectForKey:@"questions"];
    NSArray* questionIdsArray = [questionsDict allKeys];
    NSMutableArray *questions = [NSMutableArray array];
    NSMutableDictionary *logicDictionary = [[NSMutableDictionary alloc] init];
    
    for (NSString* aQuestionId in questionIdsArray)
    {
        LIOSurveyQuestion *newQuestion = [[[LIOSurveyQuestion alloc] init] autorelease];
        NSDictionary* aQuestionDict = [questionsDict objectForKey:aQuestionId];
        
        NSLog(@"%@", aQuestionDict);
        newQuestion.questionId = [aQuestionId intValue];
        newQuestion.mandatory = [[aQuestionDict objectForKey:@"mandatory"] boolValue];
        newQuestion.order = [[aQuestionDict objectForKey:@"order"] intValue];
        newQuestion.label = [aQuestionDict objectForKey:@"label"];
        newQuestion.logicId = [[aQuestionDict objectForKey:@"logic_id"] intValue];
        newQuestion.validationRegexp = [aQuestionDict objectForKey:@"validationRegexp"];
        newQuestion.lastKnownValue = [aQuestionDict objectForKey:@"last_known_value"];
        
        NSString *typeString = [aQuestionDict objectForKey:@"type"];
        newQuestion.displayType = LIOSurveyQuestionDisplayTypeText;

        if ([typeString isEqualToString:@"Dropdown Box"])
            newQuestion.displayType = LIOSurveyQuestionDisplayTypePicker;
        if ([typeString isEqualToString:@"Radio Button"])
            newQuestion.displayType = LIOSurveyQuestionDisplayTypePicker;
        if ([typeString isEqualToString:@"Radio Button (side by side)"])
            newQuestion.displayType = LIOSurveyQuestionDisplayTypePicker;
        if ([typeString isEqualToString:@"Checkbox"])
            newQuestion.displayType = LIOSurveyQuestionDisplayTypeMultiselect;
        
        NSString *validationString = [aQuestionDict objectForKey:@"validation_type"];
        if ([validationString isEqualToString:@"alpha_numeric"])
            newQuestion.validationType = LIOSurveyQuestionValidationTypeAlphanumeric;
        else if ([validationString isEqualToString:@"numeric"])
            newQuestion.validationType = LIOSurveyQuestionValidationTypeNumeric;
        else if ([validationString isEqualToString:@"email"])
            newQuestion.validationType = LIOSurveyQuestionValidationTypeEmail;
        else
            newQuestion.validationType = LIOSurveyQuestionValidationTypeRegexp;
        
        if (LIOSurveyQuestionDisplayTypePicker == newQuestion.displayType || LIOSurveyQuestionDisplayTypeMultiselect == newQuestion.displayType)
        {
            NSMutableArray *entries = [NSMutableArray array];
            NSDictionary *entriesDict = [aQuestionDict objectForKey:@"entries"];
            NSArray *entryNames = [entriesDict allKeys];
            for (NSString* anEntryName in entryNames)
            {
                NSDictionary* anEntryDict = [entriesDict objectForKey:anEntryName];
                
                LIOSurveyPickerEntry *newPickerEntry = [[[LIOSurveyPickerEntry alloc] init] autorelease];
                newPickerEntry.initiallyChecked = [[anEntryDict objectForKey:@"checked"] boolValue];
                newPickerEntry.order = [[anEntryDict objectForKey:@"order"] intValue];
                newPickerEntry.label = anEntryName;
                
                NSMutableArray *logicItems = [NSMutableArray array];
                NSArray *logicData = [anEntryDict objectForKey:@"showLogicId"];
                for (NSString *logicId in logicData)
                {
                    LIOSurveyLogicItem* logicItem = [[[LIOSurveyLogicItem alloc] init] autorelease];
                    logicItem.targetLogicId = [logicId intValue];
                    logicItem.sourceLogicId = newQuestion.logicId;
                    logicItem.sourceAnswerLabel = newPickerEntry.label;
                    logicItem.enabled = NO;
                    logicItem.propType = LIOSurveyLogicPropTypeShow;

                    [logicItems addObject:logicItem];                    
                    [logicDictionary setObject:logicItem forKey:[NSNumber numberWithInt:logicItem.targetLogicId]];
                }
                
                newPickerEntry.logicItems = logicItems;
                
                [entries addObject:newPickerEntry];
            }
            
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:TRUE];
            [entries sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            newQuestion.pickerEntries = entries;
            
            if ([newQuestion.pickerEntries count])
                [questions addObject:newQuestion];
        }
        else
        {
            [questions addObject:newQuestion];
        }
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:TRUE];
        [questions sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    }
    
    newTemplate.surveyId = idNumber;
    newTemplate.questions = questions;
    newTemplate.logicDictionary = logicDictionary;
    
    if (LIOSurveyManagerSurveyTypePre == surveyType)
    {
        [preChatHeader release];
        preChatHeader = [headerString retain];
        
        [preChatTemplate release];
        preChatTemplate = newTemplate;
    }
    if (LIOSurveyManagerSurveyTypePost == surveyType)
    {
        [postChatHeader release];
        postChatHeader = [headerString retain];
        
        [postChatTemplate release];
        postChatTemplate = newTemplate;
    }
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
    {
        [offlineHeader release];
        offlineHeader = [headerString retain];
        
        [offlineTemplate release];
        offlineTemplate = newTemplate;
    }

}

@end