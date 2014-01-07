//
//  LIOStarRatingView.m
//  LookIO
//
//  Created by Yaron Karasik on 6/21/13.
//
//

#import "LIOStarRatingView.h"

#import <QuartzCore/QuartzCore.h>

#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

#define LIOStarRatingViewTempStarButtonTag 1000

@interface LIOStarRatingView ()

@property (nonatomic, strong) NSMutableArray *starButtonArray;

@property (nonatomic, strong) UILabel *ratingLabel;

@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL isPanning;

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation LIOStarRatingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.currentRating = 0;
        
        self.starButtonArray = [[NSMutableArray alloc] init];
        for (int i=0; i<5; i++)
        {
            UIImage* fullStarImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSurveyRatingStarFull"];
            UIImage* emptyStarImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSurveyRatingStarEmpty"];

            UIButton* starButton = [[UIButton alloc] initWithFrame:CGRectZero];
            [starButton setImage:emptyStarImage forState:UIControlStateNormal];
            [starButton setImage:emptyStarImage forState:UIControlStateNormal | UIControlStateHighlighted];
            [starButton setImage:fullStarImage forState:UIControlStateSelected];
            [starButton setImage:fullStarImage forState:UIControlStateSelected | UIControlStateHighlighted];
            [starButton addTarget:self action:@selector(starWasTapped:) forControlEvents:UIControlEventTouchUpInside];
            starButton.selected = YES;
            [self addSubview:starButton];
            [self.starButtonArray addObject:starButton];
        }
        
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

        self.ratingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.ratingLabel.backgroundColor = [UIColor clearColor];
        self.ratingLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyStars];
        self.ratingLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyStars];
        self.ratingLabel.numberOfLines = 0;
        self.ratingLabel.textAlignment = UITextAlignmentCenter;
        self.ratingLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:self.ratingLabel];
        
        self.valueLabelArray = [[NSMutableArray alloc] init];
        
        self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:self.panGestureRecognizer];
    }

    return self;
}

- (void)layoutSubviews
{
    for (int i=0; i<5; i++)
    {
        if (i < self.starButtonArray.count)
        {
            UIButton* starButton = [self.starButtonArray objectAtIndex:i];
            if (!self.isAnimating)
                starButton.selected = (i < self.currentRating);
            
            CGRect aFrame = starButton.frame;
            aFrame.origin.x = (self.frame.size.width/2 - 125.0) + i * 50.0;
            aFrame.origin.y = 0;
            aFrame.size.width = 50;
            aFrame.size.height = 50;
            
            starButton.frame = aFrame;
            
            if (!self.isAnimating)
            {
                if (self.isPanning && i == self.currentRating - 1)
                {
                    starButton.transform = CGAffineTransformMakeScale(1.3, 1.3);
                } else
                {
                    starButton.transform = CGAffineTransformIdentity;
                }
            }
        }
    }
    
    CGRect aFrame = self.ratingLabel.frame;
    aFrame.origin.x = 0.0;

    aFrame.origin.y = 60.0;
    aFrame.size.width = self.bounds.size.width;
    aFrame.size.height = 18.0;
    self.ratingLabel.frame = aFrame;
    
    if (!self.isAnimating)
        [self setRatingTextForRating:self.currentRating];

}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    self.isAnimating = NO;
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
        self.isPanning = YES;
    
    CGPoint translation = [recognizer locationInView:self];

    if (translation.y > -10 && translation.y < self.bounds.size.height + 10) {
        int newRating = (translation.x - (self.frame.size.width/2 - 125.0))/50.0 + 1;
        if (newRating >= 0 && newRating <= 5)
            [self setRating:newRating];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        self.isPanning = NO;
        [self setNeedsLayout];
    }
}

- (void)setRatingTextForRating:(NSInteger)rating
{
    if (self.valueLabelArray && self.valueLabelArray.count == 5) {
        if (rating == 0)
            self.ratingLabel.text = @"";
        else
            self.ratingLabel.text = (NSString*)[self.valueLabelArray objectAtIndex:(5 - rating)];
    } else {
        switch (rating) {
            case 5:
                self.ratingLabel.text = LIOLocalizedString(@"LIOStarRatingView.ExcellentRatingTitle");
                break;
                
            case 4:
                self.ratingLabel.text = LIOLocalizedString(@"LIOStarRatingView.GoodRatingTitle");
                break;
                
            case 3:
                self.ratingLabel.text = LIOLocalizedString(@"LIOStarRatingView.OkRatingTitle");
                break;
                
            case 2:
                self.ratingLabel.text = LIOLocalizedString(@"LIOStarRatingView.NotGoodRatingTitle");
                break;
                
            case 1:
                self.ratingLabel.text = LIOLocalizedString(@"LIOStarRatingView.BadRatingTitle");
                break;
                
            case 0:
                self.ratingLabel.text = @"";
                
            default:
                break;
        }
    }
}

- (void)showIntroAnimationForAnswerAtIndex:(int)index
{
    [self setRatingTextForRating:index + 1];
    UIButton* starButton = [self.starButtonArray objectAtIndex:index];
    starButton.selected = YES;
    
    UIButton *tempStarButton = [[UIButton alloc] initWithFrame:starButton.frame];
    tempStarButton.tag = LIOStarRatingViewTempStarButtonTag + index;
    [tempStarButton addTarget:self action:@selector(tempButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:tempStarButton];

    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        starButton.transform = CGAffineTransformMakeScale(1.3, 1.3);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            UIButton* starButton = [self.starButtonArray objectAtIndex:index];
            starButton.transform = CGAffineTransformIdentity;
            
            self.ratingLabel.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            UIButton *tempStarButton = (UIButton*)[self viewWithTag:LIOStarRatingViewTempStarButtonTag + index];
            if (tempStarButton)
                [tempStarButton removeFromSuperview];
            
            if (index < 4 && self.isAnimating)
                [self showIntroAnimationForAnswerAtIndex:index+1];
            else {
                self.isAnimating = NO;
                [self setNeedsLayout];
            }
        }];
    }];
}

- (void)showIntroAnimation
{
    self.isAnimating = YES;

    for (int i=0; i<5; i++) {
        if (i < self.starButtonArray.count) {
            UIButton* starButton = [self.starButtonArray objectAtIndex:i];
            starButton.selected = NO;
        }
    }
    
    [self showIntroAnimationForAnswerAtIndex:0];
}

- (void)tempButtonWasTapped:(id)sender
{
    self.isAnimating = NO;
    
    UIButton* button = (UIButton*)sender;
    [self setRating:button.tag - LIOStarRatingViewTempStarButtonTag + 1];
}

- (void)starWasTapped:(id)sender
{
    self.isAnimating = NO;
    
    UIButton* button = (UIButton*)sender;
    [self setRating:[self.starButtonArray indexOfObject:button] + 1];
}

- (void)setRating:(NSInteger)newRating
{
    self.currentRating = newRating;
    [self setNeedsLayout];
    
    if ([(NSObject *)self.delegate respondsToSelector:@selector(starRatingView:didUpdateRating:)])
        [self.delegate starRatingView:self didUpdateRating:self.currentRating];
}

- (void)setValueLabels:(NSArray*)newValueLabelsArray
{
    if (newValueLabelsArray.count != 5)
        return;
    
    [self.valueLabelArray removeAllObjects];
    
    for (int i=0; i<newValueLabelsArray.count; i++) {
        NSString* valueLabel = (NSString*)[newValueLabelsArray objectAtIndex:i];
        [self.valueLabelArray addObject:valueLabel];
    }
}

@end
