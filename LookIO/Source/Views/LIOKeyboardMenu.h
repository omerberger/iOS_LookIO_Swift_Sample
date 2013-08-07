//
//  LIOKeyboardMenu.h
//  LookIO
//
//  Created by Yaron Karasik on 8/5/13.
//
//

#import <UIKit/UIKit.h>

@class LIOKeyboardMenu;

@protocol LIOKeyboardMenuDelegate <NSObject>

@optional

-(void)keyboardMenuAttachButtonWasTapped:(LIOKeyboardMenu*)keyboardMenu;
-(void)keyboardMenuEmailChatButtonWasTapped:(LIOKeyboardMenu*)keyboardMenu;
-(void)keyboardMenuHideChatButtonWasTapped:(LIOKeyboardMenu*)keyboardMenu;
-(void)keyboardMenuEndSessionButtonWasTapped:(LIOKeyboardMenu*)keyboardMenu;
-(void)keyboardMenuShowKeyboardButtonWasTapped:(LIOKeyboardMenu*)keyboardMenu;

@end

@interface LIOKeyboardMenu : UIView {
    NSMutableArray *buttonsArray;
    id <LIOKeyboardMenuDelegate> delegate;

}

@property (nonatomic, assign) id <LIOKeyboardMenuDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *buttonsArray;

@end
