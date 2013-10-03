//
//  LIOStarRatingView.m
//  LookIO
//
//  Created by Yaron Karasik on 6/21/13.
//
//

#import "LIOStarRatingView.h"
#import "LIOBundleManager.h"
#import <QuartzCore/QuartzCore.h>

#define LIOStarRatingViewTempStarButtonTag 1000

@implementation LIOStarRatingView

@synthesize currentRating, valueLabelArray, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        currentRating = 0;
        
        starButtonArray = [[NSMutableArray alloc] init];
        for (int i=0; i<5; i++) {
            UIImage* fullStarImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSurveyRatingStarFull"];
            UIImage* emptyStarImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSurveyRatingStarEmpty"];

            UIButton* starButton = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
            [starButton setImage:emptyStarImage forState:UIControlStateNormal];
            [starButton setImage:emptyStarImage forState:UIControlStateNormal | UIControlStateHighlighted];
            [starButton setImage:fullStarImage forState:UIControlStateSelected];
            [starButton setImage:fullStarImage forState:UIControlStateSelected | UIControlStateHighlighted];
            [starButton addTarget:self action:@selector(starWasTapped:) forControlEvents:UIControlEventTouchUpInside];
            starButton.selected = YES;
            [self addSubview:starButton];
            [starButtonArray addObject:starButton];
        }
        
        ratingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        ratingLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        ratingLabel.layer.shadowRadius = 1.0;
        ratingLabel.layer.shadowOpacity = 1.0;
        ratingLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        ratingLabel.backgroundColor = [UIColor clearColor];
        ratingLabel.textColor = [UIColor whiteColor];
        ratingLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
        ratingLabel.numberOfLines = 0;
        ratingLabel.textAlignment = UITextAlignmentCenter;
        ratingLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:ratingLabel];
        [ratingLabel release];
        
        valueLabelArray = [[NSMutableArray alloc] init];
        
        panGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)] autorelease];
        [self addGestureRecognizer:panGestureRecognizer];
    }
    return self;
}

-(void)dealloc {
    [super dealloc];
    
    [valueLabelArray release];
    
    [starButtonArray removeAllObjects];
    [starButtonArray release];
    starButtonArray = nil;
    
}

-(void)layoutSubviews {
    for (int i=0; i<5; i++) {
        if (i < starButtonArray.count) {
            UIButton* starButton = [starButtonArray objectAtIndex:i];
            if (!isAnimating)
                starButton.selected = (i < currentRating);
            
            CGRect aFrame = starButton.frame;
            aFrame.origin.x = (self.frame.size.width/2 - 125.0) + i * 50.0;
            aFrame.origin.y = 0;
            aFrame.size.width = 50;
            aFrame.size.height = 50;
            
            starButton.frame = aFrame;
            
            if (!isAnimating) {
                if (isPanning && i == currentRating - 1) {
                    starButton.transform = CGAffineTransformMakeScale(1.3, 1.3);
                } else {
                    starButton.transform = CGAffineTransformIdentity;
                }
            }
        }
    }
    
    CGRect aFrame = ratingLabel.frame;
    aFrame.origin.x = 0.0;
    aFrame.origin.y = 60.0;
    aFrame.size.width = self.bounds.size.width;
    aFrame.size.height = 15.0;
    ratingLabel.frame = aFrame;
    
    if (!isAnimating)
        [self setRatingTextForRating:currentRating];

}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    isAnimating = NO;
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
        isPanning = YES;
    
    CGPoint translation = [recognizer locationInView:self];

    if (translation.y > -10 && translation.y < self.bounds.size.height + 10) {
        int newRating = (translation.x - (self.frame.size.width/2 - 125.0))/50.0 + 1;
        if (newRating >= 0 && newRating <= 5)
            [self setRating:newRating];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        isPanning = NO;
        [self setNeedsLayout];
    }
}

- (void)setRatingTextForRating:(NSInteger)rating {
    if (valueLabelArray && valueLabelArray.count == 5) {
        if (rating == 0)
            ratingLabel.text = @"";
        else
            ratingLabel.text = (NSString*)[valueLabelArray objectAtIndex:(5 - rating)];
    } else {
        switch (rating) {
            case 5:
                ratingLabel.text = LIOLocalizedString(@"LIOStarRatingView.ExcellentRatingTitle");
                break;
                
            case 4:
                ratingLabel.text = LIOLocalizedString(@"LIOStarRatingView.GoodRatingTitle");
                break;
                
            case 3:
                ratingLabel.text = LIOLocalizedString(@"LIOStarRatingView.OkRatingTitle");
                break;
                
            case 2:
                ratingLabel.text = LIOLocalizedString(@"LIOStarRatingView.NotGoodRatingTitle");
                break;
                
            case 1:
                ratingLabel.text = LIOLocalizedString(@"LIOStarRatingView.BadRatingTitle");
                break;
                
            case 0:
                ratingLabel.text = @"";
                
            default:
                break;
        }
    }
}

- (void)showIntroAnimationForAnswerAtIndex:(int)index {
    [self setRatingTextForRating:index + 1];
    UIButton* starButton = [starButtonArray objectAtIndex:index];
    starButton.selected = YES;
    
    UIButton *tempStarButton = [[UIButton alloc] initWithFrame:starButton.frame];
    tempStarButton.tag = LIOStarRatingViewTempStarButtonTag + index;
    [tempStarButton addTarget:self action:@selector(tempButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:tempStarButton];
    [tempStarButton release];

    [UIView animateWithDuration:0.3 animations:^{
        starButton.transform = CGAffineTransformMakeScale(1.3, 1.3);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            UIButton* starButton = [starButtonArray objectAtIndex:index];
            starButton.transform = CGAffineTransformIdentity;
            
            ratingLabel.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            UIButton *tempStarButton = (UIButton*)[self viewWithTag:LIOStarRatingViewTempStarButtonTag + index];
            if (tempStarButton)
                [tempStarButton removeFromSuperview];
            
            if (index < 4 && isAnimating)
                [self showIntroAnimationForAnswerAtIndex:index+1];
            else {
                isAnimating = NO;
                [self setNeedsLayout];
            }
        }];
    }];
}

- (void)showIntroAnimation {
    isAnimating = YES;

    for (int i=0; i<5; i++) {
        if (i < starButtonArray.count) {
            UIButton* starButton = [starButtonArray objectAtIndex:i];
            starButton.selected = NO;
        }
    }
    
    [self showIntroAnimationForAnswerAtIndex:0];
}

- (void)tempButtonWasTapped:(id)sender {
    isAnimating = NO;
    
    UIButton* button = (UIButton*)sender;
    [self setRating:button.tag - LIOStarRatingViewTempStarButtonTag + 1];
}

- (void)starWasTapped:(id)sender {
    isAnimating = NO;
    
    UIButton* button = (UIButton*)sender;
    [self setRating:[starButtonArray indexOfObject:button] + 1];
}

- (void)setRating:(NSInteger)newRating {
    currentRating = newRating;
    [self setNeedsLayout];
    
    if ([(NSObject *)delegate respondsToSelector:@selector(starRatingView:didUpdateRating:)])
        [delegate starRatingView:self didUpdateRating:currentRating];
}

-(void)setValueLabels:(NSArray*)newValueLabelsArray {
    if (newValueLabelsArray.count != 5)
        return;
    
    [valueLabelArray removeAllObjects];
    
    for (int i=0; i<newValueLabelsArray.count; i++) {
        NSString* valueLabel = (NSString*)[newValueLabelsArray objectAtIndex:i];
        [valueLabelArray addObject:valueLabel];
    }
}
                                    


@end
