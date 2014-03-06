/*
     File: HeartRateMonitorAppDelegate.m
 Abstract: Implementatin of Heart Rate Monitor app using Bluetooth Low Energy (LE) Heart Rate Service. This app demonstrats the use of CoreBluetooth APIs for LE devices.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "SensorTagMonitorAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "Sensors.h"

@implementation SensorTagMonitorAppDelegate

@synthesize window;
@synthesize heartRate;
@synthesize pulseTimer;
@synthesize scanSheet;
@synthesize heartRateMonitors;
@synthesize arrayController;
@synthesize manufacturer;
@synthesize connected;
@synthesize lblTmp;
@synthesize lblIRTmp;
@synthesize lblUIID;
@synthesize UIIDDevice;
@synthesize lblX;
@synthesize lblY;
@synthesize lblZ;
@synthesize btnCalib;
@synthesize viewOGL;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    /* autoConnect = TRUE; */  /* uncomment this line if you want to automatically connect to previosly known peripheral */
    
    coordX=0.0;
    coordY=0.0;
    coordZ=0.0;
    
    self.heartRateMonitors = [NSMutableArray array];
    
    updateACCL=0;
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    if( autoConnect )
    {
        [self startScan];
    }
}


- (void) dealloc
{
    [self stopScan];
    
    [peripheral setDelegate:nil];
    [peripheral release];
    
    [heartRateMonitors release];
        
    [manager release];
    
    [super dealloc];
}

/* 
 Disconnect peripheral when application terminate 
*/
- (void) applicationWillTerminate:(NSNotification *)notification
{
    if(peripheral)
    {
        [manager cancelPeripheralConnection:peripheral];
    }
}

#pragma mark - Scan sheet methods

/* 
 Open scan sheet to discover heart rate peripherals if it is LE capable hardware 
*/
- (IBAction)openScanSheet:(id)sender 
{
    if( [self isLECapableHardware] )
    {
        autoConnect = FALSE;
        [arrayController removeObjects:heartRateMonitors];
        [NSApp beginSheet:self.scanSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
        [self startScan];
    }
}

/*
 Close scan sheet once device is selected
*/
- (IBAction)closeScanSheet:(id)sender 
{
    [NSApp endSheet:self.scanSheet returnCode:NSAlertDefaultReturn];
    [self.scanSheet orderOut:self];    
}

/*
 Close scan sheet without choosing any device
*/
- (IBAction)cancelScanSheet:(id)sender 
{
    [NSApp endSheet:self.scanSheet returnCode:NSAlertAlternateReturn];
    [self.scanSheet orderOut:self];
}

/* 
 This method is called when Scan sheet is closed. Initiate connection to selected heart rate peripheral
*/
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo 
{
    [self stopScan];
    if( returnCode == NSAlertDefaultReturn )
    {
        NSIndexSet *indexes = [self.arrayController selectionIndexes];
        if ([indexes count] != 0) 
        {
            NSUInteger anIndex = [indexes firstIndex];
            peripheral = [self.heartRateMonitors objectAtIndex:anIndex];
            [peripheral retain];
            [indicatorButton setHidden:FALSE];
            [progressIndicator setHidden:FALSE];
            [progressIndicator startAnimation:self];
            [connectButton setTitle:@"Cancel"];
            [manager connectPeripheral:peripheral options:nil];
        }
    }
}

#pragma mark - Connect Button

/*
 This method is called when connect button pressed and it takes appropriate actions depending on device connection state
 */
- (IBAction)connectButtonPressed:(id)sender
{
    if(peripheral && ([peripheral isConnected]))
    { 
        /* Disconnect if it's already connected */
        [manager cancelPeripheralConnection:peripheral]; 
    }
    else if (peripheral)
    {
        /* Device is not connected, cancel pendig connection */
        [indicatorButton setHidden:TRUE];
        [progressIndicator setHidden:TRUE];
        [progressIndicator stopAnimation:self];
        [connectButton setTitle:@"Connect"];
        [manager cancelPeripheralConnection:peripheral];
        [self openScanSheet:nil];
    }
    else
    {   /* No outstanding connection, open scan sheet */
        [self openScanSheet:nil];
    }
}

#pragma mark - Heart Rate Data

/* 
 Update UI with heart rate data received from device
 */
- (void) updateWithHRMData:(NSData *)data 
{
    float ambTemp = [sensorTMP006 calcTAmb:data];
    [lblTmp setStringValue:[NSString stringWithFormat:@"%.1f°C",ambTemp]];
    
    float irTemp = [sensorTMP006 calcTObj:data];
    [lblIRTmp setStringValue:[NSString stringWithFormat:@"%.1fºC",irTemp]];
}

-(void) updateWithACCLData:(NSData *)data
{
    valX = [sensorKXTJ9 calcXValue:data] ;
    valY = [sensorKXTJ9 calcYValue:data] ;
    valZ = [sensorKXTJ9 calcZValue:data];
    
    NSString *accValueX = [NSString stringWithFormat:@"X: % 0.1f", valX - coordX];
    NSString *accValueY = [NSString stringWithFormat:@"Y: % 0.1f", valY - coordY];
    NSString *accValueZ = [NSString stringWithFormat:@"Z: % 0.1f", valZ - coordZ];
    
    [self.lblX setStringValue:accValueX];
    [self.lblY setStringValue:accValueY];
    [self.lblZ setStringValue:accValueZ];
    
    [viewOGL rotate:valX - coordX rotaY:valY- coordY rotaZ:valZ  - coordZ];
    //  NSLog(@"%@, %@, %@", accValueX, accValueY, accValueZ);
}

- (IBAction) btnCalibPressed:(id)sender
{
    coordX=valX;
    coordY=valY;
    coordZ=valZ;
}


- (IBAction)btnResetPressed:(id)sender {
    coordZ=0.0;
    coordY=0.0;
    coordX=0.0;
}

#pragma mark - Start/Stop Scan methods

/*
 Uses CBCentralManager to check whether the current platform/hardware supports Bluetooth LE. An alert is raised if Bluetooth LE is not enabled or is not supported.
 */
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([manager state]) 
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
    
    [self cancelScanSheet:nil];
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[[NSImage alloc] initWithContentsOfFile:@"AppIcon"] autorelease]];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    return FALSE;
}

