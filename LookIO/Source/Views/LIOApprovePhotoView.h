//
//  LIOApprovePhotoView.h
//  LookIO
//
//  Created by Yaron Karasik on 2/7/14.
//
//

#import <UIKit/UIKit.h>

@class LIOApprovePhotoView;

@protocol LIOApprovePhotoViewDelegate <NSObject>

- (void)approvePhotoViewDidCancel:(LIOApprovePhotoView *)approvePhotoView;
- (void)approvePhotoViewDidApprove:(LIOApprovePhotoView *)approvePhotoView;

@end

@interface LIOApprovePhotoView : UIView

@property (nonatomic, assign) id<LIOApprovePhotoViewDelegate> delegate;
@property (nonatomic, strong) UIImageView *imageView;

- (void)viewDidAppear;

@end
