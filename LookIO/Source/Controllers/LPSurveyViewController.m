//
//  LPSurveyViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 12/31/13.
//
//

#import "LPSurveyViewController.h"

@interface LPSurveyViewController ()

@property (nonatomic, strong) LIOSurvey *survey;

@end

@implementation LPSurveyViewController

- (id)initWithSurvey:(LIOSurvey *)aSurvey
{
    self = [super init];
    if (self)
    {
        self.survey = aSurvey;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor greenColor];
}

@end
