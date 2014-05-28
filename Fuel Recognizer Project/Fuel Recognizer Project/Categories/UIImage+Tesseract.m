//
//  UIImage+Tesseract.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 02.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import "UIImage+Tesseract.h"
#import <TesseractOCR/TesseractOCR.h>

@implementation UIImage (Tesseract)

- (NSString *) ocrWithTesseract:(Tesseract *)tesseract {
    @autoreleasepool{
        [tesseract setImage:self]; //image to check
        [tesseract recognize];
        return tesseract.recognizedText;
    }

}

@end
