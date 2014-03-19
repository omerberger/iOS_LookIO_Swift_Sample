//
//  LIOWebViewChatModule.h
//  LookIO
//
//  Created by Yaron Karasik on 8/2/13.
//
//

#import "LIOChatModule.h"

@interface LIOWebViewChatModule : LIOChatModule <UIWebViewDelegate> {
    NSURL* url;
}

@property (nonatomic, retain) NSURL* url;

-(id)initWithUrl:(NSURL*)urlToUse;
-(void)loadContent;

@end
