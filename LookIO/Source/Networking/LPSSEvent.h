//
//  LPSSEvent.h
//  LookIO
//
//  Created by Yaron Karasik on 6/27/13.
//
//

#import <Foundation/Foundation.h>

@interface LPSSEvent : NSObject {
    NSString *eventId;
    NSString *eventType;
    NSString *data;
}

@property (nonatomic, copy) NSString *eventId;
@property (nonatomic, copy) NSString *eventType;
@property (nonatomic, copy) NSString *data;

@end
