//
//  TemperatureSensor.m
//  WeatherTag
//
//  Created by Keith Ermel on 3/23/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import "TemperatureSensor.h"

NSString *const kTemperatureSensorConfigUUID    = @"F000AA02-0451-4000-B000-000000000000";


@implementation TemperatureSensor

#pragma mark - SensorTagSensor

-(void)didDiscoverNotifyCharacteristic:(CBCharacteristic *)characteristic
                            forService:(CBService *)service
                        withPeripheral:(CBPeripheral *)peripheral
{
//    [self configureSensor:self forService:service withPeripheral:peripheral value:0x01];
}

-(NSString *const)configUUIDString{return kTemperatureSensorConfigUUID;}

#pragma mark - Initialization

-(id)init
{
    self = [super init];
    
    if (self) {
    }
    
    return self;
}

@end
