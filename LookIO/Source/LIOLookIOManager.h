//
//  LIOLookIOManager.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LIOLookIOManager : NSObject

@property(nonatomic, retain) UIImage *touchImage;
@property(nonatomic, retain) NSString *targetAgentId;
@property(nonatomic, assign) CGPoint controlButtonCenter;
@property(nonatomic, assign) CGPoint controlButtonCenterLandscape;
@property(nonatomic, assign) CGRect controlButtonBounds;
@property(nonatomic, assign) BOOL usesTLS, usesControlButton, usesSounds;

+ (LIOLookIOManager *)sharedLookIOManager;
- (void)beginSession;
- (void)recordCurrentUILocation:(NSString *)aLocationString;

@end
