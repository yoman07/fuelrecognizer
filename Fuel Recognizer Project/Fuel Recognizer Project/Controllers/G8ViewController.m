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
#import "DataTableViewController.h"

#define kWhiteList @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-.,ÓŁ:*%#\\"

@interface G8ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate> {
    id <ImageProcessingProtocol> imageProcessor;
}
@property (nonatomic, strong) UIImage *processedImage;
@property (weak, nonatomic) IBOutlet UIImageView *resultImageView;
@property (nonatomic,strong) UITextChecker *textChecker;
@property (weak, nonatomic) IBOutlet UITextView *textViewAfterOcr;

@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) Tesseract* tesseract;
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
    UIImage *image = [UIImage imageNamed:@"bigphoto.png"];
    self.resultImageView.contentMode = UIViewContentModeCenter; // This determines position of image
    self.resultImageView.clipsToBounds = YES;
    self.resultImageView.image = image;
    int age = 0;
    NSString *stringTest = age?[NSString stringWithFormat:@"%@",age]:@"";
    NSLog(@"test %@",stringTest);
    UITextChecker *textchecker = [[UITextChecker alloc] init];
    
    NSLog(@"Languages for spellchecker %@", [UITextChecker availableLanguages]);
    
    imageProcessor = [ImageProcessingImplementation new];
	// Do any additional setup after loading the view, typically from a nib.
	NSLog(@"tesseract version %@", [Tesseract version]);

	//language are used for recognition. Ex: eng. Tesseract will search for a eng.traineddata file in the dataPath directory.
	//eng.traineddata is in your "tessdata" folder.

    
    
    
    
//    tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"pol"];
//	//language are used for recognition. Ex: eng. Tesseract will search for a eng.traineddata file in the dataPath directory.
//	//eng.traineddata is in your "tessdata" folder.
//	image = [UIImage imageNamed:@"lotRach.png"];//color2_thershold_no_logo.png
//    image = [self processImage:image];
//	//[tesseract setVariableValue:kWhiteList forKey:@"tessedit_char_whitelist"]; //limit search
//	[tesseract setImage:image]; //image to check
//	[tesseract recognize];
//	
//	NSLog(@"%@", [tesseract recognizedText]);
//	receiptModel = [[ReceiptModel alloc] initWithOcrString:tesseract.recognizedText];
//	[tesseract clear];

    
}

- (UIImage *)processImage:(UIImage *)processImage
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

- (IBAction)choosePicture:(id)sender {
    self.imagePicker = [UIImagePickerController new];
    [self.imagePicker setDelegate:self];
    [self.imagePicker setAllowsEditing:NO];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Take a photo or choose existing, and use the control to center the announce"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Take photo", @"Choose Existing", nil];
        [actionSheet showInView:self.view];
    } else {
        [self.imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [self presentViewController:self.imagePicker animated:YES completion:nil];
    }
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
//    
//    CGImageRef ref= CGImageCreateWithImageInRect(rotatedCorrectly.CGImage, croppedRect);
   UIImage  *takenImage= original;
    [self ocrImage:takenImage];
//    [self.resultImageView setImage:takenImage];
//    processedImage= takenImage;
//    [processButton setHidden:NO];
//    [readButton setHidden:NO];
}

- (void) ocrImage:(UIImage *)image {
//    UIImage *image = [UIImage imageNamed:@"color2_thershold_no_logo.png"];//color2_thershold_no_logo.png
    self.tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"pol"];
    image = [self processImage:image];
	//[tesseract setVariableValue:kWhiteList forKey:@"tessedit_char_whitelist"]; //limit search
	[self.tesseract setImage:image]; //image to check
	[self.tesseract recognize];
	
	NSLog(@"%@", [self.tesseract recognizedText]);
    self.textViewAfterOcr.text = self.tesseract.recognizedText;
	ReceiptModel *receiptModel = [[ReceiptModel alloc] initWithOcrString:self.tesseract.recognizedText];
    DataTableViewController *dataVC =    [[self.tabBarController viewControllers] objectAtIndex:1];
    dataVC.receiptModel = receiptModel;
	[self.tesseract clear];
}



@end
