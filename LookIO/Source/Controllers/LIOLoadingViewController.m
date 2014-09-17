//
//  LIOLoadingViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 1/3/14.
//
//

#import "LIOLoadingViewController.h"

// Managers
#import "LIOBrandingManager.h"
#import "LIOBundleManager.h"

// Models
#import "LIOSoundEffect.h"
#import "LIOTimerProxy.h"

@interface LIOLoadingViewController ()

@property (nonatomic, strong) UIView *bezelView;
@property (nonatomic, strong) UIImageView *loadingImageView;
@property (nonatomic, strong) UILabel *loadingLabel;
@property (nonatomic, strong) UILabel *loadingSubLabel;
@property (nonatomic, strong) UIButton *dismissButton;

@property (nonatomic, strong) LIOSoundEffect *soundEffect;

// Animated Ellipsis
@property (nonatomic, assign) BOOL isAnimatingEllipsis;
@property (nonatomic, strong) LIOTimerProxy *animatedEllipsisTimer;


@end

@implementation LIOLoadingViewController

- (void)loadingViewDidDismiss:(id)sender
{
    [self.delegate loadingViewControllerDidDismiss:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (self.animatedEllipsisTimer)
    {
        [self.animatedEllipsisTimer stopTimer];
        self.animatedEllipsisTimer = nil;
    }
    
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.isShowingQueueingMessage = NO;
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.bezelView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 100, self.view.bounds.size.height/2 - 65, 200, 130)];
    UIColor *backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementLoadingScreen];
    CGFloat alpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementLoadingScreen];
    self.bezelView.backgroundColor = [backgroundColor colorWithAlphaComponent:alpha];
    self.bezelView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.bezelView.layer.cornerRadius = 6.0;
    [self.view addSubview:self.bezelView];
    
    self.loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20.0, self.bezelView.bounds.size.width, 50)];
    [[LIOBundleManager sharedBundleManager] cachedImageForBrandingElement:LIOBrandingElementLoadingScreen withBlock:^(BOOL success, UIImage *image) {
        if (success)
            self.loadingImageView.image = image;
        else
            self.loadingImageView.image = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSpinningLoader"];
    }];
    self.loadingImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.bezelView addSubview:self.loadingImageView];
    
    self.loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80.0, self.bezelView.bounds.size.width, 20.0)];
    self.loadingLabel.backgroundColor = [UIColor clearColor];
    self.loadingLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementLoadingScreenTitle];
    self.loadingLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementLoadingScreenTitle];
    self.loadingLabel.textAlignment = UITextAlignmentCenter;
    self.loadingLabel.text = LIOLocalizedString(@"LIOAltChatViewController.LoadingLabel");
    [self.bezelView addSubview:self.loadingLabel];
    
    self.loadingSubLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100.0, self.bezelView.bounds.size.width, 18.0)];
    self.loadingSubLabel.backgroundColor = [UIColor clearColor];
    self.loadingSubLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementLoadingScreenSubtitle];
    self.loadingSubLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementLoadingScreenSubtitle];
    self.loadingSubLabel.textAlignment = UITextAlignmentCenter;
    self.loadingSubLabel.text = LIOLocalizedString(@"LIOAltChatViewController.LoadingSubLabel");
    [self.bezelView addSubview:self.loadingSubLabel];
    
    self.dismissButton = [[UIButton alloc] initWithFrame:self.view.bounds];
    self.dismissButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.dismissButton addTarget:self action:@selector(loadingViewDidDismiss:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.dismissButton];
    
    [self resetLoadingScreen];
}

- (void)resetLoadingScreen
{
    self.loadingLabel.text = LIOLocalizedString(@"LIOAltChatViewController.LoadingLabel");
    
    CGSize expectedSize = [self.loadingLabel.text sizeWithFont:self.loadingLabel.font constrainedToSize:CGSizeMake(self.bezelView.bounds.size.width - 30.0, 9999) lineBreakMode:UILineBreakModeWordWrap];
    self.loadingLabel.numberOfLines = 0;
    
    CGRect frame = self.loadingLabel.frame;
    frame.origin.x = (self.bezelView.bounds.size.width - expectedSize.width)/2;
    frame.origin.y = 80.0;
    frame.size = expectedSize;
    self.loadingLabel.frame = frame;
    [self.loadingLabel sizeThatFits:expectedSize];
    
    self.loadingSubLabel.text = LIOLocalizedString(@"LIOAltChatViewController.LoadingSubLabel");
    
    expectedSize = [self.loadingSubLabel.text sizeWithFont:self.loadingSubLabel.font constrainedToSize:CGSizeMake(self.bezelView.bounds.size.width - 30.0, 9999) lineBreakMode:UILineBreakModeWordWrap];
    self.loadingSubLabel.numberOfLines = 0;
    
    frame = self.loadingSubLabel.frame;
    frame.origin.x = (self.bezelView.bounds.size.width - expectedSize.width)/2;
    frame.origin.y = self.loadingLabel.frame.origin.y + self.loadingLabel.frame.size.height + 5;
    frame.size = expectedSize;
    self.loadingSubLabel.frame = frame;
    [self.loadingSubLabel sizeThatFits:expectedSize];

    frame = self.bezelView.frame;
    frame.size.height = self.loadingSubLabel.frame.origin.y + self.loadingSubLabel.frame.size.height + 15;
    frame.origin.y = self.view.bounds.size.height/2 - frame.size.height/2;
    self.bezelView.frame = frame;
    
}

#pragma mark -
#pragma mark Action Methods

