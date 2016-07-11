//
//  LIOSurveyTemplate.m
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyTemplate.h"

@implementation LIOSurveyTemplate

@synthesize headerString, questions, surveyId, logicDictionary;

- (void)dealloc
{
    [surveyId release];
    [headerString release];
    [questions release];
    [logicDictionary release];
    
    [super dealloc];
}

@end