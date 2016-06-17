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

typedef enum
{
    LIOButtonKindText = 0,
    LIOButtonKindIcon = 1
} LIOButtonKind;

@class LIODraggableButton;

@protocol LIODraggableButtonDelegate <NSObject>

- (void)draggableButtonWasTapped:(LIODraggableButton *)draggableButton;

@end

@interface LIODraggableButton : UIButton

@property (nonatomic, assign) id <LIODraggableButtonDelegate> delegate;
@property (nonatomic, assign) LIOButtonMode buttonMode;
@property (nonatomic, assign) LIOButtonKind buttonKind;

@property (nonatomic, assign) NSInteger numberOfUnreadMessages;

@property (nonatomic, strong) NSString *buttonTitle;

@property (nonatomic, assign) BOOL ignoreActualInterfaceOrientation;

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;

- (void)presentMessage:(NSString *)message;
- (void)hideCurrentMessage;
- (void)resetUnreadMessages;
- (void)reportUnreadMessage;

- (void)resetFrame;
- (void)updateButtonBranding;
- (void)updateBaseValues;

- (void)setLoadingMode;
- (void)setChatMode;
- (void)setSurveyMode;

- (void)removeTimers;

@end