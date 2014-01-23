//
//  LIODraggableButton.h
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import <UIKit/UIKit.h>

typedef enum
{
    LIOButtonModeChat = 0,
    LIOButtonModeLoading,
    LIOButtonModeSurvey
} LIOButtonMode;

@class LIODraggableButton;

@protocol LIODraggableButtonDelegate <NSObject>

- (void)draggableButtonWasTapped:(LIODraggableButton *)draggableButton;
- (void)draggableButtonDidBeginDragging:(LIODraggableButton *)draggableButton;
- (void)draggableButtonDidEndDragging:(LIODraggableButton *)draggableButton;

@end

@interface LIODraggableButton : UIButton

@property (nonatomic, assign) id <LIODraggableButtonDelegate> delegate;
@property (nonatomic, assign) LIOButtonMode buttonMode;

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;

- (void)presentMessage:(NSString *)message;

- (void)resetFrame;
- (void)updateButtonBranding;

- (void)setLoadingMode;
- (void)setChatMode;
- (void)setSurveyMode;

@end