//
//  LIOSurveyLogicItem.m
//  LookIO
//
//  Created by Yaron Karasik on 6/14/13.
//
//

#import "LIOSurveyLogicItem.h"

@implementation LIOSurveyLogicItem

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.sourceLogicId = [decoder decodeIntegerForKey:@"sourceLogicId"];
        self.targetLogicId = [decoder decodeIntegerForKey:@"targetLogicId"];
        self.enabled = [decoder decodeBoolForKey:@"enabled"];
        self.propType = [decoder decodeIntegerForKey:@"propType"];
        self.sourceAnswerLabel = [decoder decodeObjectForKey:@"sourceAnswerLabel"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInteger:self.sourceLogicId forKey:@"sourceLogicId"];
    [encoder encodeInteger:self.targetLogicId forKey:@"targetLogicId"];
    [encoder encodeBool:self.enabled forKey:@"enabled"];
    [encoder encodeInteger:self.propType forKey:@"propType"];
    [encoder encodeObject:self.sourceAnswerLabel forKey:@"sourceAnswerLabel"];
}

@end