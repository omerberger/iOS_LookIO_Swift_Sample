//
//  LPAPIClient.h
//  LookIO
//
//  Created by Yaron Karasik on 6/26/13.
//
//

#import <Foundation/Foundation.h>

@class LPHTTPRequestOperation;

@interface LPAPIClient : NSObject {
    NSURL *baseURL;
    NSString* secretToken;
    BOOL usesSecretToken;
}

@property (nonatomic, retain) NSURL *baseURL;
@property (nonatomic, retain) NSString *secretToken;
@property (nonatomic, assign) BOOL usesSecretToken;

+ (LPAPIClient *)sharedClient;
- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure;
- (void)postPath:(NSString *)path
            data:(NSData *)data
         success:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure;
- (void)postMultipartDataToPath:(NSString *)path
                           data:(NSData *)data
                        success:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure;

@end
