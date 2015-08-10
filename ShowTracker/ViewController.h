//
//  RWViewController.h
//  ShowTracker
//
//  Created by Joshua on 3/1/14.
//  Copyright (c) 2014 Ray Wenderlich. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIScrollViewDelegate>
@property (nonatomic, weak) IBOutlet UIScrollView *showsScrollView;
@property (nonatomic, weak) IBOutlet UIPageControl *showsPageControl;
- (IBAction)pageChanged:(id)sender;
@end
