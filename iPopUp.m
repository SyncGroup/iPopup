//
//  iPopUp.m
//  iPopUp
//
//  Created by Gabriel Gino Vincent on 23/01/13.
//  Copyright (c) 2013 Sync. All rights reserved.
//

#define PopUpViewWidth popUpView.frame.size.width
#define PopUpViewHeight popUpView.frame.size.height
#define PopUpViewOriginX popUpView.frame.origin.x
#define PopUpViewOriginY popUpView.frame.origin.y
#define ContainerViewWidth self.frame.size.width
#define ContainerViewHeight self.frame.size.height

#import "iPopUp.h"

@implementation iPopUp

#pragma mark Initialization

- (id) init {
    
    self = [super init];
    
    if (self) {
        // Work your initialising magic here as you normally would
        
        [self configureContainerView];
    }
    
    return self;
}

- (void) configureContainerView {
    
    defaults = [[NSUserDefaults standardUserDefaults] init];
    
    CGRect deviceScreenSize;
    
    if ([UIApplication sharedApplication].statusBarHidden)
       deviceScreenSize = [[UIScreen mainScreen] bounds];
    else
        deviceScreenSize = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-20);
    
    self.frame = deviceScreenSize;
    self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
}

#pragma mark Implementation

- (void) drawBackgroundGradient {
    
    CGFloat colors [] = {
        0.5, 0.5, 0.5, 0.7,
        0.0, 0.0, 0.0, 0.7
    };
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextDrawRadialGradient(context, gradient, self.center, 0, self.center, self.frame.size.width, kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(gradient), gradient = NULL;
    CGContextRestoreGState(context);
}

- (void) drawRect:(CGRect)rect {
    
    [self drawBackgroundGradient];
    
}

- (void) savePopUpIdentifier:(NSString *)identifier {
    
    [defaults setObject:identifier forKey:@"IPOPUP_PopUpIdentifier"];
    [defaults synchronize];
    
}

- (void) verifyIfShouldShow {
    
    NSOperationQueue *queue = [NSOperationQueue new];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.checkURL cachePolicy:NSURLCacheStorageAllowed timeoutInterval:8.0];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (data) {
            
            NSString *identifier = [[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil] objectForKey:@"identifier"];
            NSString *lastSavedIdentifier = [defaults stringForKey:@"IPOPUP_PopUpIdentifier"];
            
            if ([identifier isEqualToString:lastSavedIdentifier])
                return;
            
            NSString *imageURLString = [[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil] objectForKey:@"url"];
            NSURL *imageURL = [NSURL URLWithString:imageURLString];
            
            NSData *imageData = [[NSData alloc]  initWithContentsOfURL:imageURL];
            UIImage *image = [[UIImage alloc]  initWithData:imageData];
            
            backgroundImage = image;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self show];
            });
            
            [self savePopUpIdentifier:identifier];
        }
    }];
}

- (void) startShowingAnimation {
    
    float finalOriginX = (ContainerViewWidth - PopUpViewWidth) / 2.0;
    float finalOriginY = ((ContainerViewHeight - PopUpViewHeight) / 6.0);
    float spaceBetweenImageAndCloseButton = finalOriginY/2.0;
    
    popUpViewFinalFrame = CGRectMake(finalOriginX, finalOriginY, PopUpViewWidth, PopUpViewHeight);
    
    [UIView animateWithDuration:0.3 animations:^{
        
        popUpView.frame = CGRectMake(finalOriginX, finalOriginY-20, PopUpViewWidth, PopUpViewHeight);;
        popUpView.alpha = 1.0;
        closeButton.frame = CGRectMake(PopUpViewOriginX, finalOriginY-30+PopUpViewHeight, PopUpViewWidth, 40);
        
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            
            popUpView.frame = popUpViewFinalFrame;
            closeButton.frame = CGRectMake(PopUpViewOriginX, finalOriginY+PopUpViewHeight + spaceBetweenImageAndCloseButton, PopUpViewWidth, 40);
            
        } completion:^(BOOL finished) {
            
        }];
    }];
}

- (void) close {
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
        [UIView animateWithDuration:0.2 animations:^{
            
            popUpView.alpha = 0.0;
            closeButton.alpha = 0.0;
            
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                
                self.alpha = 0.0;
                
            } completion:^(BOOL finished) {
                
                [self removeFromSuperview];
            }];
        }];
        
    });
}

- (void) show {
    NSLog(@"Showing");
    
    float reducedWidth = ContainerViewWidth-(ContainerViewWidth*0.2);
    float reducedHeight = ContainerViewHeight-(ContainerViewHeight*0.2);
    float initialOriginX = (ContainerViewWidth-reducedWidth)/2.0;
    float inititalOriginY = ContainerViewHeight;
    
    popUpView = [[UIView alloc] initWithFrame:CGRectMake(initialOriginX, inititalOriginY, reducedWidth, reducedHeight)];
    [self addSubview:popUpView];
    [self.delegate.view addSubview:self];
    
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, reducedWidth, reducedHeight)];
    backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
    backgroundImageView.image = backgroundImage;
    [popUpView addSubview:backgroundImageView];
    
    float closeButtonOriginY = PopUpViewOriginY+PopUpViewHeight;
    
    closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    closeButton.titleLabel.text = @"Close";
    closeButton.frame = CGRectMake(PopUpViewOriginX, closeButtonOriginY, PopUpViewWidth, 40);
    [closeButton setBackgroundImage:self.closeButtonImage forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    
    self.alpha = 0.0;
    popUpView.alpha = 0.0;
    
    [self addSubview:closeButton];
    
    [UIView animateWithDuration:0.2 animations:^{
        
        self.alpha = 1.0;
        
    } completion:^(BOOL finished) {
        [self startShowingAnimation];
    }];
}

@end
