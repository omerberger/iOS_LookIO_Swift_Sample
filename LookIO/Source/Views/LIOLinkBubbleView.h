//
//  LIOLinkBubbleView.h
//  LookIO
//
//  Created by Joseph Toscano on 4/19/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LIOLinkBubbleView : UIView
{
    UIImageView *backgroundImage;
    UILabel *messageLabel;
    UIButton *linkButton;
    NSURL *linkURL;
    NSString *linkDisplayString;
}

@property(nonatomic, retain) NSURL *linkURL;
@property(nonatomic, retain) NSString *linkDisplayString;


@end