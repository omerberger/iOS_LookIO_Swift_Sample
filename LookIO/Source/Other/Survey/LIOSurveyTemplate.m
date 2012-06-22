//
//  LIOSurveyTemplate.m
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyTemplate.h"

@implementation LIOSurveyTemplate

@synthesize headerString, questions;

- (void)dealloc
{
    [headerString release];
    [questions release];
    
    [super dealloc];
}

@end