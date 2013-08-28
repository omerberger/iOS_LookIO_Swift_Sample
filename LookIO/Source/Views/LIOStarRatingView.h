//
//  LIOStarRatingView.h
//  LookIO
//
//  Created by Yaron Karasik on 6/21/13.
//
//

#import <UIKit/UIKit.h>

@class LIOStarRatingView;

@protocol LIOStarRatingViewDelegate
@optional
- (void)starRatingView:(LIOStarRatingView*)aView didUpdateRating:(int)aRating;
@end

@interface LIOStarRatingView : UIView {
    id<LIOStarRatingViewDelegate> delegate;

    NSMutableArray* starButtonArray;
    UILabel* ratingLabel;
    int currentRating;
    
    BOOL isAnimating;
    BOOL isPanning;
    
    NSMutableArray* valueLabelArray;
    
    UIPanGestureRecognizer *panGestureRecognizer;
}

@property (nonatomic, assign) id<LIOStarRatingViewDelegate> delegate;
@property (nonatomic, readonly) int currentRating;
@property (nonatomic, retain) NSMutableArray* valueLabelArray;

- (void)setRating:(int)newRating;
- (void)setValueLabels:(NSArray*)newValueLabelsArray;
- (void)showIntroAnimation;

@end
