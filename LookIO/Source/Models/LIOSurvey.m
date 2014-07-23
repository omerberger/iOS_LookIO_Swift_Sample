//
//  LIOSurvey.m
//  LookIO
//
//  Created by Yaron Karasik on 12/31/13.
//
//

#import "LIOSurvey.h"

#import "LIOSurveyQuestion.h"
#import "LIOSurveyPickerEntry.h"
#import "LIOSurveyLogicItem.h"

#import "LIOBundleManager.h"

@interface LIOSurvey ()

@property (nonatomic, copy) NSString *header;
@property (nonatomic, strong) NSMutableDictionary *responses;
@property (nonatomic, assign) BOOL wasSubmitted;
@property (nonatomic, strong) NSString *surveyId;
@property (nonatomic, strong) NSDictionary *logicDictionary;

@end

@implementation LIOSurvey

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.hasMandatoryQuestions = NO;

        self.responses = [[NSMutableDictionary alloc] init];
        self.lastCompletedQuestionIndex = LIOSurveyViewControllerIndexForIntroPage;
        self.lastSeenQuestionIndex = LIOSurveyViewControllerIndexForIntroPage;
        
        self.isSubmittedUncompletedPostChatSurvey = NO;
    }
    
    return self;
}

- (id)initWithSurveyDictionary:(NSDictionary *)aDictionary surveyType:(LIOSurveyType)surveyType
{
    self = [super init];
    
    if (self)
    {
        self.surveyType = surveyType;
        self.hasMandatoryQuestions = NO;

        self.responses = [[NSMutableDictionary alloc] init];
        self.lastCompletedQuestionIndex = LIOSurveyViewControllerIndexForIntroPage;
        self.lastSeenQuestionIndex = LIOSurveyViewControllerIndexForIntroPage;
        
        [self populateTemplateWithDictionary:aDictionary];
        
        self.isSubmittedUncompletedPostChatSurvey = NO;
    }
    
    return self;
}

- (id)initWithDefaultOfflineSurveyWithResponse:(NSString *)response
{
    self = [super init];
    
    if (self)
    {
        self.hasMandatoryQuestions = NO;

        self.responses = [[NSMutableDictionary alloc] init];
        self.lastCompletedQuestionIndex = LIOSurveyViewControllerIndexForIntroPage;
        self.lastSeenQuestionIndex = LIOSurveyViewControllerIndexForIntroPage;
        
        [self populateDefaultOfflineSurveyWithResponse:response];

        self.isSubmittedUncompletedPostChatSurvey = NO;
    }
    
    return self;
}

- (void)registerAnswerObject:(id)anAnswerObj withQuestionIndex:(NSInteger)anIndex
{
    [self.responses setObject:anAnswerObj forKey:[NSNumber numberWithInteger:anIndex]];
    [self rebuildLogicDictionary];
}

- (void)clearAnswerForQuestionIndex:(NSInteger)anIndex
{
    [self.responses removeObjectForKey:[NSNumber numberWithInteger:anIndex]];
    [self rebuildLogicDictionary];
}

