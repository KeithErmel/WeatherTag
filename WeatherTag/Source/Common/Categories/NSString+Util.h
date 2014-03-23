//
//  NSString+Util.h
//  Baliza
//
//  Created by Keith Ermel on 2/14/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !defined(NSSTRING_UTIL_EXTERN)
#  if defined(__cplusplus)
#   define NSSTRING_UTIL_EXTERN extern "C"
#  else
#   define NSSTRING_UTIL_EXTERN extern
#  endif
#endif /* !defined(NSSTRING_UTIL_EXTERN) */


NSSTRING_UTIL_EXTERN NSString *NSStringFromBOOL(BOOL flag);


@interface NSString (Util)
-(BOOL)isEmpty;
-(BOOL)isNotEmpty;
-(NSString *)trim;
@end
