//
//  WeatherDisplayViewController.h
//  WeatherTag
//
//  Created by Keith Ermel on 3/23/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WeatherDisplayViewController : UIViewController
-(void)updateTemperatureValue:(float)temperature;
-(void)updateHumidityValue:(float)humidity;
@end
