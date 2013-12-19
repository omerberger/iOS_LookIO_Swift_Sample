//
//  LIOEngagement.h
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import <Foundation/Foundation.h>

@class LIOEngagement;

@protocol LIOEngagementDelegate <NSObject>

- (void)engagementDidStart:(LIOEngagement *)engagement;

@end

@interface LIOEngagement : NSObject

@property (nonatomic, assign) id <LIOEngagementDelegate> delegate;

@property (nonatomic, assign) NSInteger lastClientLineId;
@property (nonatomic, strong) NSMutableArray *messages;

- (void)startEngagementWithIntroDictionary:(NSDictionary *)introDictionary;

@end
