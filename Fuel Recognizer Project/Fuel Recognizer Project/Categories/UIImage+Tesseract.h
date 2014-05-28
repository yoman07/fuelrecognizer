//
//  UIImage+Tesseract.h
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 02.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Tesseract;
@interface UIImage (Tesseract)

- (NSString *) ocrWithTesseract:(Tesseract *)tesseract;


@end
