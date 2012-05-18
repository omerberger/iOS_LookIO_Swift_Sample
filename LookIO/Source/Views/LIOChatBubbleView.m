//
//  LIOChatBubbleView.m
//  LookIO
//
//  Created by Joseph Toscano on 12/5/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LIOChatBubbleView.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOLookIOManager.h"
#import "TTTAttributedLabel.h"
#import "LIOBundleManager.h"
#import "LIOLogManager.h"
#import "LIOChatMessage.h"

static NSDataDetector *dataDetector = nil;

@implementation LIOChatBubbleView

@synthesize senderName, linkMode, linkMessageViews, linkButtons, mainMessageView, links, rawChatMessage, delegate, index;
@dynamic formattingMode;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UIImage *stretchableBubble = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableChatBubble"] stretchableImageWithLeftCapWidth:16 topCapHeight:36];
        backgroundImage = [[UIImageView alloc] initWithImage:stretchableBubble];
        [self addSubview:backgroundImage];
        
        mainMessageView = [[TTTAttributedLabel_LIO alloc] initWithFrame:self.bounds];
        mainMessageView.dataDetectorTypes = UIDataDetectorTypeNone;
        mainMessageView.font = [UIFont systemFontOfSize:16.0];
        mainMessageView.layer.shadowColor = [UIColor blackColor].CGColor;
        mainMessageView.layer.shadowRadius = 1.0;
        mainMessageView.layer.shadowOpacity = 1.0;
        mainMessageView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        mainMessageView.backgroundColor = [UIColor clearColor];
        mainMessageView.textColor = [UIColor whiteColor];
        mainMessageView.numberOfLines = 0;
        [self addSubview:mainMessageView];
        
        UILongPressGestureRecognizer *aLongPresser = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)] autorelease];
        [self addGestureRecognizer:aLongPresser];
        
        if (nil == dataDetector)
        {
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://1112223333"]])
                dataDetector = [[NSDataDetector alloc] initWithTypes:(NSTextCheckingTypeLink|NSTextCheckingTypePhoneNumber) error:nil];
            else
                dataDetector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:nil];
        }
        
        linkMessageViews = [[NSMutableArray alloc] init];
        links = [[NSMutableArray alloc] init];
        linkButtons = [[NSMutableArray alloc] init];
        linkTypes = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [mainMessageView release];
    [backgroundImage release];
    [senderName release];
    [linkMessageViews release];
    [links release];
    [linkButtons release];
    [linkTypes release];
    [urlBeingLaunched release];
    [rawChatMessage release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
        
    CGSize maxSize = CGSizeMake(LIOChatBubbleViewMaxTextWidth, FLT_MAX);
    CGFloat bottom;
    
    if (LIOChatBubbleViewLinkModeDisabled == linkMode)
    {
        CGSize boxSize = [mainMessageView sizeThatFits:maxSize];
        mainMessageView.frame = CGRectMake(20.0, 10.0, boxSize.width, boxSize.height);
        bottom = boxSize.height;
    }
    else
    {
        CGSize mainMessageViewSize = [mainMessageView sizeThatFits:maxSize];
        mainMessageView.frame = CGRectMake(20.0, 10.0, mainMessageViewSize.width, mainMessageViewSize.height);
        
        CGRect relativeFrame = mainMessageView.frame;
        for (int i=0; i<[links count]; i++)
        {
            UIButton *aLinkButton = [linkButtons objectAtIndex:i];
            [aLinkButton sizeToFit];
            CGRect aFrame = aLinkButton.frame;
            aFrame.origin.x = 20.0;
            aFrame.origin.y = relativeFrame.origin.y + relativeFrame.size.height + 5.0;
            aFrame.size.width = self.bounds.size.width - 40.0;
            aFrame.size.height = 51.0;
            aLinkButton.frame = aFrame;
            
            relativeFrame = aLinkButton.frame;
            
            if (i < [linkMessageViews count])
            {
                UILabel *aMessageView = [linkMessageViews objectAtIndex:i];
                CGSize aMessageViewSize = [aMessageView sizeThatFits:maxSize];
                aFrame = aMessageView.frame;
                aFrame.size = aMessageViewSize;
                aFrame.origin.x = 20.0;
                aFrame.origin.y = aLinkButton.frame.origin.y + aLinkButton.frame.size.height + 5.0;
                aMessageView.frame = aFrame;
                
                relativeFrame = aMessageView.frame;
            }
            
            bottom = relativeFrame.origin.y + relativeFrame.size.height;
        }
    }
    
    // FIXME: This really shouldn't be here.
    CGRect aFrame = self.frame;
    aFrame.size.height = bottom + 30.0;
    if (aFrame.size.height < LIOChatBubbleViewMinTextHeight) aFrame.size.height = LIOChatBubbleViewMinTextHeight;
    self.frame = aFrame;
    
    backgroundImage.frame = self.bounds;    
}

