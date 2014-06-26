//
//  LIOChatViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOChatViewController.h"

// Managers
#import "LIOBundleManager.h"
#import "LIOMediaManager.h"
#import "LIOBrandingManager.h"

// Table View Cells
#import "LIOChatTableViewCell.h"
#import "LIOChatTableViewImageCell.h"
#import "LPChatBubbleView.h"
#import "LPChatImageView.h"

// Other Views
#import "LPInputBarView.h"
#import "LIOKeyboardMenu.h"
#import "LIOToasterView.h"
#import "LIOEmailChatView.h"
#import "LIOApprovePhotoView.h"

// Models
#import "LIOSoundEffect.h"

#define LIOChatViewControllerChatTableViewCellIdentifier        @"LIOChatViewControllerChatTableViewCellIdentifier"
#define LIOChatViewControllerChatTableViewImageCellIdentifier   @"LIOChatViewControllerChatTableViewImageCellIdentifier"

#define LIOChatViewControllerMaximumAttachmentActualSize 800.0

#define LIOChatViewControllerEndChatAlertViewTag          1001
#define LIOChatViewControllerOpenExtraAppLinkAlertViewTag 1002
#define LIOChatViewControllerOpenWebLinkAlertViewTag      1003

@interface LIOChatViewController () <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, LPInputBarViewDelegte, LIOKeyboardMenuDelegate, UIGestureRecognizerDelegate, LIOEmailChatViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, LIOToasterViewDelegate, LIOChatTableViewCellDelegate, LIOApprovePhotoViewDelegate>

@property (nonatomic, assign) LIOChatState chatState;

@property (nonatomic, strong) LIOEngagement *engagement;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *tableFooterView;
@property (nonatomic, assign) NSInteger numberOfMessagesToShowInScrollBack;
@property (nonatomic, assign) NSInteger lastScrollId;

@property (nonatomic, strong) LPInputBarView *inputBarView;
@property (nonatomic, assign) CGFloat inputBarViewDesiredHeight;

@property (nonatomic, strong) LIOKeyboardMenu *keyboardMenu;

@property (nonatomic, assign) LIOKeyboardState keyboardState;
@property (nonatomic, assign) CGFloat lastKeyboardHeight;
@property (nonatomic, assign) CGFloat keyboardMenuHeightBeforeDragging;
@property (nonatomic, assign) CGFloat keyboardMenuDragStartPoint;
@property (nonatomic, assign) BOOL keyboardIsAnimating;
@property (nonatomic, assign) BOOL keyboardIsDraggingInKeyboardState;

@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) UIPopoverController *popover;

@property (nonatomic, strong) LIOEmailChatView *emailChatView;
@property (nonatomic, strong) LIOApprovePhotoView *approvePhotoView;

@property (nonatomic, strong) LIOToasterView *toasterView;

@property (nonatomic, strong) NSURL *urlBeingLaunched;

// A fix to make sure the intro animation appears even if "becomeFirstResponder" does not trigger 
@property (nonatomic, assign) BOOL keyboardShouldAppear;
@property (nonatomic, strong) NSTimer *keyboardShouldAppearTimer;

@end

@implementation LIOChatViewController

#pragma mark -
#pragma mark Init methods

