//
//  LIOPreSurveyView.m
//  LookIO
//
//  Created by Yaron Karasik on 5/30/13.
//
//

#import "LIOSurveyViewPre.h"
#import "LIOSurveyManager.h"
#import "LIOSurveyTemplate.h"
#import "LIOSurveyQuestion.h"
#import "LIOBundleManager.h"
#import <QuartzCore/QuartzCore.h>

#define LIOSurveyViewPrePageControlHeight     15.0

@implementation LIOSurveyViewPre

@synthesize currentSurvey, headerString;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
    }
    return self;
}

-(void)setupViews {
    UILabel* headerLabel = [[UILabel alloc] initWithFrame:self.bounds];
    headerLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    headerLabel.layer.shadowRadius = 1.0;
    headerLabel.layer.shadowOpacity = 1.0;
    headerLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.numberOfLines = 0;
    headerLabel.text = headerString;
    headerLabel.alpha = 0.0;
    headerLabel.textAlignment = UITextAlignmentCenter;
    [headerLabel sizeToFit];
    [self addSubview:headerLabel];
    [headerLabel release];
    
    CGRect pageControlFrame;
    pageControlFrame.origin.x = 0;
    pageControlFrame.origin.y = self.bounds.size.height - LIOSurveyViewPrePageControlHeight;
    pageControlFrame.size.width = self.bounds.size.width;
    pageControlFrame.size.height = LIOSurveyViewPrePageControlHeight;
    
    pageControl = [[UIPageControl alloc] initWithFrame:pageControlFrame];
    pageControl.numberOfPages = [currentSurvey.questions count];
    pageControl.alpha = 0.0;
    [self addSubview:pageControl];
    
    UIScrollView* firstQuestionScrollView = [self scrollViewForQuestionAtIndex:0];
    firstQuestionScrollView.transform = CGAffineTransformMakeTranslation(0.0, self.superview.bounds.size.height);
    [self addSubview:firstQuestionScrollView];
    
    [UIView animateWithDuration:0.4 delay:0.5 options:UIViewAnimationCurveLinear animations:^{
        headerLabel.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 delay:1.0 options:UIViewAnimationCurveLinear animations:^{
            headerLabel.transform = CGAffineTransformMakeTranslation(0.0, -self.frame.size.height);
            firstQuestionScrollView.transform = CGAffineTransformIdentity;
            pageControl.alpha = 1.0;
        } completion:^(BOOL finished) {
            [headerLabel removeFromSuperview];
        }];
    }];
}

-(UIScrollView*)scrollViewForQuestionAtIndex:(int)index {
    int numberOfQuestions = [currentSurvey.questions count];
    if (index > numberOfQuestions - 1 || index < 0)
        return nil;
    
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:index];

    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    
    UILabel* questionLabel = [[UILabel alloc] initWithFrame:self.bounds];
    questionLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    questionLabel.layer.shadowRadius = 1.0;
    questionLabel.layer.shadowOpacity = 1.0;
    questionLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    questionLabel.backgroundColor = [UIColor clearColor];
    questionLabel.textColor = [UIColor whiteColor];
    questionLabel.numberOfLines = 0;
    questionLabel.text = question.label;
    [questionLabel sizeToFit];
    questionLabel.textAlignment = UITextAlignmentCenter;
    [scrollView addSubview:questionLabel];
    [questionLabel release];
    
    CGSize questionLabelSize = [questionLabel.text sizeWithFont:questionLabel.font constrainedToSize:CGSizeMake(self.bounds.size.width - 20.0, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    CGRect aFrame = questionLabel.frame;
    aFrame.size = questionLabelSize;
    aFrame.origin.x = 10.0;
    aFrame.origin.y = 10.0;
    questionLabel.frame = aFrame;

    if (LIOSurveyQuestionDisplayTypeText == question.displayType) {
        UIImage *fieldImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAboutStretchableInputField"];
        UIImage *stretchableFieldImage = [fieldImage stretchableImageWithLeftCapWidth:11 topCapHeight:0];
        
        UIImageView *fieldBackground = [[[UIImageView alloc] initWithImage:stretchableFieldImage] autorelease];
        fieldBackground.userInteractionEnabled = YES;
        aFrame = fieldBackground.frame;
        aFrame.origin.x = 10.0;
        aFrame.size.width = self.bounds.size.width - 20.0;
        aFrame.size.height = 48.0;
        aFrame.origin.y = questionLabel.frame.origin.y + questionLabel.frame.size.height + 10.0;
        fieldBackground.frame = aFrame;
        fieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [scrollView addSubview:fieldBackground];
        
        UITextField *inputField = [[[UITextField alloc] init] autorelease];
        inputField.delegate = self;
        inputField.backgroundColor = [UIColor clearColor];
        aFrame.origin.x = 10.0;
        aFrame.origin.y = 14.0;
        aFrame.size.width = fieldBackground.frame.size.width - 20.0;
        aFrame.size.height = 28.0;
        inputField.frame = aFrame;
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputField.font = [UIFont systemFontOfSize:14.0];
        inputField.returnKeyType = UIReturnKeyNext;
        inputField.keyboardAppearance = UIKeyboardAppearanceAlert;
        [fieldBackground addSubview:inputField];
        [inputField becomeFirstResponder];
        
    }
    
    return [scrollView autorelease];
}


@end
