//
//  LIOChatBubbleView.m
//  LookIO
//
//  Created by Joseph Toscano on 12/5/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
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

@synthesize senderName, linkMode, linkMessageViews, linkButtons, mainMessageView, links, rawChatMessage, delegate, index, bubbleStyle;
@dynamic formattingMode;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        mainMessageView = [[TTTAttributedLabel_LIO alloc] initWithFrame:self.bounds];
        mainMessageView.dataDetectorTypes = UIDataDetectorTypeNone;
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
        intraAppLinkViews = [[NSMutableArray alloc] init];
        linkSupertypes = [[NSMutableArray alloc] init];
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
    [intraAppLinkViews release];
    [linkSupertypes release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (nil == backgroundImage && LIOChatBubbleViewFormattingModeHeader != formattingMode)
    {
        UIImage *stretchableBubble = nil;
        if (LIOChatBubbleViewBubbleStyleChat == bubbleStyle)
        {
            stretchableBubble = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableChatBubble"] stretchableImageWithLeftCapWidth:16 topCapHeight:16];
        }
        else if (LIOChatBubbleViewBubbleStyleSurvey == bubbleStyle)
        {
            if (LIOChatBubbleViewFormattingModeRemote == formattingMode)
            {
                stretchableBubble = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSurveyBubbleRemote"] stretchableImageWithLeftCapWidth:16 topCapHeight:16];
            }
            else
            {
                stretchableBubble = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSurveyBubbleLocal"] stretchableImageWithLeftCapWidth:16 topCapHeight:16];
            }
        }
            
        backgroundImage = [[UIImageView alloc] initWithImage:stretchableBubble];
        [self insertSubview:backgroundImage belowSubview:mainMessageView];
    }

    CGSize maxSize = CGSizeMake(LIOChatBubbleViewMaxTextWidth, FLT_MAX);
    CGFloat bottom;
    
    // Some additional modifications for header mode.
    if (LIOChatBubbleViewFormattingModeHeader == formattingMode)
        maxSize = CGSizeMake(300.0, FLT_MAX);
    
    if (LIOChatBubbleViewLinkModeDisabled == linkMode)
    {
        CGSize boxSize = [mainMessageView sizeThatFits:maxSize];
        bottom = boxSize.height + 10.0;
        
        if (LIOChatBubbleViewFormattingModeHeader == formattingMode)
        {
            CGRect aFrame;
            aFrame.size = boxSize;
            aFrame.origin.y = 5.0;
            aFrame.origin.x = (self.bounds.size.width / 2.0) - (aFrame.size.width / 2.0);
            mainMessageView.frame = aFrame;
        }
        else
            mainMessageView.frame = CGRectMake(20.0, 10.0, boxSize.width, boxSize.height);
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
            
            // Intra-link? Check for a custom view.
            UIView *linkView = [intraAppLinkViews objectAtIndex:i];
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
    
    CGFloat bottomPadding = 30.0;
    if (LIOChatBubbleViewFormattingModeHeader == formattingMode)
        bottomPadding = 3.0;
    
    // FIXME: This really shouldn't be here.
    CGRect aFrame = self.frame;
    aFrame.size.height = bottom + bottomPadding;
    if (LIOChatBubbleViewFormattingModeHeader != formattingMode && aFrame.size.height < LIOChatBubbleViewMinTextHeight)
        aFrame.size.height = LIOChatBubbleViewMinTextHeight;
    self.frame = aFrame;
    
    backgroundImage.frame = self.bounds;    
}

- (UILabel *)createMessageView
{
    UILabel *newMessageView = [[UILabel alloc] initWithFrame:self.bounds];
    newMessageView.font = [UIFont systemFontOfSize:15.0];
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
    if (LIOChatBubbleViewFormattingModeHeader == formattingMode)
    {
        mainMessageView.font = [UIFont boldSystemFontOfSize:14.0];
        mainMessageView.textAlignment = UITextAlignmentCenter;
    }
    else
    {
        mainMessageView.font = [UIFont systemFontOfSize:15.0];
        mainMessageView.textAlignment = UITextAlignmentLeft;
    }
    
    [links removeAllObjects];
    [linkTypes removeAllObjects];
    [linkSupertypes removeAllObjects];
    
    [linkMessageViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [linkMessageViews removeAllObjects];

    [linkButtons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [linkButtons removeAllObjects];
    
    [intraAppLinkViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [intraAppLinkViews removeAllObjects];
    
    NSMutableArray *textCheckingResults = [NSMutableArray array];
    
    // Check for links.
    NSRange fullRange = NSMakeRange(0, [aString length]);
    [dataDetector enumerateMatchesInString:aString options:0 range:fullRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSString *currentLink = [aString substringWithRange:result.range];
        if (NSTextCheckingTypeLink == result.resultType)
        {
            // We filter out links marked as "NSTextCheckingTypeLink" but which
            // lack any kind of URL scheme at the beginning.
            NSURL *testURL = [NSURL URLWithString:currentLink];
            if (0 == [testURL.scheme length])
                return;
        }
        
        [links addObject:currentLink];
        [linkTypes addObject:[NSNumber numberWithLongLong:result.resultType]];
        [textCheckingResults addObject:result];
        
        // Special handling for links; could be intra-app!
        if (NSTextCheckingTypeLink == result.resultType)
        {
            NSURL *currentURL = [NSURL URLWithString:currentLink];
            if ([[LIOLookIOManager sharedLookIOManager] isIntraLink:currentURL])
            {
                [linkSupertypes addObject:[NSNumber numberWithInt:LIOChatBubbleViewLinkSupertypeIntra]];
                id linkView = [[LIOLookIOManager sharedLookIOManager] linkViewForURL:currentURL];
                if (linkView && ([linkView isKindOfClass:[UIView class]] || [linkView isKindOfClass:[NSString class]]))
                {
                    if ([linkView isKindOfClass:[UIView class]])
                        [intraAppLinkViews addObject:linkView];
                    else
                    {
                        NSString *aString = (NSString *)linkView;
                        UILabel *aLabel = [[[UILabel alloc] init] autorelease];
                        aLabel.backgroundColor = [UIColor clearColor];
                        aLabel.textColor = [UIColor whiteColor];
                        aLabel.text = aString;
                        aLabel.textAlignment = UITextAlignmentCenter;
                        [intraAppLinkViews addObject:aLabel];
                    }
                }
                else
                    [intraAppLinkViews addObject:[NSNull null]];
            }
            else
            {
                [linkSupertypes addObject:[NSNumber numberWithInt:LIOChatBubbleViewLinkSupertypeExtra]];
                [intraAppLinkViews addObject:[NSNull null]];
            }
        }
        else
        {
            [linkSupertypes addObject:[NSNumber numberWithInt:LIOChatBubbleViewLinkSupertypeExtra]];
            [intraAppLinkViews addObject:[NSNull null]];
        }
    }];
    
    NSString *firstString = aString;
    if ([links count])
    {
        // We have links, so we only use the main label for the text up to the first link.
        NSTextCheckingResult *firstLink = [textCheckingResults objectAtIndex:0];
        firstString = [aString substringWithRange:NSMakeRange(0, firstLink.range.location)];
    }
    
    [mainMessageView setText:firstString afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
                
        if (LIOChatBubbleViewBubbleStyleSurvey == bubbleStyle && LIOChatBubbleViewFormattingModeRemote == formattingMode)
        {
            int seq = rawChatMessage.sequence;
            NSString *headerString = [NSString stringWithFormat:@"Question %d:\n", seq];
            NSAttributedString *questionHeader = [[[NSAttributedString alloc] initWithString:headerString] autorelease];
            [mutableAttributedString insertAttributedString:questionHeader atIndex:0];
            NSRange boldRange = NSMakeRange(0, [questionHeader length]);
            
            UIFont *boldNameFont = [UIFont boldSystemFontOfSize:15.0];
            CTFontRef boldNameCTFont = CTFontCreateWithName((CFStringRef)boldNameFont.fontName, boldNameFont.pointSize, NULL);
            
            if (boldRange.location != NSNotFound)
            {
                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)boldNameCTFont range:boldRange];
                [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[UIColor whiteColor].CGColor range:boldRange];
            }
            
            CFRelease(boldNameCTFont);
        }
        else if ([senderName length])
        {
            NSAttributedString *nameCallout = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", senderName]] autorelease];
            [mutableAttributedString insertAttributedString:nameCallout atIndex:0];
            NSRange boldRange = NSMakeRange(0, [nameCallout length]);
            
            UIFont *boldNameFont = [UIFont boldSystemFontOfSize:15.0];
            CTFontRef boldNameCTFont = CTFontCreateWithName((CFStringRef)boldNameFont.fontName, boldNameFont.pointSize, NULL);
            
            if (boldRange.location != NSNotFound)
            {
                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)boldNameCTFont range:boldRange];
                [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[UIColor whiteColor].CGColor range:boldRange];
            }
            
            CFRelease(boldNameCTFont);
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
    int aSupertype = [[linkSupertypes objectAtIndex:linkIndex] intValue];
    if (NSTextCheckingTypeLink == aType)
    {
        if (LIOChatBubbleViewLinkSupertypeExtra == aSupertype)
        {
            [urlBeingLaunched release];
            urlBeingLaunched = [[NSURL URLWithString:aLink] retain];
            
            NSString *alertMessage = [NSString stringWithFormat:@"Are you sure you want to leave the app and visit \"%@\"?", aLink];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:alertMessage
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Don't Open", @"Open", nil];
            [alertView show];
            [alertView autorelease];
        }
        else
        {
            // Intra-app links don't require a warning.
            [delegate chatBubbleView:self didTapIntraAppLinkWithURL:[NSURL URLWithString:aLink]];
        }
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