- (void)setEngagement:(LIOEngagement *)engagement
{
    _engagement = engagement;
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark UITableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.engagement.messages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LIOChatMessage *chatMessage = [self.engagement.messages objectAtIndex:indexPath.row];

    CGSize expectedMessageSize;
    if (chatMessage.kind == LIOChatMessageKindLocalImage)
        expectedMessageSize = [LIOChatTableViewImageCell expectedSizeForChatMessage:chatMessage constrainedToSize:self.tableView.bounds.size];
    else
        expectedMessageSize = [LIOChatTableViewCell expectedSizeForChatMessage:chatMessage constrainedToSize:self.tableView.bounds.size];
    
    return expectedMessageSize.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LIOChatMessage *chatMessage = [self.engagement.messages objectAtIndex:indexPath.row];
    if (chatMessage.kind == LIOChatMessageKindLocalImage)
    {
        LIOChatTableViewImageCell *cell = [self.tableView dequeueReusableCellWithIdentifier:LIOChatViewControllerChatTableViewImageCellIdentifier];
        if (cell == nil)
        {
            cell = [[LIOChatTableViewImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LIOChatViewControllerChatTableViewImageCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.failedToSendButton addTarget:self action:@selector(resendFailedMessage:) forControlEvents:UIControlEventTouchUpInside];
            cell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        }
        
        CGRect frame = cell.frame;
        frame.size.width = tableView.bounds.size.width;
        cell.frame = frame;
        
        [cell layoutSubviewsForChatMessage:chatMessage];

        return cell;
    }
 
    LIOChatTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:LIOChatViewControllerChatTableViewCellIdentifier];
    if (cell == nil)
    {
        cell = [[LIOChatTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LIOChatViewControllerChatTableViewCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.failedToSendButton addTarget:self action:@selector(resendFailedMessage:) forControlEvents:UIControlEventTouchUpInside];
        cell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    
    CGRect frame = cell.frame;
    frame.size.width = tableView.bounds.size.width;
    cell.frame = frame;

    [cell layoutSubviewsForChatMessage:chatMessage];
    // Setup the chat view as delegate for clicking link buttons
    if (chatMessage.isShowingLinks)
        cell.delegate = self;
    else
        cell.delegate = nil;

    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // Reset the delayed scrolling animation if user scrolled
    self.lastScrollId = 0;
}

#pragma mark -
#pragma mark Action Methods

- (void)scrollToBottomDelayed:(BOOL)delayed
{
    self.lastScrollId += 1;
    if (self.lastScrollId > 1000)
        self.lastScrollId = 0;
    NSInteger scrollId = self.lastScrollId;
    
    if (delayed)
    {
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(){
            if (self.lastScrollId == scrollId)
            {
                NSIndexPath *lastRow = [NSIndexPath indexPathForRow:([self.engagement.messages count] - 1) inSection:0];
                [self.tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        });
    }
    else
    {
        NSIndexPath *lastRow = [NSIndexPath indexPathForRow:([self.engagement.messages count] - 1) inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}


- (void)dismissChat:(id)sender
{
    [self unregisterForKeyboardNotifications];

    if (self.emailChatView)
    {
        [self.emailChatView forceDismiss];
    }
    
    if (self.approvePhotoView)
    {
        self.keyboardState = LIOKeyboardStateIntroAnimation;
        [self.approvePhotoView removeFromSuperview];
        self.approvePhotoView = nil;
    }
    
    if (LIOChatStateWeb == self.chatState)
    {
        self.chatState = LIOChatStateChat;
    }
    
    [self.delegate chatViewControllerDidDismissChat:self];
 
    if ([self.inputBarView.textView isFirstResponder])
        [self.inputBarView.textView resignFirstResponder];
}

- (void)sendPhotoWithCamera:(BOOL)withCamera
{
    if (self.engagement.messages.count <= 1)
    {
        [self dismissExistingAlertView];
        self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachStartChatAlertTitle")
                                                            message:LIOLocalizedString(@"LIOAltChatViewController.AttachStartChatAlertBody")
                                                           delegate:nil
                                                  cancelButtonTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachStartChatAlertButton")
                                                  otherButtonTitles:nil];
        [self.alertView show];
    }
    else
    {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self presentImagePickerWithCamera:withCamera];
        else
            [self presentImagePickerWithCamera:NO];
    }
}

- (void)emailChat
{
    // Only allow if at least one message has been sent
    if (self.engagement.messages.count < 2)
    {
        [self dismissExistingAlertView];
        self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOAltChatViewController.NoChatHistoryAlertTitle") message:LIOLocalizedString(@"LIOAltChatViewController.NoChatHistoryAlertBody") delegate:nil cancelButtonTitle:LIOLocalizedString(@"LIOAltChatViewController.NoChatHistoryAlertButton") otherButtonTitles:nil];
        [self.alertView show];
        return;
    }
    
    self.emailChatView = [[LIOEmailChatView alloc] initWithFrame:self.view.bounds];
    CGRect frame = self.emailChatView.frame;
    frame.origin.y = -self.emailChatView.frame.size.height;
    self.emailChatView.frame = frame;
    self.emailChatView.delegate = self;
    self.emailChatView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.emailChatView];

    [self hideChatAndKeyboardWithCompletion:^{
        [self unregisterForKeyboardNotifications];
        
        self.chatState = LIOChatStateEmailChat;
        [self.emailChatView present];
    }];
}

- (void)hideChatAndKeyboardWithCompletion:(void (^)(void))completionBlock
{

    self.keyboardState = LIOKeyboardstateCompletelyHidden;
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
            [self.delegate chatViewControllerLandscapeWantsHeaderBarHidden:YES];
        
        [self updateSubviewFramesAndSaveTableViewFrames:YES saveOtherFrames:YES maintainTableViewOffset:YES];
    } completion:^(BOOL finished) {
        if (completionBlock != nil)
            completionBlock();
    }];
}


     
- (void)sendLineWithText:(NSString *)text
{
    [self.engagement sendVisitorLineWithText:text];
    [self.tableView reloadData];
    [self scrollToBottomDelayed:YES];
    
    // Accessibility - Play a sound if exists, and always read the text
    if (UIAccessibilityIsVoiceOverRunning())
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"LIOAccessibilitySoundMessageSent" ofType:@"aiff"];
        if (path)
        {
            LIOSoundEffect *soundEffect = [[LIOSoundEffect alloc] initWithSoundNamed:@"LIOAccessibilitySoundMessageSent.aiff"];
            soundEffect.completionBlock = ^{
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, text);
            };
            [soundEffect play];
        }
        else
        {
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, text);
        }
    }
}

- (void)resendFailedMessage:(id)sender
{
    UIButton *failedToSendButton = (UIButton *)sender;
    NSPredicate *clientLineIdPredicate = [NSPredicate predicateWithFormat:@"clientLineId = %@", failedToSendButton.tag];
    NSArray *messagesWithClientLineId = [self.engagement.messages filteredArrayUsingPredicate:clientLineIdPredicate];
    if (messagesWithClientLineId.count > 0)
    {
        LIOChatMessage *matchedClientLineIdMessage = [messagesWithClientLineId objectAtIndex:0];
        if (LIOChatMessageKindLocal == matchedClientLineIdMessage.kind)
            [self.engagement sendLineWithMessage:matchedClientLineIdMessage];
        if (LIOChatMessageKindLocalImage == matchedClientLineIdMessage.kind)
            [self.engagement sendMediaPacketWithMessage:matchedClientLineIdMessage];
    }
}

- (void)sendLineWithImage:(UIImage *)image
{
    NSString *attachmentId = [[LIOMediaManager sharedInstance] commitImageMedia:image];

    [self.engagement sendVisitorLineWithAttachmentId:attachmentId];
    [self.tableView reloadData];
    [self scrollToBottomDelayed:YES];
}

- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message
{
    [self.tableView reloadData];
    if (LIOKeyboardstateCompletelyHidden != self.keyboardState)
    {
        [self updateSubviewFrames];
        [self scrollToBottomDelayed:YES];
        
        // Accessibility - Read the message and play a sound if it exists
        if (UIAccessibilityIsVoiceOverRunning())
        {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"LIOAccessibilitySoundMessageReceived" ofType:@"aiff"];
            if (path)
            {
                LIOSoundEffect *soundEffect = [[LIOSoundEffect alloc] initWithSoundNamed:@"LIOAccessibilitySoundMessageReceived.aiff"];
                soundEffect.completionBlock = ^{
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:@"%@ %@", message.senderName, message.text]);
                };
                [soundEffect play];
            }
            else
            {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:@"%@ %@", message.senderName, message.text]);
            }
        }
    }
}

- (void)engagementChatMessageStatusDidChange:(LIOEngagement *)engagement
{
    [self.tableView reloadData];
}

- (void)presentEndChatAlertView
{
    [self dismissExistingAlertView];
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertTitle")
                                                      message:LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertBody")
                                                     delegate:self
                                            cancelButtonTitle:nil
                                            otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertButtonNo"), LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertButtonYes"), nil];
    self.alertView.tag = LIOChatViewControllerEndChatAlertViewTag;
    
    [self.alertView show];
}

#pragma mark -
#pragma mark Photo Sharing Methods

