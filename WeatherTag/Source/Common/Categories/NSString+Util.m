//
//  NSString+Util.m
//  Baliza
//
//  Created by Keith Ermel on 2/14/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import "NSString+Util.h"

NSString *NSStringFromBOOL(BOOL flag){return flag ? @"YES" : @"NO";}

@implementation NSString (Util)

-(BOOL)isEmpty {return self.length == 0;}
-(BOOL)isNotEmpty{return self.length > 0;}
-(NSString *)trim{return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];}

@end