/*
 Request CBCentralManager to scan for heart rate peripherals using service UUID 0x180D
 */
- (void) startScan 
{
    [manager scanForPeripheralsWithServices:nil options:nil];
}

/*
 Request CBCentralManager to stop scanning for heart rate peripherals
 */
- (void) stopScan 
{
    [manager stopScan];
}

#pragma mark - CBCentralManager delegate methods
/*
 Invoked whenever the central manager's state is updated.
 */
- (void) centralManagerDidUpdateState:(CBCentralManager *)central 
{
    [self isLECapableHardware];
}
    
/*
 Invoked when the central discovers heart rate peripheral while scanning.
 */
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI 
{    
    NSMutableArray *peripherals = [self mutableArrayValueForKey:@"heartRateMonitors"];
    if( ![self.heartRateMonitors containsObject:aPeripheral] ){
        [peripherals addObject:aPeripheral];
        NSLog(@"%@", aPeripheral);
    }
    
    /* Retreive already known devices */
    if(autoConnect)
    {
        [manager retrievePeripherals:[NSArray arrayWithObject:(id)aPeripheral.UUID]];
    }
}

/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %lu - %@", [peripherals count], peripherals);
    
    [self stopScan];
    
    /* If there are any known devices, automatically connect to it.*/
    if([peripherals count] >=1)
    {
        [indicatorButton setHidden:FALSE];
        [progressIndicator setHidden:FALSE];
        [progressIndicator startAnimation:self];
        peripheral = [peripherals objectAtIndex:0];
        [peripheral retain];
        [connectButton setTitle:@"Cancel"];
        [manager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    }
}

