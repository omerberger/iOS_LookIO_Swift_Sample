//
//  LIOWebViewController.h
//  LookIO
//
//  Created by Yaron Karasik on 1/29/14.
//
//

#import <UIKit/UIKit.h>

@interface LIOWebViewController : UIViewController


- (id)initWithURL:(NSURL *)aURL;
- (NSURL *)currentWebViewURL;

@end