- (UILabel *)createMessageView
{
    UILabel *newMessageView = [[UILabel alloc] initWithFrame:self.bounds];
    newMessageView.font = [UIFont systemFontOfSize:16.0];
    newMessageView.layer.shadowColor = [UIColor blackColor].CGColor;
    newMessageView.layer.shadowRadius = 1.0;
    newMessageView.layer.shadowOpacity = 1.0;
    newMessageView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    newMessageView.backgroundColor = [UIColor clearColor];
    newMessageView.textColor = [UIColor whiteColor];
    newMessageView.numberOfLines = 0;
    
    return newMessageView;
}

- (UIButton *)createLinkButton
{
    UIImage *linkButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableTransparentLinkButton"];
    linkButtonImage = [linkButtonImage stretchableImageWithLeftCapWidth:9 topCapHeight:9];
    
    UIButton *newLinkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [newLinkButton setBackgroundImage:linkButtonImage forState:UIControlStateNormal];
    newLinkButton.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    [newLinkButton addTarget:self action:@selector(linkButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    newLinkButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 20.0, 0.0, 20.0);
    
    return newLinkButton;
}

- (void)populateMessageViewWithText:(NSString *)aString
{
    [links removeAllObjects];
    [linkTypes removeAllObjects];
    
    [linkMessageViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [linkMessageViews removeAllObjects];

    [linkButtons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [linkButtons removeAllObjects];
    
    NSMutableArray *textCheckingResults = [NSMutableArray array];
    
    // Check for links.
    NSRange fullRange = NSMakeRange(0, [aString length]);
    [dataDetector enumerateMatchesInString:aString options:0 range:fullRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [linkTypes addObject:[NSNumber numberWithLongLong:result.resultType]];
        [textCheckingResults addObject:result];
        NSString *currentLink = [aString substringWithRange:result.range];
        [links addObject:currentLink];
    }];
    
    NSString *firstString = aString;
    if ([links count])
    {
        // We have links, so we only use the main label for the text up to the first link.
        NSTextCheckingResult *firstLink = [textCheckingResults objectAtIndex:0];
        firstString = [aString substringWithRange:NSMakeRange(0, firstLink.range.location)];
    }
    
    [mainMessageView setText:firstString afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        
        if (0 == [senderName length])
            return mutableAttributedString;
        
        NSAttributedString *nameCallout = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", senderName]] autorelease];
        [mutableAttributedString insertAttributedString:nameCallout atIndex:0];
        
        NSRange boldRange = NSMakeRange(0, [nameCallout length]);
        
        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:16.0]; 
        CTFontRef font = CTFontCreateWithName((CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
        if (font && boldRange.location != NSNotFound)
        {
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:boldRange];
            [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[UIColor whiteColor].CGColor range:boldRange];
            CFRelease(font);
        }
        
        return mutableAttributedString;
    }];
    
    if ([links count])
    {
        linkMode = LIOChatBubbleViewLinkModeEnabled;
        
        for (int i=0; i<[links count]; i++)
        {
            // First, we need a view for the link button.
            UIButton *newLinkButton = [[self createLinkButton] autorelease];
            NSString *curLink = [links objectAtIndex:i];
            [newLinkButton setTitle:curLink forState:UIControlStateNormal];
            [linkButtons addObject:newLinkButton];
            [self addSubview:newLinkButton];
            
            // Isolate text after the link, if any.
            NSString *followingText = nil;
            NSTextCheckingResult *curResult = [textCheckingResults objectAtIndex:i];
            if (i < [links count] - 1)
            {
                // Since there's another link after this one, we need to grab the text
                // between this one and the next.
                NSTextCheckingResult *nextResult = [textCheckingResults objectAtIndex:(i + 1)];
                NSRange rangeOfText = NSUnionRange(curResult.range, nextResult.range);
                NSString *substring = [aString substringWithRange:rangeOfText];
                substring = [substring stringByReplacingOccurrencesOfString:curLink withString:@""];
                substring = [substring stringByReplacingOccurrencesOfString:[links objectAtIndex:(i + 1)] withString:@""];
                followingText = substring;
            }
            else
            {
                // No link after this one. Just grab all the text after.
                followingText = [aString substringFromIndex:(curResult.range.location + curResult.range.length)];
            }
            
            // TRIM THE BITCH
            [followingText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // Second, we need a view for the text that follows the link, if any.
            if ([followingText length])
            {
                UILabel *newMessageView = [[self createMessageView] autorelease];
                newMessageView.text = followingText;
                [linkMessageViews addObject:newMessageView];
                [self addSubview:newMessageView];
            }
        }
    }
    
    [self layoutSubviews];
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
    [UIPasteboard generalPasteboard].string = rawChatMessage.text;
}

#pragma mark -
#pragma mark Dynamic accessor methods

- (LIOChatBubbleViewFormattingMode)formattingMode
{
    return formattingMode;
}

- (void)setFormattingMode:(LIOChatBubbleViewFormattingMode)aMode
{
    formattingMode = aMode;
    [self setNeedsLayout];
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
    
    CGRect targetFrame = CGRectMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0, 0.0, 0.0);
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
        [delegate chatBubbleViewWantsCopyMenu:self];
}

#pragma mark -
#pragma mark UIControl actions

- (void)linkButtonWasTapped:(UIButton *)aButton
{
    NSUInteger linkIndex = [linkButtons indexOfObject:aButton];
    if (NSNotFound == linkIndex)
        return;
    
    NSString *aLink = [links objectAtIndex:linkIndex];
    NSTextCheckingType aType = (NSTextCheckingType)[[linkTypes objectAtIndex:linkIndex] longLongValue];
    if (NSTextCheckingTypeLink == aType)
    {
        if (NO == [aLink hasPrefix:@"http://"] && NO == [aLink hasPrefix:@"https://"])
        {
            NSString *result = [@"http://" stringByAppendingString:aLink];
            [urlBeingLaunched release];
            urlBeingLaunched = [[NSURL URLWithString:result] retain];
        }
        else
        {
            [urlBeingLaunched release];
            urlBeingLaunched = [[NSURL URLWithString:aLink] retain];
        }
        
        NSString *alertMessage = [NSString stringWithFormat:@"Are you sure you want to leave the app and visit \"%@\"?", aLink];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:alertMessage
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Don't Open", @"Open", nil];
        [alertView show];
        [alertView autorelease];
    }
    else if (NSTextCheckingTypePhoneNumber)
    {
        NSString *cleanedString = [[aLink componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
        NSString *escapedPhoneNumber = [cleanedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *result = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", escapedPhoneNumber]];        
        
        [urlBeingLaunched release];
        urlBeingLaunched = [result retain];
        
        NSString *alertMessage = [NSString stringWithFormat:@"Are you sure you want to leave the app and call \"%@\"?", aLink];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:alertMessage
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Don't Call", @"Call", nil];
        [alertView show];
        [alertView autorelease];
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (1 == buttonIndex && urlBeingLaunched)
    {
        [[UIApplication sharedApplication] openURL:urlBeingLaunched];
    }
    
    [urlBeingLaunched release];
    urlBeingLaunched = nil;
}

@end