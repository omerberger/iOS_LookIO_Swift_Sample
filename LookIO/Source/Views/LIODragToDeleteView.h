//
//  LIODragToDeleteView.h
//  LookIO
//
//  Created by Yaron Karasik on 10/29/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOAltChatViewController.h"

@interface LIODragToDeleteView : UIView {
    UILabel *deleteLabel;
    UILabel *dragHereLabel;
    BOOL isZoomedIn;
    LIOGradientLayer *vertGradient;
}

@property (nonatomic, assign) BOOL isZoomedIn;
@property (nonatomic, readonly) UILabel *deleteLabel;
- (void)presentDeleteArea;
- (void)dismissDeleteArea;
- (void)zoomInOnDeleteArea;
- (void)zoomOutOfDeleteArea;

@end
