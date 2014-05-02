//
//  SensorTag.m
//  WeatherTag
//
//  Created by Keith Ermel on 3/23/14.
//  Copyright (c) 2014 Keith Ermel. All rights reserved.
//

#import "SensorTag.h"
#import "BarometerSensor.h"
#import "Luokat/NSString+Utils.h"


NSString *const kTemperature            = @"temperature";
NSString *const kHumidity               = @"humidity";
NSString *const kBarometer              = @"barometer";

NSString *const kTemperatureData        = @"temperature.data";
NSString *const kHumidityData           = @"humidity.data";
NSString *const kBarometerData          = @"barometer.data";

NSString *const kTemperatureServiceUUID = @"F000AA00-0451-4000-B000-000000000000";
NSString *const kHumidityServiceUUID    = @"F000AA20-0451-4000-B000-000000000000";
NSString *const kBarometerServiceUUID   = @"F000AA40-0451-4000-B000-000000000000";

NSString *const kTemperatureConfigUUID  = @"F000AA02-0451-4000-B000-000000000000";
NSString *const kHumidityConfigUUID     = @"F000AA22-0451-4000-B000-000000000000";
NSString *const kBarometerConfigUUID    = @"F000AA42-0451-4000-B000-000000000000";

NSString *const kTemperatureDataUUID    = @"F000AA01-0451-4000-B000-000000000000";
NSString *const kHumidityDataUUID       = @"F000AA21-0451-4000-B000-000000000000";
NSString *const kBarometerDataUUID      = @"F000AA41-0451-4000-B000-000000000000";

NSString *const kBarometerCalibrationUUID   = @"F000AA43-0451-4000-B000-000000000000";

typedef void(^SensorTagDataHandler)(CBCharacteristic *characteristic);


@interface SensorTag ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (strong, readonly) CBCentralManager *centralManager;
@property (strong, readonly) NSMutableArray *peripherals;
@property (strong, readonly) NSArray *scannedServices;
@property (strong, readonly) BarometerSensor *barometerSensor;

// TODO: Combine these two; use inner dictionary to hold name & configUUID values
@property (strong, readonly) NSDictionary *serviceNameMap;
@property (strong, readonly) NSDictionary *configCharacteristicMap;

