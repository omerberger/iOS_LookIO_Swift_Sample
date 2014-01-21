//
//  LIOChatViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOChatViewController.h"

#import "LIOChatTableViewCell.h"
#import "LIOChatTableViewImageCell.h"

#import "LPInputBarView.h"
#import "LIOKeyboardMenu.h"

#import "LPChatBubbleView.h"
#import "LPChatImageView.h"

#import "LIOToasterView.h"

#import "LIOEmailChatView.h"

#import "LIOBundleManager.h"
#import "LIOMediaManager.h"

#define LIOChatViewControllerChatTableViewCellIdentifier        @"LIOChatViewControllerChatTableViewCellIdentifier"
#define LIOChatViewControllerChatTableViewImageCellIdentifier   @"LIOChatViewControllerChatTableViewImageCellIdentifier"

#define LIOChatViewControllerMaximumAttachmentActualSize 800.0

#define LIOChatViewControllerEndChatAlertViewTag 1001

#define LIOChatViewControllerPhotoSourceActionSheetTag 2001

@interface LIOChatViewController () <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, LPInputBarViewDelegte, LIOKeyboardMenuDelegate, UIGestureRecognizerDelegate, LIOEmailChatViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, LIOToasterViewDelegate>

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

@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, strong) LIOEmailChatView *emailChatView;

@property (nonatomic, strong) UIImage *pendingImageAttachment;

@property (nonatomic, strong) LIOToasterView *toasterView;

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
        cell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    
    CGRect frame = cell.frame;
    frame.size.width = tableView.bounds.size.width;
    cell.frame = frame;

    [cell layoutSubviewsForChatMessage:chatMessage];

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
    if (self.emailChatView)
    {
        [self.emailChatView forceDismiss];
    }
    
    [self.delegate chatViewControllerDidDismissChat:self];
 
    if ([self.inputBarView.textView isFirstResponder])
        [self.inputBarView.textView resignFirstResponder];
}

- (void)sendPhoto
{
    if (self.engagement.messages.count <= 1)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachStartChatAlertTitle")
                                                            message:LIOLocalizedString(@"LIOAltChatViewController.AttachStartChatAlertBody")
                                                           delegate:nil
                                                  cancelButtonTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachStartChatAlertButton")
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self presentPhotoSourceActionSheet];
        else
            [self presentImagePickerWithCamera:NO];
    }
}

- (void)emailChat
{
    // Only allow if at least one message has been sent
    if (self.engagement.messages.count < 2)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOAltChatViewController.NoChatHistoryAlertTitle") message:LIOLocalizedString(@"LIOAltChatViewController.NoChatHistoryAlertBody") delegate:nil cancelButtonTitle:LIOLocalizedString(@"LIOAltChatViewController.NoChatHistoryAlertButton") otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    CGFloat emailChatHeight = self.view.bounds.size.height - self.keyboardMenu.bounds.size.height;
    self.emailChatView = [[LIOEmailChatView alloc] initWithFrame:CGRectMake(0, -emailChatHeight, self.view.bounds.size.width, emailChatHeight)];
    self.emailChatView.delegate = self;
    self.emailChatView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.emailChatView];
    
    self.keyboardState = LIOKeyboardStateEmailChatIntroAnimation;
    self.chatState = LIOChatStateEmailChat;
    [self.emailChatView present];
}

- (void)sendLineWithText:(NSString *)text
{
    [self.engagement sendVisitorLineWithText:text];
    [self.tableView reloadData];
    [self scrollToBottomDelayed:YES];
}

- (void)sendLineWithPendingImage
{
    NSString *attachmentId = [[LIOMediaManager sharedInstance] commitImageMedia:self.pendingImageAttachment];

    [self.engagement sendVisitorLineWithAttachmentId:attachmentId];
    [self.tableView reloadData];
    [self scrollToBottomDelayed:YES];
}

- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message
{
    [self.tableView reloadData];
    [self updateSubviewFrames];
    [self scrollToBottomDelayed:YES];
}

- (void)presentEndChatAlertView
{
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertTitle")
                                                      message:LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertBody")
                                                     delegate:self
                                            cancelButtonTitle:nil
                                            otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertButtonNo"), LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertButtonYes"), nil];
    self.alertView.tag = LIOChatViewControllerEndChatAlertViewTag;
    
    [self.alertView show];
}

