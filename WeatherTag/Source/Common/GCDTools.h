//
//  GCDTools.h
//  Categorization
//
//  Created by Keith Ermel on 3/23/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#ifndef GCDTools_h
#define GCDTools_h

#ifndef GCD_ON_MAIN_QUEUE
#define GCD_ON_MAIN_QUEUE(block) dispatch_async(dispatch_get_main_queue(), block);
#endif


#endif
