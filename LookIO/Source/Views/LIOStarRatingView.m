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

@implementation LIOStarRatingView

@synthesize currentRating, valueLabelArray, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        currentRating = 5;
        
        starButtonArray = [[NSMutableArray alloc] init];
        for (int i=0; i<5; i++) {
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
    }
    return self;
}

-(void)dealloc {
    [super dealloc];

    [starButtonArray removeAllObjects];
    [starButtonArray release];
    starButtonArray = nil;
}

-(void)layoutSubviews {
    for (int i=0; i<5; i++) {
        if (i < starButtonArray.count) {
            UIButton* starButton = [starButtonArray objectAtIndex:i];
            starButton.selected = (i < currentRating);
            
            CGRect aFrame = starButton.frame;
            aFrame.origin.x = (self.frame.size.width/2 - 75.0) + i * 30.0;
            aFrame.origin.y = 0;
            aFrame.size.width = 25;
            aFrame.size.height = 25;
            
            starButton.frame = aFrame;
            
        }
    }
    
    CGRect aFrame = ratingLabel.frame;
    aFrame.origin.x = 0.0;
    aFrame.origin.y = 34.0;
    aFrame.size.width = self.bounds.size.width;
    aFrame.size.height = 15.0;
    ratingLabel.frame = aFrame;
    
    if (valueLabelArray && valueLabelArray.count == 5) {
        ratingLabel.text = (NSString*)[valueLabelArray objectAtIndex:(5 - currentRating)];
    } else {        
        switch (currentRating) {
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
                
            default:
                break;
        }
    }
}

-(void)starWasTapped:(id)sender {
    UIButton* button = (UIButton*)sender;
    currentRating = [starButtonArray indexOfObject:button] + 1;
    [self setNeedsLayout];
    
    if ([(NSObject *)delegate respondsToSelector:@selector(starRatingView:didUpdateRating:)])
        [delegate starRatingView:self didUpdateRating:currentRating];
}

- (void)setRating:(int)newRating {
    currentRating = newRating;
    [self setNeedsLayout];
    
    if ([(NSObject *)delegate respondsToSelector:@selector(starRatingView:didUpdateRating:)])
        [delegate starRatingView:self didUpdateRating:currentRating];
}

-(void)setValueLabels:(NSArray*)newValueLabelsArray {
    if (newValueLabelsArray.count != 5)
        return;
    
    [valueLabelArray removeAllObjects];
    [valueLabelArray release];
    valueLabelArray = nil;
    
    valueLabelArray = [[NSMutableArray alloc] init];
    
    for (int i=0; i<newValueLabelsArray.count; i++) {
        NSString* valueLabel = (NSString*)[newValueLabelsArray objectAtIndex:i];
        [valueLabelArray addObject:valueLabel];
    }
}
                                    


@end
