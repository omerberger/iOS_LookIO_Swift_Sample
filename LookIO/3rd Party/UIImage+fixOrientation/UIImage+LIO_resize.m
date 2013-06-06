//
//  UIImage+fixOrientation.m
//  LookIO
//
//  Created by Yaron Karasik on 6/5/13.
//
//

#import "UIImage+LIO_resize.h"

@implementation UIImage (LIO_resize)

+ (UIImage*)LIO_imageWithImage:(UIImage*)sourceImage scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [sourceImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end