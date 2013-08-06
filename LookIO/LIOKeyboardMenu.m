//
//  LIOKeyboardMenu.m
//  LookIO
//
//  Created by Yaron Karasik on 8/5/13.
//
//

#import "LIOKeyboardMenu.h"
#import "LIOBundleManager.h"

@implementation LIOKeyboardMenu

@synthesize buttonsArray, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.8];
        
        buttonsArray = [[NSMutableArray alloc] init];
        
        UIImageView* backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        backgroundImageView.image = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOKeyboardMenuSeparators"];
        backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:backgroundImageView];
        
        UIButton* attachButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 56, 44)];
        [attachButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOCameraIconLarge"] forState:UIControlStateNormal];
        [self addSubview:attachButton];
        [attachButton addTarget:self action:@selector(attachButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:attachButton];
    }
    return self;
}

-(void)layoutSubviews {
    
}

-(void)attachButtonWasTapped:(id)sender {
    [self.delegate keyboardMenuAttachButtonWasTapped:self];
}

@end