- (void)presentImagePickerWithCamera:(BOOL)withCamera
{
    self.chatState = LIOChatStateImagePicker;
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = withCamera ? UIImagePickerControllerSourceTypeCamera : (UIImagePickerControllerSourceTypePhotoLibrary | UIImagePickerControllerSourceTypeSavedPhotosAlbum);
    imagePickerController.allowsEditing = NO;
    imagePickerController.delegate = self;
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    if (padUI && !withCamera)
    {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
        [self.popover presentPopoverFromRect:self.inputBarView.plusButton.bounds inView:self.inputBarView.plusButton permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }
    else
    {
        [self presentModalViewController:imagePickerController animated:YES];
    }
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    if ((picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary || picker.sourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum) && padUI)
    {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
    else
    {
        [self dismissModalViewControllerAnimated:YES];
    }
    
    self.chatState = LIOChatStateChat;
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image)
    {
        CGSize resizedImageSize;
        CGFloat targetSize = LIOChatViewControllerMaximumAttachmentActualSize / [[UIScreen mainScreen] scale];
        if (image.size.height >= image.size.width)
        {
            resizedImageSize.height = targetSize;
            resizedImageSize.width = targetSize*(image.size.width/image.size.height);
        } else {
            resizedImageSize.width = targetSize;
            resizedImageSize.height = targetSize*(image.size.height/image.size.width);
        }
        self.chatState = LIOChatStateImageApprove;
        
        self.approvePhotoView = [[LIOApprovePhotoView alloc] initWithFrame:self.view.bounds];
        self.approvePhotoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.approvePhotoView.imageView.image = [[LIOMediaManager sharedInstance] scaleImage:image toSize:resizedImageSize];
        CGRect frame = self.approvePhotoView.frame;
        frame.origin.y = -self.approvePhotoView.frame.size.height;
        self.approvePhotoView.frame = frame;
        self.approvePhotoView.delegate = self;
        [self.view addSubview:self.approvePhotoView];
        [self.approvePhotoView setNeedsLayout];
        
        [self hideChatAndKeyboardWithCompletion:^{
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGRect frame = self.approvePhotoView.frame;
                frame.origin.y = 0;
                self.approvePhotoView.frame = frame;
            } completion:^(BOOL finished) {
                [self.approvePhotoView viewDidAppear];
            }];
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    if ((picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary || picker.sourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum) && padUI)
    {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
    else
    {
        [self dismissModalViewControllerAnimated:YES];
    }
    self.chatState = LIOChatStateChat;
}

#pragma mark -
#pragma mark ApprovePhotoView Delegate Methods

- (void)approvePhotoViewDidApprove:(LIOApprovePhotoView *)approvePhotoView
{
    if (approvePhotoView)
    {
        [self sendLineWithImage:approvePhotoView.imageView.image];
    }
    [self dismissApprovePhotoView];
}

- (void)approvePhotoViewDidCancel:(LIOApprovePhotoView *)approvePhotoView
{
    [self dismissApprovePhotoView];
}

- (void)dismissApprovePhotoView
{
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = self.approvePhotoView.frame;
        frame.origin.y = -self.approvePhotoView.frame.size.height;
        self.approvePhotoView.frame = frame;
    } completion:^(BOOL finished) {
        self.chatState = LIOChatStateChat;
        [self.approvePhotoView removeFromSuperview];
        self.approvePhotoView = nil;
        
        self.keyboardState = LIOKeyboardStateIntroAnimation;
        [self appearanceAnimationForKeyboardInitialPosition];
    }];
}

#pragma mark -
#pragma mark EmailChatView Delegate Methods

- (void)emailChatView:(LIOEmailChatView *)emailChatView didSubmitEmail:(NSString *)email
{
    [self.engagement sendChatHistoryPacketWithEmail:email retries:0];
}

- (void)emailChatViewDidCancel:(LIOEmailChatView *)emailChatView
{
    [self.emailChatView dismiss];
}

- (void)emailChatViewDidFinishDismissAnimation:(LIOEmailChatView *)emailChatView
{
    self.chatState = LIOChatStateChat;
    
    [self registerForKeyboardNotifications];
    self.keyboardState = LIOKeyboardStateIntroAnimation;
    [self appearanceAnimationForKeyboardInitialPosition];
}

- (void)emailChatViewDidForceDismiss:(LIOEmailChatView *)emailChatView
{
    self.keyboardState = LIOKeyboardStateIntroAnimation;
    [self.emailChatView removeFromSuperview];
}

#pragma mark -
#pragma mark AlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case LIOChatViewControllerEndChatAlertViewTag:
            if (buttonIndex == 1)
            {
                [self.delegate chatViewControllerDidEndChat:self];

                [self.inputBarView clearTextView];
                
                if ([self.inputBarView.textView isFirstResponder])
                    [self.inputBarView.textView resignFirstResponder];

            }
            break;
            
        case LIOChatViewControllerOpenExtraAppLinkAlertViewTag:
            if (buttonIndex == 1)
            {
                [[UIApplication sharedApplication] openURL:self.urlBeingLaunched];
                self.urlBeingLaunched = nil;
            }
            break;
            
        case LIOChatViewControllerOpenWebLinkAlertViewTag:
            if (buttonIndex == 1)
            {
                [self openWebLinkURL:self.urlBeingLaunched];
                self.urlBeingLaunched = nil;
            }
            break;
            
            
        default:
            break;
    }
}

- (void)dismissExistingAlertView
{
    if (self.alertView)
    {
        [self.alertView dismissWithClickedButtonIndex:-1 animated:NO];
        self.alertView = nil;
    }
    
    if (self.popover)
    {
        [self.popover dismissPopoverAnimated:NO];
        self.popover = nil;
    }        
    
    if (self.chatState == LIOChatStateEmailChat && self.emailChatView)
        [self.emailChatView dismissExistingAlertView];
    
    if (self.chatState == LIOChatStateImagePicker)
        [self dismissModalViewControllerAnimated:YES];
    
    if (self.chatState == LIOChatStateImageApprove)
        [self dismissApprovePhotoView];
}

#pragma mark -
#pragma mark InputBarViewDelegate Methods

