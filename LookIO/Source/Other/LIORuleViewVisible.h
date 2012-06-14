//
//  LIORuleViewVisible.h
//  LookIO
//
//  Created by Joseph Toscano on 5/30/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIORuleViewVisible, LIOTimerProxy;

@protocol LIORuleViewVisibleDelegate
- (void)ruleViewVisibleTimerDidFire:(LIORuleViewVisible *)aRule;
@end

@interface LIORuleViewVisible : NSObject
{
    NSTimeInterval duration;
    NSString *locationName;
    LIOTimerProxy *timer;
    id<LIORuleViewVisibleDelegate> delegate;
}

@property(nonatomic, readonly) NSTimeInterval duration;
@property(nonatomic, readonly) NSString *locationName;
@property(nonatomic, assign) id<LIORuleViewVisibleDelegate> delegate;

- (id)initWithLocationName:(NSString *)aString duration:(NSTimeInterval)anInterval;
- (void)startTimer;
- (void)stopTimer;

@end