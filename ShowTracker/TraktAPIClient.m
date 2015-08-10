//
//  TraktAPIClient.m
//  ShowTracker
//
//  Created by Maxim on 08.08.15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

#import "TraktAPIClient.h"

NSString * const kTraktAPIKey = @"8750d2cc95aac9fd38267418fb4396253153e16a07554f8e0fb4ee14c7eb9024";
NSString * const kTraktBaseURLString = @"https://api-v2launch.trakt.tv/";

/*
Client ID: 8750d2cc95aac9fd38267418fb4396253153e16a07554f8e0fb4ee14c7eb9024
Client Secret: d8590e991f7c144bba932673506facbcfe8c3c8fa10e6f4c688ad56dcf5b0f65
*/

@implementation TraktAPIClient

+ (TraktAPIClient *)sharedClient {
    static TraktAPIClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kTraktBaseURLString]];
    });
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
    
    [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestSerializer setValue:kTraktAPIKey forHTTPHeaderField:@"trakt-api-key"];
    [requestSerializer setValue:@"2" forHTTPHeaderField:@"trakt-api-version"];
    
    self.responseSerializer = [AFJSONResponseSerializer serializer];
    self.requestSerializer = requestSerializer;
    
    //self.requestSerializer
    
    return self;
}

- (void)getShowsForDate:(NSDate *)date username:(NSString *)username numbersOfDays:(int)numberOfDays success:(void(^)(NSURLSessionDataTask *task, id responseObject))success failure:(void(^)(NSURLSessionDataTask *task, NSError *error))failure {
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString* dateString = [formatter stringFromDate:date];
    
    NSString* path = [NSString stringWithFormat:@"%@calendars/all/shows/%@/%d",
                      kTraktBaseURLString, dateString, numberOfDays];
    
    [self GET:path parameters:@{@"extended" : @"images"} success:^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(task, responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(task, error);
        }
    }];
    
}

@end
