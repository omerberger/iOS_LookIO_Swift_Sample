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

@end