@property (strong, readonly) NSDictionary *characteristicNameMap;
@property (strong, readonly) NSDictionary *dataHandlersMap;

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
    NSLog(@"didDiscoverCharacteristicsForService: %@\n%@",
          [self nameForService:service],
          service.characteristics);
    
    if ([self isBarometerService:service]) {
        [self configureBarometer:peripheral service:service];
    }
    else {
        for (CBCharacteristic *characteristic in service.characteristics) {
            [self logCharacteristic:characteristic];
            
            if ([self characteristicCanNotify:characteristic]) {
                [self configurePeripheral:peripheral forService:service value:0x01];
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
    
}

-(void)configureBarometer:(CBPeripheral *)peripheral service:(CBService *)service
{
    for (CBCharacteristic *characteristic in service.characteristics) {
        [self logCharacteristic:characteristic];
        
        if ([self isBarometerConfigCharacteristic:characteristic]) {
            uint8_t value = 0x02;
            NSData *data = [NSData dataWithBytes:&value length:1];
            [peripheral writeValue:data
                 forCharacteristic:characteristic
                              type:CBCharacteristicWriteWithResponse];
        }
        else if ([self isBarometerCalibrationCharacteristic:characteristic]) {
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
}

-(BOOL)isBarometerService:(CBService *)service
{
    NSString *name = [self nameForService:service];
    return [name isEqualToString:kBarometer];
}

-(BOOL)isBarometerConfigCharacteristic:(CBCharacteristic *)characteristic
{
    NSString *uuidString = characteristic.UUID.UUIDString;
    return [uuidString isEqualToString:kBarometerConfigUUID];
}

-(BOOL)isBarometerCalibrationCharacteristic:(CBCharacteristic *)characteristic
{
    NSString *uuidString = characteristic.UUID.UUIDString;
    return [uuidString isEqualToString:kBarometerCalibrationUUID];
}

-(BOOL)isBarometerDataCharacteristic:(CBCharacteristic *)characteristic
{
    NSString *uuidString = characteristic.UUID.UUIDString;
    return [uuidString isEqualToString:kBarometerDataUUID];
}


              -(void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                          error:(NSError *)error
{
    NSLog(@"didUpdateValueForCharacteristic: %@", [self characteristicNameForCharacteristic:characteristic]);
    NSLog(@"  %ld bytes", (unsigned long)characteristic.value.length);
    
    if ([self isBarometerCalibrationCharacteristic:characteristic]) {
        [self configureBarometerSensorWithCalibrationData:characteristic.value];

        for (CBService *service in peripheral.services) {
            NSLog(@"service: %@", service);
            
            for (CBCharacteristic *serviceCharacteristic in service.characteristics) {
                if ([self isBarometerConfigCharacteristic:serviceCharacteristic]) {
                    [self configurePeripheral:peripheral forService:service value:0x01];
                }
                else if ([self isBarometerDataCharacteristic:serviceCharacteristic]) {
                    [peripheral setNotifyValue:YES forCharacteristic:serviceCharacteristic];
                }
            }
        }
    }
    
    SensorTagDataHandler handler = [self dataHandlerForCharacteristic:characteristic];
    if (handler) {
        handler(characteristic);
    }
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

-(NSString *)nameForService:(CBService *)service
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

-(CBCharacteristic *)configCharacteristicForService:(CBService *)service
{
    return [self characteristicForUUID:[self.configCharacteristicMap objectForKey:service.UUID.UUIDString]
                            forService:service];
}

-(void)configurePeripheral:(CBPeripheral *)peripheral
                forService:(CBService *)service
                     value:(uint8_t)value
{
    CBCharacteristic *config = [self configCharacteristicForService:service];
    if (config) {
        NSData *data = [NSData dataWithBytes:&value length:1];
        [peripheral writeValue:data
             forCharacteristic:config
                          type:CBCharacteristicWriteWithResponse];
    }
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

-(SensorTagDataHandler)dataHandlerForCharacteristic:(CBCharacteristic *)characteristic
{
    return [self.dataHandlersMap objectForKey:characteristic.UUID.UUIDString];
}


#pragma mark - Temperature Data

-(void)processTemperatureData:(CBCharacteristic *)characteristic
{
    float temperature = [self temperatureFromData:characteristic.value];
    [self.delegate didReadTemperature:temperature];
}

-(float)temperatureFromData:(NSData *)data {
    char buffer[data.length];
    [data getBytes:&buffer length:data.length];
    
    int16_t temperature = ((buffer[2] & 0xff)| ((buffer[3] << 8) & 0xff00));
    return (float)((float)temperature / (float)128);
}


#pragma mark - Humidity Data

-(void)processHumidityData:(CBCharacteristic *)characteristic
{
    float humidityRH = [self pressureFromData:characteristic.value];
    [self.delegate didReadHumidity:humidityRH];
}

-(float)pressureFromData:(NSData *)data
{
    char buffer[data.length];
    [data getBytes:&buffer length:data.length];
    
    UInt16 humidity = (buffer[2] & 0xff) | ((buffer[3] << 8) & 0xff00);
    return -6.0f + 125.0f * (float)((float)humidity/(float)65535);;
}


#pragma mark - Barometer Data

-(void)processBarometerData:(CBCharacteristic *)characteristic
{
    int pressure = [self.barometerSensor calculatePressureFromData:characteristic.value];
    [self.delegate didReadPressure:pressure];
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

-(void)configureBarometerSensorWithCalibrationData:(NSData *)calibrationData
{
    _barometerSensor = [[BarometerSensor alloc] initWithCalibrationData:calibrationData];
}

-(void)configureDataStructures
{
    _scannedServices = @[[CBUUID UUIDWithString:kTemperatureServiceUUID],
                         [CBUUID UUIDWithString:kHumidityServiceUUID],
                         [CBUUID UUIDWithString:kBarometerServiceUUID]];
    
    _serviceNameMap = @{kTemperatureServiceUUID: kTemperature,
                        kHumidityServiceUUID: kHumidity,
                        kBarometerServiceUUID: kBarometer};
    
    _characteristicNameMap = @{kTemperatureDataUUID: kTemperatureData,
                               kHumidityDataUUID: kHumidityData,
                               kBarometerDataUUID: kBarometerData};
    
    _configCharacteristicMap = @{kTemperatureServiceUUID: kTemperatureConfigUUID,
                                 kHumidityServiceUUID: kHumidityConfigUUID,
                                 kBarometerServiceUUID: kBarometerConfigUUID};
    
    _dataHandlersMap = @{kTemperatureDataUUID: ^(CBCharacteristic *c) {[self processTemperatureData:c];},
                         kHumidityDataUUID: ^(CBCharacteristic *c) {[self processHumidityData:c];},
                         kBarometerDataUUID: ^(CBCharacteristic *c) {[self processBarometerData:c];}};
}

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {[self configureSensorTag];}
    return self;
}
@end
