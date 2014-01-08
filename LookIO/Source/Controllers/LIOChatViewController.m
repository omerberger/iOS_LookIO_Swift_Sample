//
//  LIOChatViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOChatViewController.h"

#import "LIOChatTableViewCell.h"
#import "LPInputBarView.h"
#import "LIOKeyboardMenu.h"
#import "LIOBundleManager.h"
#import "LPChatBubbleView.h"

#define LIOChatViewControllerChatTableViewCellIdentifier  @"LIOChatViewControllerChatTableViewCellIdentifier"

#define LIOChatViewControllerEndChatAlertViewTag 1001

@interface LIOChatViewController () <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, LPInputBarViewDelegte, LIOKeyboardMenuDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) LIOEngagement *engagement;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *tableFooterView;

@property (nonatomic, strong) LPInputBarView *inputBarView;
@property (nonatomic, assign) CGFloat inputBarViewDesiredHeight;

@property (nonatomic, strong) LIOKeyboardMenu *keyboardMenu;

@property (nonatomic, assign) LIOKeyboardState keyboardState;
@property (nonatomic, assign) CGFloat lastKeyboardHeight;

@property (nonatomic, strong) UIAlertView *alertView;

@end

@implementation LIOChatViewController

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
    CGSize expectedMessageSize = [LIOChatTableViewCell expectedSizeForChatMessage:chatMessage constrainedToSize:self.tableView.bounds.size];
    return expectedMessageSize.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LIOChatTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:LIOChatViewControllerChatTableViewCellIdentifier];
    if (cell == nil)
    {
        cell = [[LIOChatTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LIOChatViewControllerChatTableViewCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    LIOChatMessage *chatMessage = [self.engagement.messages objectAtIndex:indexPath.row];
    [cell layoutSubviewsForChatMessage:chatMessage];
    
    return cell;
}


#pragma mark Action Methods

- (void)dismissChat:(id)sender
{
    [self.delegate chatViewControllerDidDismissChat:self];
 
    if ([self.inputBarView.textView isFirstResponder])
        [self.inputBarView.textView resignFirstResponder];
    
    self.keyboardState = LIOKeyboardStateHidden;
    [self updateSubviewFrames];
}

- (void)sendPhoto
{
    
}

- (void)emailChat
{
    
}

- (void)sendLineWithText:(NSString *)text
{
    [self.engagement sendVisitorLineWithText:text];
    [self.tableView reloadData];
}

- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message
{
    [self.tableView reloadData];
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

#pragma mark AlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case LIOChatViewControllerEndChatAlertViewTag:
            if (buttonIndex == 1)
            {
                [self.delegate chatViewControllerDidEndChat:self];

                self.inputBarView.textView.text = @"";
                
                if ([self.inputBarView.textView isFirstResponder])
                    [self.inputBarView.textView resignFirstResponder];
                
                self.keyboardState = LIOKeyboardStateHidden;
                [self updateSubviewFrames];

            }
            break;
            
        default:
            break;
    }
}

#pragma mark InputBarViewDelegate Methods

- (void)inputBarViewSendButtonWasTapped:(LPInputBarView *)inputBarView
{
    switch (self.keyboardState) {
        case LIOKeyboardStateHidden:
            // Do nothing
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
                [self sendLineWithText:self.inputBarView.textView.text];
                
                self.inputBarView.textView.text = @"";
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

#pragma mark Keyboard Menu Methods

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
            BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
            UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
            
            if (padUI) {
                self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(actualOrientation) ? 264.0 : 352.0;
            } else {
                self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(actualOrientation) ? 216.0 : 162.0;
            }
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
    
    self.tableView.contentOffset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height);
    
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

    // Hide the chat so we can drop it when we return..
    self.keyboardState = LIOKeyboardStateIntroAnimation;
    CGRect frame = self.tableView.frame;
    frame.origin.y = -frame.size.height;
    self.tableView.frame = frame;
    
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

    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    if (padUI)
        self.tableView.frame = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.origin.y, self.view.bounds.size.width/2, self.view.bounds.size.height);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
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

    self.inputBarView = [[LPInputBarView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 50, self.view.bounds.size.width, 50)];
    self.inputBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.inputBarView.alpha = 1.0;
    self.inputBarView.delegate = self;
    self.inputBarView.textView.inputAccessoryView = [[LIOObservingInputAccessoryView alloc] init];
    [self.view addSubview:self.inputBarView];    
    
    self.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.inputBarView.frame.size.height + 5.0)];
    self.tableFooterView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.tableFooterView = self.tableFooterView;
    
    self.keyboardMenu = [[LIOKeyboardMenu alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 0)];
    self.keyboardMenu.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.keyboardMenu.delegate = self;
    [self.view addSubview:self.keyboardMenu];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissChat:)];
    tapGestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:tapGestureRecognizer];
}


#pragma mark Subview Update Methods

- (void)updateSubviewFrames
{
    CGRect tableViewFrame = self.tableView.frame;
    CGRect inputBarViewFrame = self.inputBarView.frame;
    CGRect tableFooterViewFrame = self.tableFooterView.frame;
    CGRect keyboardMenuFrame = self.keyboardMenu.frame;
    
    inputBarViewFrame.size.height = self.inputBarViewDesiredHeight;
    keyboardMenuFrame.size.height = self.lastKeyboardHeight;

    switch (self.keyboardState) {
        case LIOKeyboardStateKeyboard:
            inputBarViewFrame.origin.y = self.view.bounds.size.height - inputBarViewFrame.size.height - self.lastKeyboardHeight;
            [self.inputBarView unrotatePlusButton];
            break;
            
        case LIOKeyboardStateHidden:
            inputBarViewFrame.origin.y = self.view.bounds.size.height - inputBarViewFrame.size.height;
            [self.inputBarView unrotatePlusButton];
            break;
            
        case LIOKeyboardStateMenu:
            inputBarViewFrame.origin.y = self.view.bounds.size.height - inputBarViewFrame.size.height - keyboardMenuFrame.size.height;
            [self.inputBarView rotatePlusButton];
            break;
            
        default:
            break;
    }

    keyboardMenuFrame.origin.y = inputBarViewFrame.origin.y + inputBarViewFrame.size.height;
    tableFooterViewFrame.size.height = inputBarViewFrame.size.height + 5.0;
    tableViewFrame.size.height = inputBarViewFrame.origin.y + inputBarViewFrame.size.height;

    self.inputBarView.frame = inputBarViewFrame;
    self.tableView.frame = tableViewFrame;
    self.tableFooterView.frame = tableFooterViewFrame;
    self.tableView.tableFooterView = self.tableFooterView;
    self.keyboardMenu.frame = keyboardMenuFrame;
}

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
    self.keyboardState = LIOKeyboardStateKeyboard;
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(actualOrientation) ? keyboardRect.size.height : keyboardRect.size.width;
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
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
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        [self updateSubviewFrames];
    } completion:^(BOOL finished) {
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
    if (LIOKeyboardStateMenu == self.keyboardState)
    {
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
        if (padUI) {
            self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? 264.0 : 352.0;
        } else {
            self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? 216.0 : 162.0;
        }
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate method

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[LPChatBubbleView class]] || [touch.view.superview isKindOfClass:[LPChatBubbleView class]] || [touch.view.superview.superview isKindOfClass:[LPChatBubbleView class]])
        return NO;
    
    return YES;
}


@end
