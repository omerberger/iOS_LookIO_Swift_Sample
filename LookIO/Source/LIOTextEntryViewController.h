//
//  LIOTextEntryViewController.h
//  LookIO
//
//  Created by Joe Toscano on 9/9/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
@protocol LIOTextEntryViewControllerDelegate
- (void)textEntryViewControllerWasDismissed:(LIOTextEntryViewController *)aController;
- (void)textEntryViewController:(LIOTextEntryViewController *)aController wasDismissedWithText:(NSString *)someText;
@optional
- (UIReturnKeyType)textEntryViewControllerReturnKeyType:(LIOTextEntryViewController *)aController;
- (UIKeyboardType)textEntryViewControllerKeyboardType:(LIOTextEntryViewController *)aController;
- (UITextAutocorrectionType)textEntryViewControllerAutocorrectionType:(LIOTextEntryViewController *)aController;
- (UITextAutocapitalizationType)textEntryViewControllerAutocapitalizationType:(LIOTextEntryViewController *)aController;
@end
 */

@interface LIOTextEntryViewController : UIViewController
{
    UIView *bubbleView;
    UITextView *textEditor;
    UILabel *instructionsLabel;
    UIButton *sendButton, *cancelButton;
    BOOL keyboardShown;
    NSString *instructionsText;
    id delegate;
}

@property(nonatomic, assign) id delegate;
@property(nonatomic, retain) NSString *instructionsText;

@end