#pragma mark -
#pragma mark UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case LIOChatViewControllerPhotoSourceActionSheetTag:
            if (buttonIndex == 0)
                [self presentImagePickerWithCamera:YES];
            if (buttonIndex == 1)
                [self presentImagePickerWithCamera:NO];
            break;
            
        default:
            break;
    }
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
    
    [self presentModalViewController:imagePickerController animated:YES];
}

- (void)presentPhotoSourceActionSheet
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                              delegate:self
                                     cancelButtonTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachSourceCancel")
                                destructiveButtonTitle:nil
                                     otherButtonTitles:LIOLocalizedString(@"LIOAltChatViewController.AttachSourceCamera"),
                                                       LIOLocalizedString(@"LIOAltChatViewController.AttachSourceLibrary"), nil];
    actionSheet.tag = LIOChatViewControllerPhotoSourceActionSheetTag;
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    
    [actionSheet showInView:self.view];
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissModalViewControllerAnimated:YES];
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
        self.pendingImageAttachment = [[LIOMediaManager sharedInstance] scaleImage:image toSize:resizedImageSize];
        
        [self sendLineWithPendingImage];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
    self.chatState = LIOChatStateChat;
}

#pragma mark -
#pragma mark EmailChatView Delegate Methods

- (void)emailChatView:(LIOEmailChatView *)emailChatView didSubmitEmail:(NSString *)email
{
    self.keyboardState = LIOKeyboardStateEmailChatOutroAnimation;
    self.chatState = LIOChatStateChat;
    [self.emailChatView dismiss];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.SuccessAlertTitle") message:LIOLocalizedString(@"LIOEmailHistoryViewController.SuccessAlertBody") delegate:nil cancelButtonTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.SuccessAlertButton") otherButtonTitles:nil];
    [alertView show];
    
    [self.engagement sendChatHistoryPacketWithEmail:email];
}

- (void)emailChatViewDidCancel:(LIOEmailChatView *)emailChatView
{
    self.keyboardState = LIOKeyboardStateEmailChatOutroAnimation;
    self.chatState = LIOChatStateChat;
    [self.emailChatView dismiss];
}

- (void)emailChatViewDidForceDismiss:(LIOEmailChatView *)emailChatView
{
    self.keyboardState = LIOKeyboardStateMenu;
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
            
        default:
            break;
    }
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
    [self.engagement sendAdvisoryPacketWithDict:typingStart];
}

- (void)inputBarDidStopTyping:(LPInputBarView *)inputBarView
{
    NSDictionary *typingStart = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"typing_stop", @"action",
                                 nil];
    [self.engagement sendAdvisoryPacketWithDict:typingStart];
}

