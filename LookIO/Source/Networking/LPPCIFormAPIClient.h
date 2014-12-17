//
//  LPPCIFormAPIClient.h
//  LookIO
//
//  Created by Gil Goldenberg on 12/15/14.
//
//

#import "LPAPIClient.h"

#define LIOLookIOManagerPCIFormSubmitRequestURL       @"submit"


@interface LPPCIFormAPIClient : LPAPIClient

+ (LPPCIFormAPIClient *)sharedClient;

@end
