//
//  LPChatAPIClient.h
//  LookIO
//
//  Created by Yaron Karasik on 6/26/13.
//
//

#import <Foundation/Foundation.h>

@class LPHTTPRequestOperation;

@interface LPChatAPIClient : NSObject

@property (nonatomic, retain) NSURL *baseURL;
@property (nonatomic, assign) BOOL usesTLS;

+ (LPChatAPIClient *)sharedClient;
- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure;

@end
