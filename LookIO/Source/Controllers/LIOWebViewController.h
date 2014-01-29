//
//  LIOWebViewController.h
//  LookIO
//
//  Created by Yaron Karasik on 1/29/14.
//
//

#import <UIKit/UIKit.h>

@interface LIOWebViewController : UIViewController

@property (nonatomic, strong) NSURL *url;

- (id)initWithURL:(NSURL *)aURL;

@end
