//
//  LIOSurveyPickerView.m
//  LookIO
//
//  Created by Joseph Toscano on 6/19/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyPickerView.h"
#import "LIOSurveyQuestion.h"
#import "LIOSurveyPickerEntry.h"
#import "LIOBundleManager.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOLogManager.h"

@implementation LIOSurveyPickerView

@synthesize currentMode, surveyQuestion, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UIImage *toolbarImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIORepeatableEtchedGlassToolbar"];
        toolbarImage = [toolbarImage stretchableImageWithLeftCapWidth:0 topCapHeight:0];
        
        toolbarImageView = [[UIImageView alloc] initWithImage:toolbarImage];
        [self addSubview:toolbarImageView];
        
        UIImage *sendButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableRecessedButtonBlue"];
        sendButtonImage = [sendButtonImage stretchableImageWithLeftCapWidth:16 topCapHeight:0];
        
        doneButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [doneButton setTitle:@"Select" forState:UIControlStateNormal];
        [doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        doneButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
        [doneButton setBackgroundImage:sendButtonImage forState:UIControlStateNormal];
        [doneButton addTarget:self action:@selector(doneButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:doneButton];
        
        self.backgroundColor = [UIColor darkGrayColor];
        self.clipsToBounds = NO;
        
        selectedIndices = [[NSMutableSet alloc] init];
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    pickerView.delegate = nil;
    pickerView.dataSource = nil;
    [pickerView removeFromSuperview];
    [pickerView release];
    pickerView = nil;
    
    tableView.delegate = nil;
    tableView.dataSource = nil;
    [tableView removeFromSuperview];
    [tableView release];
    tableView = nil;
}

- (void)didMoveToSuperview
{
    if (LIOSurveyPickerViewModeSingle == currentMode)
    {
        pickerView = [[UIPickerView alloc] init];
        CGRect aFrame = pickerView.frame;
        aFrame.origin.x = 0.0;
        aFrame.origin.y = 40.0;
        aFrame.size.width = self.bounds.size.width;
        aFrame.size.height = 216.0;
        pickerView.frame = aFrame;
        pickerView.delegate = self;
        pickerView.dataSource = self;
        pickerView.showsSelectionIndicator = YES;
        [pickerView reloadAllComponents];
        [self addSubview:pickerView];
    }
    else
    {
        tableView = [[UITableView alloc] init];
        tableView.delegate = self;
        tableView.dataSource = self;
        [tableView reloadData];
        tableView.layer.cornerRadius = 5.0;
        tableView.layer.masksToBounds = YES;
        //tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self addSubview:tableView];
        
        UIImage *tableWell = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableTableWell"];
        tableWell = [tableWell stretchableImageWithLeftCapWidth:19 topCapHeight:30];
        tableWellImage = [[UIImageView alloc] initWithImage:tableWell];
        tableWellImage.backgroundColor = [UIColor clearColor];
        [self addSubview:tableWellImage];
    }
}

- (void)layoutSubviews
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
    {
        if (LIOSurveyPickerViewModeSingle == currentMode)
        {
            CGRect aFrame = pickerView.frame;
            aFrame.origin.x = 0.0;
            aFrame.origin.y = 40.0;
            aFrame.size.width = self.bounds.size.width;
            aFrame.size.height = 0.0;
            pickerView.frame = aFrame;
            
            aFrame = self.frame;
            aFrame.size.height = pickerView.bounds.size.height + 40.0;
            self.frame = aFrame;
        }
        else
        {
            CGRect aFrame = tableWellImage.frame;
            aFrame.origin.x = 0.0;
            aFrame.origin.y = 40.0;
            aFrame.size.width = self.bounds.size.width;
            aFrame.size.height= 216.0;
            tableWellImage.frame = aFrame;
            
            aFrame = tableView.frame;
            aFrame.origin.x = 5.0; // border offset
            aFrame.origin.y = 40.0 + 14.0; // border offset
            aFrame.size.width = self.bounds.size.width - 10.0;
            aFrame.size.height = 216.0 - 28.0;
            tableView.frame = aFrame;
                        
            aFrame = self.frame;
            aFrame.size.height = 216.0 + 40.0;
            self.frame = aFrame;
        }
    }
    else
    {
        if (LIOSurveyPickerViewModeSingle == currentMode)
        {
            CGRect aFrame = pickerView.frame;
            aFrame.origin.x = 0.0;
            aFrame.origin.y = 40.0;
            aFrame.size.width = self.bounds.size.width;
            aFrame.size.height = 0.0;
            pickerView.frame = aFrame;
            
            aFrame = self.frame;
            aFrame.size.height = pickerView.bounds.size.height + 40.0;
            self.frame = aFrame;
        }
        else
        {
            CGRect aFrame = tableWellImage.frame;
            aFrame.origin.x = 0.0;
            aFrame.origin.y = 40.0;
            aFrame.size.width = self.bounds.size.width;
            aFrame.size.height= 162.0;
            tableWellImage.frame = aFrame;
            
            aFrame = tableView.frame;
            aFrame.origin.x = 5.0; // border offset
            aFrame.origin.y = 40.0 + 14.0; // border offset
            aFrame.size.width = self.bounds.size.width - 10.0;
            aFrame.size.height = 162.0 - 28.0;
            tableView.frame = aFrame;
            
            aFrame = self.frame;
            aFrame.size.height = 162.0 + 40.0;
            self.frame = aFrame;
        }
    }
    
    // toolbar shadow spills above 8.5 points
    CGRect aFrame = toolbarImageView.frame;
    aFrame.origin.x = 0.0;
    aFrame.origin.y = -8.5;
    aFrame.size.width = self.bounds.size.width;
    toolbarImageView.frame = aFrame;
    
    [doneButton sizeToFit];
    aFrame = doneButton.frame;
    aFrame.size.width += 10.0;
    aFrame.origin.x = self.bounds.size.width - aFrame.size.width - 10.0;
    aFrame.origin.y = 20.0 - (aFrame.size.height / 2.0);
    doneButton.frame = aFrame;
}

