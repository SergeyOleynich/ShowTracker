//
//  RWViewController.m
//  ShowTracker
//
//  Created by Joshua on 3/1/14.
//  Copyright (c) 2014 Ray Wenderlich. All rights reserved.
//

#import "ViewController.h"
#import "TraktAPIClient.h"
#import <AFNetworking/UIKit+AFNetworking.h>
#import <Nimbus/NIAttributedLabel.h>
#import <SAMCategories/UIScreen+SAMAdditions.h>
#import "UIImageView+ImageViewBorder.h"
#import "MBProgressHUD.h"

@interface ViewController () <NIAttributedLabelDelegate>

@property (strong, nonatomic) NSArray *jsonResponse;
@property (assign, nonatomic) BOOL pageControlUsed;
@property (assign, nonatomic) NSInteger previousPage;
@property (strong, nonatomic) NSMutableArray *loadedPages;

@end

@implementation ViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.previousPage = -1;
    
    _loadedPages = [[NSMutableArray alloc] init];
    
    [[TraktAPIClient sharedClient] getShowsForDate:[NSDate date] username:@"SergeyOleynich" numbersOfDays:2 success:^(NSURLSessionDataTask *task, id responseObject) {
        self.jsonResponse = responseObject;
        
        NSInteger shows = [self.jsonResponse count];
        
        self.showsPageControl.numberOfPages = shows;
        self.showsPageControl.currentPage = 0;
        
        self.showsScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds) * shows, CGRectGetHeight(self.showsScrollView.frame));
        
        [self loadShow:0];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"error = %@", error.localizedDescription);
        
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                 }];
            
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
        
    }];
    
}

#pragma mark - Private

