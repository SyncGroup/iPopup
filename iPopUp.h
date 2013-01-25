//
//  iPopUp.h
//  iPopUp
//
//  Created by Gabriel Gino Vincent on 23/01/13.
//  Copyright (c) 2013 Sync. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface iPopUp : UIView {
    UIView *popUpView;
    NSUserDefaults *defaults;
    UIImage *backgroundImage;
    CGRect popUpViewFinalFrame;
    UIButton *closeButton;
}

@property (nonatomic, strong) UIViewController *delegate;
@property (nonatomic, strong) NSURL *checkURL;
@property (nonatomic, strong) UIImage *closeButtonImage;

- (void) verifyIfShouldShow;

@end
