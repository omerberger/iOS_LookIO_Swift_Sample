//
//  LIODraggableButton.h
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import <UIKit/UIKit.h>

@class LIODraggableButton;

@protocol LIODraggableButtonDelegate <NSObject>

- (void)draggableButtonWasTapped:(LIODraggableButton *)draggableButton;
- (void)draggableButtonDidBeginDragging:(LIODraggableButton *)draggableButton;
- (void)draggableButtonDidEndDragging:(LIODraggableButton *)draggableButton;

@end

@interface LIODraggableButton : UIButton

@property (nonatomic, assign) id <LIODraggableButtonDelegate> delegate;

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;

- (void)resetFrame;
- (void)updateButtonBranding;

@end