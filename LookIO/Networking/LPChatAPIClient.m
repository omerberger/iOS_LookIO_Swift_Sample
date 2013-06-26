//
//  LPChatAPIClient.m
//  LookIO
//
//  Created by Yaron Karasik on 6/26/13.
//
//

#import "LPChatAPIClient.h"
#import "LPHTTPRequestOperation.h"

#import "SBJSON.h"

static LPChatAPIClient *sharedClient = nil;

@interface LPChatAPIClient ()

@property (nonatomic, retain) NSOperationQueue *operationQueue;
@property (nonatomic, retain) SBJsonWriter_LIO* jsonWriter;

@end

@implementation LPChatAPIClient

@synthesize usesTLS, baseURL, jsonWriter;

+ (LPChatAPIClient *) sharedClient
{
    if (nil == sharedClient)
        sharedClient = [[LPChatAPIClient alloc] init];
    
    return sharedClient;
}

- (id)init
{
    if ((self = [super init]))
    {
        jsonWriter = [[SBJsonWriter_LIO alloc] init];
        
        self.operationQueue = [[NSOperationQueue alloc] init];
        [self.operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    }
    
    return self;
}

-(void)dealloc {
    [self.operationQueue release];
    self.operationQueue = nil;
    
    [self.baseURL release];
    self.baseURL = nil;
    
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
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http%@://%@%@", usesTLS ? @"s" : @"", baseURL, path]];
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url
                                                                cachePolicy:NSURLCacheStorageNotAllowed
                                                            timeoutInterval:10.0] retain];
    [request setHTTPMethod:method];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    if (parameters) {
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]) {
            // TO DO - Encode parameters here
            [request setURL:url];
        } else {
            NSString *parametersJSONEncoded = [jsonWriter stringWithObject:parameters];
            [request setHTTPBody:[parametersJSONEncoded dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
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

- (void)enqueueHTTPRequestOperation:(LPHTTPRequestOperation *)operation {
    [self.operationQueue addOperation:operation];
}

@end
