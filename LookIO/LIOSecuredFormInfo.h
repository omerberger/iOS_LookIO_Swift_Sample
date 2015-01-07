//
//  LIOSecuredFormInfo.h
//  LookIO
//
//  Created by Gil Goldenberg on 12/23/14.
//
//

#import <Foundation/Foundation.h>

@class LIOChatMessage;

@interface LIOSecuredFormInfo : NSObject

@property (nonatomic, copy) NSString *formUrl;
@property (nonatomic, copy) NSString *formSessionId;
@property (nonatomic, copy) NSString *redirectUrl;

//keep a refference to the message to be able to change its text...
@property (nonatomic, strong) LIOChatMessage *originalMessage;

@end
