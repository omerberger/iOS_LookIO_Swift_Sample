//
//  LIOSurveyQuestion.m
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyQuestion.h"

@implementation LIOSurveyQuestion

@synthesize questionId, mandatory, order, label, logicId, displayType;
@synthesize validationType, pickerEntries;
@synthesize lastKnownValue;

- (void)dealloc
{
    [label release];
    [pickerEntries release];
    
    [super dealloc];
}

@end