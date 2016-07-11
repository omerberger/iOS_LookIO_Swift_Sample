//
//  LPChatAPIClient.h
//  LookIO
//
//  Created by Yaron Karasik on 7/16/13.
//
//

#import "LPAPIClient.h"

#define LIOLookIOManagerChatIntroRequestURL         @"intro"
#define LIOLookIOManagerChatOutroRequestURL         @"outro"
#define LIOLookIOManagerChatLineRequestURL          @"line"
#define LIOLookIOManagerChatFeedbackRequestURL      @"feedback"
#define LIOLookIOManagerChatSurveyRequestURL        @"survey"
#define LIOLookIOManagerChatCapabilitiesRequestURL  @"capabilities"
#define LIOLookIOManagerChatHistoryRequestURL       @"chat_history"
#define LIOLookIOManagerChatAdvisoryRequestURL      @"advisory"
#define LIOLookIOManagerCustomVarsRequestURL        @"custom_vars"
#define LIOLookIOManagerChatPermissionRequestURL    @"permission"
#define LIOLookIOManagerChatScreenshotRequestURL    @"screenshot"
#define LIOLookIOManagerMediaUploadRequestURL       @"upload"

@interface LPChatAPIClient : LPAPIClient

+ (LPChatAPIClient *)sharedClient;

@end
