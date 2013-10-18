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

@property (nonatomic, retain) NSString *eventId;
@property (nonatomic, retain) NSString *eventType;
@property (nonatomic, retain) NSString *data;

@end
