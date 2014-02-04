//
//  LIOSurveyQuestion.m
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyQuestion.h"
#import "LIOSurveyPickerEntry.h"

@implementation LIOSurveyQuestion

- (NSArray*)pickerEntryTitles
{
    NSMutableArray* pickerEntryTitles = [[NSMutableArray alloc] init];
    
    for (int i=0; i < self.pickerEntries.count; i++) {
        LIOSurveyPickerEntry* pickerEntry = [self.pickerEntries objectAtIndex:i];
        [pickerEntryTitles addObject:pickerEntry.label];
    }
    
    return pickerEntryTitles;
}

- (BOOL)shouldUseStarRatingView
{
    if (self.displayType != LIOSurveyQuestionDisplayTypePicker)
        return NO;
    
    if (self.pickerEntries.count != 5)
        return NO;

    NSArray* pickerEntryTitles = [self pickerEntryTitles];
    
    if ([pickerEntryTitles isEqualToArray:[NSArray arrayWithObjects:@"Very Satisfied", @"Satisfied", @"Neither Satisfied Nor Dissatisfied", @"Dissatisfied", @"Very Dissatisfied", nil]])
        return YES;
    
    if ([pickerEntryTitles isEqualToArray:[NSArray arrayWithObjects:@"Very Likely", @"Likely", @"Neither Likely Nor Unlikely", @"Unlikely", @"Very Unlikely", nil]])
        return YES;
    
    return NO;
}

#pragma mark -
#pragma mark NSCopying Methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.questionId = [decoder decodeIntegerForKey:@"questionId"];
        self.mandatory = [decoder decodeBoolForKey:@"mandatory"];
        self.order = [decoder decodeIntegerForKey:@"order"];
        self.label = [decoder decodeObjectForKey:@"label"];
        self.logicId = [decoder decodeObjectForKey:@"logicId"];
        self.displayType = [decoder decodeIntegerForKey:@"displayType"];
        self.validationType = [decoder decodeIntegerForKey:@"validationType"];
        self.pickerEntries = [NSKeyedUnarchiver unarchiveObjectWithData:[decoder decodeObjectForKey:@"pickerEntries"]];
        self.selectedIndices = [decoder decodeObjectForKey:@"selectedIndices"];
        self.lastKnownValue = [decoder decodeObjectForKey:@"lastKnownValue"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInteger:self.questionId forKey:@"questionId"];
    [encoder encodeBool:self.mandatory forKey:@"mandatory"];
    [encoder encodeInteger:self.order forKey:@"order"];
    [encoder encodeObject:self.label forKey:@"label"];
    [encoder encodeInteger:self.logicId forKey:@"logicId"];
    [encoder encodeInteger:self.displayType forKey:@"displayType"];
    [encoder encodeInteger:self.validationType forKey:@"validationType"];
    [encoder encodeObject:[NSKeyedArchiver archivedDataWithRootObject:self.pickerEntries] forKey:@"pickerEntries"];
    [encoder encodeObject:self.selectedIndices forKey:@"selectedIndices"];
    [encoder encodeObject:self.lastKnownValue forKey:@"lastKnownValue"];
}

@end