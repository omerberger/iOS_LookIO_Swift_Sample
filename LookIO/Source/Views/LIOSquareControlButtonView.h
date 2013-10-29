//
//  LIOSquareControlButtonView.h
//  LookIO
//
//  Created by Yaron Karasik on 10/29/13.
//
//

#import <UIKit/UIKit.h>

@class LIOSquareControlButtonView, LIOTimerProxy;

@protocol LIOSquareControlButtonViewDelegate
- (void)squareControlButtonViewWasTapped:(LIOSquareControlButtonView *)aControlButton;
@end

typedef enum
{
    LIOSquareControlButtonViewModeDefault,
    LIOSquareControlButtonViewModePending
} LIOSquareControlButtonViewMode;

@interface LIOSquareControlButtonView : UIView
{
    UILabel *label;
    UIColor *tintColor, *textColor, *fillColor, *shadowColor, *borderColor;
    NSString *labelText;
    UIImageView *innerShadow;
    UIImageView *bubbleImageView;
    UIActivityIndicatorView *spinner;
    LIOSquareControlButtonViewMode currentMode;
    
    id<LIOSquareControlButtonViewDelegate> delegate;
}

@property(nonatomic, retain) UIColor *tintColor, *textColor;
@property(nonatomic, retain) NSString *labelText;
@property(nonatomic, readonly) UILabel *label;
@property(nonatomic, assign) LIOSquareControlButtonViewMode currentMode;
@property(nonatomic, readonly) UIActivityIndicatorView *spinner;
@property(nonatomic, assign) id<LIOSquareControlButtonViewDelegate> delegate;

- (void)updateButtonForChatTheme;

@end