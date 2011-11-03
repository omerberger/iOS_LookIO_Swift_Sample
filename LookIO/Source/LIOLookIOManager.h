//
//  LIOLookIOManager.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

UIImage *lookioImage(NSString *path);

@interface LIOLookIOManager : NSObject

@property(nonatomic, retain) UIImage *touchImage;
@property(nonatomic, retain) NSString *targetAgentId;
@property(nonatomic, retain) NSArray *supportedOrientations;
@property(nonatomic, assign) BOOL usesTLS, usesControlButton, usesSounds, horizontalControlButton;
@property(nonatomic, retain) NSDictionary *sessionExtras;
@property(nonatomic, assign) CGPoint controlButtonOrigin;

+ (LIOLookIOManager *)sharedLookIOManager;
- (void)beginSession;
- (void)recordCurrentUILocation:(NSString *)aLocationString;

@end