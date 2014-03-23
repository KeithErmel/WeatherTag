//
//  WeatherDisplayViewController.m
//  WeatherTag
//
//  Created by Keith Ermel on 3/23/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import "WeatherDisplayViewController.h"
#import "GCDTools.h"


unichar const kDegreesSymbol            = 0x00B0;
unichar const kDegreesCelsius           = 0x2103;
unichar const kDegreesFahrenheit        = 0x2109;


@interface WeatherDisplayViewController ()
// Outlets
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *humidityLabel;
@property (weak, nonatomic) IBOutlet UILabel *barometerLabel;
@end


@implementation WeatherDisplayViewController

#pragma mark - Public API

-(void)updateTemperatureValue:(float)temperature
{
    GCD_ON_MAIN_QUEUE(^{
        self.temperatureLabel.text = [self NSStringFromTemperature:temperature celsius:YES];
    });
}


#pragma mark - Internal API

-(NSString *)NSStringFromTemperature:(float)temperature celsius:(BOOL)celsius
{
    unichar degreesSymbol = (unichar)(celsius ? kDegreesCelsius : kDegreesFahrenheit);
    return [NSString stringWithFormat:@"%3.2f%C", temperature, degreesSymbol];
}

@end