- (void)loadShow:(NSInteger)index {
   
    if ([self.loadedPages containsObject:@(index)]) {
        return ;
    }
    
    [self.loadedPages addObject:@(index)];
    
    NSDictionary *showDict = [self.jsonResponse objectAtIndex:index][@"show"];
    
    NIAttributedLabel *titleLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectMake(index * CGRectGetWidth(self.showsScrollView.bounds), 50, CGRectGetWidth(self.showsScrollView.bounds), 40)];
    titleLabel.text = showDict[@"title"];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.linkColor = [UIColor blueColor];
    titleLabel.linksHaveUnderlines = YES;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [titleLabel addLink: [NSURL URLWithString:[NSString stringWithFormat:@"https://www.trakt.tv/shows/%@", [[showDict objectForKey:@"ids"] objectForKey:@"slug"]]] range:NSMakeRange(0, titleLabel.text.length)];
    titleLabel.delegate = self;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleLabel sizeToFit];
    titleLabel.center = CGPointMake(CGRectGetMidX(self.view.frame) + (CGRectGetWidth(self.view.frame) * index), CGRectGetHeight(titleLabel.frame) + 50);
    
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateIntervalFormatterLongStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        formatter.timeZone = [NSTimeZone localTimeZone];
    }
    
    NSDictionary *episodeDict = [[self.jsonResponse objectAtIndex:index] objectForKey:@"episode"];
    
    static NSDateFormatter *formatter1 = nil;
    if (!formatter1) {
        formatter1 = [[NSDateFormatter alloc] init];
        [formatter1 setDateFormat:@"YYYY-MM-dd'T'HH:mm:ss.SSS'Z'"];
    }
    
    NSDate *showDate1 = [formatter1 dateFromString:[[self.jsonResponse objectAtIndex:index] objectForKey:@"first_aired"]];
    
    NSString *showDate = [formatter stringFromDate:showDate1];
    
    NSString *posterURL = nil;
    
    if ([[UIScreen mainScreen] sam_isRetina]) {
        posterURL = [[[showDict objectForKey:@"images"] objectForKey:@"poster"] objectForKey:@"full"];
    } else {
        posterURL = [[[showDict objectForKey:@"images"] objectForKey:@"poster"] objectForKey:@"medium"];
    }
    
    UIImageView *posterImage = [[UIImageView alloc] init];
    posterImage.clipsToBounds = YES;
    [posterImage setContentMode:UIViewContentModeScaleAspectFill];
    NSUInteger width = lrintf(100 + CGRectGetWidth(self.view.frame) / 4);
    posterImage.frame = CGRectMake(index * CGRectGetWidth (self.view.frame) + (CGRectGetWidth(self.view.frame) - width) * 0.5, CGRectGetMaxY(titleLabel.frame) + 50, width, width * 1.5);
    if (![posterURL isKindOfClass:[NSNull class]]) {
        [MBProgressHUD showHUDAddedTo:posterImage animated:YES];
        __weak UIImageView *posterImageWeak = posterImage;
        [posterImage setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:posterURL]] placeholderImage:[UIImage imageNamed:@"placeholder.png"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            [MBProgressHUD hideHUDForView:posterImageWeak animated:YES];
            [posterImageWeak setImage:image withBorderWidth:2.f];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            [MBProgressHUD hideHUDForView:posterImageWeak animated:YES];
        }];
    } else {
        [posterImage setImage:[UIImage imageNamed:@"placeholder.png"]];
    }
    
    NIAttributedLabel *episodeLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectMake(index * CGRectGetWidth(self.showsScrollView.bounds), CGRectGetMaxY(posterImage.frame) + 50, CGRectGetWidth(self.showsScrollView.bounds), 40)];
    
    NSString *episodeStr = [NSString stringWithFormat:@"%02dx%02d - \"%@\"", [[episodeDict objectForKey:@"season"] intValue], [[episodeDict objectForKey:@"number"] intValue], [episodeDict objectForKey:@"title"]];
    
    episodeLabel.text = [NSString stringWithFormat:@"%@\n%@", episodeStr, showDate];
    episodeLabel.numberOfLines = 0;
    episodeLabel.textAlignment = NSTextAlignmentCenter;
    episodeLabel.textColor = [UIColor whiteColor];
    episodeLabel.backgroundColor = [UIColor clearColor];
    episodeLabel.linkColor = [UIColor blueColor];
    episodeLabel.linksHaveUnderlines = YES;
    episodeLabel.delegate = self;
    
    NSString *linkToEpisode = [NSString stringWithFormat:@"https://www.trakt.tv/shows/%@/seasons/%@/episodes/%@", [[showDict objectForKey:@"ids"] objectForKey:@"slug"], [[[self.jsonResponse objectAtIndex:index] objectForKey:@"episode"] objectForKey:@"season"], [[[self.jsonResponse objectAtIndex:index] objectForKey:@"episode"] objectForKey:@"number"]];
    
    [episodeLabel addLink:[NSURL URLWithString:linkToEpisode] range:NSMakeRange(0, episodeLabel.text.length)];
    
    CGSize size = [episodeLabel sizeThatFits:CGSizeMake(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetMinY(episodeLabel.frame))];
    CGRect frame = episodeLabel.frame;
    frame.size.width = self.view.frame.size.width;
    frame.size.height = size.height;
    episodeLabel.frame = frame;
    
    CALayer *sublayer = [CALayer layer];
    sublayer.backgroundColor = [UIColor redColor].CGColor;
    sublayer.shadowRadius = 10.f;
    sublayer.shadowOffset = CGSizeMake(0, 5);
    sublayer.shadowRadius = 20.0;
    sublayer.shadowColor = [UIColor blackColor].CGColor;
    sublayer.shadowOpacity = 0.8;
    sublayer.frame = posterImage.frame;
    sublayer.borderColor = [UIColor blackColor].CGColor;
    sublayer.borderWidth = 2.0;
    sublayer.cornerRadius = 10.0;
    //sublayer.hidden = YES;
    [self.showsScrollView.layer addSublayer:sublayer];
    //[self.showsScrollView.layer insertSublayer:sublayer above:self.showsScrollView.layer];
    //[self.showsScrollView.]
    
    [self.showsScrollView addSubview:posterImage];
    [self.showsScrollView addSubview:episodeLabel];
    [self.showsScrollView addSubview:titleLabel];

}

#pragma mark - NIAttributedLabelDelegate

- (void)attributedLabel:(NIAttributedLabel *)attributedLabel didSelectTextCheckingResult:(NSTextCheckingResult *)result atPoint:(CGPoint)point {
    
    [[UIApplication sharedApplication] openURL:result.URL];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {

    if (self.pageControlUsed)
        return;
    
    CGFloat pageWidth = sender.frame.size.width;
    NSInteger page = floor((sender.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if (page == self.previousPage || page < 0 || page >= self.showsPageControl.numberOfPages)
        return;
    self.previousPage = page;
    
    self.showsPageControl.currentPage = page;
    
    [self loadShow:page];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.pageControlUsed = NO;
}

#pragma mark - Actions

- (IBAction)pageChanged:(id)sender
{
    self.pageControlUsed = YES;
    
    NSInteger page = self.showsPageControl.currentPage;
    self.previousPage = page;
    
    [self loadShow:page];
    
    CGRect frame = self.showsScrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [UIView animateWithDuration:.5 animations:^{
        [self.showsScrollView scrollRectToVisible:frame animated:NO];
    } completion:^(BOOL finished) {
        self.pageControlUsed = NO;
    }];
}

@end
