//
//  LIOSurveyPickerEntry.m
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyPickerEntry.h"

@implementation LIOSurveyPickerEntry

@synthesize initiallyChecked, label, logicItems, order;

- (void)dealloc
{
    [label release];
    [logicItems release];
    
    [super dealloc];
}

@end
