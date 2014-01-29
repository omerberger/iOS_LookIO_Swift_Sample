//
//  LPChatBubbleView.m
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import "LPChatBubbleView.h"

// Managers
#import "LIOLookIOManager.h"
#import "LIOBrandingManager.h"
#import "LIOBundleManager.h"

// Views
#import "LIOChatTableViewCell.h"

@interface LPChatBubbleView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *linkMessageViews;
@property (nonatomic, strong) NSMutableArray *intraAppLinkViews;

@end

@implementation LPChatBubbleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.layer.cornerRadius = 10.0;
        
        self.messageLabel = [[TTTAttributedLabel_LIO alloc] initWithFrame:CGRectMake(10, 0, self.bounds.size.width, self.bounds.size.height)];
        self.messageLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.messageLabel.textColor = [UIColor colorWithWhite:79.0/255.0 alpha:1.0];
        self.messageLabel.textAlignment = NSTextAlignmentLeft;
        self.messageLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.messageLabel];
        
        UILongPressGestureRecognizer *aLongPresser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        aLongPresser.delegate = self;
        [self addGestureRecognizer:aLongPresser];
        
        self.linkMessageViews = [[NSMutableArray alloc] init];
        self.linkButtons = [[NSMutableArray alloc] init];
        self.intraAppLinkViews = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)prepareForReuse
{
    [self.linkMessageViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.linkButtons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (id object in self.intraAppLinkViews)
    {
        if ([object isKindOfClass:[UIView class]])
        {
            UIView *view = (UIView *)object;
            [view removeFromSuperview];
        }            
    }
    
    [self.linkMessageViews removeAllObjects];
    [self.linkButtons removeAllObjects];
    [self.intraAppLinkViews removeAllObjects];
}

- (CGFloat)populateLinksChatBubbleViewWithMessage:(LIOChatMessage *)chatMessage forWidth:(CGFloat)width
{
    CGSize maxSize = CGSizeMake(width, FLT_MAX);
    
    LIOBrandingElement brandingElement;
    LIOBrandingElement linkBrandingElement;

    // Set up background color
    switch (chatMessage.kind) {
        case LIOChatMessageKindLocal:
            brandingElement = LIOBrandingElementVisitorChatBubble;
            linkBrandingElement = LIOBrandingElementVisitorChatBubbleLink;
            break;
            
        case LIOChatMessageKindRemote:
            brandingElement = LIOBrandingElementAgentChatBubble;
            linkBrandingElement = LIOBrandingElementAgentChatBubbleLink;
            break;
            
        default:
            break;
    }
    
    UIColor *textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:brandingElement];
    UIFont *boldNameFont = [[LIOBrandingManager brandingManager] boldFontForElement:brandingElement];
    self.messageLabel.textColor = textColor;
    self.messageLabel.font = [[LIOBrandingManager brandingManager] fontForElement:brandingElement];
    
    NSString *text = chatMessage.text;
    if (chatMessage.senderName != nil)
        text = [NSString stringWithFormat:@"%@: %@", chatMessage.senderName, chatMessage.text];

    // Setup the link views
    for (LPChatBubbleLink *currentLink in chatMessage.links)
    {
        if (currentLink.isIntraAppLink)
        {
            id linkView = [[LIOLookIOManager sharedLookIOManager] performSelector:@selector(linkViewForURL:) withObject:currentLink.URL];
            if (linkView && ([linkView isKindOfClass:[UIView class]] || [linkView isKindOfClass:[NSString class]]))
            {
                if ([linkView isKindOfClass:[UIView class]])
                {
                    UIView *linkViewObject = (UIView *)linkView;
                    linkViewObject.clipsToBounds = YES;
                    
                    [self.intraAppLinkViews addObject:linkView];
                }
                else
                {
                    NSString *aString = (NSString *)linkView;
                    UILabel *aLabel = [[UILabel alloc] init];
                    aLabel.backgroundColor = [UIColor clearColor];
                    
                    aLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:linkBrandingElement];
                    
                    aLabel.text = aString;
                    aLabel.textAlignment = UITextAlignmentCenter;
                    
                    [self.intraAppLinkViews addObject:aLabel];
                }
            }
            else
                [self.intraAppLinkViews addObject:[NSNull null]];
        }
        else
            [self.intraAppLinkViews addObject:[NSNull null]];
    }
    
    // We have links, so we only use the main label for the text up to the first link.
    NSTextCheckingResult *firstCheckingResult = [chatMessage.textCheckingResults objectAtIndex:0];
    NSString *firstString = [text substringWithRange:NSMakeRange(0, firstCheckingResult.range.location)];
    
    // Use the actual message label for the first part of the string
    [self.messageLabel setText:firstString afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        
        if ([chatMessage.senderName length])
        {
            NSAttributedString *nameCallout = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", chatMessage.senderName]] ;
            NSRange boldRange = NSMakeRange(0, [nameCallout length]);
            
            CTFontRef boldNameCTFont = CTFontCreateWithName((CFStringRef)boldNameFont.fontName, boldNameFont.pointSize, NULL);
            
            if (boldRange.location != NSNotFound)
            {
                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)CFBridgingRelease(boldNameCTFont) range:boldRange];
                [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)textColor.CGColor range:boldRange];
            }
        }
        
        return mutableAttributedString;
    }];
    
    CGSize mainMessageViewSize = [LIOChatTableViewCell expectedSizeForText:firstString withFont:boldNameFont forWidth:width];
    self.messageLabel.frame = CGRectMake(10.0, 8.0, mainMessageViewSize.width, mainMessageViewSize.height);
    
    for (int i=0; i < [chatMessage.links count]; i++)
    {
        // First, we need a view for the link button.
        UIButton *newLinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        newLinkButton.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        newLinkButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 20.0, 0.0, 20.0);
        newLinkButton.layer.cornerRadius = 10.0;
        newLinkButton.layer.borderWidth = 1.0;
        newLinkButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [newLinkButton setBackgroundColor:[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:linkBrandingElement]];
        [newLinkButton setTitleColor:[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:linkBrandingElement] forState:UIControlStateNormal];
        newLinkButton.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:linkBrandingElement] CGColor];

        LPChatBubbleLink *curLink = [chatMessage.links objectAtIndex:i];
        [newLinkButton setTitle:curLink.string forState:UIControlStateNormal];
        [self.linkButtons addObject:newLinkButton];
        [self addSubview:newLinkButton];
        
        // Isolate text after the link, if any.
        NSString *followingText = nil;
        NSTextCheckingResult *curResult = [chatMessage.textCheckingResults objectAtIndex:i];
        if (i < [chatMessage.links count] - 1)
        {
            // Since there's another link after this one, we need to grab the text
            // between this one and the next.
            NSTextCheckingResult *nextResult = [chatMessage.textCheckingResults objectAtIndex:(i + 1)];
            NSRange rangeOfText = NSUnionRange(curResult.range, nextResult.range);
            NSString *substring = [text substringWithRange:rangeOfText];
            substring = [substring stringByReplacingOccurrencesOfString:curLink.originalRawString withString:@""];
            LPChatBubbleLink *nextLink = [chatMessage.links objectAtIndex:(i + 1)];
            substring = [substring stringByReplacingOccurrencesOfString:nextLink.originalRawString withString:@""];
            followingText = substring;
        }
        else
        {
            // No link after this one. Just grab all the text after.
            followingText = [text substringFromIndex:(curResult.range.location + curResult.range.length)];
        }
        
        // TRIM THE BITCH
        followingText = [followingText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // Second, we need a view for the text that follows the link, if any.
        if ([followingText length])
        {
            UILabel *newMessageView = [[UILabel alloc] initWithFrame:self.bounds];
            newMessageView.font = [UIFont systemFontOfSize:15.0];
            newMessageView.backgroundColor = [UIColor clearColor];
            newMessageView.numberOfLines = 0;
            newMessageView.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:brandingElement];
            
            newMessageView.text = followingText;
            [self.linkMessageViews addObject:newMessageView];
            [self addSubview:newMessageView];
        }
    }
    
    CGFloat bottom = 0.0;

    CGRect relativeFrame = self.messageLabel.frame;
    for (int i=0; i < [chatMessage.links count]; i++)
    {
        UIButton *aLinkButton = [self.linkButtons objectAtIndex:i];
        [aLinkButton sizeToFit];
        CGRect aFrame = aLinkButton.frame;
        aFrame.origin.x = 10.0;
        aFrame.origin.y = relativeFrame.origin.y + relativeFrame.size.height + 10.0;
        aFrame.size.width = self.bounds.size.width - 20.0;
        aFrame.size.height = 51.0;
        aLinkButton.frame = aFrame;
        
        // Intra-link? Check for a custom view.
        UIView *linkView = [self.intraAppLinkViews objectAtIndex:i];
        if (linkView && (id)linkView != [NSNull null])
        {
            aFrame = linkView.frame;
            aFrame.origin.x = 5.0;
            aFrame.origin.y = 5.0;
            aFrame.size.width = aLinkButton.frame.size.width - 10.0;
            aFrame.size.height = aLinkButton.frame.size.height - 12.0;
            linkView.frame = aFrame;
            linkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            linkView.userInteractionEnabled = NO;
            [aLinkButton addSubview:linkView];
            
            [aLinkButton setTitle:[NSString string] forState:UIControlStateNormal];
        }
        
        relativeFrame = aLinkButton.frame;
        
        if (i < [self.linkMessageViews count])
        {
            UILabel *aMessageView = [self.linkMessageViews objectAtIndex:i];
            CGSize aMessageViewSize = [LIOChatTableViewCell expectedSizeForText:aMessageView.text withFont:aMessageView.font forWidth:maxSize.width];
            aFrame = aMessageView.frame;
            aFrame.size = aMessageViewSize;
            aFrame.origin.x = 10.0;
            aFrame.origin.y = aLinkButton.frame.origin.y + aLinkButton.frame.size.height + 5.0;
            aMessageView.frame = aFrame;
            
            relativeFrame = aMessageView.frame;
        }

        bottom = relativeFrame.origin.y + relativeFrame.size.height;
    }
    
    return bottom;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return action == @selector(copy:);
}