- (void)inputBarViewSendButtonWasTapped:(LPInputBarView *)inputBarView
{
    switch (self.keyboardState) {
        case LIOKeyboardStateHidden:
            if (self.inputBarView.textView.text.length > 0)
            {
                [self inputBarDidStopTyping:self.inputBarView];
                [self sendLineWithText:self.inputBarView.textView.text];
                [self.inputBarView clearTextView];
            
                [self updateSubviewFrames];
            }

            break;
            
        case LIOKeyboardStateMenu:
            [self dismissKeyboardMenu];
            break;
            
        case LIOKeyboardStateKeyboard:
            if (self.inputBarView.textView.text.length == 0)
            {
                [self.inputBarView.textView resignFirstResponder];
            }
            else
            {
                [self inputBarDidStopTyping:self.inputBarView];
                [self sendLineWithText:self.inputBarView.textView.text];
                [self.inputBarView clearTextView];
                
                [self updateSubviewFrames];
                
                [self.inputBarView.textView resignFirstResponder];
            }
            
            break;
            
        default:
            break;
    }
}

- (void)inputBarViewPlusButtonWasTapped:(LPInputBarView *)inputBarView {
    if (self.keyboardIsAnimating)
        return;
    
    if (LIOKeyboardStateMenu == self.keyboardState) {
        self.keyboardState = LIOKeyboardStateKeyboard;
        [self.inputBarView.textView becomeFirstResponder];
    } else {
        [self presentKeyboardMenu];
    }
}

- (void)inputBarViewKeyboardSendButtonWasTapped:(LPInputBarView *)inputBarView
{
    
}

- (void)inputBarTextFieldDidBeginEditing:(LPInputBarView *)inputBarView
{
    
}

- (void)inputBarTextFieldDidEndEditing:(LPInputBarView *)inputBarView
{
    
}

- (void)inputBarDidStartTyping:(LPInputBarView *)inputBarView
{
    NSDictionary *typingStart = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"typing_start", @"action",
                                 nil];
    [self.engagement sendAdvisoryPacketWithDict:typingStart retries:0];
}

- (void)inputBarDidStopTyping:(LPInputBarView *)inputBarView
{
    NSDictionary *typingStart = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"typing_stop", @"action",
                                 nil];
    [self.engagement sendAdvisoryPacketWithDict:typingStart retries:0];
}

- (void)inputBar:(LPInputBarView *)inputBar wantsNewHeight:(CGFloat)height
{
    self.inputBarViewDesiredHeight = height;

    if (self.keyboardIsAnimating)
    {
        if (LIOKeyboardstateCompletelyHidden != self.keyboardState)
            [self updateSubviewFrames];
        return;
    }

    
    [UIView animateWithDuration:0.3 animations:^{
        if (LIOKeyboardstateCompletelyHidden != self.keyboardState)
            [self updateSubviewFrames];
    }];
}

- (void)inputBarStartedTyping:(LPInputBarView *)inputBar
{
    
}

- (void)inputBarEndedTyping:(LPInputBarView *)inputBar
{
    
}

#pragma mark -
#pragma mark Keyboard Menu Methods

- (void)setDefaultKeyboardHeightsForOrientation:(UIInterfaceOrientation)orientation
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    if (padUI) {
        self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(orientation) ? 264.0 : 352.0;
    } else {
        self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(orientation) ? 216.0 : 162.0;
    }
}

- (void)introAnimationForKeyboardHidden
{
    BOOL introAnimation = NO;
    if (LIOKeyboardStateIntroAnimation == self.keyboardState)
        introAnimation = YES;
    self.keyboardState = LIOKeyboardStateHidden;

    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self updateSubviewFrames];
        
        if (introAnimation)
        {
            CGRect frame = self.tableView.frame;
            frame.origin.y = 0;
            self.tableView.frame = frame;
        }
    } completion:nil];
}

- (void)presentKeyboardMenu
{
    BOOL introAnimation = NO;
    if (LIOKeyboardStateIntroAnimation == self.keyboardState)
        introAnimation = YES;
    self.keyboardState = LIOKeyboardStateMenu;

    // If keyboard is visible, resigning the textview as first responder will update the view
    if (self.inputBarView.textView.isFirstResponder)
    {
        [self.inputBarView.textView resignFirstResponder];
    }
    // If keyboard is not visible, display the keyboard menu
    else
    {
        if (self.lastKeyboardHeight == 0.0)
        {
            UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
            
            [self setDefaultKeyboardHeightsForOrientation:actualOrientation];
        }
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
                [self.delegate chatViewControllerLandscapeWantsHeaderBarHidden:YES];

            [self updateSubviewFrames];
            if (introAnimation)
            {
                CGRect frame = self.tableView.frame;
                frame.origin.y = 0;
                self.tableView.frame = frame;
            }
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)dismissKeyboardMenu
{
    self.keyboardState = LIOKeyboardStateHidden;
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
            [self.delegate chatViewControllerLandscapeWantsHeaderBarHidden:NO];

        [self updateSubviewFrames];
    } completion:nil];
}

- (BOOL)keyboardMenuShouldShowHideEmailChatDefaultItem:(LIOKeyboardMenu *)keyboardMenu
{
    return [self.engagement shouldShowEmailChatButtonItem];
}

- (BOOL)keyboardMenuShouldShowTakePhotoDefaultItem:(LIOKeyboardMenu *)keyboardMenu
{
    return [self.engagement shouldShowSendPhotoButtonItem];
}

- (void)keyboardMenu:(LIOKeyboardMenu *)keyboardMenu itemWasTapped:(LIOKeyboardMenuItem *)item
{
    switch (item.type) {
        case LIOKeyboardMenuItemEndChat:
            [self presentEndChatAlertView];
            break;
            
        case LIOKeyboardMenuItemShowKeyboard:
            [self.inputBarView.textView becomeFirstResponder];
            break;
            
        case LIOKeyboardMenuItemHideChat:
            [self dismissChat:self];
            break;
            
        case LIOKeyboardMenuItemTakePhoto:
            [self sendPhotoWithCamera:YES];
            break;
            
        case LIOKeyboardMenuItemUploadPhoto:
            [self sendPhotoWithCamera:NO];
            break;

            
        case LIOKeyboardMenuItemEmailChat:
            [self emailChat];
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark View Lifecycle Methods

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
    
    // If only one message appears, read it
    if (UIAccessibilityIsVoiceOverRunning())
    {
        if (self.engagement.messages.count == 1)
        {
            LIOChatMessage *firstMessage = [self.engagement.messages objectAtIndex:0];
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, firstMessage.text);
        }
    }
}

