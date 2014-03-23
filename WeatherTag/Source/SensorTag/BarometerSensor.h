//
//  BarometerSensor.h
//  WeatherTag
//
//  Created by Keith Ermel on 3/23/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BarometerSensor : NSObject
-(id)initWithCalibrationData:(NSData *)data;
-(int)calculatePressureFromData:(NSData *)data;
@end
