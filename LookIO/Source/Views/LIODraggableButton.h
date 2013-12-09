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

@property (nonatomic, strong) NSString *fillColor;
@property (nonatomic, strong) NSString *textColor;

- (void)show;
- (void)hide;

- (void)resetFrame;
- (void)updateButtonColors;
- (void)updateButtonIcon;

@end