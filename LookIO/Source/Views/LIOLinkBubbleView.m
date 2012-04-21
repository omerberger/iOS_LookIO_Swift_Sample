//
//  LIOLinkBubbleView.m
//  LookIO
//
//  Created by Joseph Toscano on 4/19/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import "LIOLinkBubbleView.h"
#import "LIOBundleManager.h"
#import <QuartzCore/QuartzCore.h>

@implementation LIOLinkBubbleView

@synthesize linkURL, linkDisplayString;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        backgroundImage = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableChatBubble"]];
        [self addSubview:backgroundImage];
        
        messageLabel = [[UILabel alloc] init];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.font = [UIFont systemFontOfSize:16.0];
        messageLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        messageLabel.layer.shadowRadius = 1.0;
        messageLabel.layer.shadowOpacity = 1.0;
        messageLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        [self addSubview:messageLabel];
        
        linkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [linkButton setBackgroundImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableRecessedLinkButton"] forState:UIControlStateNormal];
    }
    
    return self;
}

- (void)layoutSubviews
{
}

- (void)dealloc
{
    [backgroundImage release];
    [messageLabel release];
    [linkButton release];
    [linkURL release];
    [linkDisplayString release];
    
    [super dealloc];
}

@end
