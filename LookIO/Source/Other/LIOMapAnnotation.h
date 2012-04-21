//
//  LIOMapAnnotation.h
//  LookIO
//
//  Created by Joseph Toscano on 4/19/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface LIOMapAnnotation : NSObject <MKAnnotation>
{
}

@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly, copy) NSString *title;
@property(nonatomic, readonly, copy) NSString *subtitle;

- (id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate title:(NSString *)aTitle subtitle:(NSString *)aSubtitle;

@end