- (void)inputBar:(LPInputBarView *)inputBar wantsNewHeight:(CGFloat)height
{
    self.inputBarViewDesiredHeight = height;
    [UIView animateWithDuration:0.2 animations:^{
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

- (void)presentKeyboardMenu
{
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
        
        [UIView animateWithDuration:0.3 animations:^{
            [self updateSubviewFrames];
        }];
    }
}

- (void)dismissKeyboardMenu
{
    self.keyboardState = LIOKeyboardStateHidden;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self updateSubviewFrames];
    }];
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
            
        case LIOKeyboardMenuItemSendPhoto:
            [self sendPhoto];
            break;
            
        case LIOKeyboardMenuItemEmailChat:
            [self emailChat];
            
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
    [self.inputBarView.textView becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self scrollToBottomDelayed:NO];
    
    // Register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.chatState != LIOChatStateImagePicker)
    {
        // Hide the chat so we can drop it when we return..
        self.keyboardState = LIOKeyboardStateIntroAnimation;
        [self updateSubviewFrames];
    }
    
    // Unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:LIOObservingInputAccessoryViewSuperviewFrameDidChangeNotification
                                                      object:nil];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.chatState = LIOChatStateChat;
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    if (padUI)
        self.numberOfMessagesToShowInScrollBack = 3;
    else
    {
        if (LIO_IS_IPHONE_5)
            self.numberOfMessagesToShowInScrollBack = 2;
        else
            self.numberOfMessagesToShowInScrollBack = 1;
    }
    self.lastScrollId = 0;

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
    self.inputBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.inputBarView.alpha = 1.0;
    self.inputBarView.delegate = self;
    self.inputBarView.textView.inputAccessoryView = [[LIOObservingInputAccessoryView alloc] init];
    [self.view addSubview:self.inputBarView];    
    
    self.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.inputBarView.frame.size.height + 5.0)];
    self.tableFooterView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.tableView.tableFooterView = self.tableFooterView;
    
    self.keyboardMenu = [[LIOKeyboardMenu alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 0)];
    self.keyboardMenu.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.keyboardMenu.delegate = self;
    [self.keyboardMenu setDefaultButtonItems];
    [self.view addSubview:self.keyboardMenu];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissChat:)];
    tapGestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:tapGestureRecognizer];
    
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
    CGFloat tableViewContentOffsetY = self.tableView.contentOffset.y;
    CGRect tableViewFrame = self.tableView.frame;
    CGRect inputBarViewFrame = self.inputBarView.frame;
    CGRect tableFooterViewFrame = self.tableFooterView.frame;
    CGRect keyboardMenuFrame = self.keyboardMenu.frame;
    CGRect emailChatViewFrame = self.emailChatView.frame;
    
    inputBarViewFrame.size.height = self.inputBarViewDesiredHeight;
    
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
            
        case LIOKeyboardStateEmailChatIntroAnimation:
            emailChatViewFrame.origin.y = 0;
            break;
            
        case LIOKeyboardStateEmailChatOutroAnimation:
            emailChatViewFrame.origin.y = -emailChatViewFrame.size.height;
            
        default:
            break;
    }

    keyboardMenuFrame.origin.y = inputBarViewFrame.origin.y + inputBarViewFrame.size.height;
    tableViewFrame.size.height = inputBarViewFrame.origin.y + inputBarViewFrame.size.height;
    tableFooterViewFrame.size.height = tableViewFrame.size.height - [self heightForPreviousMessagesToShow];

    if (saveOtherFrames)
    {
        self.inputBarView.frame = inputBarViewFrame;
        self.keyboardMenu.frame = keyboardMenuFrame;
        self.emailChatView.frame = emailChatViewFrame;
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

- (void)keyboardWillShow:(NSNotification *)notification
{
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
    
    // Set new keyboard state and size
    if (self.keyboardState != LIOKeyboardStateEmailChatIntroAnimation)
        self.keyboardState = LIOKeyboardStateKeyboard;
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(actualOrientation) ? keyboardRect.size.height : keyboardRect.size.width;
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        [self updateSubviewFramesAndSaveTableViewFrames:YES saveOtherFrames:YES maintainTableViewOffset:NO];
        if (introAnimation)
        {
            CGRect frame = self.tableView.frame;
            frame.origin.y = 0;
            self.tableView.frame = frame;
        }
    } completion:^(BOOL finished) {
        if (self.chatState == LIOChatStateChat)
            [self scrollToBottomDelayed:NO];
        if (introAnimation)
            self.keyboardState = LIOKeyboardStateKeyboard;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
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
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(actualOrientation) ? keyboardRect.size.height : keyboardRect.size.width;
    
    [self updateSubviewFramesAndSaveTableViewFrames:YES saveOtherFrames:NO maintainTableViewOffset:YES];
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        [self updateSubviewFramesAndSaveTableViewFrames:NO saveOtherFrames:YES maintainTableViewOffset:NO];
    } completion:^(BOOL finished) {
        if (LIOKeyboardStateEmailChatOutroAnimation == self.keyboardState)
        {
            self.keyboardState = LIOKeyboardStateMenu;
            [self.emailChatView removeFromSuperview];
        }
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
    }
}

#pragma mark -
#pragma mark Rotation Methods

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setDefaultKeyboardHeightsForOrientation:toInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
    [self updateSubviewFrames];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate method

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
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

        [UIView animateWithDuration:0.3 animations:^{
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

- (void)toasterViewDidFinishHiding:(LIOToasterView *)aView
{

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



@end
