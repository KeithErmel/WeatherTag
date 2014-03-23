//
//  SensorTag.m
//  WeatherTag
//
//  Created by Keith Ermel on 3/23/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import "SensorTag.h"
#import "NSString+Util.h"

NSString *const kTemperature            = @"temperature";
NSString *const kHumidity               = @"humidity";
NSString *const kBarometer              = @"barometer";

NSString *const kTemperatureData        = @"temperature.data";

NSString *const kTemperatureServiceUUID = @"F000AA00-0451-4000-B000-000000000000";
NSString *const kHumidityServiceUUID    = @"F000AA20-0451-4000-B000-000000000000";
NSString *const kBarometerServiceUUID   = @"F000AA40-0451-4000-B000-000000000000";

NSString *const kTemperatureConfigUUID  = @"F000AA02-0451-4000-B000-000000000000";

NSString *const kTemperatureDataUUID    = @"F000AA01-0451-4000-B000-000000000000";
//NSString *const kHumidityDataUUID       = @"";
//NSString *const kBarometerDataUUID      = @"";


@interface SensorTag ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (strong, readonly) CBCentralManager *centralManager;
@property (strong, readonly) NSMutableArray *peripherals;
@property (strong, readonly) NSArray *scannedServices;

// TODO: Combine these two; use inner dictionary to hold name & configUUID values
@property (strong, readonly) NSDictionary *serviceNameMap;
@property (strong, readonly) NSDictionary *configCharacteristicMap;

@property (strong, readonly) NSDictionary *characteristicNameMap;
@end


@implementation SensorTag

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"central ON");
        [self startScanningForPeripherals];
    }
    else if (central.state == CBCentralManagerStatePoweredOff) {
        NSLog(@"central OFF");
        [self stopScanningForPeripherals];
    }
}

-(void)centralManager:(CBCentralManager *)central
didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary *)advertisementData
                 RSSI:(NSNumber *)RSSI
{
    if ([peripheral.name isEqualToString:@"TI BLE Sensor Tag"]) {
        NSLog(@"didDiscoverPeripheral: %@", peripheral.name ? peripheral.name : @"(unknown)");
        NSLog(@"       SensorTag: %@", peripheral);
        NSLog(@"peripheral.state: %d", (int)peripheral.state);
        [self.delegate didDiscoverSensorTag];
        
        if (peripheral.state == CBPeripheralStateDisconnected) {
            [self.peripherals addObject:peripheral];
            [central connectPeripheral:peripheral options:nil];
        }
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"--> connected to peripheral: %@", peripheral.name);
    [self.delegate didConnectToSensorTag];
    peripheral.delegate = self;
    
    [peripheral discoverServices:self.scannedServices];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"<-- disconnected from: %@ [%@]", peripheral.name, error);
    [self.delegate didDisconnectFromSensorTag];
}


#pragma mark - CBPeripheralDelegate

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"peripheral.services: %@", peripheral.services);
    for (CBService *service in peripheral.services) {
        NSLog(@"    service: %@", service.UUID.UUIDString);
        [peripheral discoverCharacteristics:nil forService:service];
    }
    NSLog(@"");
}

-(void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
            error:(NSError *)error
{
    NSLog(@"didDiscoverCharacteristicsForService: %@", [self serviceNameForService:service]);
    CBCharacteristic *config = [self characteristicForUUID:kTemperatureConfigUUID forService:service];
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        [self logCharacteristic:characteristic];
        
        if ([self characteristicCanNotify:characteristic]) {
            [self configurSensorTag:peripheral characteristic:config enabled:YES];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

              -(void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                          error:(NSError *)error
{
    NSLog(@"didUpdateValueForCharacteristic: %@",
          [self characteristicNameForCharacteristic:characteristic]);
    NSLog(@"  %ld bytes", (unsigned long)characteristic.value.length);
    
    if ([self isTemperatureCharacteristic:characteristic]) {
        float temperature = [self temperatureFromData:characteristic.value];
        [self.delegate didReadTemperature:temperature];
    }
}

-(BOOL)isTemperatureCharacteristic:(CBCharacteristic *)characteristic
{
    return [self.characteristicNameMap objectForKey:characteristic.UUID.UUIDString] != nil;
}

-(void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
            error:(NSError *)error
{
    NSLog(@"didWriteValueForCharacteristic: %@\n  error: %@", characteristic.UUID.UUIDString, error);
}


#pragma mark - Internal API

-(void)startScanningForPeripherals
{
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}

-(void)stopScanningForPeripherals
{
    [self.centralManager stopScan];
}

-(NSString *)serviceNameForService:(CBService *)service
{
    return [self.serviceNameMap objectForKey:service.UUID.UUIDString];
}

-(CBCharacteristic *)characteristicForUUID:(NSString *)uuidString forService:(CBService *)service
{
    CBCharacteristic *result;
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID.UUIDString isEqualToString:uuidString]) {
            result = characteristic;
            break;
        }
    }
    return result;
}

-(BOOL)characteristicCanNotify:(CBCharacteristic *)characteristic
{
    return characteristic.properties & CBCharacteristicPropertyNotify;
}

-(void)configurSensorTag:(CBPeripheral *)peripheral
          characteristic:(CBCharacteristic *)characteristic
                 enabled:(BOOL)enabled
{
    uint8_t bytes = enabled ? 0x01 : 0x00;
    NSData *data = [NSData dataWithBytes:&bytes length:1];
    [peripheral writeValue:data
         forCharacteristic:characteristic
                      type:CBCharacteristicWriteWithResponse];
}

-(void)logCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"characteristic properties: 0x%lx [%@] (%@)",
          (unsigned long)characteristic.properties,
          NSStringFromBOOL([self characteristicCanNotify:characteristic]),
          characteristic.UUID.UUIDString);
}

-(NSString *)characteristicNameForCharacteristic:(CBCharacteristic *)characteristic
{
    return [self.characteristicNameMap objectForKey:characteristic.UUID.UUIDString];
}

-(float)temperatureFromData:(NSData *)data {
    char scratchVal[data.length];
    int16_t ambTemp;
    [data getBytes:&scratchVal length:data.length];
    ambTemp = ((scratchVal[2] & 0xff)| ((scratchVal[3] << 8) & 0xff00));
    
    return (float)((float)ambTemp / (float)128);
}


#pragma mark - Configuration

-(void)configureSensorTag
{
    [self configureBluetooth];
    [self configureDataStructures];
}

-(void)configureBluetooth
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
    _peripherals = [[NSMutableArray alloc] init];
    
}

-(void)configureDataStructures
{
    _scannedServices = @[[CBUUID UUIDWithString:kTemperatureServiceUUID]/*,
                                                                         [CBUUID UUIDWithString:kHumidityServiceUUID],
                                                                         [CBUUID UUIDWithString:kBarometerServiceUUID]*/];
    
    _serviceNameMap = @{kTemperatureServiceUUID: kTemperature/*,
                                                              kHumidityServiceUUID: kHumidityKey,
                                                              kBarometerServiceUUID: kBarometerKey*/};
    _characteristicNameMap = @{kTemperatureDataUUID: kTemperatureData};
    
    _configCharacteristicMap = @{kTemperatureServiceUUID: kTemperatureConfigUUID};
}

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {[self configureSensorTag];}
    return self;
}
@end
