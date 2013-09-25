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
#import "LIOBundleManager.h"

static LIOSurveyManager *sharedSurveyManager = nil;

@implementation LIOSurveyManager

@synthesize preChatHeader, postChatHeader, offlineHeader, preChatTemplate, postChatTemplate, offlineTemplate, lastCompletedQuestionIndexPre, lastCompletedQuestionIndexPost, lastCompletedQuestionIndexOffline, preSurveyCompleted, offlineSurveyIsDefault, surveysEnabled, receivedEmptyPreSurvey;

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

        NSDictionary *savedPostChatDict = [userDefaults objectForKey:LIOSurveyManagerLastKnownPostChatSurveyDictKey];
        if (savedPostChatDict)
            [self populateTemplateWithDictionary:savedPostChatDict type:LIOSurveyManagerSurveyTypePost];
        NSDictionary *savedOfflineChatDict = [userDefaults objectForKey:LIOSurveyManagerLastKnownOfflineSurveyDictKey];
        if (savedOfflineChatDict)
            [self populateTemplateWithDictionary:savedOfflineChatDict type:LIOSurveyManagerSurveyTypeOffline];
        
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

- (LIOSurveyTemplate*)surveyTemplateForType:(LIOSurveyManagerSurveyType)surveyType {
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        return self.preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        return self.postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        return self.offlineTemplate;
    
    return nil;
}

- (NSString*)surveyHeaderForType:(LIOSurveyManagerSurveyType)surveyType {
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        return self.preChatHeader;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        return self.postChatHeader;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        return self.offlineHeader;
    
    return nil;
}