- (void)appearanceAnimationForKeyboardInitialPosition
{
    LIOKeyboardInitialPosition initialPosition = [[LIOBrandingManager brandingManager] keyboardInitialPositionForElement:LIOBrandingElementKeyboard];
    
    if (self.chatState != LIOChatStateImagePicker && self.chatState != LIOChatStateImageApprove)
    {
        switch (initialPosition) {
            case LIOKeyboardInitialPositionUp:
                self.keyboardShouldAppear = YES;
                self.keyboardShouldAppearTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(keyboardShouldAppearTimerDidTrigger:) userInfo:nil repeats:NO];
                [self.inputBarView.textView becomeFirstResponder];
                break;
                
            case LIOKeyboardInitialPositionMenu:
                [self presentKeyboardMenu];
                break;
                
            case LIOKeyboardInitialPositionDown:
                [self introAnimationForKeyboardHidden];
                break;
                
            default:
                break;
        }
    }
}

- (void)keyboardShouldAppearTimerDidTrigger:(id)sender
{
    [self.keyboardShouldAppearTimer invalidate];
    self.keyboardShouldAppearTimer = nil;
    
    if (self.keyboardShouldAppear) {
        [self setDefaultKeyboardHeightsForOrientation:self.interfaceOrientation];

        self.keyboardShouldAppear = NO;
        self.keyboardIsAnimating = YES;
        
        BOOL introAnimation = NO;
        if (LIOKeyboardStateIntroAnimation == self.keyboardState)
            introAnimation = YES;
        
        self.keyboardState = LIOKeyboardStateKeyboard;
        BOOL dontScrollToBottom = NO;
        if (self.keyboardIsDraggingInKeyboardState)
        {
            self.keyboardIsDraggingInKeyboardState = NO;
            dontScrollToBottom = YES;
        }
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
                [self.delegate chatViewControllerLandscapeWantsHeaderBarHidden:YES];
            
            [self updateSubviewFramesAndSaveTableViewFrames:YES saveOtherFrames:YES maintainTableViewOffset:NO];
            if (introAnimation)
            {
                CGRect frame = self.tableView.frame;
                frame.origin.y = 0;
                self.tableView.frame = frame;
            }
        } completion:^(BOOL finished) {
            if (self.chatState == LIOChatStateChat && dontScrollToBottom == NO)
                [self scrollToBottomDelayed:NO];
            
            if (introAnimation)
                self.keyboardState = LIOKeyboardStateKeyboard;
            
            if (self.emailChatView)
            {
                [self.emailChatView removeFromSuperview];
                [self.emailChatView cleanup];
                self.emailChatView = nil;
            }
            
            self.keyboardIsAnimating = NO;
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateNumberOfMessagesToShowInScrollBackForOrientation:self.interfaceOrientation];
    
    [self scrollToBottomDelayed:NO];
    
    [self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.chatState != LIOChatStateImagePicker && self.chatState != LIOChatStateWeb)
    {
        // Hide the chat so we can drop it when we return..
        self.keyboardState = LIOKeyboardStateIntroAnimation;
        [self updateSubviewFrames];
    }
    
    if (self.chatState == LIOChatStateEmailChat)
    {
        [self.emailChatView cleanup];
        [self.emailChatView removeFromSuperview];
        self.emailChatView = nil;
    }
    
    if (self.chatState == LIOChatStateImageApprove)
    {
        [self.approvePhotoView removeFromSuperview];
        self.approvePhotoView = nil;
    }
 
    [self unregisterForKeyboardNotifications];
}

- (void)updateNumberOfMessagesToShowInScrollBackForOrientation:(UIInterfaceOrientation)orientation
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    BOOL landscape = UIInterfaceOrientationIsLandscape(orientation);
    
    if (padUI)
        self.numberOfMessagesToShowInScrollBack = 3;
    else
    {
        
        if (LIO_IS_IPHONE_5) {
            if (landscape)
                self.numberOfMessagesToShowInScrollBack = 1;
            else
                self.numberOfMessagesToShowInScrollBack = 2;
        }
        else
        {
            self.numberOfMessagesToShowInScrollBack = 1;
        }
    }

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.keyboardShouldAppear = NO;

    self.chatState = LIOChatStateChat;
    
    [self updateNumberOfMessagesToShowInScrollBackForOrientation:self.interfaceOrientation];
    
    self.lastScrollId = 0;

    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    if (padUI)
        self.tableView.frame = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.origin.y, self.view.bounds.size.width/2, self.view.bounds.size.height);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (padUI)
        self.tableView.clipsToBounds = NO;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:self.tableView];

    self.keyboardState = LIOKeyboardStateIntroAnimation;
    CGRect frame = self.tableView.frame;
    frame.origin.y = -frame.size.height;
    self.tableView.frame = frame;
    
    CGFloat inputBarHeight = padUI ? 85 : 50;
    self.inputBarView = [[LPInputBarView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - inputBarHeight, self.view.bounds.size.width, inputBarHeight)];
    self.inputBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    self.inputBarView.alpha = 1.0;
    self.inputBarView.delegate = self;
    self.inputBarView.textView.inputAccessoryView = [[LIOObservingInputAccessoryView alloc] init];
    [self.view addSubview:self.inputBarView];    
    
    self.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.inputBarView.frame.size.height + 5.0)];
    self.tableFooterView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.tableFooterView.isAccessibilityElement = YES; 
    self.tableFooterView.accessibilityLabel = LIOLocalizedString(@"LIODismissalBarView.DismissalLabel");
    self.tableView.tableFooterView = self.tableFooterView;
    
    self.keyboardMenu = [[LIOKeyboardMenu alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 0)];
    self.keyboardMenu.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    self.keyboardMenu.delegate = self;
    [self.keyboardMenu setDefaultButtonItems];
    [self.view addSubview:self.keyboardMenu];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissChat:)];
    tapGestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:tapGestureRecognizer];

    if (padUI)
    {
        UIView *iPadTappableBackView = [[UIView alloc] initWithFrame:self.view.bounds];
        iPadTappableBackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:iPadTappableBackView];
        [self.view sendSubviewToBack:iPadTappableBackView];

        UITapGestureRecognizer *iPadBackTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissChat:)];
        tapGestureRecognizer.delegate = self;
        [iPadTappableBackView addGestureRecognizer:iPadBackTapGestureRecognizer];
    }
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewDidPan:)];
    panGestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:panGestureRecognizer];
        
    if (padUI)
    {
        self.toasterView = [[LIOToasterView alloc] init];
        self.toasterView.delegate = self;
        self.toasterView.yOrigin = self.inputBarView.frame.origin.y - 80.0;
        CGRect aFrame = self.toasterView.frame;
        aFrame.origin.x = -500.0;
        aFrame.origin.y = self.toasterView.yOrigin;
        self.toasterView.frame = aFrame;
        [self.view addSubview:self.toasterView];
    }
}

