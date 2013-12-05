//
//  LIOChat.h
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import <Foundation/Foundation.h>

@interface LIOChat : NSObject

@property (nonatomic, assign) NSInteger lastClientLineId;
@property (nonatomic, strong) NSMutableArray *messages;

@end
