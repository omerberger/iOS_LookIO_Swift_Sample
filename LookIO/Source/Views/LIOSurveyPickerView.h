//
//  LIOSurveyPickerView.h
//  LookIO
//
//  Created by Joseph Toscano on 6/19/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    LIOSurveyPickerViewModeSingle,
    LIOSurveyPickerViewModeMulti
} LIOSurveyPickerViewMode;

@class LIOSurveyQuestion, LIOSurveyPickerView;

@protocol LIOSurveyPickerViewDelegate
- (void)surveyPickerViewDidTapSelect:(LIOSurveyPickerView *)aView;
- (void)surveyPickerViewDidFinishDismissalAnimation:(LIOSurveyPickerView *)aView;
@end

@interface LIOSurveyPickerView : UIView <UITableViewDelegate, UITableViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate>
{
    UITableView *tableView;
    UIPickerView *pickerView;
    UIButton *doneButton;
    LIOSurveyPickerViewMode currentMode;
    LIOSurveyQuestion *surveyQuestion;
    NSMutableSet *selectedIndices;
    UIImageView *toolbarImageView;
    UIImageView *tableWellImage;
    NSArray *results;
    id<LIOSurveyPickerViewDelegate> delegate;
}

@property(nonatomic, assign) LIOSurveyPickerViewMode currentMode;
@property(nonatomic, retain) LIOSurveyQuestion *surveyQuestion;
@property(nonatomic, readonly) NSArray *results;
@property(nonatomic, assign) id<LIOSurveyPickerViewDelegate> delegate;

- (void)showAnimated;
- (void)hideAnimated;

@end