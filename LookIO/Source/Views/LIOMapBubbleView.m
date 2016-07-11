//
//  LIOMapBubbleView.m
//  LookIO
//
//  Created by Joseph Toscano on 4/19/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOMapBubbleView.h"
#import "LIOBundleManager.h"

@implementation LIOMapBubbleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        backgroundImage = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableChatBubble"]];
        backgroundImage.backgroundColor = [UIColor clearColor];
        [self addSubview:backgroundImage];
        
        tinyMapMarker = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOTinyMapMarker"]];
        tinyMapMarker.backgroundColor = [UIColor clearColor];
        [self addSubview:tinyMapMarker];
        
        addressLabel = [[UILabel alloc] init];
        addressLabel.font = [UIFont boldSystemFontOfSize:16.0];
        addressLabel.backgroundColor = [UIColor clearColor];
        addressLabel.numberOfLines = 0;
        [self addSubview:addressLabel];
        
        mapView = [[MKMapView alloc] init];
        mapView.userInteractionEnabled = NO;
        mapView.delegate = self;
        [self addSubview:mapView];
    }
    
    return self;
}

- (void)dealloc
{
    [backgroundImage release];
    [mapView release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    backgroundImage.frame = self.bounds;
    
    CGRect aFrame;
    aFrame.origin.x = 5.0;
    aFrame.origin.y = 5.0;
    aFrame.size.width = self.frame.size.width - 10.0;
    aFrame.size.height = 60.0;
    mapView.frame = aFrame;
    
    aFrame = tinyMapMarker.frame;
    aFrame.origin.x = 10.0;
    aFrame.origin.y = mapView.frame.origin.y + mapView.frame.size.height;
    tinyMapMarker.frame = aFrame;
    
    [addressLabel sizeToFit];
    aFrame = addressLabel.frame;
    aFrame.origin.x = tinyMapMarker.frame.origin.x + tinyMapMarker.frame.size.width + 5.0;
    aFrame.origin.y = tinyMapMarker.frame.origin.y;
    addressLabel.frame = aFrame;
}

#pragma mark -
#pragma mark MKMapViewDelegate methods

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKPinAnnotationView *aView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:LIOMapBubbleViewAnnotationReuseId];
    if (nil == aView)
        aView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:LIOMapBubbleViewAnnotationReuseId] autorelease];
    
    return aView;    
}

@end