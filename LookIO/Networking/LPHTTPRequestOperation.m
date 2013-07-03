//
//  LPHTTPRequestOperation.m
//  LookIO
//
//  Created by Yaron Karasik on 6/26/13.
//
//

#import "LPHTTPRequestOperation.h"
#import "LIOLogManager.h"
#import "SBJsonParser.h"

@interface LPHTTPRequestOperation ()

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, retain) NSHTTPURLResponse *response;
@property (nonatomic, retain) NSError *HTTPError;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, copy)   NSString *responseString;
@property (nonatomic, assign) NSInteger requestResponseCode;
@property (nonatomic, assign) LPOperationState state;

@property (nonatomic, assign) int retriesLeft;

@end

@implementation LPHTTPRequestOperation

@synthesize connection, request, response, HTTPError, responseData, responseString, requestResponseCode, retriesLeft;

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super init];
    if (!self) {
		return nil;
    }
    
    self.request = urlRequest;
    self.state = LPOperationReadyState;
    self.retriesLeft = LIOHTTPRequestOperationRetries;
    
    return self;
}

-(void)dealloc {
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
            self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
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

- (void)setCompletionBlockWithSuccess:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure
{
    [self setCompletionBlock:^{
        if (self.error) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(self, self.error);
                });
            }
        } else {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    SBJsonParser_LIO* jsonParser = [[SBJsonParser_LIO alloc] init];
                    NSDictionary *responseDict = [jsonParser objectWithString:responseString];

                    success(self, responseDict);
                });
            }
        }
    }];
}

#pragma mark
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
    self.responseData = [[NSMutableData alloc] init];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    BOOL failure = NO;
    NSInteger statusCode = self.response.statusCode;
    
    if (404 == statusCode)
    {
        failure = YES;
        LIOLog(@"<LPHTTPRequestOperation> Failure. HTTP code: 404.");
    }
    else if (statusCode >= 400)
    {
        LIOLog(@"<LPHTTPRequestOperation> Failure. HTTP code: %d.", statusCode);
    }
    else if (statusCode < 300 && statusCode >= 200)
    {
        // Success.
        responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
        LIOLog(@"<LPHTTPRequestOperation> Success! Response: %@", responseString);
        
        
    }
    else
    {
        // Wat.
        
        LIOLog(@"<LPHTTPRequestOperation> Unhandled HTTP code: %d", statusCode);
    }
    
    [self willChangeValueForKey:@"isFinished"];
    [self finish];
    [self didChangeValueForKey:@"isFinished"];

    [self.connection release];
    self.connection = nil;    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = error;
    LIOLog(@"<LPHTTPRequestOperation> Failed. Reason: %@", [error localizedDescription]);
    
    if (retriesLeft > 0) {
        retriesLeft -= 1;
        LIOLog(@"<LPHTTPRequestOperation> Retry %d or 3", 3-retriesLeft);
        
        [self.connection release];
        self.connection = nil;
        
        self.state = LPOperationReadyState;
        [self start];
    } else {
        [self willChangeValueForKey:@"isFinished"];
        [self finish];
        [self didChangeValueForKey:@"isFinished"];

        [self.connection release];
        self.connection = nil;
    }
}

@end