#pragma mark -
#pragma mark Subview Update Methods

- (void)updateSubviewFrames
{
    [self updateSubviewFramesAndSaveTableViewFrames:YES saveOtherFrames:YES maintainTableViewOffset:NO];
}

- (void)updateSubviewFramesAndSaveTableViewFrames:(BOOL)saveTableViewFrames saveOtherFrames:(BOOL)saveOtherFrames maintainTableViewOffset:(BOOL)maintainTableViewOffset
{
    // Fix for case where views are updated before view has loaded
    if (self.tableView.bounds.size.width == 0) return;
    
    CGFloat tableViewContentOffsetY = self.tableView.contentOffset.y;
    CGRect tableViewFrame = self.tableView.frame;
    CGRect inputBarViewFrame = self.inputBarView.frame;
    CGRect tableFooterViewFrame = self.tableFooterView.frame;
    CGRect keyboardMenuFrame = self.keyboardMenu.frame;
    CGRect emailChatViewFrame = self.emailChatView.frame;

    inputBarViewFrame.size.height = self.inputBarViewDesiredHeight;
    emailChatViewFrame.origin.y = -emailChatViewFrame.size.height;
    
    if (self.keyboardState != LIOKeyboardStateMenuDragging)
        keyboardMenuFrame.size.height = self.lastKeyboardHeight;

    switch (self.keyboardState) {
        case LIOKeyboardStateKeyboard:
            inputBarViewFrame.origin.y = self.view.bounds.size.height - inputBarViewFrame.size.height - self.lastKeyboardHeight;
            if (saveOtherFrames)
                [self.inputBarView unrotatePlusButton];
            break;
            
        case LIOKeyboardStateHidden:
            inputBarViewFrame.origin.y = self.view.bounds.size.height - inputBarViewFrame.size.height;
            if (saveOtherFrames)
                [self.inputBarView unrotatePlusButton];
            break;
            
        case LIOKeyboardStateMenu:
            inputBarViewFrame.origin.y = self.view.bounds.size.height - inputBarViewFrame.size.height - keyboardMenuFrame.size.height;
            if (saveOtherFrames)
                [self.inputBarView rotatePlusButton];
            break;
            
        case LIOKeyboardStateMenuDragging:
            inputBarViewFrame.origin.y = self.view.bounds.size.height - self.lastKeyboardHeight;
            break;
            
        case LIOKeyboardStateIntroAnimation:
            inputBarViewFrame.origin.y = self.view.bounds.size.height - inputBarViewFrame.size.height;
            tableViewFrame.origin.y = - (inputBarViewFrame.origin.y + inputBarViewFrame.size.height);
            break;
            
        case LIOKeyboardstateCompletelyHidden:
            tableViewFrame.origin.y = - self.view.bounds.size.height*1.3;
            inputBarViewFrame.origin.y = self.view.bounds.size.height;
            if (saveOtherFrames)
                [self.inputBarView unrotatePlusButton];
            break;
            
        default:
            break;
    }

    keyboardMenuFrame.origin.y = inputBarViewFrame.origin.y + inputBarViewFrame.size.height;
    if (LIOKeyboardstateCompletelyHidden != self.keyboardState)
        tableViewFrame.size.height = inputBarViewFrame.origin.y + inputBarViewFrame.size.height;
    tableFooterViewFrame.size.height = tableViewFrame.size.height - [self heightForPreviousMessagesToShow];
    if (tableFooterViewFrame.size.height < 0)
        tableFooterViewFrame.size.height = inputBarViewFrame.size.height;
    
    self.emailChatView.frame = emailChatViewFrame;

    if (saveOtherFrames)
    {
        self.inputBarView.frame = inputBarViewFrame;
        self.keyboardMenu.frame = keyboardMenuFrame;
    }
    
    if (saveTableViewFrames)
    {
        self.tableView.frame = tableViewFrame;
        self.tableFooterView.frame = tableFooterViewFrame;
        self.tableView.tableFooterView = self.tableFooterView;
    }
    
    if (maintainTableViewOffset)
    {
        self.tableView.contentOffset = CGPointMake(0, tableViewContentOffsetY);
    }

    CGRect frame = self.toasterView.frame;
    frame.origin.y = self.inputBarView.frame.origin.y - 80.0;
    self.toasterView.yOrigin = frame.origin.y;
    self.toasterView.frame = frame;
}

- (CGFloat)heightForPreviousMessagesToShow
{
    CGFloat heightAccum = 0.0;
    
    for (int i=0; i<self.numberOfMessagesToShowInScrollBack; i++)
    {
        NSInteger aRow = [self.engagement.messages count] - i - 1;
        if (aRow > -1) {
            heightAccum +=  [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:aRow inSection:0]];
        }
    }
    return heightAccum;
}

#pragma mark -
#pragma mark Keyboard Methods


- (void)registerForKeyboardNotifications
{
    // Register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidChangeFrame:)
                                                     name:LIOObservingInputAccessoryViewSuperviewFrameDidChangeNotification
                                                   object:nil];
    }
}

- (void)unregisterForKeyboardNotifications
{
    // Unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:LIOObservingInputAccessoryViewSuperviewFrameDidChangeNotification
                                                      object:nil];
    }
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    if (LIOChatStateEmailChat == self.chatState)
        return;
    
    [self keyboardWillShow:notification];
}


