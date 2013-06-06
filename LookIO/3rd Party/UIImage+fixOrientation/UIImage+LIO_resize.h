//
//  UIImage+fixOrientation.h
//  LookIO
//
//  Created by Yaron Karasik on 6/5/13.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (LIO_resize)

+ (UIImage*)LIO_imageWithImage:(UIImage*)sourceImage scaledToSize:(CGSize)newSize;

@end
