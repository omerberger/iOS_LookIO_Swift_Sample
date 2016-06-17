//
//  LPVisitAPIClient.h
//  LookIO
//
//  Created by Yaron Karasik on 7/16/13.
//
//

#import "LPAPIClient.h"

#define LIOLookIOManagerAppLaunchRequestURL         @"/api/v1/visit/launch"
#define LIOLookIOManagerAppContinueRequestURL       @"/continue"
#define LIOLookIOManagerVisitFunnelRequestURL       @"/funnel"

@interface LPVisitAPIClient : LPAPIClient

+ (LPVisitAPIClient *)sharedClient;

@end