/*
 Invoked whenever a connection is succesfully created with the peripheral. 
 Discover available services on the peripheral
 */
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral 
{    
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
	
	self.connected = @"Connected";
    [connectButton setTitle:@"Disconnect"];
    [indicatorButton setHidden:TRUE];
    [progressIndicator setHidden:TRUE];
    [progressIndicator stopAnimation:self];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down. 
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
	self.connected = @"Not connected";
    [connectButton setTitle:@"Connect"];
    self.manufacturer = @"";
    self.heartRate = 0;
    if( peripheral )
    {
        [peripheral setDelegate:nil];
        [peripheral release];
        peripheral = nil;
    }
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
    [connectButton setTitle:@"Connect"]; 
    if( peripheral )
    {
        [peripheral setDelegate:nil];
        [peripheral release];
        peripheral = nil;
    }
}

#pragma mark - CBPeripheral delegate methods
/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error 
{
    for (CBService *aService in aPeripheral.services) 
    {
        NSLog(@"Service found with UUID: %@", aService.UUID);
        
        /* Sensor de temperatura */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"f000aa00-0451-4000 b0000000-00000000"]])
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* Accelerometer */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"f000aa10-0451-4000 b0000000-00000000"]]) {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* Device Information Service */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"180A"]]) 
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* GAP (Generic Access Profile) for Device Name */
        if ( [aService.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error 
{    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"f000aa00-0451-4000 b0000000-00000000"]]) 
    {
        for (CBCharacteristic *aChar in service.characteristics) 
        {
            /* Set notification and data temperature measurement */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"f000aa01-0451-4000 b0000000-00000000"]]) 
            {
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found a Temperature Measurement Characteristic");
            }
            
            /* Write temperature control point */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"f000aa02-0451-4000 b0000000-00000000"]])
            {
                uint8_t val = 1;
                NSData* valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
                [aPeripheral writeValue:valData forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];
            }
            
        }
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"f000aa10-0451-4000 b0000000-00000000"]])
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Set notification and accelerometer measurement */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"f000aa11-0451-4000 b0000000-00000000"]])
            {
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found a Accelerometer Characteristic");
            }
            
            /* Write accelerometer control point */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"f000aa12-0451-4000 b0000000-00000000"]])
            {
                uint8_t val = 1;
                NSData* valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
                [aPeripheral writeValue:valData forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];
            }
            /* Write accelerometer period */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"f000aa13-0451-4000 b0000000-00000000"]])
            {
                // Period = [Input*10]ms
                uint8_t val = 1; // 500ms
                NSData* valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
                [aPeripheral writeValue:valData forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];
            }
        }
    }
    
    if ( [service.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
    {
        for (CBCharacteristic *aChar in service.characteristics) 
        {
            /* Read device name */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]]) 
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Name Characteristic");
            }
        }
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180A"]]) 
    {
        for (CBCharacteristic *aChar in service.characteristics) 
        {
            /* Read manufacturer name */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]]) 
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Manufacturer Name Characteristic");
            }
    
            /* Read UIID device */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A23"]])
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Encontrado UIID");
            }
    
        }
    }
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error 
{
    /* Updated value for temperature rate measurement received */
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"f000aa01-0451-4000 b0000000-00000000"]]) 
    {
        if( (characteristic.value)  || !error )
        {
            /* Update UI with temperature rate data */
            [self updateWithHRMData:characteristic.value];
        }
    }
    /* Update value for accelerometer rate measurement received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"F000AA11-0451-4000 b0000000-00000000"]]){
        if((characteristic.value) || !error)
        {
            /* Update UI with acelerometer rate data */
            [self updateWithACCLData:characteristic.value];
        }
    }
    /* Value for device Name received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]])
    {
        NSString * deviceName = [[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"Device Name = %@", deviceName);
    } 
    /* Value for manufacturer name received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]]) 
    {
        self.manufacturer = [[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"Manufacturer Name = %@", self.manufacturer);
    }
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A23"]])
    {
       //2A25 // self.UIIDDevice = [[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] autorelease];
        
        self.UIIDDevice = [[[NSString alloc] initWithFormat:@"%@", [characteristic.value subdataWithRange:NSMakeRange(0, 8)]] autorelease];

        [self.lblUIID setStringValue:self.UIIDDevice];
        NSLog(@"UIID = %@", self.UIIDDevice);
        
    }
}

@end
