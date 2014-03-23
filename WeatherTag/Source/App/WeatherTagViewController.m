//
//  WeatherTagViewController.m
//  WeatherTag
//
//  Created by Keith Ermel on 3/22/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import "WeatherTagViewController.h"

#import "SensorTag.h"
#import "WeatherDisplayViewController.h"
#import "GCDTools.h"
#import "UIStoryboardSegue+Utils.h"


NSString *const kWeatherDisplaySegue    = @"weatherDisplaySegue";


@interface WeatherTagViewController ()<SensorTagDelegate>
@property (strong, nonatomic, readonly) WeatherDisplayViewController *weatherDisplayVC;
@property (strong, readonly) SensorTag *sensorTag;
// Outlets
@property (weak, nonatomic) IBOutlet UILabel *sensorTagLabel;
@property (weak, nonatomic) IBOutlet UIView *weatherDisplayView;
@end


@implementation WeatherTagViewController


#pragma mark - SensorTagDelegate

-(void)didDiscoverSensorTag
{
    [self updateSensorTagLabel:@"Discovered"];
}

-(void)didConnectToSensorTag
{
    [self updateSensorTagLabel:@"Connected"];
}

-(void)didDisconnectFromSensorTag
{
    [self updateSensorTagLabel:@"Disconnected"];
}

-(void)didReadTemperature:(float)temperature
{
    if (self.weatherDisplayView.hidden) {[self showWeatherDisplay];}
    [self.weatherDisplayVC updateTemperatureValue:temperature];
}

-(void)didReadHumidity:(float)humidityRH
{
    [self.weatherDisplayVC updateHumidityValue:humidityRH];
}

-(void)didReadPressure:(int)pressure
{
    [self.weatherDisplayVC updateBarometerValue:pressure];
}


#pragma mark - Internal API

-(void)updateSensorTagLabel:(NSString *)message
{
    GCD_ON_MAIN_QUEUE(^{self.sensorTagLabel.text = message;});
}

-(void)showWeatherDisplay
{
    GCD_ON_MAIN_QUEUE(^{self.weatherDisplayView.hidden = NO;});
}


#pragma mark - Configuration

-(void)configureWeatherDisplay:(UIStoryboardSegue *)segue
{
    _weatherDisplayVC = (WeatherDisplayViewController *)segue.destinationViewController;
}

-(void)configureSensorTag
{
    _sensorTag = [[SensorTag alloc] init];
    self.sensorTag.delegate = self;
}


#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue isNamed:kWeatherDisplaySegue]) {[self configureWeatherDisplay:segue];}
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureSensorTag];
    self.sensorTagLabel.text = @"Not Connected";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // TODO: Dispose of any resources that can be recreated.
}

@end
