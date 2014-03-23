//
//  UIView+Animations.m
//  FlyCard
//
//  Created by Hawk on 3/17/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import "UIView+Animations.h"
#import "CGRectTools.h"


@implementation UIView (Animations)

#pragma mark - Public API

-(CGFloat)fadeOut:(NSTimeInterval)duration
{
    CGFloat originalAlpha = self.alpha;
    
    [UIView animateWithDuration:duration animations:^{self.alpha = 0.0;} 
                     completion:^(BOOL finished) {self.hidden = YES;}];
    
    return originalAlpha;
}

-(void)fadeIn:(NSTimeInterval)duration {[self fadeIn:duration alpha:1.0];}

-(void)fadeIn:(NSTimeInterval)duration alpha:(CGFloat)originalAlpha
{
    self.alpha = 0.0;
    self.hidden = NO;
    
    [UIView animateWithDuration:duration animations:^{self.alpha = originalAlpha;}];
}

-(void)moveFromOffscreenBottomWithDuration:(NSTimeInterval)duration toFrame:(CGRect)endFrame
{
    CGFloat y = [self screenBottom];
    self.frame = CGRectMakeWithY(self.frame, y);
    self.hidden = NO;
    
    [UIView animateWithDuration:duration animations:^{self.frame = endFrame;}];
}


#pragma mark - Internal API

-(CGFloat)screenBottom {return [UIScreen mainScreen].bounds.size.height;}

@end
