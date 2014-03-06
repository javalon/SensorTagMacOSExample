
#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>
#import "MyOpenGLView.h"

@interface SensorTagMonitorAppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>
{
    NSWindow *window;
    NSWindow *scanSheet;
    NSView *heartView;
    NSTimer *pulseTimer;
    NSArrayController *arrayController;
    
    CBCentralManager *manager;
    CBPeripheral *peripheral;
    
    NSMutableArray *heartRateMonitors;
    
    NSString *manufacturer;
    NSString *UIIDDevice;
    
    uint16_t heartRate;
    
    int updateACCL;
    
    IBOutlet NSButton* connectButton;
    BOOL autoConnect;
    
    // Progress Indicator
    IBOutlet NSButton * indicatorButton;
    IBOutlet NSProgressIndicator *progressIndicator;
    
    IBOutlet NSTextField *lblTmp;
    IBOutlet NSTextField *lblUIID;
    IBOutlet NSTextField *lblIRTmp;
    IBOutlet NSTextField *lblX;
    IBOutlet NSTextField *lblY;
    IBOutlet NSTextField *lblZ;
    IBOutlet MyOpenGLView *viewOGL;
    IBOutlet NSButton *btnCalib;
    
    float coordX;
    float coordY;
    float coordZ;
    
    float valX ;
    float valY ;
    float valZ ;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *scanSheet;
@property (assign) IBOutlet NSArrayController *arrayController;

@property (assign) uint16_t heartRate;
@property (retain) NSTimer *pulseTimer;
@property (retain) NSMutableArray *heartRateMonitors;
@property (copy) NSString *manufacturer;
@property (copy) NSString *UIIDDevice;
@property (copy) NSString *connected;

@property (assign) IBOutlet NSTextField *lblX;
@property (assign) IBOutlet NSTextField *lblY;
@property (assign) IBOutlet NSTextField *lblZ;
@property (assign) IBOutlet NSTextField *lblTmp;
@property (assign) IBOutlet NSTextField *lblUIID;
@property (assign) IBOutlet NSTextField *lblIRTmp;
@property (assign) IBOutlet MyOpenGLView *viewOGL;
@property (assign) IBOutlet NSButton *btnCalib;



- (IBAction) openScanSheet:(id) sender;
- (IBAction) closeScanSheet:(id)sender;
- (IBAction) cancelScanSheet:(id)sender;
- (IBAction) connectButtonPressed:(id)sender;
- (IBAction) btnCalibPressed:(id)sender;
- (IBAction) btnResetPressed:(id)sender;

- (void) startScan;
- (void) stopScan;
- (BOOL) isLECapableHardware;

- (void) updateWithHRMData:(NSData *)data;
- (void) updateWithACCLData:(NSData *)data;


@end
