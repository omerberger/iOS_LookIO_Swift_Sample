//
//  LIOSquareControlButtonView.h
//  LookIO
//
//  Created by Yaron Karasik on 10/29/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOTimerProxy.h"

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
    BOOL labelVisible;
    UIColor *tintColor, *textColor, *fillColor, *shadowColor, *borderColor;
    NSString *labelText;
    UIImageView *innerShadow;
    UIImageView *bubbleImageView;
    UIActivityIndicatorView *spinner;
    LIOSquareControlButtonViewMode currentMode;
    UIView *backgroundView;
    
    id<LIOSquareControlButtonViewDelegate> delegate;
    
    LIOTimerProxy *timerProxy;
}

@property(nonatomic, retain) UIColor *tintColor, *textColor;
@property(nonatomic, retain) NSString *labelText;
@property(nonatomic, readonly) UILabel *label;
@property(nonatomic, readonly) UIImageView *bubbleImageView;
@property(nonatomic, assign) LIOSquareControlButtonViewMode currentMode;
@property(nonatomic, readonly) UIActivityIndicatorView *spinner;
@property(nonatomic, assign) id<LIOSquareControlButtonViewDelegate> delegate;

- (void)dismissLabel;
- (void)presentLabel;
- (void)toggleLabel;
- (void)updateButtonColor;
- (void)updateButtonForChatTheme;

@end