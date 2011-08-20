//
//  LIOLookIOManager.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LIOLookIOManagerDelegate
@end

@interface LIOLookIOManager : NSObject
{
    NSTimer *screenCaptureTimer;
    UIImage *touchImage;
    id<LIOLookIOManagerDelegate> delegate;
}

@property(nonatomic, retain) UIImage *touchImage;
@property(nonatomic, assign) id<LIOLookIOManagerDelegate> delegate;

+ (LIOLookIOManager *)sharedLookIOManager;

@end
