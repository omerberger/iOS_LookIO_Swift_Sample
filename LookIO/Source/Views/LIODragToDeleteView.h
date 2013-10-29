//
//  LIODragToDeleteView.h
//  LookIO
//
//  Created by Yaron Karasik on 10/29/13.
//
//

#import <UIKit/UIKit.h>

@interface LIODragToDeleteView : UIView {
    UILabel *deleteLabel;
    BOOL isZoomedIn;
}

@property (nonatomic, assign) BOOL isZoomedIn;

- (void)zoomInOnDeleteArea;
- (void)zoomOutOfDeleteArea;

@end
