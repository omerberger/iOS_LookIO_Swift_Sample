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
@property(nonatomic, assign) CGRect controlButtonFrame;
@property(nonatomic, assign) BOOL usesTLS;

+ (LIOLookIOManager *)sharedLookIOManager;
- (void)beginSession;
- (void)recordCurrentUILocation:(NSString *)aLocationString;

@end
