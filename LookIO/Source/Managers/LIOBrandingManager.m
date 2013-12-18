//
//  LIOBrandingManager.m
//  LookIO
//
//  Created by Yaron Karasik on 12/17/13.
//
//

#import "LIOBrandingManager.h"

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                                    green:((c>>8)&0xFF)/255.0 \
                                     blue:((c)&0xFF)/255.0 \
                                    alpha:1.0]

@implementation LIOBrandingManager

static LIOBrandingManager *brandingManager = nil;

#pragma mark Initialization Methods

+ (LIOBrandingManager *)brandingManager
{
    if (nil == brandingManager)
        brandingManager = [[LIOBrandingManager alloc] init];
    
    return brandingManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        [self setDefaults];
    }
    
    return self;
}

- (UIColor *)colorForHexString:(NSString *)string
{
    unsigned int colorValue;
    [[NSScanner scannerWithString:string] scanHexInt:&colorValue];

    return HEXCOLOR(colorValue);
}

- (void)setDefaults
{
    // Control Button
    self.controlButtonIconUrl = nil;
    self.controlButtonBackgroundColor = [self colorForHexString:@"373737"];
    self.controlButtonBorderColor = [self colorForHexString:@"666666"];
    self.controlButtonContentColor = [self colorForHexString:@"ffffff"];
    self.controlButtonAttachedToRight = YES;
    self.controlButtonVerticalPosition = 0.5;
    
    self.chatBackgroundColor = [self colorForHexString:@"d8d8d8"];
    self.chatBackgroundAlpha = 0.4;
    self.chatBackgroundBlurRadius = 24.0;
    self.chatBackgroundBlurIterations = 8;
    self.chatBackgroundSaturationFactor = 3.0;
    
    self.fontName = @"HelveticaNeue-Light";

    self.logoUrl = nil;
    
    self.brandingBarBackgroundColor = [self colorForHexString:@"ffffff"];
    self.brandingBarBackgroundAlpha = 0.0;
    self.brandingbarNotificationsTextColor = [self colorForHexString:@"555555"];
    self.brandingBarNotificationsFontSize = 12.0;
    
    self.agentBubbleBackgroundColor = [self colorForHexString:@"47a1ff"];
    self.agentBubbleTextColor = [self colorForHexString:@"4f4f4f"];
    self.agentBubbleWidth = 0.625;
    self.agentBubbleFontSize = 15.0;
    self.agentBubbleShowAvatar = NO;
    self.agentAvatarImageUrl = nil;
    self.agentLinkBackgroundColor = [self colorForHexString:@"ffffff"];
    self.agentLinkBorderColor = [self colorForHexString:@"019fde"];
    self.agentLinkTextColor = [self colorForHexString:@"555555"];
    self.agentLinkFontSize = 15.0;
    
    self.visitorBubbleBackgroundColor = [self colorForHexString:@"e1e1e7"];
    self.visitorBubbleTextColor = [self colorForHexString:@"ffffff"];
    self.visitorBubbleWidth = 0.625;
    self.visitorBubbleFontSize = 15.0;
    self.visitorBubbleShowAvatar = NO;
    self.visitorAvatarImageUrl = nil;
    self.visitorLinkBackgroundColor = [self colorForHexString:@"ffffff"];
    self.visitorLinkBorderColor = [self colorForHexString:@"019fde"];
    self.visitorLinkTextColor = [self colorForHexString:@"555555"];
    self.visitorLinkFontSize = 15.0;    
}


@end
