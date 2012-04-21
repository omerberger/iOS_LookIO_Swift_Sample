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

@implementation LIOChatBubbleView

@synthesize senderName;
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
        
        dataDetector = [[NSDataDetector alloc] initWithTypes:(NSTextCheckingTypeLink|NSTextCheckingTypePhoneNumber) error:nil];
        
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
    [dataDetector release];
    [linkMessageViews release];
    [links release];
    [linkButtons release];
    [linkTypes release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
        
    
    if (LIOChatBubbleViewLinkModeDisabled == linkMode)
    {
        CGSize maxSize = CGSizeMake(LIOChatBubbleViewMaxTextWidth, FLT_MAX);
        CGSize boxSize = [mainMessageView sizeThatFits:maxSize];
        mainMessageView.frame = CGRectMake(20.0, 10.0, boxSize.width, boxSize.height);
        
        // This feels really wrong. >______>!
        CGRect aFrame = self.frame;
        aFrame.size.height = boxSize.height + 30.0;
        if (aFrame.size.height < LIOChatBubbleViewMinTextHeight) aFrame.size.height = LIOChatBubbleViewMinTextHeight;
        self.frame = aFrame;
        
        backgroundImage.frame = self.bounds;
    }
    else
    {
    }
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
    UIButton *newLinkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [newLinkButton setBackgroundImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableRecessedLinkButton"] forState:UIControlStateNormal];
    
    return newLinkButton;
}

- (void)populateMessageViewWithText:(NSString *)aString
{
    [linkMessageViews removeAllObjects];
    [links removeAllObjects];
    [linkButtons removeAllObjects];
    [linkTypes removeAllObjects];
    
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
    NSString *remainderString = nil;
    if ([links count])
    {
        // We have links, so we only use the main label for the text up to the first link.
        NSTextCheckingResult *firstLink = [links objectAtIndex:0];
        firstString = [aString substringWithRange:NSMakeRange(0, firstLink.range.location)];
        remainderString = [aString substringFromIndex:firstLink.range.location];
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
        for (int i=0; i<[links count]; i++)
        {
            // First, we need a view for the link button.
            UIButton *newLinkButton = [[self createLinkButton] autorelease];
            NSString *curLink = [links objectAtIndex:i];
            [newLinkButton setTitle:curLink forState:UIControlStateNormal];
            [linkButtons addObject:newLinkButton];
            
            // Isolate text after the link, if any.
            NSTextCheckingResult *curResult = [textCheckingResults objectAtIndex:i];
            if (i < [links count] - 1)
            {
                NSTextCheckingResult *nextResult = [textCheckingResults objectAtIndex:(i + 1)];
                NSRange rangeOfText = NSUnionRange(curResult.range, nextResult.range);
                //NSString *substring = [aString 
            }
        }
                
        // "Here's a test message with a phone number like 949.505.2670. Also, here's a URL: http://google.com/ Have fun!"
        // Remainder: "949.505.2670. Also, here's a URL: http://google.com/ Have fun!"
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
    [UIPasteboard generalPasteboard].string = mainMessageView.text;
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

#pragma mark -
#pragma mark Gesture handlers

- (void)handleLongPress:(UILongPressGestureRecognizer *)aLongPresser
{
    if (aLongPresser.state == UIGestureRecognizerStateBegan)
    {
        CGRect targetFrame = CGRectMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0, 0.0, 0.0);
        
        [self becomeFirstResponder];
        
        [self performBounceAnimation];
        
        UIMenuController *menu = [UIMenuController sharedMenuController];
        menu.arrowDirection = UIMenuControllerArrowUp;
        [menu setTargetRect:targetFrame inView:self];
        [menu setMenuVisible:YES animated:YES];
    }
}

@end