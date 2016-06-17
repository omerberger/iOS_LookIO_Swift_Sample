//
//  LPHTTPRequestOperation.m
//  LookIO
//
//  Created by Yaron Karasik on 6/26/13.
//
//

#import "LPHTTPRequestOperation.h"
#import "LIOLogManager.h"

@interface LPHTTPRequestOperation () {
    NSMutableData *responseData;
}

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, retain) NSError *HTTPError;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, assign) LPOperationState state;

@property (nonatomic, assign) BOOL requestFailed;
@property (nonatomic, assign) int retriesLeft;

@end

@implementation LPHTTPRequestOperation

@synthesize connection, request, HTTPError, retriesLeft, requestFailed, responseCode, error, state;

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super init];
    if (!self) {
		return nil;
    }
    
    self.request = urlRequest;
    self.state = LPOperationReadyState;
    self.retriesLeft = LIOHTTPRequestOperationRetries;
    self.requestFailed = NO;
    self.redirectURLs = [[[NSMutableArray alloc] init] autorelease];
    
    responseData = [[[NSMutableData alloc] init] retain];

    
    return self;
}

- (void)dealloc {
    [request release];
    if (responseData)
        [responseData release];
    
    [self.redirectURLs removeAllObjects];
    self.redirectURLs = nil;
    
    [super dealloc];
}

- (BOOL)isReady {
    return self.state == LPOperationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == LPOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == LPOperationFinishedState;
}

- (void)start {
    if ([self isReady]) {
        self.state = LPOperationExecutingState;
        
        [self operationDidStart];
    }
}

- (void)operationDidStart {
    if (! [self isCancelled]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
            [self.connection start];
        });
    }
    
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        [self finish];
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (void)finish {
    self.state = LPOperationFinishedState;
}

- (void)cancel {
    if (![self isFinished] && ![self isCancelled]) {
        [self cancel];
        
        // Cancel the connection on the thread it runs on to prevent race conditions
        [self cancelConnection];
    }
}

- (void)cancelConnection {
    NSDictionary *userInfo = nil;
    if ([self.request URL]) {
        userInfo = [NSDictionary dictionaryWithObject:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
    }
    self.error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
    
    if (self.connection) {
        [self.connection cancel];
        
        // Manually send this delegate message since `[self.connection cancel]` causes the connection to never send another message to its delegate
        [self connection:self.connection didFailWithError:self.error];
    }
}

- (void)setCompletionBlock:(void (^)(void))block {
    if (!block) {
        [super setCompletionBlock:nil];
    }
 
    __block id _blockSelf = self;
    [super setCompletionBlock:^ {
        block();
        [_blockSelf setCompletionBlock:nil];
    }];
}

- (void)setCompletionBlockWithSuccess:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure
{
    [self setCompletionBlock:^{
        if (self.error || self.requestFailed) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(self, self.error);
                });
            }
        } else {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *jsonError = nil;
                    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&jsonError];
                    if (!self.allowStringResponse) {
                        success(self, responseDict);
                    } else {
                        if (!jsonError) {
                            success(self, responseDict);
                        } else {
                            NSString *stringResponse = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                            success (self, stringResponse);
                        }
                    }
                });
            }
        }
    }];
}

#pragma mark
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* myResponse = (NSHTTPURLResponse*)response;
    self.responseCode = myResponse.statusCode;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (404 == self.responseCode)
    {
        self.requestFailed = YES;
        LIOLog(@"<LPHTTPRequestOperation> Failure. HTTP code: 404.");
    }
    else if (self.responseCode >= 400)
    {
        self.requestFailed = YES;
        LIOLog(@"<LPHTTPRequestOperation> Failure. HTTP code: %d.", self.responseCode);
    }
    else if (self.responseCode < 300 && self.responseCode >= 200)
    {
        // Success.
        NSString *responseString = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
        LIOLog(@"<LPHTTPRequestOperation> Success! Response: %@", responseString);
    }
    else
    {
        self.requestFailed = YES;
        // Wat.
        LIOLog(@"<LPHTTPRequestOperation> Unhandled HTTP code: %d", self.responseCode);
    }
    
    [self willChangeValueForKey:@"isFinished"];
    [self finish];
    [self didChangeValueForKey:@"isFinished"];

    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    self.connection = nil;
    [responseData release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)anError
{
    self.error = anError;
    LIOLog(@"<LPHTTPRequestOperation> Failed. Reason: %@", [error localizedDescription]);
    
    if (retriesLeft > 0) {
        retriesLeft -= 1;
        LIOLog(@"<LPHTTPRequestOperation> Retry %d or 3", 3-retriesLeft);
        
        [[NSURLCache sharedURLCache] removeAllCachedResponses];

        self.connection = nil;
        [responseData release];
        
        self.state = LPOperationReadyState;
        [self start];
    } else {
        [self willChangeValueForKey:@"isFinished"];
        [self finish];
        [self didChangeValueForKey:@"isFinished"];

        [[NSURLCache sharedURLCache] removeAllCachedResponses];

        self.connection = nil;
        [responseData release];
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)sendRequest
             redirectResponse:(NSURLResponse *)redirectResponse
{
    if (redirectResponse) {
        LIOLog(@"<LPHTTPRequestOperation> Redirected to %@", sendRequest.URL.absoluteString);
        [self.redirectURLs addObject:sendRequest.URL];
    }
    return sendRequest;
}

@end
