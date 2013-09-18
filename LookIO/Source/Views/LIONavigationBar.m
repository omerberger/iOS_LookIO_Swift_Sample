//
//  LIONavigationBar.m
//  LookIO
//
//  Created by Joseph Toscano on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIONavigationBar.h"
#import "LIOBundleManager.h"
#import "LIOLookIOManager.h"
#import <QuartzCore/QuartzCore.h>

@implementation LIONavigationBar

@synthesize /*displayMode, */titleImage, titleString, leftButtonText, rightButtonText, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.clipsToBounds = NO;
        
        if (kLPChatThemeClassic == [[LIOLookIOManager sharedLookIOManager] selectedChatTheme]) {
            stretchableBackgroundPortrait = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIONavBarPortrait"];
            stretchableBackgroundPortrait = [[stretchableBackgroundPortrait stretchableImageWithLeftCapWidth:1 topCapHeight:0] retain];
        
            stretchableBackgroundLandscape = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIONavBarLandscape"];
            stretchableBackgroundLandscape = [[stretchableBackgroundLandscape stretchableImageWithLeftCapWidth:1 topCapHeight:0] retain];
        
            stretchableButtonPortrait = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIONavBarButtonPortrait"];
            stretchableButtonPortrait = [[stretchableButtonPortrait stretchableImageWithLeftCapWidth:10 topCapHeight:0] retain];
        
            stretchableButtonLandscape = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIONavBarButtonLandscape"];
            stretchableButtonLandscape = [[stretchableButtonLandscape stretchableImageWithLeftCapWidth:10 topCapHeight:0] retain];
        
            backgroundImageView = [[UIImageView alloc] initWithImage:stretchableBackgroundPortrait];
            [self addSubview:backgroundImageView];
        } else {
            self.backgroundColor = [UIColor whiteColor];
            
            UIView *bottomBorderView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 1.0, self.frame.size.width, 1.0)];
            bottomBorderView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
            bottomBorderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
            [self addSubview:bottomBorderView];
        }
        
        titleImageView = [[UIImageView alloc] init];
        titleImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:titleImageView];
        
        leftButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [leftButton addTarget:self action:@selector(leftButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        if (kLPChatThemeClassic == [[LIOLookIOManager sharedLookIOManager] selectedChatTheme]) {

            [leftButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            leftButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
            leftButton.titleLabel.shadowColor = [UIColor blackColor];
            leftButton.titleLabel.shadowOffset = CGSizeMake(0.0, -0.75);
        } else {
            leftButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
            [leftButton setTitleColor:[UIColor colorWithRed:0.0f green:0.49f blue:0.96f alpha:1.0f] forState:UIControlStateNormal];

        }
        [self addSubview:leftButton];
        
        rightButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [rightButton addTarget:self action:@selector(rightButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
        rightButton.titleLabel.shadowColor = [UIColor blackColor];
        rightButton.titleLabel.shadowOffset = CGSizeMake(0.0, -0.75);            
        [self addSubview:rightButton];
        
        titleLabel = [[UILabel alloc] init];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
        titleLabel.textColor = [UIColor grayColor];
        titleLabel.layer.shadowColor = [UIColor whiteColor].CGColor;
        titleLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        titleLabel.layer.shadowOpacity = 0.8;
        titleLabel.layer.shadowRadius = 0.5;
        titleLabel.adjustsFontSizeToFitWidth = YES;
        titleLabel.minimumFontSize = 9.0;
        titleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
        titleLabel.textAlignment = UITextAlignmentCenter;
        [self addSubview:titleLabel];
    }
    
    return self;
}

- (void)dealloc
{
    [backgroundImageView release];
    [leftButton release];
    [rightButton release];
    [leftButtonText release];
    [rightButtonText release];
    [titleString release];
    [titleImage release];
    [titleImageView release];
    [titleLabel release];
    [stretchableBackgroundPortrait release];
    [stretchableBackgroundLandscape release];
    [stretchableButtonPortrait release];
    [stretchableButtonLandscape release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (padUI || UIInterfaceOrientationIsPortrait(orientation))
    {
        CGRect selfFrame = self.frame;
        selfFrame.size.height = 44.0;
        if (LIOIsUIKitFlatMode()) {
            if (![[UIApplication sharedApplication] isStatusBarHidden] && !padUI) {
                selfFrame.size.height += 15;
            }
        }
        self.frame = selfFrame;
        
        backgroundImageView.image = stretchableBackgroundPortrait;
        CGRect backgroundFrame = backgroundImageView.frame;
        backgroundFrame.origin = CGPointZero;
        backgroundFrame.size.width = self.bounds.size.width;
        backgroundFrame.size.height = 46.0;
        if (LIOIsUIKitFlatMode()) {
            if (![[UIApplication sharedApplication] isStatusBarHidden] && !padUI) {
                backgroundFrame.size.height += 15.0;
            }
        }
        backgroundImageView.frame = backgroundFrame;
        
        [leftButton setBackgroundImage:stretchableButtonPortrait forState:UIControlStateNormal];
        leftButton.hidden = 0 == [leftButtonText length];
        //if (NO == leftButton.hidden)
        //{
            if ([leftButtonText length]) [leftButton setTitle:leftButtonText forState:UIControlStateNormal];
            else [leftButton setTitle:@"12345" forState:UIControlStateNormal];
            [leftButton sizeToFit];
            CGRect leftFrame = leftButton.frame;
            leftFrame.size.height = 29.0;
            //leftFrame.size.width += 5.0;
            leftFrame.origin.x = 7.0;
            leftFrame.origin.y = (self.bounds.size.height / 2.0) - (leftFrame.size.height / 2.0);
            if (LIOIsUIKitFlatMode()) {
                if (![[UIApplication sharedApplication] isStatusBarHidden]&& !padUI) {
                    leftFrame.origin.y += 10.0;
                }
            }
            leftButton.frame = leftFrame;
        //}
        
        [rightButton setBackgroundImage:stretchableButtonPortrait forState:UIControlStateNormal];
        rightButton.hidden = 0 == [rightButtonText length];
        //if (NO == rightButton.hidden)
        //{
            if ([rightButtonText length]) [rightButton setTitle:rightButtonText forState:UIControlStateNormal];
            else [rightButton setTitle:@"12345" forState:UIControlStateNormal];
            [rightButton sizeToFit];
            CGRect rightFrame = rightButton.frame;
            rightFrame.size.height = 29.0;
            //rightFrame.size.width += 5.0;
            rightFrame.origin.x = self.bounds.size.width - rightFrame.size.width - 7.0;
            rightFrame.origin.y = (self.bounds.size.height / 2.0) - (rightFrame.size.height / 2.0);
            if (LIOIsUIKitFlatMode()) {
                if (![[UIApplication sharedApplication] isStatusBarHidden] && !padUI) {
                    rightFrame.origin.y += 10.0;
                }
            }
            rightButton.frame = rightFrame;
        //}
    }
    else
    {
        CGRect selfFrame = self.frame;
        selfFrame.size.height = 32.0;
        if (LIOIsUIKitFlatMode()) {
            if (![[UIApplication sharedApplication] isStatusBarHidden] && !padUI) {
                selfFrame.size.height += 15.0;
            }
        }
        self.frame = selfFrame;
        
        backgroundImageView.image = stretchableBackgroundLandscape;
        CGRect backgroundFrame = backgroundImageView.frame;
        backgroundFrame.origin = CGPointZero;
        backgroundFrame.size.width = self.bounds.size.width;
        backgroundFrame.size.height = 34.0;
        if (LIOIsUIKitFlatMode()) {
            if (![[UIApplication sharedApplication] isStatusBarHidden] && !padUI) {
                backgroundFrame.size.height += 15.0;
            }
        }
        backgroundImageView.frame = backgroundFrame;
        
        [leftButton setBackgroundImage:stretchableButtonLandscape forState:UIControlStateNormal];
        leftButton.hidden = 0 == [leftButtonText length];
        //if (NO == leftButton.hidden)
        //{
            if ([leftButtonText length]) [leftButton setTitle:leftButtonText forState:UIControlStateNormal];
            else [leftButton setTitle:@"12345" forState:UIControlStateNormal];
            [leftButton sizeToFit];
            CGRect leftFrame = leftButton.frame;
            leftFrame.size.height = 24.0;
            //leftFrame.size.width += 10.0;
            leftFrame.origin.x = 7.0;
            leftFrame.origin.y = (self.bounds.size.height / 2.0) - (leftFrame.size.height / 2.0);
            if (LIOIsUIKitFlatMode()) {
                if (![[UIApplication sharedApplication] isStatusBarHidden] && !padUI) {
                    leftFrame.origin.y += 10.0;
                }
            }
            leftButton.frame = leftFrame;
        //}
        
        [rightButton setBackgroundImage:stretchableButtonLandscape forState:UIControlStateNormal];
        rightButton.hidden = 0 == [rightButtonText length];
        //if (NO == rightButton.hidden)
        //{
            if ([rightButtonText length]) [rightButton setTitle:rightButtonText forState:UIControlStateNormal];
            else [rightButton setTitle:@"12345" forState:UIControlStateNormal];
            [rightButton sizeToFit];
            CGRect rightFrame = rightButton.frame;
            rightFrame.size.height = 24.0;
            //rightFrame.size.width += 10.0;
            rightFrame.origin.x = self.bounds.size.width - rightFrame.size.width - 7.0;
            rightFrame.origin.y = (self.bounds.size.height / 2.0) - (rightFrame.size.height / 2.0);
            if (LIOIsUIKitFlatMode()) {
                if (![[UIApplication sharedApplication] isStatusBarHidden] && !padUI) {
                    rightFrame.origin.y += 10.0;
                }
            }
            rightButton.frame = rightFrame;
        //}
    }
    
    CGRect aFrame = CGRectZero;
    
    titleImageView.hidden = nil == titleImage;
    if (NO == titleImageView.hidden)
    {
        CGFloat maxWidth = FLT_MAX;
        if (NO == rightButton.hidden && NO == leftButton.hidden)
            maxWidth = (rightButton.frame.origin.x - 20.0) - (leftButton.frame.origin.x + leftButton.frame.size.width + 20.0);
        
        CGFloat maxHeight = self.bounds.size.height - 10.0;
        
        titleImageView.image = titleImage;
        [titleImageView sizeToFit];
        aFrame = titleImageView.frame;
        if (aFrame.size.width > maxWidth) aFrame.size.width = maxWidth;
        if (aFrame.size.height > maxHeight) aFrame.size.height = maxHeight;
        aFrame.origin.x = (self.bounds.size.width / 2.0) - (aFrame.size.width / 2.0);
        aFrame.origin.y = (self.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
        if (LIOIsUIKitFlatMode()) {
            if (![[UIApplication sharedApplication] isStatusBarHidden] && !padUI) {
                aFrame.origin.y += 10.0;
            }
        }
        titleImageView.frame = aFrame;
    }
    
    titleLabel.hidden = 0 == [titleString length] || NO == titleImageView.hidden;
    if (NO == titleLabel.hidden)
    {
        titleLabel.text = titleString;
        [titleLabel sizeToFit];
        aFrame = titleLabel.frame;
        aFrame.origin.y = (self.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
        aFrame.origin.x = leftButton.frame.origin.x + leftButton.frame.size.width + 10.0;
        aFrame.size.width = rightButton.frame.origin.x - aFrame.origin.x - 10.0;
        if (LIOIsUIKitFlatMode()) {
            if (![[UIApplication sharedApplication] isStatusBarHidden] && !padUI) {
                aFrame.origin.y += 10.0;
            }
        }
        titleLabel.frame = aFrame;
    }
}

#pragma mark - UIControl actions -

- (void)leftButtonWasTapped
{
    [delegate navigationBarDidTapLeftButton:self];
}

- (void)rightButtonWasTapped
{
    [delegate navigationBarDidTapRightButton:self];
}

@end