- (int)lastCompletedQuestionIndexForType:(LIOSurveyManagerSurveyType)surveyType {
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        return self.lastCompletedQuestionIndexPre;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        return self.lastCompletedQuestionIndexPost;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        return self.lastCompletedQuestionIndexOffline;
    
    return 0;    
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
    LIOSurveyTemplate *aSurvey = nil;
    
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        aSurvey = postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        aSurvey = offlineTemplate;
    
    if (aSurvey != nil) {
        for (int i=0; i<aSurvey.questions.count; i++) {
            LIOSurveyQuestion* question = [aSurvey.questions objectAtIndex:i];
            
            if (question.displayType == LIOSurveyQuestionDisplayTypeMultiselect || question.displayType == LIOSurveyQuestionDisplayTypePicker ) {
                
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
}

- (id)answerObjectForSurveyType:(LIOSurveyManagerSurveyType)surveyType withQuestionIndex:(int)anIndex
{
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        return [preChatResponses objectForKey:[NSNumber numberWithInt:anIndex]];
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        return [postChatResponses objectForKey:[NSNumber numberWithInt:anIndex]];
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        return [offlineResponses objectForKey:[NSNumber numberWithInt:anIndex]];
    
    return nil;
}

- (BOOL)responsesRequiredForSurveyType:(LIOSurveyManagerSurveyType)surveyType
{
    LIOSurveyTemplate *aSurvey = nil;
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        aSurvey = postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        aSurvey = offlineTemplate;
    
    int unansweredMandatoryQuestions = 0;
    if (aSurvey != nil) {
        for (int i=0; i<[aSurvey.questions count]; i++)
        {
            LIOSurveyQuestion *aQuestion = (LIOSurveyQuestion *)[aSurvey.questions objectAtIndex:i];
            id anAnswer = [self answerObjectForSurveyType:surveyType withQuestionIndex:i];
            if (aQuestion.mandatory && nil == anAnswer)
                unansweredMandatoryQuestions++;
        }
    }
    
    return unansweredMandatoryQuestions;
}

- (int)nextQuestionWithResponseRequiredForSurveyType:(LIOSurveyManagerSurveyType)surveyType
{
    LIOSurveyTemplate *aSurvey = nil;
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        aSurvey = postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        aSurvey = offlineTemplate;
    
    if (aSurvey) {
        for (int i=0; i<[aSurvey.questions count]; i++)
        {
            LIOSurveyQuestion *aQuestion = (LIOSurveyQuestion *)[aSurvey.questions objectAtIndex:i];
            id anAnswer = [self answerObjectForSurveyType:surveyType withQuestionIndex:i];
            if (aQuestion.mandatory && nil == anAnswer)
                return i;
        }
    }
    
    return -1;
}

- (void)clearAllResponsesForSurveyType:(LIOSurveyManagerSurveyType)surveyType
{
    LIOSurveyTemplate *aSurvey = nil;
    NSMutableDictionary *responseDict = nil;
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

    if (responseDict != nil)
        [responseDict removeAllObjects];

    if (aSurvey != nil) {
        NSArray* allLogicKeys = [aSurvey.logicDictionary allKeys];
        for (int i=0; i<allLogicKeys.count; i++) {
            NSNumber* key = [allLogicKeys objectAtIndex:i];
            LIOSurveyLogicItem* logicItem = [aSurvey.logicDictionary objectForKey:key];
            logicItem.enabled = NO;
        }
    }
}

- (int)realIndexWithLogicOfQuestionAtIndex:(int)anIndex forSurveyType:(LIOSurveyManagerSurveyType)surveyType {
    LIOSurveyTemplate *aSurvey = nil;
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
    
    if (aSurvey != nil) {
        for (int i=0; i<aSurvey.questions.count; i++) {
            if (i == anIndex)
                return realIndex;
            
            BOOL shouldCountQuestion = YES;
            LIOSurveyQuestion* question = [aSurvey.questions objectAtIndex:i];
            
            // If the question is a target of any logic, it will be in the survey's logic dictionary
            LIOSurveyLogicItem* logicItem = [aSurvey.logicDictionary objectForKey:[NSNumber numberWithInteger:question.logicId]];
            if (logicItem)
                if (!logicItem.enabled)
                    shouldCountQuestion = NO;
            
            if (shouldCountQuestion)
                realIndex += 1;
            
        }
    }
    
    return realIndex;
}

- (int)numberOfQuestionsWithLogicForSurveyType:(LIOSurveyManagerSurveyType)surveyType {
    LIOSurveyTemplate *aSurvey = nil;
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
    
    if (aSurvey != nil) {
        for (LIOSurveyQuestion* question in aSurvey.questions) {
            BOOL shouldShowQuestion = YES;
            
            // If the question is a target of any logic, it will be in the survey's logic dictionary
            LIOSurveyLogicItem* logicItem = [aSurvey.logicDictionary objectForKey:[NSNumber numberWithInteger:question.logicId]];
            if (logicItem)
                if (!logicItem.enabled)
                    shouldShowQuestion = NO;
            
            if (shouldShowQuestion)
                numberOfQuestions += 1;
        }
    }

    return numberOfQuestions;
}

- (BOOL)shouldShowQuestion:(int)index surveyType:(LIOSurveyManagerSurveyType)surveyType {
    LIOSurveyTemplate *aSurvey = nil;
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        aSurvey = postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        aSurvey = offlineTemplate;

    BOOL shouldShowQuestion = YES;
    
    if (aSurvey != nil) {
        
        LIOSurveyQuestion* question = [aSurvey.questions objectAtIndex:index];
        
        // If the question is a target of any logic, it will be in the survey's logic dictionary
        LIOSurveyLogicItem* logicItem = [aSurvey.logicDictionary objectForKey:[NSNumber numberWithInteger:question.logicId]];
        if (logicItem)
            if (!logicItem.enabled)
                shouldShowQuestion = NO;
    }
    
    return shouldShowQuestion;
}

-(NSDictionary*)responseDictForSurveyType:(LIOSurveyManagerSurveyType)surveyType {
    LIOSurveyTemplate *aSurvey = nil;
    
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    if (LIOSurveyManagerSurveyTypePost == surveyType)
        aSurvey = postChatTemplate;
    if (LIOSurveyManagerSurveyTypeOffline == surveyType)
        aSurvey = offlineTemplate;
    
    NSMutableArray* questionsArray = [NSMutableArray array];
    
    if (aSurvey != nil) {
        for (int i=0; i<[aSurvey.questions count]; i++)
        {
            // Only send answers for questions that should be visible according to the current logic
            if ([self shouldShowQuestion:i surveyType:surveyType]) {
                NSMutableDictionary *questionDict = [NSMutableDictionary dictionary];
                
                LIOSurveyQuestion *aQuestion = (LIOSurveyQuestion *)[aSurvey.questions objectAtIndex:i];
                [questionDict setObject:[NSString stringWithFormat:@"%ld", (long)aQuestion.questionId] forKey:@"question_id"];
                
                id aResponse = [self answerObjectForSurveyType:surveyType withQuestionIndex:i];
                if (aResponse != nil) {
                    [questionDict setObject:aResponse forKey:@"answer"];
                    [questionsArray addObject:questionDict];
                }
            }
        }
        
        NSMutableDictionary *surveyDict = [NSMutableDictionary dictionary];
        [surveyDict setObject:aSurvey.surveyId forKey:@"id"];
        [surveyDict setObject:questionsArray forKey:@"questions"];
        
        return surveyDict;
    }
    
    return nil;
}

- (void)populateDefaultOfflineSurvey {
    NSString *headerString = LIOLocalizedString(@"LIOSurveyView.DefaultOfflineSurveyHeader");
    
    LIOSurveyTemplate *newTemplate = [[LIOSurveyTemplate alloc] init];
    NSMutableDictionary *logicDictionary = [[[NSMutableDictionary alloc] init] autorelease];

    LIOSurveyQuestion *emailQuestion = [[[LIOSurveyQuestion alloc] init] autorelease];
    emailQuestion.questionId = 0;
    emailQuestion.mandatory = YES;
    emailQuestion.order = 0;
    emailQuestion.logicId = 0;
    emailQuestion.lastKnownValue = @"";
    emailQuestion.label = LIOLocalizedString(@"LIOSurveyView.DefaultOfflineSurveyLeaveEmailTitle");
    emailQuestion.displayType = LIOSurveyQuestionDisplayTypeTextField;
    emailQuestion.validationType = LIOSurveyQuestionValidationTypeEmail;
    
    LIOSurveyQuestion *messageQuestion = [[[LIOSurveyQuestion alloc] init] autorelease];
    messageQuestion.questionId = 0;
    messageQuestion.mandatory = YES;
    messageQuestion.order = 1;
    messageQuestion.logicId = 1;
    messageQuestion.lastKnownValue = @"";
    messageQuestion.label = LIOLocalizedString(@"LIOSurveyView.DefaultOfflineSurveyLeaveMessageTitle");
    messageQuestion.displayType = LIOSurveyQuestionDisplayTypeTextArea;
    emailQuestion.validationType = LIOSurveyQuestionValidationTypeAlphanumeric;

    newTemplate.surveyId = [NSNumber numberWithInt:0];
    newTemplate.questions = [NSArray arrayWithObjects:emailQuestion, messageQuestion, nil];
    newTemplate.logicDictionary = logicDictionary;
    
    [offlineResponses removeAllObjects];

    [offlineHeader release];
    offlineHeader = [headerString retain];
        
    [offlineTemplate release];
    offlineTemplate = newTemplate;
}

- (void)clearTemplateForSurveyType:(LIOSurveyManagerSurveyType)surveyType {
    if (LIOSurveyManagerSurveyTypePre == surveyType) {
        if (preChatHeader) {
            [preChatHeader release];
            preChatHeader = nil;
        }
        
        if (preChatTemplate) {
            [preChatTemplate release];
            preChatTemplate = nil;
        }
    }
    
    if (LIOSurveyManagerSurveyTypePost == surveyType) {
        if (postChatHeader) {
            [postChatHeader release];
            postChatHeader = nil;
        }
        
        if (postChatTemplate) {
            [postChatTemplate release];
            postChatTemplate = nil;
        }
    }
    
    if (LIOSurveyManagerSurveyTypeOffline == surveyType) {
        if (offlineHeader) {
            [offlineHeader release];
            offlineHeader = nil;
        }
        
        if (offlineTemplate) {
            [offlineTemplate release];
            offlineTemplate = nil;
        }
    }
}


- (void)populateTemplateWithDictionary:(NSDictionary *)aDict type:(LIOSurveyManagerSurveyType)surveyType
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Delete current survey if aDict is empty.
    if (0 == [aDict count])
    {
        if (LIOSurveyManagerSurveyTypePre == surveyType)
        {
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
        
        newQuestion.questionId = [aQuestionId integerValue];
        newQuestion.mandatory = [[aQuestionDict objectForKey:@"mandatory"] boolValue];
        newQuestion.order = [[aQuestionDict objectForKey:@"order"] integerValue];
        newQuestion.label = [aQuestionDict objectForKey:@"label"];
        newQuestion.logicId = [[aQuestionDict objectForKey:@"logic_id"] integerValue];
        newQuestion.lastKnownValue = [aQuestionDict objectForKey:@"last_known_value"];
        
        NSString *typeString = [aQuestionDict objectForKey:@"type"];
        newQuestion.displayType = LIOSurveyQuestionDisplayTypeTextField;

        if ([typeString isEqualToString:@"Text Area"])
            newQuestion.displayType = LIOSurveyQuestionDisplayTypeTextArea;
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
                newPickerEntry.order = [[anEntryDict objectForKey:@"order"] integerValue];
                newPickerEntry.label = anEntryName;
                
                NSMutableArray *logicItems = [NSMutableArray array];
                NSArray *logicData = [anEntryDict objectForKey:@"showLogicId"];
                for (NSString *logicId in logicData)
                {
                    LIOSurveyLogicItem* logicItem = [[[LIOSurveyLogicItem alloc] init] autorelease];
                    logicItem.targetLogicId = [logicId integerValue];
                    logicItem.sourceLogicId = newQuestion.logicId;
                    logicItem.sourceAnswerLabel = newPickerEntry.label;
                    logicItem.enabled = NO;
                    logicItem.propType = LIOSurveyLogicPropTypeShow;

                    [logicItems addObject:logicItem];                    
                    [logicDictionary setObject:logicItem forKey:[NSNumber numberWithInteger:logicItem.targetLogicId]];
                }
                
                newPickerEntry.logicItems = logicItems;
                
                [entries addObject:newPickerEntry];
            }
            
            NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"order" ascending:TRUE] autorelease];
            [entries sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            newQuestion.pickerEntries = entries;
            
            if ([newQuestion.pickerEntries count])
                [questions addObject:newQuestion];
        }
        else
        {
            [questions addObject:newQuestion];
        }
        
        NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"order" ascending:TRUE] autorelease];
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