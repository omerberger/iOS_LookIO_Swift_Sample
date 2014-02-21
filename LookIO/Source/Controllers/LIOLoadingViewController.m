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

@interface LIOLoadingViewController ()

@property (nonatomic, strong) UIView *bezelView;
@property (nonatomic, strong) UIImageView *loadingImageView;
@property (nonatomic, strong) UILabel *loadingLabel;
@property (nonatomic, strong) UILabel *loadingSubLabel;
@property (nonatomic, strong) UIButton *dismissButton;

@property (nonatomic, strong) LIOSoundEffect *soundEffect;

@end

@implementation LIOLoadingViewController

- (void)loadingViewDidDismiss:(id)sender
{
    [self.delegate loadingViewControllerDidDismiss:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.bezelView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 100, self.view.bounds.size.height/2 - 65, 200, 130)];
    UIColor *backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementLoadingScreen];
    CGFloat alpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementLoadingScreen];
    self.bezelView.backgroundColor = [backgroundColor colorWithAlphaComponent:alpha];
    self.bezelView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.bezelView.layer.cornerRadius = 6.0;
    [self.view addSubview:self.bezelView];
    
    self.loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20.0, self.bezelView.bounds.size.width, 50)];
    self.loadingImageView.image = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSpinningLoader"];
    self.loadingImageView.contentMode = UIViewContentModeCenter;
    self.loadingImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.bezelView addSubview:self.loadingImageView];
    
    self.loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80.0, self.bezelView.bounds.size.width, 20.0)];
    self.loadingLabel.backgroundColor = [UIColor clearColor];
    self.loadingLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.loadingLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementLoadingScreenTitle];
    self.loadingLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementLoadingScreenTitle];
    self.loadingLabel.textAlignment = UITextAlignmentCenter;
    self.loadingLabel.text = LIOLocalizedString(@"LIOAltChatViewController.LoadingLabel");
    [self.bezelView addSubview:self.loadingLabel];
    
    self.loadingSubLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100.0, self.bezelView.bounds.size.width, 18.0)];
    self.loadingSubLabel.backgroundColor = [UIColor clearColor];
    self.loadingSubLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.loadingSubLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementLoadingScreenSubtitle];
    self.loadingSubLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementLoadingScreenSubtitle];
    self.loadingSubLabel.textAlignment = UITextAlignmentCenter;
    self.loadingSubLabel.text = LIOLocalizedString(@"LIOAltChatViewController.LoadingSubLabel");
    [self.bezelView addSubview:self.loadingSubLabel];
    
    self.dismissButton = [[UIButton alloc] initWithFrame:self.view.bounds];
    self.dismissButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.dismissButton addTarget:self action:@selector(loadingViewDidDismiss:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.dismissButton];
}

#pragma mark -
#pragma mark Action Methods

- (void)showBezel
{
    self.bezelView.hidden = NO;
    
    BOOL spinImage = [[LIOBrandingManager brandingManager] booleanValueForField:@"spin_image" element:LIOBrandingElementLoadingScreen];
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
}

- (void)hideBezel
{
    self.bezelView.hidden = YES;
    
    [self.loadingImageView.layer removeAnimationForKey:@"animation"];
    if (self.soundEffect)
    {
        self.soundEffect.shouldRepeat = NO;
        [self.soundEffect stop];
    }
}

@end