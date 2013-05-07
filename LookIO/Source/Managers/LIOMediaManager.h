//
//  LIOMediaManager.h
//  LookIO
//
//  Created by Joseph Toscano on 5/6/13.
//
//

#import <UIKit/UIKit.h>

@class LIOMediaManager;

@interface LIOMediaManager : NSObject

+ (LIOMediaManager *)sharedInstance;
- (void)uploadMediaData:(NSData *)someData withType:(NSString *)aType;
- (void)purgeAllMedia;
- (NSString *)commitImageMedia:(UIImage *)anImage;
- (NSData *)mediaDataWithId:(NSString *)anId;
- (NSString *)mimeTypeFromId:(NSString *)anId;

@end
