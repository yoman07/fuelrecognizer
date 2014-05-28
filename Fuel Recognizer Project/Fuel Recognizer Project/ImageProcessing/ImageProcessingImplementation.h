//
//  ImageProcessingImplementation.h
//  ANPR
//
//  Created by Christian Roman on 29/08/13.
//  Copyright (c) 2013 Christian Roman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageProcessingProtocol.h"

@interface ImageProcessingImplementation : NSObject <ImageProcessingProtocol>

- (UIImage *) imageWithCVMat:(cv::Mat&)res;
cv::Mat calculateAndRotateAngle(cv::Mat& res, cv::Mat &dst);
cv::Mat findBoxes(cv::Mat& src, cv::Mat& dst);
cv::Mat thresholdImage(cv::Mat source);
cv::Mat greyscale(cv::Mat source);
cv::Mat processImage(cv::Mat source);
cv::Mat findContoursAndCrop(cv::Mat mat);

@end
