//
//  LPHTTPRequestOperation.h
//  LookIO
//
//  Created by Yaron Karasik on 6/26/13.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    LPOperationPausedState      = -1,
    LPOperationReadyState       = 1,
    LPOperationExecutingState   = 2,
    LPOperationFinishedState    = 3,
} LPOperationState;

#define LIOHTTPRequestOperationRetries   0

@interface LPHTTPRequestOperation : NSOperation <NSURLConnectionDelegate> {
    NSInteger responseCode;
}

- (id)initWithRequest:(NSURLRequest *)urlRequest;
- (void)setCompletionBlockWithSuccess:(void (^)(LPHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(LPHTTPRequestOperation *operation, NSError *error))failure;

@property (nonatomic, assign) NSInteger responseCode;
@property (nonatomic, retain) NSMutableArray *redirectURLs;
@property (nonatomic, assign) BOOL allowStringResponse;

@end
