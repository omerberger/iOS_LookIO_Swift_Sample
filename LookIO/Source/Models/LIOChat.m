//
//  LIOChat.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOChat.h"

@implementation LIOChat

- (id)init {
    self = [super init];
    if (self) {
        self.messages = [[NSMutableArray alloc] init];
        self.lastClientLineId = 0;
    }
}

@end
