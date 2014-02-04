//
//  LIOSurveyPickerEntry.m
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyPickerEntry.h"

@implementation LIOSurveyPickerEntry

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.order = [decoder decodeIntegerForKey:@"order"];
        self.initiallyChecked = [decoder decodeBoolForKey:@"initiallyChecked"];
        self.label = [decoder decodeObjectForKey:@"label"];
        self.logicItems = [NSKeyedUnarchiver unarchiveObjectWithData:[decoder decodeObjectForKey:@"logicItems"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInteger:self.order forKey:@"order"];
    [encoder encodeBool:self.initiallyChecked forKey:@"initiallyChecked"];
    [encoder encodeObject:self.label forKey:@"label"];
    [encoder encodeObject:[NSKeyedArchiver archivedDataWithRootObject:self.logicItems] forKey:@"logicItems"];
}

@end