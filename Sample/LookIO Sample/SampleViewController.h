//
//  SampleViewController.h
//  LookIO Sample
//
//  Created by Marc Campbell on 1/15/12.
//  Copyright (c) 2012 Look.IO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIOLookIOManager.h"

@interface SampleViewController : UIViewController <LIOLookIOManagerDelegate>
{
    IBOutlet UILabel *availabilityLabel;
    IBOutlet UIButton *liveHelpButton;
    IBOutlet UIWebView *webView;
}

@property(nonatomic, readonly) UILabel *availabilityLabel;
@property(nonatomic, readonly) UIButton *liveHelpButton;
@property(nonatomic, readonly) UIWebView *webView;

- (IBAction)helpButtonSelected:(id)sender;
- (IBAction)crashButtonSelected:(id)sender;

@end
