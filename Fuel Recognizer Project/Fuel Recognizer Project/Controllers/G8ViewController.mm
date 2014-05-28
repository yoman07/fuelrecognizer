//
//  G8ViewController.m
//  Template Framework Project
//
//  Created by Daniele on 14/10/13.
//  Copyright (c) 2013 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "G8ViewController.h"
#import <TesseractOCR/TesseractOCR.h>
#import "ImageProcessingImplementation.h"
#import "UIImage+operation.h"
#import "ImageFilter.h"
#import "UIImage+FixOrientation.h"
#import "ReceiptModel.h"
#import "RBResearchMainClass.h"
#import <opencv2/highgui/cap_ios.h>
#import "ImageProcessor.h"
#import "UIImage+OpenCV.h"
#import "NSArray+Combinatory.h"
#import "UIImage+Tesseract.h"
#import "RBFuelEntity.h"
#import "AppDelegate.h"
#import "ReceiptObject.h"

using namespace cv;
#define kWhiteList @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-.,ÓŁ:*%#\\"

@interface G8ViewController ()<CvVideoCameraDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate> {
    id <ImageProcessingProtocol> imageProcessor;
}

@property (weak, nonatomic) IBOutlet UITextField *dashboardTextField;
@property (weak, nonatomic) IBOutlet UITextField *priceTextField;
@property (weak, nonatomic) IBOutlet UITextField *amountTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;

@property (nonatomic, retain) CvVideoCamera* receiptVideoCamera;
@property (nonatomic, retain) CvVideoCamera* dashboardVideoCamera;
@property (nonatomic, retain) CvVideoCamera* currentCamera;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet UIButton *receiptActionButton;
@property (weak, nonatomic) IBOutlet UIButton *dashboardActionButton;

@property (weak, nonatomic) IBOutlet UIImageView *dashboardImageView;

@property (nonatomic) BOOL stopCamera;
@property (nonatomic, strong) UIImage *processedImage;

@property (strong, nonatomic) UIImageView *currentImageView;
@property (weak, nonatomic) IBOutlet UIImageView *resultImageView;
@property (nonatomic,strong) UITextChecker *textChecker;
@property (nonatomic, strong) NSTimer *ocrTimer;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) Tesseract* tesseract;
@property (nonatomic, strong) RBResearchMainClass *researchMainClass;
@end

@implementation G8ViewController

/****README****/
/*
 tessdata group is linked into the template project, from the main project.
 TesseractOCR.framework is linked into the template project under the Framework group. It's builded by the main project.
 
 If you are using iOS7 or greater, import libstdc++.6.0.9.dylib (not libstdc++)!!!!!
 
 Follow the readme at https://github.com/gali8/Tesseract-OCR-iOS for first step.
 */

 

- (void)viewDidLoad
{
    [super viewDidLoad];
    //1
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    //2
    self.managedObjectContext = appDelegate.managedObjectContext;
    self.imagePicker = [UIImagePickerController new];
    [self.imagePicker setDelegate:self];
    [self.imagePicker setAllowsEditing:NO];
    self.researchMainClass = [[RBResearchMainClass alloc] init];
    //[researchMainClass makeSegmentedTesting];
    //[researchMainClass makeOcrAndSegmentedTesting];

    // [researchMainClass makeOcrTesting];
    

    

    
    self.tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"pol"];

    

    
    imageProcessor = [ImageProcessingImplementation new];



    UILongPressGestureRecognizer *longPressReceipt = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressReceipt:)];
    [self.receiptActionButton addGestureRecognizer:longPressReceipt];
    
    UILongPressGestureRecognizer *longPressDashboard = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressDashboard:)];
    [self.dashboardActionButton addGestureRecognizer:longPressDashboard];
    
 
    [self initDashboardCamera];
    [self initReceiptCamera];  
}

- (void)longPressReceipt:(UILongPressGestureRecognizer*)gesture {
    if ( gesture.state == UIGestureRecognizerStateEnded ) {
        self.currentImageView = self.resultImageView;
        [self showGallery];
    }
}

- (void)longPressDashboard:(UILongPressGestureRecognizer*)gesture {
    if ( gesture.state == UIGestureRecognizerStateEnded ) {
        self.currentImageView = self.dashboardImageView;
        [self showGallery];
    }
}


