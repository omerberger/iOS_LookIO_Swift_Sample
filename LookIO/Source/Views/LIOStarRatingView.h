//
//  LIOStarRatingView.h
//  LookIO
//
//  Created by Yaron Karasik on 6/21/13.
//
//

#import <UIKit/UIKit.h>

@interface LIOStarRatingView : UIView {
    NSMutableArray* starButtonArray;
    UILabel* ratingLabel;
    int currentRating;
}

@property (nonatomic, readonly) int currentRating;

- (void)setRating:(int)newRating;

@end
