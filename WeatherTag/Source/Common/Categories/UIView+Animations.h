//
//  UIView+Animations.h
//  FlyCard
//
//  Created by Hawk on 3/17/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Animations)

/* Returns the view's alpha prior to being set to zero.
   The return value can be passed to fadeIn:alpha to 
   restore the view's original alpha value. Useful when
   the view has an alpha value < 1.0.
 */
-(CGFloat)fadeOut:(NSTimeInterval)duration;

/* After fading in, the view's alpha is 1.0*/
-(void)fadeIn:(NSTimeInterval)duration;

/* After fading in, the view's alpha is originalAlpha*/
-(void)fadeIn:(NSTimeInterval)duration alpha:(CGFloat)originalAlpha;

/* Starts below the bottom of the screen, moving this view
   to the given end frame.*/
-(void)moveFromOffscreenBottomWithDuration:(NSTimeInterval)duration toFrame:(CGRect)endFrame;

@end