- (UIImage *)addToResultsImageView:(UIImage *)processImage
{
    UIImage *image = processImage;// = [processImage edgeDetect];
   // image = [image fixOrientation];
   // image = [imageProcessor processImage:image];
    self.resultImageView.contentMode = UIViewContentModeScaleToFill; // This determines position of image
    [self.resultImageView setImage:image];
    return image;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) showGallery {
    [self.imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentViewController:self.imagePicker animated:YES completion:nil];
    self.imagePicker.delegate = self;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if(buttonIndex != actionSheet.cancelButtonIndex){
        if (buttonIndex == 0)
            [self.imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        else if (buttonIndex == 1)
            [self.imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [self presentViewController:self.imagePicker animated:YES completion:nil];
    } else
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
//    CGRect croppedRect=[[info objectForKey:UIImagePickerControllerCropRect] CGRectValue];
    UIImage *original=[info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage *rotatedCorrectly;
    
    if (original.imageOrientation!=UIImageOrientationUp)
        rotatedCorrectly = [original rotate:original.imageOrientation];
    else
        rotatedCorrectly = original;

    
   UIImage  *takenImage= original;

    [self.currentImageView setImage:takenImage];
    
    
    [self ocrImage:takenImage];
  //  [self ocrImage:takenImage];

}

- (void) ocrImage:(UIImage *)image {
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if([self.currentImageView isEqual:self.resultImageView]) {
            
            NSString *recognizedText =  [self.researchMainClass ocrImage:image];
            ReceiptModel *receiptModel = [[ReceiptModel alloc] initWithOcrString:recognizedText];
            
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                ReceiptObject *gasolineObject = receiptModel.products[0];
                
                self.amountTextField.text = [NSString stringWithFormat:@"%.2f", gasolineObject.quantity];
                self.nameTextField.text = gasolineObject.name;
                
                self.priceTextField.text = [NSString stringWithFormat:@"%.2f", gasolineObject.totalPrice];
            });
            
        }
    });
}

- (IBAction)startCamera:(id)sender {

        if(![sender isSelected]) {
            self.currentImageView = self.resultImageView;

            [self.resultImageView setImage:nil];
    

            [self.receiptVideoCamera start];
            self.currentCamera = self.receiptVideoCamera;

            [sender setSelected:YES];
            [self.dashboardActionButton setSelected:NO];
        }
        else {
            if(!self.stopCamera) self.stopCamera = YES;
            [sender setSelected:NO];
        }
}

- (IBAction)startDashboardCamera:(id)sender {

        if(![sender isSelected]) {

            self.currentImageView = self.dashboardImageView;
            [self.dashboardImageView setImage:nil];

            
            [self.dashboardVideoCamera start];
            self.currentCamera = self.dashboardVideoCamera;
            [sender setSelected:YES];
            [self.receiptActionButton setSelected:NO];
        } else {
            if(!self.stopCamera) self.stopCamera = YES;
            [sender setSelected:NO];
        }

}




- (IBAction)ocrCurrentImage:(id)sender {
    if(!self.stopCamera) self.stopCamera = YES;
}

- (void) stopCameraAndProcessImage {
    [self.currentCamera stop];
    
    self.stopCamera = NO;
    //[self ocrImage:self.processedImage];
    self.currentImageView.image = self.processedImage;
    [self.dashboardActionButton setSelected:NO];
    [self.receiptActionButton setSelected:NO];
    
    //    self.videoCamera = nil;

    
}

- (void)processImage:(Mat&)image;
{
    if(self.stopCamera) {
        UIImage *filtered=[UIImage imageWithCVMat:image];
        self.processedImage = filtered;
        [self stopCameraAndProcessImage];
    }
}

- (void) initReceiptCamera{
    self.receiptVideoCamera = [[CvVideoCamera alloc] initWithParentView:self.resultImageView];
    self.receiptVideoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.receiptVideoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720
    ;
    self.receiptVideoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.receiptVideoCamera.defaultFPS = 30;
    self.receiptVideoCamera.delegate = self;
    self.receiptVideoCamera.grayscaleMode = YES;
}

- (void) initDashboardCamera{
    self.dashboardVideoCamera = [[CvVideoCamera alloc] initWithParentView:self.dashboardImageView];
    self.dashboardVideoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.dashboardVideoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720
    ;
    self.dashboardVideoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.dashboardVideoCamera.defaultFPS = 30;
    self.dashboardVideoCamera.delegate = self;
    self.dashboardVideoCamera.grayscaleMode = YES;
}

- (IBAction)saveReceipt:(id)sender {
  
        // Add Entry to PhoneBook Data base and reset all fields
        
        //  1
        RBFuelEntity * newEntry = [NSEntityDescription insertNewObjectForEntityForName:@"RBFuelEntity"
                                                          inManagedObjectContext:self.managedObjectContext];
        //  2

        newEntry.name = self.nameTextField.text;
        newEntry.totalPrice = @([self.priceTextField.text doubleValue]);
        newEntry.dashboardValue = @([self.dashboardTextField.text doubleValue]);
        newEntry.amount = @([self.amountTextField.text doubleValue]);
        //  3 
    
        NSLog(@"new entry name %@ %@ %@ %@", newEntry.name, newEntry.totalPrice, newEntry.dashboardValue, newEntry.amount);
    
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
    
    

    
    self.nameTextField.text = @"";
    self.priceTextField.text = @"";

    self.dashboardTextField.text = @"";
    self.amountTextField.text = @"";

        [self.view endEditing:YES];
}


@end
