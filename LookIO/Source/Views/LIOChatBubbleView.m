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

@implementation LIOChatBubbleView

@dynamic tailDirection, formattingMode;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UIImage *stretchableBubble = [lookioImage(@"LIOStretchableChatBubble") stretchableImageWithLeftCapWidth:32 topCapHeight:36];
        backgroundImage = [[UIImageView alloc] initWithImage:stretchableBubble];
        [self addSubview:backgroundImage];
                                      
        messageView = [[UILabel alloc] initWithFrame:self.bounds];
        messageView.layer.shadowColor = [UIColor blackColor].CGColor;
        messageView.layer.shadowRadius = 1.0;
        messageView.layer.shadowOpacity = 1.0;
        messageView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        messageView.backgroundColor = [UIColor clearColor];
        messageView.textColor = [UIColor whiteColor];
        [self addSubview:messageView];
    }
    
    return self;
}

- (void)dealloc
{
    [messageView release];
    [backgroundImage release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat messageViewLeftInset = 0.0;
    
    if (LIOChatBubbleViewFormattingModeRemote == formattingMode)
    {
        messageView.font = [UIFont systemFontOfSize:18.0];
        messageViewLeftInset = 25.0;
    }
    else
    {
        messageView.font = [UIFont boldSystemFontOfSize:18.0];
        messageViewLeftInset = 13.0;
    }
    
    CGSize maxSize = CGSizeMake(LIOChatBubbleViewMaxTextWidth, FLT_MAX);
    CGSize boxSize = [messageView.text sizeWithFont:messageView.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    messageView.numberOfLines = 0;
    messageView.frame = CGRectMake(messageViewLeftInset, 10.0, boxSize.width, boxSize.height);
    
    // This feels really wrong. >______>!
    CGRect aFrame = self.frame;
    aFrame.size.height = boxSize.height + 23.0;
    if (aFrame.size.height < LIOChatBubbleViewMinTextHeight) aFrame.size.height = LIOChatBubbleViewMinTextHeight;
    self.frame = aFrame;
    
    backgroundImage.frame = self.bounds;
    
    if (LIOChatBubbleViewTailDirectionRight == tailDirection)
    {
        backgroundImage.transform = CGAffineTransformIdentity;
    }
    else
    {
        CGAffineTransform scale = CGAffineTransformMakeScale(-1.0, 1.0);
        backgroundImage.transform = scale;
    }
}

/*
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (LIOChatBubbleViewTailDirectionRight == tailDirection)
    {
        CGContextTranslateCTM(context, rect.size.width, 0.0);
        CGContextScaleCTM(context, -1.0, 1.0);    
    }
    
    CGFloat radius = 15;
    
    CGFloat originBufferX = 0.0;
    CGFloat originBufferY = 0.0;
    CGFloat rightAngleTriangleWidth = 10.0;
    CGFloat rightAngleTriangleHeight = 10.0;
    CGFloat fullRectWidth = rect.size.width;
    CGFloat fullRectHeight = rect.size.height;
    
    CGPoint pointZero = CGPointMake(originBufferX, fullRectHeight);
    CGPoint pointOne = CGPointMake(originBufferX + rightAngleTriangleWidth, fullRectHeight - rightAngleTriangleHeight);
    CGPoint pointTwo = CGPointMake(originBufferX + rightAngleTriangleWidth, radius + originBufferY);
    CGPoint pointThree = CGPointMake(originBufferX + fullRectWidth - radius, 0 + originBufferY);
    CGPoint pointFour = CGPointMake(fullRectWidth, originBufferY + fullRectHeight - radius);    
    
    CGContextSetRGBStrokeColor(context, 0.8, 0.8, 0.8, 0.7);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, pointZero.x, pointZero.y);
    
    CGPathAddLineToPoint(path, NULL, pointOne.x, pointOne.y);
    
    CGPathAddLineToPoint(path, NULL, pointTwo.x, pointTwo.y);
    
    CGPathAddArc(path, NULL, rightAngleTriangleWidth + radius, originBufferY + radius, radius, M_PI, -M_PI_2, 0);
    
    CGPathAddLineToPoint(path, NULL, pointThree.x - rightAngleTriangleWidth, pointThree.y);
    
    CGPathAddArc(path, NULL, fullRectWidth - radius - rightAngleTriangleWidth, originBufferY + radius, radius, -M_PI_2, 0.0f, 0);
    
    CGPathAddLineToPoint(path, NULL, pointFour.x - rightAngleTriangleWidth, pointFour.y);
    
    CGPathAddArc(path, NULL, fullRectWidth - radius - rightAngleTriangleWidth, originBufferY + fullRectHeight - radius, radius, 0.0f, M_PI_2, 0);
    
    CGPathAddLineToPoint(path, NULL, pointZero.x, pointZero.y);
    
    CGContextSaveGState(context);
    CGContextAddPath(context, path);
    
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 0.2f);
    CGContextFillPath(context);
    
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
}
*/

- (void)populateMessageViewWithText:(NSString *)aString
{
    messageView.text = aString;
    [self layoutSubviews];
}

#pragma mark -
#pragma mark Dynamic accessor methods

- (LIOChatBubbleViewTailDirection)tailDirection
{
    return tailDirection;
}

- (void)setTailDirection:(LIOChatBubbleViewTailDirection)aDirection
{
    tailDirection = aDirection;
    [self setNeedsDisplay];
}

- (LIOChatBubbleViewFormattingMode)formattingMode
{
    return formattingMode;
}

- (void)setFormattingMode:(LIOChatBubbleViewFormattingMode)aMode
{
    formattingMode = aMode;
    [self setNeedsLayout];
}

@end