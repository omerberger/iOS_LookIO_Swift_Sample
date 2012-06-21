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

@implementation LIOSurveyPickerView

@synthesize currentMode, surveyQuestion, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UIImage *sendButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSendButton"];
        sendButtonImage = [sendButtonImage stretchableImageWithLeftCapWidth:5 topCapHeight:20];
        
        doneButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [doneButton setTitle:@"Done" forState:UIControlStateNormal];
        [doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        doneButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
        [doneButton setBackgroundImage:sendButtonImage forState:UIControlStateNormal];
        [doneButton addTarget:self action:@selector(doneButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:doneButton];
        
        self.backgroundColor = [UIColor darkGrayColor];
        
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
        [self addSubview:tableView];
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
            CGRect aFrame = tableView.frame;
            aFrame.origin.x = 0.0;
            aFrame.origin.y = 40.0;
            aFrame.size.width = self.bounds.size.width;
            aFrame.size.height = 216.0;
            tableView.frame = aFrame;
            
            aFrame = self.frame;
            aFrame.size.height = tableView.bounds.size.height + 40.0;
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
            CGRect aFrame = tableView.frame;
            aFrame.origin.x = 0.0;
            aFrame.origin.y = 40.0;
            aFrame.size.width = self.bounds.size.width;
            aFrame.size.height = 162.0;
            tableView.frame = aFrame;
            
            aFrame = self.frame;
            aFrame.size.height = tableView.bounds.size.height + 40.0;
            self.frame = aFrame;
        }
    }
    
    [doneButton sizeToFit];
    CGRect aFrame = doneButton.frame;
    aFrame.size.width += 20.0;
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
    
    [surveyQuestion release];
    [pickerView release];
    [tableView release];
    [doneButton release];
    [selectedIndices release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark UIControl actions

- (void)doneButtonWasTapped
{
    NSMutableArray *results = [NSMutableArray array];
    
    if (LIOSurveyPickerViewModeSingle == currentMode)
    {
        int selectedRow = [pickerView selectedRowInComponent:0];
        NSNumber *result = [NSNumber numberWithInt:selectedRow];
        [results addObject:result];
    }
    else
    {
        for (NSIndexPath *anIndexPath in selectedIndices)
        {
            NSNumber *result = [NSNumber numberWithInt:anIndexPath.row];
            [results addObject:result];
        }
    }
    
    [delegate surveyPickerView:self didFinishSelectingIndices:results];
}

#pragma mark -
#pragma mark UIPickerViewDataSource methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [surveyQuestion.pickerEntries count];
}

#pragma mark -
#pragma mark UIPickerViewDelegate methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    LIOSurveyPickerEntry *entry = [surveyQuestion.pickerEntries objectAtIndex:row];
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
    if (nil == aCell)
    {
        aCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"balls"] autorelease];
    }
    
    LIOSurveyPickerEntry *anEntry = [surveyQuestion.pickerEntries objectAtIndex:indexPath.row];
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

@end