- (void)keyboardWillShow:(NSNotification *)notification
{
    self.keyboardShouldAppear = NO;
    self.keyboardIsAnimating = YES;
    
    // Acquire keyboard info
    NSDictionary *info = [notification userInfo];
    
    UIViewAnimationCurve curve;
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&curve];
    
    NSTimeInterval duration;
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    
    CGRect keyboardRect;
    [[info objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];

    BOOL introAnimation = NO;
    if (LIOKeyboardStateIntroAnimation == self.keyboardState)
        introAnimation = YES;
    
    self.keyboardState = LIOKeyboardStateKeyboard;
    BOOL dontScrollToBottom = NO;
    if (self.keyboardIsDraggingInKeyboardState)
    {
        self.keyboardIsDraggingInKeyboardState = NO;
        dontScrollToBottom = YES;
    }
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(actualOrientation) ? keyboardRect.size.height : keyboardRect.size.width;
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
            [self.delegate chatViewControllerLandscapeWantsHeaderBarHidden:YES];
        
        [self updateSubviewFramesAndSaveTableViewFrames:YES saveOtherFrames:YES maintainTableViewOffset:NO];
        if (introAnimation)
        {
            CGRect frame = self.tableView.frame;
            frame.origin.y = 0;
            self.tableView.frame = frame;
        }
    } completion:^(BOOL finished) {
        if (self.chatState == LIOChatStateChat && dontScrollToBottom == NO)
            [self scrollToBottomDelayed:NO];
        
        if (introAnimation)
            self.keyboardState = LIOKeyboardStateKeyboard;
        
        if (self.emailChatView)
        {
            [self.emailChatView removeFromSuperview];
            [self.emailChatView cleanup];
            self.emailChatView = nil;
        }

        self.keyboardIsAnimating = NO;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.keyboardIsAnimating = YES;
    
    // Acquire keyboard info
    NSDictionary *info = [notification userInfo];
    
    UIViewAnimationCurve curve;
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&curve];
    
    NSTimeInterval duration;
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    
    CGRect keyboardRect;
    [[info objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];
    
    // Set new keyboard state and size
    if (LIOKeyboardStateKeyboard == self.keyboardState)
        self.keyboardState = LIOKeyboardStateHidden;
    
    self.keyboardIsDraggingInKeyboardState = NO;
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(actualOrientation) ? keyboardRect.size.height : keyboardRect.size.width;
    
    [self updateSubviewFramesAndSaveTableViewFrames:YES saveOtherFrames:NO maintainTableViewOffset:YES];
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        if ((LIOKeyboardStateHidden == self.keyboardState) && UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        {
            [self.delegate chatViewControllerLandscapeWantsHeaderBarHidden:NO];
            [self updateSubviewFramesAndSaveTableViewFrames:YES saveOtherFrames:YES maintainTableViewOffset:NO];
        }
        else
        {
            [self updateSubviewFramesAndSaveTableViewFrames:NO saveOtherFrames:YES maintainTableViewOffset:NO];
        }
    } completion:^(BOOL finished) {
        self.keyboardIsAnimating = NO;
    }];
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification
{
    if (self.keyboardState == LIOKeyboardStateKeyboard)
    {
        LIOObservingInputAccessoryView *accessoryView = (LIOObservingInputAccessoryView *)notification.object;
        CGRect frame = [self.view convertRect:accessoryView.frame fromView:accessoryView];
        self.lastKeyboardHeight = self.view.bounds.size.height - frame.origin.y;
    
        [self updateSubviewFrames];
        self.keyboardIsDraggingInKeyboardState = YES;
    }
}

- (BOOL)shouldHideHeaderBarForLandscape
{
    switch (self.keyboardState) {
        case LIOKeyboardStateHidden:
            return NO;
            break;
            
        case LIOKeyboardStateMenu:
            return YES;
            break;
            
        case LIOKeyboardStateKeyboard:
            return YES;
            break;
            
        default:
            break;
    }
    
    return YES;
}


#pragma mark -
#pragma mark Rotation Methods

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (LIOKeyboardStateMenu == self.keyboardState)
    {
        [self setDefaultKeyboardHeightsForOrientation:toInterfaceOrientation];
    }
    [self updateNumberOfMessagesToShowInScrollBackForOrientation:toInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (LIOKeyboardstateCompletelyHidden != self.keyboardState)
    {
        [self.tableView reloadData];
        [self updateSubviewFrames];
    }
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate method

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
        return YES;
    
    if ([touch.view isKindOfClass:[LPChatBubbleView class]] || [touch.view.superview isKindOfClass:[LPChatBubbleView class]] || [touch.view.superview.superview isKindOfClass:[LPChatBubbleView class]])
        return NO;
    
    if ([touch.view isKindOfClass:[LPChatImageView class]] || [touch.view.superview isKindOfClass:[LPChatImageView class]] || [touch.view.superview.superview isKindOfClass:[LPChatImageView class]])
        return NO;
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)tableViewDidPan:(id)sender
{
    // Only allow dragging for keyboard menu on iOS 7.0
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        if (!(self.keyboardState == LIOKeyboardStateMenu || self.keyboardState == LIOKeyboardStateMenuDragging))
            return;
    }
    
    UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer*)sender;
    CGPoint locationPoint = [panGestureRecognizer locationInView:self.view];
    
    BOOL shouldAnimateToEndState = NO;
    CGFloat delta = 0.0;
    switch ([panGestureRecognizer state]) {
        case UIGestureRecognizerStateBegan:
            break;
            
        case UIGestureRecognizerStateChanged:
            switch (self.keyboardState) {
                case LIOKeyboardStateKeyboard:
                    if (locationPoint.y > (self.view.bounds.size.height - self.keyboardMenu.frame.size.height))
                    {
                        [self.inputBarView.textView resignFirstResponder];
                        return;
                    }
                    break;
                    
                case LIOKeyboardStateMenu:
                    // Let's see if we've started to drag the actual menu
                    if (locationPoint.y > (self.view.bounds.size.height - self.keyboardMenu.frame.size.height))
                    {
                        if (!LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
                        {
                            [self dismissKeyboardMenu];
                            return;
                        }

                        self.keyboardState = LIOKeyboardStateMenuDragging;
                        self.keyboardMenuHeightBeforeDragging = self.lastKeyboardHeight;
                        self.keyboardMenuDragStartPoint = locationPoint.y;
                    }
                    
                    break;
                    
                case LIOKeyboardStateMenuDragging:
                    delta = self.keyboardMenuDragStartPoint - locationPoint.y;

                    if (delta > 0)
                    {
                        self.keyboardState = LIOKeyboardStateMenu;
                        self.lastKeyboardHeight = self.keyboardMenuHeightBeforeDragging;
                        [self updateSubviewFramesAndSaveTableViewFrames:YES saveOtherFrames:YES maintainTableViewOffset:YES];
                    }
                    else
                    {
                        if (self.lastKeyboardHeight >= self.inputBarView.frame.size.height)
                        {
                            self.keyboardState = LIOKeyboardStateMenuDragging;
                        
                            self.lastKeyboardHeight = self.keyboardMenuHeightBeforeDragging + delta + self.inputBarView.frame.size.height;
                            [self updateSubviewFramesAndSaveTableViewFrames:YES saveOtherFrames:YES maintainTableViewOffset:YES];
                        }
                        else
                        {
                            self.keyboardState = LIOKeyboardStateHidden;
                            shouldAnimateToEndState = YES;
                        }
                    }
                    
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        case UIGestureRecognizerStateCancelled:
            if (self.keyboardState == LIOKeyboardStateMenuDragging)
            {
                self.keyboardState = LIOKeyboardStateMenu;
                shouldAnimateToEndState = YES;
            }
            break;
            
        case UIGestureRecognizerStateEnded:
            if (self.keyboardState == LIOKeyboardStateMenuDragging)
            {
                self.keyboardState = LIOKeyboardStateHidden;
                shouldAnimateToEndState = YES;
            }
            break;
            
        default:
            break;
    }
    
    if (shouldAnimateToEndState)
    {
        UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [self setDefaultKeyboardHeightsForOrientation:actualOrientation];

        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self updateSubviewFrames];
        } completion:^(BOOL finished) {
        }];
    }
}