- (void)showBezel
{
    self.bezelView.hidden = NO;
    
    BOOL spinImage = [[LIOBrandingManager brandingManager] booleanValueForField:@"spin" element:LIOBrandingElementLoadingScreenImage];
    if (spinImage)
    {
        CABasicAnimation *loadingAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        loadingAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        loadingAnimation.toValue = [NSNumber numberWithFloat: 2*M_PI];
        loadingAnimation.duration = 1.0f;
        loadingAnimation.repeatCount = HUGE_VAL;
        [self.loadingImageView.layer addAnimation:loadingAnimation forKey:@"animation"];
    }
    
    // Accessibility - Play a sound if it exists
    if (UIAccessibilityIsVoiceOverRunning())
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"LIOAccessibilitySoundLoading" ofType:@"aiff"];
        if (path)
        {
            self.soundEffect = [[LIOSoundEffect alloc] initWithSoundNamed:@"LIOAccessibilitySoundLoading.aiff"];
            [self.soundEffect play];
            self.soundEffect.shouldRepeat = YES;
        }
    }
    
    if (UIAccessibilityIsVoiceOverRunning())
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.isShowingQueueingMessage)
            {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, self.loadingSubLabel.text);
            }
            else
            {
                NSString *loadingMessage = [NSString stringWithFormat:@"%@ %@", self.loadingLabel.text, self.loadingSubLabel.text];
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingMessage);
            }
        });
    }
}

- (void)updateEllipsisAnimationForMessage:(NSString *)message
{
    if (self.animatedEllipsisTimer)
    {
        [self.animatedEllipsisTimer stopTimer];
        self.animatedEllipsisTimer = nil;
    }
    self.isAnimatingEllipsis = [message hasSuffix:@"..."];
    if (self.isAnimatingEllipsis)
    {
        self.animatedEllipsisTimer = [[LIOTimerProxy alloc] initWithTimeInterval:0.5 target:self selector:@selector(animatedEllipsisTimerDidFire)];
    }
}

- (void)showBezelForQueueingMessage:(NSString *)queueingMessage
{
    self.isShowingQueueingMessage = YES;
    
    // If there is no existing queueing message, just show the regular loading message.
    // Once a message is received it will replace it
    if (queueingMessage)
    {
        // Hide the loading sublabel
        self.loadingLabel.alpha = 0.0;
        self.loadingSubLabel.alpha = 1.0;
    
        self.loadingSubLabel.text = queueingMessage;
        [self updateFramesForQueueingMessage];
    }
    
    [self showBezel];
}

- (void)updateQueueingMessage:(NSString *)queueingMessage
{
    [UIView animateWithDuration:0.5 animations:^{
        self.loadingSubLabel.alpha = 0.0;
        self.loadingLabel.alpha = 0.0;
    } completion:^(BOOL finished) {

        self.loadingSubLabel.text = queueingMessage;
        [self updateFramesForQueueingMessage];

        [UIView animateWithDuration:0.5 animations:^{
            self.loadingSubLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            if (UIAccessibilityIsVoiceOverRunning()) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, self.loadingSubLabel.text);
                });
            }
        }];
    }];
}

- (void)updateFramesForQueueingMessage
{
    CGSize expectedSize = [self.loadingSubLabel.text sizeWithFont:self.loadingSubLabel.font constrainedToSize:CGSizeMake(self.bezelView.bounds.size.width - 30.0, 9999) lineBreakMode:UILineBreakModeWordWrap];
    self.loadingSubLabel.numberOfLines = 0;
    
    CGRect frame = self.loadingSubLabel.frame;
    frame.origin.x = (self.bezelView.bounds.size.width - expectedSize.width)/2;
    frame.origin.y = 85.0;
    frame.size = expectedSize;
    self.loadingSubLabel.frame = frame;
    [self.loadingSubLabel sizeThatFits:expectedSize];
    
    frame = self.bezelView.frame;
    frame.size.height = self.loadingSubLabel.frame.origin.y + self.loadingSubLabel.frame.size.height + 20;
    frame.origin.y = self.view.bounds.size.height/2 - frame.size.height/2;
    self.bezelView.frame = frame;
    
    self.loadingSubLabel.textAlignment = UITextAlignmentCenter;
    
}


- (void)hideBezel
{
    self.bezelView.hidden = YES;
    self.isShowingQueueingMessage = NO;
    [self resetLoadingScreen];
    
    [self.loadingImageView.layer removeAnimationForKey:@"animation"];
    if (self.soundEffect)
    {
        self.soundEffect.shouldRepeat = NO;
        [self.soundEffect stop];
    }
    
    if (self.animatedEllipsisTimer)
    {
        [self.animatedEllipsisTimer stopTimer];
        self.animatedEllipsisTimer = nil;
    }
}

- (void)animatedEllipsisTimerDidFire
{
    UILabel *aLabel = self.loadingSubLabel;
    if ([aLabel.text hasSuffix:@"..."])
        aLabel.text = [aLabel.text stringByReplacingCharactersInRange:NSMakeRange([aLabel.text length] - 3, 3) withString:@"."];
    else if ([aLabel.text hasSuffix:@".."])
        aLabel.text = [aLabel.text stringByReplacingCharactersInRange:NSMakeRange([aLabel.text length] - 2, 2) withString:@"..."];
    else if ([aLabel.text hasSuffix:@"."])
        aLabel.text = [aLabel.text stringByReplacingCharactersInRange:NSMakeRange([aLabel.text length] - 1, 1) withString:@".."];
}

@end