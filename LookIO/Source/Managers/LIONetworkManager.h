//
//  LIONetworkManager.h
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import <Foundation/Foundation.h>

typedef enum
{
    LIOServerProduction = 0,
    LIOServerStaging,
    LIOServerQA
} LIOServerMode;

@interface LIONetworkManager : NSObject

@property (nonatomic, assign) LIOServerMode serverMode;
@property (nonatomic, copy) NSString *controlEndpoint;
@property (nonatomic, assign) BOOL usesTLS;

+ (LIONetworkManager *)networkManager;

- (void)setProductionMode;
- (void)setStagingMode;
- (void)setQAMode;

@end