- (void)copy:(id)sender
{
    [UIPasteboard generalPasteboard].string = self.messageLabel.text;
}

- (void)performBounceAnimation
{
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.transform = CGAffineTransformMakeScale(1.2, 1.2);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.25
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              self.transform = CGAffineTransformMakeScale(0.97, 0.97);
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:0.15
                                                                    delay:0.0
                                                                  options:UIViewAnimationOptionCurveEaseIn
                                                               animations:^{
                                                                   self.transform = CGAffineTransformIdentity;
                                                               }
                                                               completion:^(BOOL finished) {
                                                               }];
                                          }];
                     }];
}

- (void)enterCopyModeAnimated:(BOOL)animated
{
    if (animated)
        [self performBounceAnimation];
    
    [self becomeFirstResponder];
    
    CGRect targetFrame = CGRectMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0, 0.0, 0.0);
    UIMenuController *menu = [UIMenuController sharedMenuController];
    menu.arrowDirection = UIMenuControllerArrowUp;
    [menu setTargetRect:targetFrame inView:self];
    [menu setMenuVisible:YES animated:YES];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleLongPress:(UILongPressGestureRecognizer *)aLongPresser
{
    if (aLongPresser.state == UIGestureRecognizerStateBegan)
        [self enterCopyModeAnimated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}



@end
