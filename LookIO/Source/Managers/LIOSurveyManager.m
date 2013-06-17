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

@synthesize preChatHeader, postChatHeader, preChatTemplate, postChatTemplate, lastCompletedQuestionIndexPre, lastCompletedQuestionIndexPost;

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
        
        lastCompletedQuestionIndexPre = lastCompletedQuestionIndexPost = -1;
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

- (void)registerAnswerObject:(id)anAnswerObj forSurveyType:(LIOSurveyManagerSurveyType)surveyType withQuestionIndex:(int)anIndex
{
    if (LIOSurveyManagerSurveyTypePre == surveyType)
    {
        [preChatResponses setObject:anAnswerObj forKey:[NSNumber numberWithInt:anIndex]];
    }
    else
    {
        [postChatResponses setObject:anAnswerObj forKey:[NSNumber numberWithInt:anIndex]];
    }
}

- (id)answerObjectForSurveyType:(LIOSurveyManagerSurveyType)surveyType withQuestionIndex:(int)anIndex
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

- (BOOL)responsesRequiredForSurveyType:(LIOSurveyManagerSurveyType)surveyType
{
    LIOSurveyTemplate *aSurvey;
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    else
        aSurvey = postChatTemplate;
    
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
    else
        aSurvey = postChatTemplate;
    
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
    if (LIOSurveyManagerSurveyTypePre == surveyType)
    {
        [preChatResponses removeAllObjects];
    }
    else
    {
        [postChatResponses removeAllObjects];
    }
}

- (int)numberOfQuestionsWithLogicForSurveyType:(LIOSurveyManagerSurveyType)surveyType {
    LIOSurveyTemplate *aSurvey;
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    else
        aSurvey = postChatTemplate;
    
    int numberOfQuestions = 0;
    
    // For each question, we need to see if the target of any of the logic elements.
    // If it isn't, we should display it/count it
    // If it is, we need to make sure that the correct answer was selected, otherwise we hide it
    
    for (LIOSurveyQuestion* question in aSurvey.questions) {
        BOOL shouldShowQuestion = YES;

        // If the question is a target of any logic, it will be in the survey's logic dictionary
        LIOSurveyLogicItem* logicItem = [aSurvey.logicDictionary objectForKey:[NSNumber numberWithInt:question.questionId]];
        if (logicItem)
            if (!logicItem.enabled)
                shouldShowQuestion = NO;

        if (shouldShowQuestion)
            numberOfQuestions += 1;
    }

    return numberOfQuestions;
}

