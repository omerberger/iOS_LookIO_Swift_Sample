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

#import "SBJSON.h"

static LPAPIClient *sharedClient = nil;

@interface LPAPIClient ()

@property (nonatomic, retain) NSOperationQueue *operationQueue;
@property (nonatomic, retain) SBJsonWriter_LIO* jsonWriter;

@end

@implementation LPAPIClient

@synthesize baseURL, jsonWriter, operationQueue, usesSecretToken, secretToken;

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
        jsonWriter = [[SBJsonWriter_LIO alloc] init];
        
        self.operationQueue = [[[NSOperationQueue alloc] init] autorelease];
        [self.operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
        
        self.usesSecretToken = NO;
    }
    
    return self;
}

-(void)dealloc {    
    [jsonWriter release];
    jsonWriter = nil;
    
    [super dealloc];
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
    if (usesSecretToken) {
        [request setValue:secretToken forHTTPHeaderField:@"X-LP-Secret-Token"];
    }
    
    if (parameters) {
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]) {
            // TO DO - Encode parameters here
            [request setURL:url];
        } else {
            NSString *parametersJSONEncoded = [jsonWriter stringWithObject:parameters];
            [request setHTTPBody:[parametersJSONEncoded dataUsingEncoding:NSUTF8StringEncoding]];
            LIOLog(@"Request:\n%@", parametersJSONEncoded);
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
    if (usesSecretToken) {
        [request setValue:secretToken forHTTPHeaderField:@"X-LP-Secret-Token"];
    }

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
    if (usesSecretToken) {
        [request setValue:secretToken forHTTPHeaderField:@"X-LP-Secret-Token"];
    }
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
