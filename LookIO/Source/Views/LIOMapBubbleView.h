//
//  LIOMapBubbleView.h
//  LookIO
//
//  Created by Joseph Toscano on 4/19/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#define LIOMapBubbleViewAnnotationReuseId @"LIOMapBubbleViewAnnotationReuseId"

@interface LIOMapBubbleView : UIView <MKMapViewDelegate>
{
    UIImageView *backgroundImage, *tinyMapMarker;
    MKMapView *mapView;
    UILabel *addressLabel;
}

@end