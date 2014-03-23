//
//  SensorTag.h
//  WeatherTag
//
//  Created by Keith Ermel on 3/23/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreBluetooth;


@protocol SensorTagDelegate <NSObject>
-(void)didDiscoverSensorTag;
-(void)didConnectToSensorTag;
-(void)didDisconnectFromSensorTag;
-(void)didReadTemperature:(float)temperature;
-(void)didReadHumidity:(float)humidityRH;
-(void)didReadPressure:(int)pressure;
@end


@interface SensorTag : NSObject
@property (weak) id<SensorTagDelegate> delegate;
@end
