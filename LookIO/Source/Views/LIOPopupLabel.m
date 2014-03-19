//
//  LIOPopupLabel.m
//  LookIO
//
//  Created by Yaron Karasik on 2/6/14.
//
//

#import "LIOPopupLabel.h"

#define LIOPopupLabelMarginSize 10

@interface LIOPopupLabel ()

@end

@implementation LIOPopupLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.arrowLayer = [CAShapeLayer layer];
        self.arrowLayer.cornerRadius = 3.0;
        self.arrowLayer.strokeColor =  [[UIColor clearColor] CGColor];
        [self.layer addSublayer:self.arrowLayer];
        
        self.borderLayer = [CAShapeLayer layer];
        self.borderLayer.cornerRadius = 3.0;
        self.borderLayer.fillColor = [[UIColor clearColor] CGColor];
        [self.layer addSublayer:self.borderLayer];
        
        self.clipsToBounds = NO;
    }
    return self;
}

- (void)layoutSubviews
{
    UIBezierPath *arrowPath = [[UIBezierPath alloc] init];
    if (self.isPointingRight)
    {
        [arrowPath moveToPoint:CGPointMake(self.bounds.size.width, 0)];
        [arrowPath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height*0.33)];
        [arrowPath addLineToPoint:CGPointMake(self.bounds.size.width + self.bounds.size.height*0.2, self.bounds.size.height*0.5)];
        [arrowPath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height*0.66)];
        [arrowPath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height)];
        [arrowPath closePath];
    }
    else
    {
        [arrowPath moveToPoint:CGPointMake(0, 0)];
        [arrowPath addLineToPoint:CGPointMake(0, self.bounds.size.height*0.33)];
        [arrowPath addLineToPoint:CGPointMake(-self.bounds.size.height*0.2, self.bounds.size.height*0.5)];
        [arrowPath addLineToPoint:CGPointMake(0, self.bounds.size.height*0.66)];
        [arrowPath addLineToPoint:CGPointMake(0, self.bounds.size.height)];
        [arrowPath closePath];
    }
    
    self.arrowLayer.path = [arrowPath CGPath];
    self.arrowLayer.frame = self.bounds;
    
    UIBezierPath *borderPath = [[UIBezierPath alloc] init];
    if (self.isPointingRight)
    {
        [borderPath moveToPoint:CGPointMake(0, 0)];
        [borderPath addLineToPoint:CGPointMake(self.bounds.size.width, 0)];
        [borderPath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height*0.33)];
        [borderPath addLineToPoint:CGPointMake(self.bounds.size.width + self.bounds.size.height*0.2, self.bounds.size.height*0.5)];
        [borderPath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height*0.66)];
        [borderPath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height)];
        [borderPath addLineToPoint:CGPointMake(0, self.bounds.size.height)];
        [borderPath closePath];
    }
    else
    {
        [borderPath moveToPoint:CGPointMake(0, 0)];
        [borderPath addLineToPoint:CGPointMake(0, self.bounds.size.height*0.33)];
        [borderPath addLineToPoint:CGPointMake(-self.bounds.size.height*0.2, self.bounds.size.height*0.5)];
        [borderPath addLineToPoint:CGPointMake(0, self.bounds.size.height*0.66)];
        [borderPath addLineToPoint:CGPointMake(0, self.bounds.size.height)];
        [borderPath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height)];
        [borderPath addLineToPoint:CGPointMake(self.bounds.size.width, 0)];
        [borderPath closePath];
    }
    
    self.borderLayer.path = [borderPath CGPath];
    self.borderLayer.frame = self.bounds;
    
}

- (void)drawTextInRect:(CGRect)rect {
    UIEdgeInsets insets = {LIOPopupLabelMarginSize, LIOPopupLabelMarginSize, LIOPopupLabelMarginSize, LIOPopupLabelMarginSize};
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end