- (void)rebuildLogicDictionary
{
    for (int i=0; i < self.questions.count; i++)
    {
        LIOSurveyQuestion* question = [self.questions objectAtIndex:i];
        
        if (question.displayType == LIOSurveyQuestionDisplayTypeMultiselect || question.displayType == LIOSurveyQuestionDisplayTypePicker )
        {
            id aResponse = [self answerObjectForQuestionIndex:i];
            
            if (aResponse)
            {
                NSMutableArray* answersArray;
                
                if ([aResponse isKindOfClass:[NSString class]]) {
                    NSString* answerString = (NSString*)aResponse;
                    answersArray = [[NSMutableArray alloc] initWithObjects:answerString, nil];
                }
                
                if ([aResponse isKindOfClass:[NSArray class]])
                {
                    answersArray = (NSMutableArray*)aResponse;
                }
                
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
            else
            {
                for (LIOSurveyPickerEntry* pickerEntry in question.pickerEntries)
                    for (LIOSurveyLogicItem* logicItem in pickerEntry.logicItems)
                        logicItem.enabled = NO;
            }
        }
    }
}

- (id)answerObjectForQuestionIndex:(NSInteger)anIndex
{
    return [self.responses objectForKey:[NSNumber numberWithInteger:anIndex]];
}

- (BOOL)allMandatoryQuestionsAnswered
{
    int unansweredMandatoryAndVisibleQuestions = 0;
    for (int i=0; i<[self.questions count]; i++)
    {
        LIOSurveyQuestion *aQuestion = (LIOSurveyQuestion *)[self.questions objectAtIndex:i];
        
        // Let's check if this question is visible according to current logic, and is mandatory
        if ([self shouldShowQuestion:i] && aQuestion.mandatory)
        {
            id anAnswer = [self answerObjectForQuestionIndex:i];
            
            // Let's check if it's unanswered
            if (nil == anAnswer)
                unansweredMandatoryAndVisibleQuestions += 1;
        }
    }
    
    return (unansweredMandatoryAndVisibleQuestions == 0);
}

- (NSInteger)nextQuestionWithResponseRequired
{
    for (int i=0; i<[self.questions count]; i++)
    {
        LIOSurveyQuestion *aQuestion = (LIOSurveyQuestion *)[self.questions objectAtIndex:i];
        id anAnswer = [self answerObjectForQuestionIndex:i];
        if (aQuestion.mandatory && nil == anAnswer)
            return i;
    }
    
    return -1;
}

- (void)clearAllResponses
{
    // Remove all responses
    [self.responses removeAllObjects];
    
    // Clear logic
    NSArray* allLogicKeys = [self.logicDictionary allKeys];
    for (int i=0; i<allLogicKeys.count; i++)
    {
        NSNumber* key = [allLogicKeys objectAtIndex:i];
        LIOSurveyLogicItem* logicItem = [self.logicDictionary objectForKey:key];
        logicItem.enabled = NO;
    }
}

- (NSInteger)realIndexWithLogicOfQuestionAtIndex:(NSInteger)anIndex
{
    NSInteger realIndex = 0;
    
    // For each question, we need to see if the target of any of the logic elements.
    // If it isn't, we should display it/count it
    // If it is, we need to make sure that the correct answer was selected, otherwise we hide it
    
    for (int i=0; i < self.questions.count; i++)
    {
        if (i == anIndex)
            return realIndex;
        
        BOOL shouldCountQuestion = YES;
        LIOSurveyQuestion* question = [self.questions objectAtIndex:i];
        
        // If the question is a target of any logic, it will be in the survey's logic dictionary
        LIOSurveyLogicItem* logicItem = [self.logicDictionary objectForKey:[NSNumber numberWithInteger:question.logicId]];
        if (logicItem)
            if (!logicItem.enabled)
                shouldCountQuestion = NO;
        
        if (shouldCountQuestion)
            realIndex += 1;
    }
    
    return realIndex;
}

- (NSInteger)numberOfQuestionsWithLogic
{
    NSInteger numberOfQuestions = 0;
    
    // For each question, we need to see if the target of any of the logic elements.
    // If it isn't, we should display it/count it
    // If it is, we need to make sure that the correct answer was selected, otherwise we hide it
    
    for (LIOSurveyQuestion* question in self.questions) {
        BOOL shouldShowQuestion = YES;
        
        // If the question is a target of any logic, it will be in the survey's logic dictionary
        LIOSurveyLogicItem* logicItem = [self.logicDictionary objectForKey:[NSNumber numberWithInteger:question.logicId]];
        if (logicItem)
            if (!logicItem.enabled)
                shouldShowQuestion = NO;
        
        if (shouldShowQuestion)
            numberOfQuestions += 1;
    }
    
    return numberOfQuestions;
}

- (BOOL)shouldShowQuestion:(NSInteger)index
{
    BOOL shouldShowQuestion = YES;
    
    LIOSurveyQuestion* question = [self.questions objectAtIndex:index];
    
    // If the question is a target of any logic, it will be in the survey's logic dictionary
    LIOSurveyLogicItem* logicItem = [self.logicDictionary objectForKey:[NSNumber numberWithInteger:question.logicId]];
    if (logicItem)
        if (!logicItem.enabled)
            shouldShowQuestion = NO;
    
    return shouldShowQuestion;
}

- (NSDictionary*)responseDict
{
    NSMutableArray* questionsArray = [NSMutableArray array];
    
    for (int i=0; i<[self.questions count]; i++)
    {
        // Only send answers for questions that should be visible according to the current logic
        if ([self shouldShowQuestion:i]) {
            NSMutableDictionary *questionDict = [NSMutableDictionary dictionary];
            
            LIOSurveyQuestion *aQuestion = (LIOSurveyQuestion *)[self.questions objectAtIndex:i];
            [questionDict setObject:[NSString stringWithFormat:@"%ld", (long)aQuestion.questionId] forKey:@"question_id"];
            
            id aResponse = [self answerObjectForQuestionIndex:i];
            if (aResponse != nil) {
                [questionDict setObject:aResponse forKey:@"answer"];
                [questionsArray addObject:questionDict];
            }
        }
    }
    
    NSMutableDictionary *surveyDict = [NSMutableDictionary dictionary];
    [surveyDict setObject:self.surveyId forKey:@"id"];
    [surveyDict setObject:questionsArray forKey:@"questions"];
    
    return surveyDict;
}


- (void)populateDefaultOfflineSurveyWithResponse:(NSString*)response
{
    self.header = LIOLocalizedString(@"LIOSurveyView.DefaultOfflineSurveyHeader");
    
    LIOSurveyQuestion *emailQuestion = [[LIOSurveyQuestion alloc] init];
    emailQuestion.questionId = 0;
    emailQuestion.mandatory = YES;
    emailQuestion.order = 0;
    emailQuestion.logicId = 0;
    emailQuestion.lastKnownValue = @"";
    emailQuestion.label = LIOLocalizedString(@"LIOSurveyView.DefaultOfflineSurveyLeaveEmailTitle");
    emailQuestion.displayType = LIOSurveyQuestionDisplayTypeTextField;
    emailQuestion.validationType = LIOSurveyQuestionValidationTypeEmail;
    
    LIOSurveyQuestion *messageQuestion = [[LIOSurveyQuestion alloc] init];
    messageQuestion.questionId = 0;
    messageQuestion.mandatory = YES;
    messageQuestion.order = 1;
    messageQuestion.logicId = 1;
    messageQuestion.lastKnownValue = @"";
    messageQuestion.label = LIOLocalizedString(@"LIOSurveyView.DefaultOfflineSurveyLeaveMessageTitle");
    messageQuestion.displayType = LIOSurveyQuestionDisplayTypeTextArea;
    emailQuestion.validationType = LIOSurveyQuestionValidationTypeAlphanumeric;
    
    self.surveyId = @"0";
    self.questions = [NSArray arrayWithObjects:emailQuestion, messageQuestion, nil];
    self.logicDictionary = [[NSMutableDictionary alloc] init];
    
    if (response)
        [self registerAnswerObject:response withQuestionIndex:1];
}

- (void)populateTemplateWithDictionary:(NSDictionary *)aDict
{
    // Delete current survey if aDict is empty.
    if (0 == [aDict count])
    {
        self.header = nil;
        self.questions = nil;
        [self clearAllResponses];
        
        return;
    }
    
    self.header = [aDict objectForKey:@"header"];
    self.surveyId = [aDict objectForKey:@"id"];
    
    NSDictionary *questionsDict = [aDict objectForKey:@"questions"];
    NSArray* questionIdsArray = [questionsDict allKeys];
    NSMutableArray *questions = [NSMutableArray array];
    NSMutableDictionary *logicDictionary = [[NSMutableDictionary alloc] init];
    
    for (NSString* aQuestionId in questionIdsArray)
    {
        LIOSurveyQuestion *newQuestion = [[LIOSurveyQuestion alloc] init];
        NSDictionary* aQuestionDict = [questionsDict objectForKey:aQuestionId];
        
        newQuestion.questionId = [aQuestionId integerValue];
        newQuestion.mandatory = [[aQuestionDict objectForKey:@"mandatory"] boolValue];
        if (newQuestion.mandatory)
            self.hasMandatoryQuestions = YES;
        newQuestion.order = [[aQuestionDict objectForKey:@"order"] integerValue];
        newQuestion.label = [aQuestionDict objectForKey:@"label"];
        newQuestion.logicId = [[aQuestionDict objectForKey:@"logic_id"] integerValue];
        newQuestion.lastKnownValue = [aQuestionDict objectForKey:@"last_known_value"];
        newQuestion.selectedIndices = [[NSMutableArray alloc] init];
        
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
                
                LIOSurveyPickerEntry *newPickerEntry = [[LIOSurveyPickerEntry alloc] init];
                newPickerEntry.initiallyChecked = [[anEntryDict objectForKey:@"checked"] boolValue];
                newPickerEntry.order = [[anEntryDict objectForKey:@"order"] integerValue];
                newPickerEntry.label = anEntryName;
                
                NSMutableArray *logicItems = [NSMutableArray array];
                NSArray *logicData = [anEntryDict objectForKey:@"showLogicId"];
                for (NSString *logicId in logicData)
                {
                    LIOSurveyLogicItem* logicItem = [[LIOSurveyLogicItem alloc] init];
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
            
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:TRUE];
            [entries sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            newQuestion.pickerEntries = entries;
            
            // After sorting, let's check the initiall checked entries
            for (LIOSurveyPickerEntry* pickerEntry in newQuestion.pickerEntries) {
                if (pickerEntry.initiallyChecked) {
                    NSUInteger questionRow = [newQuestion.pickerEntries indexOfObject:pickerEntry];
                    if (newQuestion.shouldUseStarRatingView)
                        [newQuestion.selectedIndices addObject:[NSIndexPath indexPathForRow:(5-questionRow) inSection:0]];
                    else
                        [newQuestion.selectedIndices addObject:[NSIndexPath indexPathForRow:questionRow inSection:0]];
                }
            }
                        
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
    
    self.questions = questions;
    self.logicDictionary = logicDictionary;
}

- (LIOSurveyQuestion *)questionForIntroView
{
    LIOSurveyQuestion *question = [[LIOSurveyQuestion alloc] init];
    question.displayType = LIOSurveyQuestionDisplayTypeIntro;
    question.label = self.header;
    // The mandatory field for the intro question will be used to indicate if the mandatory questions
    // subtitles should be shown
    question.mandatory = self.hasMandatoryQuestions;
    
    return question;    
}

- (BOOL)anyQuestionsAnswered
{
    NSDictionary* surveyDict = [self responseDict];
    NSDictionary* questionsArray = [surveyDict objectForKey:@"questions"];
    if (!questionsArray || questionsArray.count == 0)
        return NO;

    return YES;
}

- (BOOL)isQuestionWithIndexLastQuestion:(NSInteger)anIndex
{
    NSInteger nextQuestionIndex = anIndex;
    BOOL foundNextPage = NO;
    
    while (!foundNextPage)
    {
        if (nextQuestionIndex == self.questions.count - 1)
            return YES;
        
        nextQuestionIndex += 1;
        if ([self shouldShowQuestion:nextQuestionIndex])
            return NO;
    }
    
    return NO;
}

#pragma mark -
#pragma mark NSCopying Methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.surveyType = [decoder decodeIntegerForKey:@"surveyType"];
        self.questions = [NSKeyedUnarchiver unarchiveObjectWithData:[decoder decodeObjectForKey:@"questions"]];

        self.lastCompletedQuestionIndex = [decoder decodeIntegerForKey:@"lastCompletedQuestionIndex"];
        self.lastSeenQuestionIndex = [decoder decodeIntegerForKey:@"lastSeenQuestionIndex"];
        
        self.header = [decoder decodeObjectForKey:@"header"];
        self.responses = [decoder decodeObjectForKey:@"responses"];
        
        self.wasSubmitted = [decoder decodeBoolForKey:@"wasSubmitted"];
        self.surveyId = [decoder decodeObjectForKey:@"surveyId"];
        
        self.logicDictionary = [decoder decodeObjectForKey:@"logicDictionary"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInteger:self.surveyType forKey:@"surveyType"];
    [encoder encodeObject:[NSKeyedArchiver archivedDataWithRootObject:self.questions] forKey:@"questions"];
    
    [encoder encodeInteger:self.lastCompletedQuestionIndex forKey:@"lastCompletedQuestionIndex"];
    [encoder encodeInteger:self.lastSeenQuestionIndex forKey:@"lastSeenQuestionIndex"];
    
    [encoder encodeObject:self.header forKey:@"header"];
    [encoder encodeObject:self.responses forKey:@"responses"];
    
    [encoder encodeBool:self.wasSubmitted forKey:@"wasSubmitted"];
    [encoder encodeObject:self.surveyId forKey:@"surveyId"];
    
    [encoder encodeObject:self.logicDictionary forKey:@"logicDictionary"];
}

@end