- (LIOSurveyQuestion*)questionWithLogicForIndex:(int)index surveyType:(LIOSurveyManagerSurveyType)surveyType {
    LIOSurveyTemplate *aSurvey;
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        aSurvey = preChatTemplate;
    else
        aSurvey = postChatTemplate;
    
    int arrayIndex = 0;
    int questionIndex = 0;
    while (questionIndex <= index) {
        // Let's make sure we're not accessing a non-existant index
        if (arrayIndex > aSurvey.questions.count - 1)
            return nil;
        
        LIOSurveyQuestion* question = [aSurvey.questions objectAtIndex:arrayIndex];

        BOOL shouldShowQuestion = YES;
        
        // If the question is a target of any logic, it will be in the survey's logic dictionary
        LIOSurveyLogicItem* logicItem = [aSurvey.logicDictionary objectForKey:[NSNumber numberWithInt:question.questionId]];
        if (logicItem)
            if (!logicItem.enabled)
                shouldShowQuestion = NO;
        
        if (!shouldShowQuestion) {
            // If this question is hidden, just advance past it, without increasing the index
            arrayIndex += 1;
        } else {
            // If this is our target question, let's return it
            if (questionIndex == index) {
                NSLog(@"Question for index %d has a title %@ (Index in the array is %d)", index, question.label, arrayIndex);
                return question;
            }
            
            // If not, let's advance both indexes
            arrayIndex += 1;
            questionIndex += 1;
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
            [userDefaults removeObjectForKey:LIOSurveyManagerLastKnownPreChatSurveyDictKey];
            
            [preChatHeader release];
            preChatHeader = nil;
            
            [preChatTemplate release];
            preChatTemplate = nil;
            
            [preChatResponses removeAllObjects];
        }
        else
        {
            [userDefaults removeObjectForKey:LIOSurveyManagerLastKnownPostChatSurveyDictKey];
            
            [postChatHeader release];
            postChatHeader = nil;
            
            [postChatTemplate release];
            postChatTemplate = nil;
            
            [postChatResponses removeAllObjects];
        }
        
        return;
    }
    
    if (LIOSurveyManagerSurveyTypePre == surveyType)
        [userDefaults setObject:aDict forKey:LIOSurveyManagerLastKnownPreChatSurveyDictKey];
    else
        [userDefaults setObject:aDict forKey:LIOSurveyManagerLastKnownPostChatSurveyDictKey];
    
    NSString *headerString = [aDict objectForKey:@"header"];
    NSNumber *idNumber = [aDict objectForKey:@"id"];
    
    LIOSurveyTemplate *newTemplate = [[LIOSurveyTemplate alloc] init];
    NSDictionary *questionsDict = [aDict objectForKey:@"questions"];
    NSArray* questionIdsArray = [questionsDict allKeys];
    NSMutableArray *questions = [NSMutableArray array];
    NSMutableDictionary *logicDictionary = [NSMutableDictionary dictionary];
    
    for (NSString* aQuestionId in questionIdsArray)
    {
        LIOSurveyQuestion *newQuestion = [[[LIOSurveyQuestion alloc] init] autorelease];
        NSDictionary* aQuestionDict = [questionsDict objectForKey:aQuestionId];
        
        NSLog(@"%@", aQuestionDict);
        newQuestion.questionId = [aQuestionId intValue];
        newQuestion.mandatory = [[aQuestionDict objectForKey:@"mandatory"] boolValue];
        newQuestion.order = [[aQuestionDict objectForKey:@"order"] intValue];
        newQuestion.label = [aQuestionDict objectForKey:@"label"];
        newQuestion.logicId = [[aQuestionDict objectForKey:@"logicId"] intValue];
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
                NSLog(@"order is %d", newPickerEntry.order);
                newPickerEntry.label = anEntryName;
                
                NSMutableArray *logicProps = [NSMutableArray array];
                NSDictionary *logicData = [anEntryDict objectForKey:@"logic"];
                for (NSString *aKey in logicData)
                {
                    LIOSurveyLogicProp *newLogicProp = [[[LIOSurveyLogicProp alloc] init] autorelease];
                    if ([aKey isEqualToString:@"showLogicId"])
                        newLogicProp.propType = LIOSurveyLogicPropTypeShow;
                    
                    newLogicProp.targetLogicId = [[logicData objectForKey:aKey] intValue];
                    
                    [logicProps addObject:newLogicProp];
                    
                    LIOSurveyLogicItem* logicItem = [[[LIOSurveyLogicItem alloc] init] autorelease];
                    logicItem.targetLogicId = [[logicData objectForKey:aKey] intValue];
                    logicItem.sourceLogicId = newQuestion.logicId;
                    logicItem.sourceAnswerLabel = newPickerEntry.label;
                    logicItem.enabled = NO;
                    logicItem.propType = LIOSurveyLogicPropTypeShow;
                        
                    [logicDictionary setObject:logicItem forKey:[NSNumber numberWithInt:logicItem.targetLogicId]];
                }
                
                newPickerEntry.logicProps = logicProps;
                
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
    else
    {
        [postChatHeader release];
        postChatHeader = [headerString retain];
        
        [postChatTemplate release];
        postChatTemplate = newTemplate;
    }
}

@end