- (void)dealloc
{
    pickerView.delegate = nil;
    pickerView.dataSource = nil;
    
    tableView.delegate = nil;
    tableView.dataSource = nil;
    
    [self.layer removeAllAnimations];
    
    [surveyQuestion release];
    [pickerView release];
    [tableView release];
    [doneButton release];
    [selectedIndices release];
    [toolbarImageView release];
    [tableWellImage release];
    
    [super dealloc];
}

- (void)showAnimated
{
    CGRect targetFrame = self.frame;
    
    CGRect aFrame = self.frame;
    aFrame.origin.y += aFrame.size.height;
    self.frame = aFrame;
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.frame = targetFrame;
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (void)hideAnimated
{
    CGRect targetFrame = self.frame;
    targetFrame.origin.y += targetFrame.size.height;
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.frame = targetFrame;
                     }
                     completion:^(BOOL finished) {
                         [delegate surveyPickerViewDidFinishDismissalAnimation:self];
                     }];
}

#pragma mark -
#pragma mark UIControl actions

- (void)doneButtonWasTapped
{
    NSMutableArray *results = [NSMutableArray array];
    
    if (LIOSurveyPickerViewModeSingle == currentMode)
    {
        int selectedRow = [pickerView selectedRowInComponent:0];
        if (selectedRow > 0)
        {
            NSNumber *result = [NSNumber numberWithInt:(selectedRow - 1)];
            [results addObject:result];
        }
    }
    else
    {
        for (NSIndexPath *anIndexPath in selectedIndices)
        {
            NSNumber *result = [NSNumber numberWithInt:anIndexPath.row];
            [results addObject:result];
        }
    }

    [delegate surveyPickerView:self didSelectIndices:results];
}

#pragma mark -
#pragma mark UIPickerViewDataSource methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [surveyQuestion.pickerEntries count] + 1;
}

#pragma mark -
#pragma mark UIPickerViewDelegate methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (0 == row)
        return @"Choose an option below:";
    
    LIOSurveyPickerEntry *entry = [surveyQuestion.pickerEntries objectAtIndex:row - 1];
    return entry.label;
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [surveyQuestion.pickerEntries count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *aCell = [tableView dequeueReusableCellWithIdentifier:@"balls"];
    //UILabel *cellLabel = nil;
    if (nil == aCell)
    {
        aCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"balls"] autorelease];
        aCell.textLabel.textColor = [UIColor colorWithWhite:(96.0/255.0) alpha:1.0];
        
        /*
        aCell.backgroundView.backgroundColor = [UIColor clearColor];
        aCell.backgroundColor = [UIColor clearColor];

        cellLabel = [[[UILabel alloc] init] autorelease];
        cellLabel.backgroundColor = [UIColor clearColor];
        cellLabel.textColor = [UIColor colorWithWhite:(96.0/255.0) alpha:1.0];
        cellLabel.font = [UIFont systemFontOfSize:16.0];
        cellLabel.tag = 2742;
        [aCell.contentView addSubview:cellLabel];
        
        UIImage *paperTextureImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOTablePaperTexture"];
        UIImageView *paperTexture = [[[UIImageView alloc] initWithImage:paperTextureImage] autorelease];
        paperTexture.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        paperTexture.frame = aCell.contentView.bounds;
        [aCell.contentView addSubview:paperTexture];
        [aCell.contentView sendSubviewToBack:paperTexture];
        */
    }
    
    LIOSurveyPickerEntry *anEntry = [surveyQuestion.pickerEntries objectAtIndex:indexPath.row];
    
    /*
    cellLabel = (UILabel *)[aCell.contentView viewWithTag:2742];
    cellLabel.text = anEntry.label;
    [cellLabel sizeToFit];
    CGRect aFrame = cellLabel.frame;
    aFrame.origin.x = 60.0;
    aFrame.origin.y = (aCell.contentView.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
    aFrame.size.width = aCell.contentView.frame.size.width - 40.0;
    cellLabel.frame = aFrame;
    */
    
    aCell.textLabel.text = anEntry.label;
    
    if ([selectedIndices containsObject:indexPath])
        aCell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        aCell.accessoryType = UITableViewCellAccessoryNone;
    
    return aCell;
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if ([selectedIndices containsObject:indexPath])
        [selectedIndices removeObject:indexPath];
    else
        [selectedIndices addObject:indexPath];
    
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

/*
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0;
}
*/

@end