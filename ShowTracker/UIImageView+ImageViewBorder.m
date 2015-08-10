//
//  UIImageView+ImageViewBorder.m
//  ShowTracker
//
//  Created by Maxim on 10.08.15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

#import "UIImageView+ImageViewBorder.h"

@implementation UIImageView (ImageViewBorder)

-(void)setImage:(UIImage*)image withBorderWidth:(CGFloat)borderWidth {
    [self configureImageViewBorder:borderWidth];
    //UIImage* scaledImage = [self rescaleImage:image];
    self.image = image;
}

-(void)configureImageViewBorder:(CGFloat)borderWidth{

    CALayer* layer = [self layer];
    [layer setBorderWidth:borderWidth];
    [self setContentMode:UIViewContentModeScaleAspectFill];
    [layer setBorderColor:[UIColor blackColor].CGColor];
    [layer setCornerRadius:10.f];
    
}

-(UIImage*)rescaleImage:(UIImage*)image{

    UIImage* scaledImage = image;

    CALayer* layer = self.layer;
    CGFloat borderWidth = layer.borderWidth;

    if (borderWidth > 0) {

        CGRect imageRect = CGRectMake(0.0, 0.0, self.bounds.size.width - 2 * borderWidth,self.bounds.size.height - 2 * borderWidth);
        if (image.size.width > imageRect.size.width || image.size.height > imageRect.size.height) {

            UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, 0.f);
            [image drawInRect:imageRect];
            scaledImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

        }

    }

    return scaledImage;

}

@end
