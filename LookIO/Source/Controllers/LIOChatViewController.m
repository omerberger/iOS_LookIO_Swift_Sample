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

#define LIOChatViewControllerChatTableViewCellIdentifier  @"LIOChatViewControllerChatTableViewCellIdentifier"

@interface LIOChatViewController () <UITableViewDelegate, UITableViewDataSource, LPInputBarViewDelegte>

@property (nonatomic, strong) LIOEngagement *engagement;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *tableFooterView;

@property (nonatomic, strong) LPInputBarView *inputBarView;
@property (nonatomic, assign) CGFloat inputBarViewDesiredHeight;

@property (nonatomic, strong) LIOKeyboardMenu *keyboardMenu;

@property (nonatomic, assign) LIOKeyboardState keyboardState;
@property (nonatomic, assign) CGFloat lastKeyboardHeight;

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

#pragma mark InputBarViewDelegate Methods

- (void)inputBarViewSendButtonWasTapped:(LPInputBarView *)inputBarView
{
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
}

- (void)inputBarViewPlusButtonWasTapped:(LPInputBarView *)inputBarView
{
    
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

    // Register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.tableView];

    self.inputBarView = [[LPInputBarView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 50, self.view.bounds.size.width, 50)];
    self.inputBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.inputBarView.alpha = 1.0;
    self.inputBarView.delegate = self;
    [self.view addSubview:self.inputBarView];
    
    self.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.inputBarView.frame.size.height + 5.0)];
    self.tableFooterView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.tableFooterView = self.tableFooterView;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissChat:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}


#pragma mark Subview Update Methods

- (void)updateSubviewFrames
{
    CGRect tableViewFrame = self.tableView.frame;
    CGRect inputBarViewFrame = self.inputBarView.frame;
    CGRect tableFooterViewFrame = self.tableFooterView.frame;
    
    inputBarViewFrame.size.height = self.inputBarViewDesiredHeight;

    switch (self.keyboardState) {
        case LIOKeyboardStateKeyboard:
            inputBarViewFrame.origin.y = self.view.bounds.size.height - inputBarViewFrame.size.height - self.lastKeyboardHeight;
            break;
            
        case LIOKeyboardStateHidden:
            inputBarViewFrame.origin.y = self.view.bounds.size.height - inputBarViewFrame.size.height;
            break;
            
        case LIOKeyboardStateMenu:
            inputBarViewFrame.origin.y = self.view.bounds.size.height - self.keyboardMenu.bounds.size.height;
            
            break;
            
        default:
            break;
    }

    tableFooterViewFrame.size.height = inputBarViewFrame.size.height + 5.0;
    tableViewFrame.size.height = inputBarViewFrame.origin.y + inputBarViewFrame.size.height;

    self.inputBarView.frame = inputBarViewFrame;
    self.tableView.frame = tableViewFrame;
    self.tableFooterView.frame = tableFooterViewFrame;
    self.tableView.tableFooterView = self.tableFooterView;
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
    
    // Set new keyboard state and size
    self.keyboardState = LIOKeyboardStateKeyboard;
    self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? keyboardRect.size.height : keyboardRect.size.width;
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        [self updateSubviewFrames];
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
    self.keyboardState = LIOKeyboardStateHidden;
    self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? keyboardRect.size.height : keyboardRect.size.width;
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        [self updateSubviewFrames];
    } completion:^(BOOL finished) {
    }];
}

#pragma mark Rotation Methods

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}

@end
