//
//  LIOWebViewChatModule.m
//  LookIO
//
//  Created by Yaron Karasik on 8/2/13.
//
//

#import "LIOWebViewChatModule.h"

@interface LIOWebViewChatModule () {
    UIWebView* webView;
}

@end

@implementation LIOWebViewChatModule

@synthesize view = webView;
@synthesize url;

-(id)initWithUrl:(NSURL*)urlToUse {
    self = [super init];
    if (self) {
        chatModuleType = LIOChatModuleTypeWebView;
        url = urlToUse;
        
        webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        webView.delegate = self;
    }
    return self;
}

-(void)loadContent {
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (delegate)
        if ((NSObject*)[delegate respondsToSelector:@selector(chatModuleContentDidFail:)])
            [delegate chatModuleContentDidFail:self];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    if (delegate)
        if ((NSObject*)[delegate respondsToSelector:@selector(chatModuleContentDidLoad:)])
            [delegate chatModuleContentDidLoad:self];
}

-(void)dealloc {
    webView.delegate = nil;
    [webView release];
    webView = nil;
    
    [super dealloc];
}

@end
