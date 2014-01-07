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

- (void)starRatingView:(LIOStarRatingView*)aView didUpdateRating:(NSInteger)aRating;

@end

@interface LIOStarRatingView : UIView

@property (nonatomic, assign) id<LIOStarRatingViewDelegate> delegate;
@property (nonatomic, assign) NSInteger currentRating;
@property (nonatomic, strong) NSMutableArray* valueLabelArray;

- (void)setRating:(NSInteger)newRating;
- (void)setValueLabels:(NSArray*)newValueLabelsArray;
- (void)showIntroAnimation;

@end
