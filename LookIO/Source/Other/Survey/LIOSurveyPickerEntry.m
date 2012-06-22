//
//  LIOSurveyPickerEntry.m
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyPickerEntry.h"

@implementation LIOSurveyPickerEntry

@synthesize initiallyChecked, label, logicProps;

- (void)dealloc
{
    [label release];
    [logicProps release];
    
    [super dealloc];
}

@end
