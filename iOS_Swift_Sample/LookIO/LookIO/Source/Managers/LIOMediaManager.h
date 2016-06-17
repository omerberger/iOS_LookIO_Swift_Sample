//
//  LIOMediaManager.h
//  LookIO
//
//  Created by Joseph Toscano on 5/6/13.
//
//

#import <UIKit/UIKit.h>

@class LIOMediaManager;
@class LIOChatMessage;

@interface LIOMediaManager : NSObject

+ (LIOMediaManager *)sharedInstance;
- (UIImage*)scaleImage:(UIImage*)sourceImage toSize:(CGSize)newSize;
- (void)purgeAllMedia;
- (NSString *)commitImageMedia:(UIImage *)anImage;
- (NSData *)mediaDataWithId:(NSString *)anId;
- (NSString *)mimeTypeFromId:(NSString *)anId;

@end