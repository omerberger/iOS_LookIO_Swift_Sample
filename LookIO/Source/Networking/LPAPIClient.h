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
}

@property (nonatomic, retain) NSURL *baseURL;

+ (LPAPIClient *)sharedClient;
- (void)clearCookies;

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure;

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure;

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         headers:(NSDictionary *)headers
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