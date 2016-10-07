//
//  BTCCameraViewController.m
//  BTCWallet
//
//  Created by Admin on 8/16/16.
//

#import "BTCCameraViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface BTCCameraViewController ()<AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (strong, nonatomic) IBOutlet UIView *cameraView;
@property (strong, nonatomic) IBOutlet UIButton *flashButton;
@property (strong, nonatomic) IBOutlet UIImageView *indicator;
@end

@implementation BTCCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.flashButton.hidden = !device.hasTorch;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied) {
        [[[UIAlertView alloc]
          initWithTitle:[NSString stringWithFormat:@"%@ is not allowed to access the camera",
                         NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"]]
          message:[NSString stringWithFormat:@"\nallow camera access in\n"
                                                               "Settings->Privacy->Camera->%@",
                   NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"]] delegate:nil
          cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
        return;
    }
    
    NSError *error = nil;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    AVCaptureMetadataOutput *output = [AVCaptureMetadataOutput new];
    
    if (error) NSLog(@"%@", error.localizedDescription);
    
    if ([device lockForConfiguration:&error]) {
        if (device.isAutoFocusRangeRestrictionSupported) {
            device.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
        }
        
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        
        [device unlockForConfiguration];
    }
    
    self.session = [AVCaptureSession new];
    if (input) [self.session addInput:input];
    [self.session addOutput:output];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
        output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    }
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.frame = [UIScreen mainScreen].bounds;
    [self.cameraView.layer addSublayer:self.previewLayer];
    
    dispatch_async(dispatch_queue_create("qrscanner", NULL), ^{
        [self.session startRunning];
    });
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
     self.previewLayer.frame = self.cameraView.layer.bounds;
     [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.session stopRunning];
    self.session = nil;
    [self.previewLayer removeFromSuperlayer];
    self.previewLayer = nil;
    
    [super viewDidDisappear:animated];
}

- (void)stop
{
    [self.session removeOutput:self.session.outputs.firstObject];
}

- (void)scanDone{
    _indicator.image = [UIImage imageNamed:@"cameraguide-green"];
    [self stop];
    [self scanDone:nil];
}

- (IBAction)scanDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)flash:(id)sender {
    NSError *error = nil;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([device lockForConfiguration:&error]) {
        device.torchMode = (device.torchActive) ? AVCaptureTorchModeOff : AVCaptureTorchModeOn;
        [device unlockForConfiguration];
    }
}

- (void)errorScan{
    _indicator.image = [UIImage imageNamed:@"cameraguide-red"];
    NSLog(@"error scan");
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    for (AVMetadataMachineReadableCodeObject *codeObject in metadataObjects) {
        if (! [codeObject.type isEqual:AVMetadataObjectTypeQRCode]) continue;
        NSString *addr = [codeObject.stringValue stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        [self.delegate camera:self didScanAddress:addr];
    }
}




@end
