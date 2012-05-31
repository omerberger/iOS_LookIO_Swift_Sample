//
//  LIOTimerProxy.h
//  LookIO
//
//  Created by Joe Toscano on 9/30/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LIOTimerProxy : NSObject
{
    NSTimer *theTimer;
    id theTarget;
    SEL theSelector;
    BOOL selectorTakesArgument;
    id userInfo;
}

@property(nonatomic, readonly) id userInfo;

- (id)initWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)aUserInfo;
- (id)initWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector;
- (void)stopTimer;

@end