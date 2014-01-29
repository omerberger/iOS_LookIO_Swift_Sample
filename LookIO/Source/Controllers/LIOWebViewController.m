//
//  LIOWebViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 1/29/14.
//
//

#import "LIOWebViewController.h"

@interface LIOWebViewController ()

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation LIOWebViewController

- (id)initWithURL:(NSURL *)aURL
{
    self = [super init];
    if (self)
    {
        self.url = aURL;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