#pragma mark -
#pragma mark Header Bar Methods

- (void)headerBarViewPlusButtonWasTapped
{
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [self.view endEditing:YES];
}

#pragma mark -
#pragma mark ToasterView Delegate Methods

- (BOOL)toasterViewShouldDismissNotification:(LIOToasterView *)aView
{
    return self.engagement.isConnected;
}

- (void)toasterViewDidFinishHiding:(LIOToasterView *)aView
{
    if (self.engagement.isAgentTyping)
    {
        [self displayToasterAgentIsTyping:YES];
    }
}

- (void)toasterViewDidFinishShowing:(LIOToasterView *)aView
{
}

- (void)displayToasterNotification:(NSString *)notification
{
    self.toasterView.keyboardIconVisible = NO;
    self.toasterView.text = notification;
    [self.toasterView showAnimated:YES permanently:NO];

}

- (void)displayToasterAgentIsTyping:(BOOL)isTyping
{
    if (isTyping)
    {
        self.toasterView.keyboardIconVisible = YES;
        self.toasterView.text = LIOLocalizedString(@"LIOAltChatViewController.AgentTypingNotification");
        [self.toasterView showAnimated:YES permanently:YES];
    }
    else
    {
        [self.toasterView hideAnimated:YES];
    }
}

- (void)hideToasterView
{
    self.toasterView.delegate = nil;
    [self.toasterView hideAnimated:YES];
}

#pragma mark -
#pragma mark LIOChatTableViewCellDelegate Methods

- (void)chatTableViewCell:(LIOChatTableViewCell *)cell didTapLinkButtonWithIndex:(NSInteger)index
{
    NSIndexPath *messageIndex = [self.tableView indexPathForCell:cell];
    LIOChatMessage *chatMessage = [self.engagement.messages objectAtIndex:messageIndex.row];
    
    LPChatBubbleLink *link = [chatMessage.links objectAtIndex:index];
    if (NSTextCheckingTypeLink == link.checkingType)
    {
        if (link.isIntraAppLink)
        {
            // Intra-app links don't require a warning.
            [self.delegate chatViewControllerDidTapIntraAppLink:link.URL];
        }
        else {
            NSString *alertMessage = nil;
            NSString *alertCancel = LIOLocalizedString(@"LIOChatBubbleView.AlertCancel");
            NSString *alertOpen = LIOLocalizedString(@"LIOChatBubbleView.AlertGo");

            if ([[link.scheme lowercaseString] hasPrefix:@"http"])
            {
                [self openWebLinkURL:link.URL];
                return;
            }
            else if ([[link.scheme lowercaseString] hasPrefix:@"mailto"])
            {
                alertMessage = [NSString stringWithFormat:LIOLocalizedString(@"LIOChatBubbleView.LinkAlertEmail"), link.string];
            }
            else if ([[link.scheme lowercaseString] hasPrefix:@"tel"])
            {
                alertMessage = [NSString stringWithFormat:LIOLocalizedString(@"LIOChatBubbleView.LinkAlertPhone"), link.string];
                alertCancel = LIOLocalizedString(@"LIOChatBubbleView.AlertCancelPhone");
                alertOpen = LIOLocalizedString(@"LIOChatBubbleView.AlertGoPhone");
            }

            self.urlBeingLaunched = link.URL;
            
            [self dismissExistingAlertView];
            self.alertView = [[UIAlertView alloc] initWithTitle:nil
                                                   message:alertMessage
                                                  delegate:self
                                         cancelButtonTitle:nil
                                         otherButtonTitles:alertCancel, alertOpen, nil];
            self.alertView.tag = LIOChatViewControllerOpenExtraAppLinkAlertViewTag;
            [self.alertView show];
        }
    }
    else if (NSTextCheckingTypePhoneNumber == link.checkingType)
    {
        self.urlBeingLaunched = link.URL;
        
        NSString *alertMessage = [NSString stringWithFormat:LIOLocalizedString(@"LIOChatBubbleView.LinkAlertPhone"), link.string];
        [self dismissExistingAlertView];
        self.alertView = [[UIAlertView alloc] initWithTitle:nil
                                               message:alertMessage
                                              delegate:self
                                     cancelButtonTitle:nil
                                     otherButtonTitles:LIOLocalizedString(@"LIOChatBubbleView.AlertCancelPhone"), LIOLocalizedString(@"LIOChatBubbleView.AlertGoPhone"), nil];
        self.alertView.tag = LIOChatViewControllerOpenExtraAppLinkAlertViewTag;
        [self.alertView show];
    }
}

#pragma mark -
#pragma mark Link opening methods

- (void)didTapIntraAppLinkWithURL:(NSURL*)url
{
    [self.delegate chatViewControllerDidTapIntraAppLink:url];
}

- (void)openWebLinkURL:(NSURL*)url
{
    self.chatState = LIOChatStateWeb;
    [self.view endEditing:YES];
    [self.delegate chatViewControllerDidTapWebLink:url];
}

@end
