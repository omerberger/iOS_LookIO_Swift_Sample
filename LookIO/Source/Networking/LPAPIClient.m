//
//  LPAPIClient.m
//  LookIO
//
//  Created by Yaron Karasik on 6/26/13.
//
//

#import "LPAPIClient.h"
#import "LPHTTPRequestOperation.h"
#import "LIOLogManager.h"

static LPAPIClient *sharedClient = nil;

@interface LPAPIClient ()

@property (nonatomic, retain) NSOperationQueue *operationQueue;

@end

@implementation LPAPIClient

@synthesize baseURL, operationQueue;

+ (LPAPIClient *) sharedClient
{
    if (nil == sharedClient)
        sharedClient = [[LPAPIClient alloc] init];
    
    return sharedClient;
}

- (id)init
{
    if ((self = [super init]))
    {
        self.operationQueue = [[[NSOperationQueue alloc] init] autorelease];
        [self.operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    }
    
    return self;
}

- (void)clearCookies
{
    NSMutableArray *cookiesToDelete = [NSMutableArray array];
    [cookiesToDelete addObjectsFromArray:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:self.baseURL]];
    for (NSHTTPCookie *cookie in cookiesToDelete)
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];

}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    if (!path) {
        path = @"";
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, path]];
    LIOLog(@"<%@> Endpoint: %@", [path uppercaseString], url.absoluteString);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLCacheStorageNotAllowed
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:method];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    if (parameters) {
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]) {
            // TO DO - Encode parameters here
            [request setURL:url];
        } else {
            NSError *jsonError = nil;
            NSData *parametersJSONEncoded = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&jsonError];
            [request setHTTPBody:parametersJSONEncoded];
            LIOLog(@"Request:\n%@", [[NSString alloc] initWithData:parametersJSONEncoded encoding:NSUTF8StringEncoding]);
        }
    }
        
	return request;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                      data:(NSData *)data
{
    if (!path) {
        path = @"";
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, path]];
    LIOLog(@"<%@> Endpoint: %@", [path uppercaseString], url.absoluteString);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLCacheStorageNotAllowed
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:method];

    [request setHTTPBody:data];
          
    return request;
}

- (NSMutableURLRequest *)multipartRequestWithMethod:(NSString *)method
                                               path:(NSString *)path
                                               data:(NSData *)data
{
    if (!path) {
        path = @"";
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, path]];
    LIOLog(@"<%@> Endpoint: %@", [path uppercaseString], url.absoluteString);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLCacheStorageNotAllowed
                                                       timeoutInterval:10.0];
    
    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];

    [request setHTTPMethod:method];
    [request setHTTPBody:data];
        
	return request;
}

- (LPHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure
{
    LPHTTPRequestOperation *operation = [[LPHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [operation setCompletionBlockWithSuccess:success failure:failure];        
    return operation;
}

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:parameters];
    LPHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters];
	LPHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)postPath:(NSString *)path
            data:(NSData *)data
         success:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"POST" path:path data:data];
	LPHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)postMultipartDataToPath:(NSString *)path
                           data:(NSData *)data
                        success:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self multipartRequestWithMethod:@"POST" path:path data:data];
	LPHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}



- (void)enqueueHTTPRequestOperation:(LPHTTPRequestOperation *)operation {
    [self.operationQueue addOperation:operation];
    [operation release];
}

@end
