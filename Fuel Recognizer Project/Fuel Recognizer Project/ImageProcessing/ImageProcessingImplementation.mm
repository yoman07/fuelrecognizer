//
//  ImageProcessingImplementation.m
//  ANPR
//
//  Created by Christian Roman on 29/08/13.
//  Copyright (c) 2013 Christian Roman. All rights reserved.
//

#import "ImageProcessingImplementation.h"
#import "ImageProcessor.h"
#import "UIImage+OpenCV.h"
#include <stdexcept>

#define kWhiteList @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-"

using namespace std;
using namespace cv;

@implementation ImageProcessingImplementation

- (NSString*)pathToLanguageFile
{
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
    NSString *dataPath = [documentPath stringByAppendingPathComponent:@"tessdata"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dataPath]) {
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *tessdataPath = [bundlePath stringByAppendingPathComponent:@"tessdata"];
        if (tessdataPath) {
            [fileManager copyItemAtPath:tessdataPath toPath:dataPath error:NULL];
        }
    }
    setenv("TESSDATA_PREFIX", [[documentPath stringByAppendingString:@"/"] UTF8String], 1);
    return dataPath;
}

- (UIImage*)denoisingImage:(UIImage*)src {
    cv::Mat source = [src CVMat];
    cvtColor(source, source, CV_BGR2GRAY);

    cv::fastNlMeansDenoising(source, source);
    @autoreleasepool {
        UIImage *filtered=[UIImage imageWithCVMat:source];
        return filtered;
    }
}

void makeSkeletonImage(Mat& img,Mat& Res) {

    cv::Mat skel(img.size(), CV_8UC1, cv::Scalar(0));
    cv::Mat temp(img.size(), CV_8UC1);
    
    cv::Mat element = cv::getStructuringElement(cv::MORPH_CROSS, cv::Size(3, 3));

    bool done;
    do
    {
        cv::morphologyEx(img, temp, cv::MORPH_OPEN, element);
        cv::bitwise_not(temp, temp);
        cv::bitwise_and(img, temp, temp);
        cv::bitwise_or(skel, temp, skel);
        cv::erode(img, img, element);
        
        double max;
        cv::minMaxLoc(img, 0, &max);
        done = (max == 0);
    } while (!done);
    
    Res = skel;
}

//- (UIImage *) findCountours:(UIImage*)src {
//    
//    cv::Mat mat = [src CVMat];
//    cv::cvtColor(mat, mat, CV_BGR2GRAY);
//    cv::GaussianBlur(mat, mat, cv::Size(3,3), 0);
//    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Point(9,9));
//    cv::Mat dilated;
//    cv::dilate(mat, dilated, kernel);
//    
//    cv::Mat edges;
//    cv::Canny(dilated, edges, 84, 3);
//    cv::OutputArray lines=
//    cv:lines.clear();
//    cv::HoughLinesP(edges, lines, 1, CV_PI/180, 25);
//    std::vector<cv::Vec4i>::iterator it = lines.begin();
//    for(; it!=lines.end(); ++it) {
//        cv::Vec4i l = *it;
//        cv::line(edges, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), cv::Scalar(255,0,0), 2, 8);
//    }
//    std::vector< std::vector<cv::Point> > contours;
//    cv::findContours(edges, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_TC89_KCOS);
//    std::vector< std::vector<cv::Point> > contoursCleaned;
//    for (int i=0; i < contours.size(); i++) {
//        if (cv::arcLength(contours[i], false) > 100)
//            contoursCleaned.push_back(contours[i]);
//    }
//    std::vector<std::vector<cv::Point> > contoursArea;
//    
//    for (int i=0; i < contoursCleaned.size(); i++) {
//        if (cv::contourArea(contoursCleaned[i]) > 10000){
//            contoursArea.push_back(contoursCleaned[i]);
//        }/Users/yoman/Documents/iOS/mgr/Tesseract-OCR-iOS/Template Framework Project/Template Framework Project
//    }
//    std::vector<std::vector<cv::Point> > contoursDraw (contoursCleaned.size());
//    for (int i=0; i < contoursArea.size(); i++){
//        cv::approxPolyDP(cv::Mat(contoursArea[i]), contoursDraw[i], 40, true);
//    }
//    cv::Mat drawing = cv::Mat::zeros( mat.size(), CV_8UC3 );
//    cv::drawContours(drawing, contoursDraw, -1, cv::Scalar(0,255,0),1);
//}

- (UIImage *)addThreshold:(UIImage*)src {
    ImageProcessor processor;
    cv::Mat source = [src CVMat];
    
    
    cv::Mat output = processor.filterMedianSmoot(source);
    cv::Mat img_gray;
    cv::cvtColor(source, img_gray, CV_BGR2GRAY);
    blur(img_gray, img_gray, cv::Size(5,5));
    //medianBlur(img_gray, img_gray, 9);
    cv::Mat img_sobel;
    cv::Sobel(img_gray, img_sobel, CV_8U, 1, 0, 3, 1, 0, cv::BORDER_DEFAULT);
    cv::Mat img_threshold;
    threshold(img_gray, img_threshold, 0, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
    cv::Mat element = getStructuringElement(cv::MORPH_RECT, cv::Size(3, 3) );
    morphologyEx(img_threshold, img_threshold, CV_MOP_CLOSE, element);
    
    
    @autoreleasepool {
        UIImage *filtered=[UIImage imageWithCVMat:img_threshold];
        return filtered;
    }
}

cv::Mat findContoursAndCrop(cv::Mat mat) {
    /* Search for contours */
//    cv::Mat img_threshold = [src CVMat];
//    cv::cvtColor(img_threshold, img_threshold, CV_BGR2GRAY);
//
    cv::Mat img_threshold = mat;
    std::vector<std::vector<cv::Point> > contours;
    cv::Mat contourOutput = img_threshold.clone();
    cv::findContours( contourOutput, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE );
    
    std::vector<cv::Vec4i> hierarchy;
    
    /* Get the largest contour (Possible license plate) */
    
    int largestArea = -1;
    std::vector<std::vector<cv::Point> > largestContour;
    
    std::vector<std::vector<cv::Point> > polyContours( contours.size() );
    
    //std::vector<cv::Point> approx;
    for( int i = 0; i < contours.size(); i++ ){
        approxPolyDP( cv::Mat(contours[i]), polyContours[i], arcLength(cv::Mat(contours[i]), true)*0.02, true );
        
        if (polyContours[i].size() == 4 && fabs(contourArea(cv::Mat(polyContours[i]))) > 1000 && isContourConvex(cv::Mat(polyContours[i]))){
            double maxCosine = 0;
            
            for (int j = 2; j < 5; j++){
                double cosine = fabs(::angle(polyContours[i][j%4], polyContours[i][j-2], polyContours[i][j-1]));
                
                maxCosine = MAX(maxCosine, cosine);
            }
            
            if (maxCosine < 0.3)
                NSLog(@"Square detected");
        }
        
    }
    
    for( int i = 0; i< polyContours.size(); i++ ){
        
        int area = fabs(contourArea(polyContours[i],false));
        if(area > largestArea){
            largestArea = area;
            largestContour.clear();
            largestContour.push_back(polyContours[i]);
        }
        
    }
    
    // Contour drawing debug
    cv::Mat drawing = cv::Mat::zeros( contourOutput.size(), CV_8UC3 );
    if(largestContour.size()>=1){
        
        cv::drawContours(img_threshold, largestContour, -1, cv::Scalar(0, 255, 0), 0);
        
    }
    
    /* Get RotatedRect for the largest contour */
    
    std::vector<cv::RotatedRect> minRect( largestContour.size() );
    for( int i = 0; i < largestContour.size(); i++ )
        minRect[i] = minAreaRect( cv::Mat(largestContour[i]) );
    
    cv::Mat drawing2 = cv::Mat::zeros( img_threshold.size(), CV_8UC3 );
    for( int i = 0; i< largestContour.size(); i++ ){
        
        cv::Point2f rect_points[4]; minRect[i].points( rect_points );
        for( int j = 0; j < 4; j++ ){
            line( drawing2, rect_points[j], rect_points[(j+1)%4], cv::Scalar(0,255,0), 1, 8 );
            
        }
        
    }
    
    
    /* Get Region Of Interest ROI */
    NSLog(@"Region Of Interest ROI");
    cv::RotatedRect box = minAreaRect( cv::Mat(largestContour[0]));
    cv::Rect box2 = cv::RotatedRect(box.center, box.size, box.angle).boundingRect();
    //
    box2.x += box2.width * 0.028;
    box2.width -= box2.width * 0.05;
    box2.y += box2.height * 0.028;
    box2.height -= box2.height * 0.05;
    
    cv::Mat cvMat;
    try {
        cvMat = img_threshold(box2).clone();
    }
    catch (const std::exception & e) {
        cvMat = img_threshold;
    }
    
    
    
    /* Experimental
     
     cv::Point2f pts[4];
     
     std::vector<cv::Point> shape;
     
     shape.push_back(largestContour[0][3]);
     shape.push_back(largestContour[0][2]);
     shape.push_back(largestContour[0][1]);
     shape.push_back(largestContour[0][0]);
     
     cv::RotatedRect boxx = minAreaRect(cv::Mat(shape));
     
     box.points(pts);
     
     cv::Point2f src_vertices[3];
     src_vertices[0] = shape[0];
     src_vertices[1] = shape[1];
     src_vertices[2] = shape[3];
     
     cv::Point2f dst_vertices[3];
     dst_vertices[0] = cv::Point(0, 0);
     dst_vertices[1] = cv::Point(boxx.boundingRect().width-1, 0);
     dst_vertices[2] = cv::Point(0, boxx.boundingRect().height-1);
     
     cv::Mat warpAffineMatrix = getAffineTransform(src_vertices, dst_vertices);
     
     cv::Mat rotated;
     cv::Size size(boxx.boundingRect().width, boxx.boundingRect().height);
     cv::warpAffine(source, rotated, warpAffineMatrix, size, cv::INTER_LINEAR, cv::BORDER_CONSTANT);
     
     */
    
    return cvMat;

    
}

cv::Mat greyscale(cv::Mat source) {
    greyscale(source,source);
    return source;
}

void greyscale (cv::Mat& src,cv::Mat& dst) {
    cv::cvtColor(src, dst, CV_BGR2GRAY);
}

cv::Mat processImage(cv::Mat source)
{
    ImageProcessor processor;
    
    
    cv::Mat output = processor.filterMedianSmoot(source);
    
    //threshold(output, output, 230, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
    //threshold( output, output, 150, 255, CV_THRESH_BINARY );
    //GaussianBlur(output, output, cv::Size(5, 5), 0, 0);
    //adaptiveThreshold(output, output, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY, 75, 10);
    
    /* Pre-processing */
    
    cv::Mat img_gray = source;
//    cv::cvtColor(source, img_gray, CV_BGR2GRAY);
    
    blur(img_gray, img_gray, cv::Size(5,5));
    //medianBlur(img_gray, img_gray, 9);
    cv::Mat img_sobel;
    cv::Sobel(img_gray, img_sobel, CV_8U, 1, 0, 3, 1, 0, cv::BORDER_DEFAULT);
    cv::Mat img_threshold;
    threshold(img_gray, img_threshold, 0, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
    cv::Mat element = getStructuringElement(cv::MORPH_RECT, cv::Size(3, 3) );
    morphologyEx(img_threshold, img_threshold, CV_MOP_CLOSE, element);
    
    /* Search for contours */
    
    std::vector<std::vector<cv::Point> > contours;
    cv::Mat contourOutput = img_threshold.clone();
    cv::findContours( contourOutput, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE );
    
    std::vector<cv::Vec4i> hierarchy;
    
    /* Get the largest contour (Possible license plate) */
    
    int largestArea = -1;
    std::vector<std::vector<cv::Point> > largestContour;
    
    std::vector<std::vector<cv::Point> > polyContours( contours.size() );
    
    //std::vector<cv::Point> approx;
    for( int i = 0; i < contours.size(); i++ ){
        approxPolyDP( cv::Mat(contours[i]), polyContours[i], arcLength(cv::Mat(contours[i]), true)*0.02, true );
        
        if (polyContours[i].size() == 4 && fabs(contourArea(cv::Mat(polyContours[i]))) > 1000 && isContourConvex(cv::Mat(polyContours[i]))){
            double maxCosine = 0;
            
            for (int j = 2; j < 5; j++){
                double cosine = fabs(::angle(polyContours[i][j%4], polyContours[i][j-2], polyContours[i][j-1]));
                
                maxCosine = MAX(maxCosine, cosine);
            }
            
            if (maxCosine < 0.3)
                NSLog(@"Square detected");
        }
        
    }
    
    for( int i = 0; i< polyContours.size(); i++ ){
        
        int area = fabs(contourArea(polyContours[i],false));
        if(area > largestArea){
            largestArea = area;
            largestContour.clear();
            largestContour.push_back(polyContours[i]);
        }
        
    }
    
    // Contour drawing debug
    cv::Mat drawing = cv::Mat::zeros( contourOutput.size(), CV_8UC3 );
    if(largestContour.size()>=1){
        
        cv::drawContours(source, largestContour, -1, cv::Scalar(0, 255, 0), 0);
        
    }
    
    /* Get RotatedRect for the largest contour */
    
    std::vector<cv::RotatedRect> minRect( largestContour.size() );
    for( int i = 0; i < largestContour.size(); i++ )
        minRect[i] = minAreaRect( cv::Mat(largestContour[i]) );
    
    cv::Mat drawing2 = cv::Mat::zeros( img_threshold.size(), CV_8UC3 );
    for( int i = 0; i< largestContour.size(); i++ ){
        
        cv::Point2f rect_points[4]; minRect[i].points( rect_points );
        for( int j = 0; j < 4; j++ ){
            line( drawing2, rect_points[j], rect_points[(j+1)%4], cv::Scalar(0,255,0), 1, 8 );
            
        }
        
    }
    
    cv::Mat cvMat;

    /* Get Region Of Interest ROI */
    NSLog(@"Region Of Interest ROI");
    try {
        if(largestContour.size()>=1) {
                cv::RotatedRect box = minAreaRect( cv::Mat(largestContour[0]));
            cv::Rect box2 = cv::RotatedRect(box.center, box.size, box.angle).boundingRect();
//    
//    box2.x += box2.width * 0.028;
//    box2.width -= box2.width * 0.05;
//    box2.y += box2.height * 0.028;
//    box2.height -= box2.height * 0.05;
            
            cvMat = source(box2).clone();
        } else {
            cvMat = source;
        }
    }
    catch (const std::exception & e) {
        cvMat = source;
    }

    
    
    /* Experimental
     
     cv::Point2f pts[4];
     
     std::vector<cv::Point> shape;
     
     shape.push_back(largestContour[0][3]);
     shape.push_back(largestContour[0][2]);
     shape.push_back(largestContour[0][1]);
     shape.push_back(largestContour[0][0]);
     
     cv::RotatedRect boxx = minAreaRect(cv::Mat(shape));
     
     box.points(pts);
     
     cv::Point2f src_vertices[3];
     src_vertices[0] = shape[0];
     src_vertices[1] = shape[1];
     src_vertices[2] = shape[3];
     
     cv::Point2f dst_vertices[3];
     dst_vertices[0] = cv::Point(0, 0);
     dst_vertices[1] = cv::Point(boxx.boundingRect().width-1, 0);
     dst_vertices[2] = cv::Point(0, boxx.boundingRect().height-1);
     
     cv::Mat warpAffineMatrix = getAffineTransform(src_vertices, dst_vertices);
     
     cv::Mat rotated;
     cv::Size size(boxx.boundingRect().width, boxx.boundingRect().height);
     cv::warpAffine(source, rotated, warpAffineMatrix, size, cv::INTER_LINEAR, cv::BORDER_CONSTANT);
     
     */
    return source;
}

- (UIImage*)oldProcessImage:(UIImage*)src
{
    ImageProcessor processor;
    cv::Mat source = [src CVMat];
    cv::Mat output = processor.filterMedianSmoot(source);
    
    //threshold(output, output, 230, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
    //threshold( output, output, 150, 255, CV_THRESH_BINARY );
    //GaussianBlur(output, output, cv::Size(5, 5), 0, 0);
    //adaptiveThreshold(output, output, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY, 75, 10);
    
    /* Pre-processing */
    
    cv::Mat img_gray;
    cv::cvtColor(source, img_gray, CV_BGR2GRAY);
    blur(img_gray, img_gray, cv::Size(5,5));
    //medianBlur(img_gray, img_gray, 9);
    cv::Mat img_sobel;
    cv::Sobel(img_gray, img_sobel, CV_8U, 1, 0, 3, 1, 0, cv::BORDER_DEFAULT);
    cv::Mat img_threshold;
    threshold(img_gray, img_threshold, 0, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
    cv::Mat element = getStructuringElement(cv::MORPH_RECT, cv::Size(3, 3) );
    morphologyEx(img_threshold, img_threshold, CV_MOP_CLOSE, element);
    
    /* Search for contours */
    
    std::vector<std::vector<cv::Point> > contours;
    cv::Mat contourOutput = img_threshold.clone();
    
    
    cv::findContours( contourOutput, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE );
    
    std::vector<cv::Vec4i> hierarchy;
    
    /* Get the largest contour (Possible license plate) */
    
    int largestArea = -1;
    std::vector<std::vector<cv::Point> > largestContour;
    
    std::vector<std::vector<cv::Point> > polyContours( contours.size() );
    
    //std::vector<cv::Point> approx;
    for( int i = 0; i < contours.size(); i++ ){
        approxPolyDP( cv::Mat(contours[i]), polyContours[i], arcLength(cv::Mat(contours[i]), true)*0.02, true );
        
        if (polyContours[i].size() == 4 && fabs(contourArea(cv::Mat(polyContours[i]))) > 1000 && isContourConvex(cv::Mat(polyContours[i]))){
            double maxCosine = 0;
            
            for (int j = 2; j < 5; j++){
                double cosine = fabs(::angle(polyContours[i][j%4], polyContours[i][j-2], polyContours[i][j-1]));
                
                maxCosine = MAX(maxCosine, cosine);
            }
            
            if (maxCosine < 0.3)
                NSLog(@"Square detected");
        }
        
    }
    
    for( int i = 0; i< polyContours.size(); i++ ){
        
        int area = fabs(contourArea(polyContours[i],false));
        if(area > largestArea){
            largestArea = area;
            largestContour.clear();
            largestContour.push_back(polyContours[i]);
        }
        
    }
    
    // Contour drawing debug
//    cv::Mat drawing = cv::Mat::zeros( contourOutput.size(), CV_8UC3 );
//    if(largestContour.size()>=1){
//        
//        cv::drawContours(source, largestContour, -1, cv::Scalar(0, 255, 0), 0);
//        
//    }
    
    /* Get RotatedRect for the largest contour */
    
    std::vector<cv::RotatedRect> minRect( largestContour.size() );
    for( int i = 0; i < largestContour.size(); i++ )
        minRect[i] = minAreaRect( cv::Mat(largestContour[i]) );
    
    cv::Mat drawing2 = cv::Mat::zeros( img_threshold.size(), CV_8UC3 );
    for( int i = 0; i< largestContour.size(); i++ ){
        
        cv::Point2f rect_points[4]; minRect[i].points( rect_points );
        for( int j = 0; j < 4; j++ ){
            line( drawing2, rect_points[j], rect_points[(j+1)%4], cv::Scalar(0,255,0), 1, 8 );
            
        }
        
    }
    
    /* Get Region Of Interest ROI */
    
    cv::RotatedRect box = minAreaRect( cv::Mat(largestContour[0]));
    cv::Rect box2 = cv::RotatedRect(box.center, box.size, box.angle).boundingRect();
    
    box2.x += box2.width * 0.028;
    box2.width -= box2.width * 0.05;
    box2.y += box2.height * 0.25;
    box2.height -= box2.height * 0.55;
    
    cv::Mat cvMat = img_threshold(box2).clone();
    
    /* Experimental
     
     cv::Point2f pts[4];
     
     std::vector<cv::Point> shape;
     
     shape.push_back(largestContour[0][3]);
     shape.push_back(largestContour[0][2]);
     shape.push_back(largestContour[0][1]);
     shape.push_back(largestContour[0][0]);
     
     cv::RotatedRect boxx = minAreaRect(cv::Mat(shape));
     
     box.points(pts);
     
     cv::Point2f src_vertices[3];
     src_vertices[0] = shape[0];
     src_vertices[1] = shape[1];
     src_vertices[2] = shape[3];
     
     cv::Point2f dst_vertices[3];
     dst_vertices[0] = cv::Point(0, 0);
     dst_vertices[1] = cv::Point(boxx.boundingRect().width-1, 0);
     dst_vertices[2] = cv::Point(0, boxx.boundingRect().height-1);
     
     cv::Mat warpAffineMatrix = getAffineTransform(src_vertices, dst_vertices);
     
     cv::Mat rotated;
     cv::Size size(boxx.boundingRect().width, boxx.boundingRect().height);
     cv::warpAffine(source, rotated, warpAffineMatrix, size, cv::INTER_LINEAR, cv::BORDER_CONSTANT);
     
     */
    
    @autoreleasepool {
        UIImage *filtered=[UIImage imageWithCVMat:source];
        return filtered;
    }
}

double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 )
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1 * dx2 + dy1 * dy2)/sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2) + 1e-10);
}


void CalcBlockMeanVariance(Mat& Img,Mat& Res,float blockSide=21) // blockSide - the parameter (set greater for larger font on image)
{
    Mat I;
    Img.convertTo(I,CV_32FC1);
    Res=Mat::zeros(Img.rows/blockSide,Img.cols/blockSide,CV_32FC1);
    Mat inpaintmask;
    Mat patch;
    Mat smallImg;
    Scalar m,s;
    
    for(int i=0;i<Img.rows-blockSide;i+=blockSide)
    {
        for (int j=0;j<Img.cols-blockSide;j+=blockSide)
        {
            patch=I(Range(i,i+blockSide+1),Range(j,j+blockSide+1));
            cv::meanStdDev(patch,m,s);
            if(s[0]>0.01) // Thresholding parameter (set smaller for lower contrast image)
            {
                Res.at<float>(i/blockSide,j/blockSide)=m[0];
            }else
            {
                Res.at<float>(i/blockSide,j/blockSide)=0;
            }
        }
    }
    
    cv::resize(I,smallImg,Res.size());
    
    cv::threshold(Res,inpaintmask,0.02,1.0,cv::THRESH_BINARY);
    
    Mat inpainted;
    smallImg.convertTo(smallImg,CV_8UC1,255);
    
    inpaintmask.convertTo(inpaintmask,CV_8UC1);
    inpaint(smallImg, inpaintmask, inpainted, 5, INPAINT_TELEA);
    
    cv::resize(inpainted,Res,Img.size());
    Res.convertTo(Res,CV_32FC1,1.0/255.0);
    
}
//-----------------------------------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------------------------------


//http://stackoverflow.com/questions/22122309/opencv-adaptive-threshold-ocr
cv::Mat thresholdImage(cv::Mat Img){
    
//    cvtColor(Img, Img, CV_BGR2GRAY);

    Mat res;
    Img.convertTo(Img,CV_32FC1,1.0/255.0);
    CalcBlockMeanVariance(Img,res);
    res=1.0-res;
    res=Img+res;
    threshold(res,res,0.85,1,cv::THRESH_BINARY);
    resize(res,res,cv::Size(res.cols/2,res.rows/2));
    
    res.convertTo(res,CV_8UC3,255.0);

    //Sobel(res, res, CV_8U, 1, 3, 6, 1, 0, cv::BORDER_DEFAULT);
    //medianBlur(res, res, 1);
    
  
    return res;
}

- (UIImage *) imageWithCVMat:(Mat&)res {
    return [UIImage imageWithCVMat:res];
}

Mat findBoxes(Mat& src, Mat& dst) {
    
    
    cv::Mat outputErode;

    cv::dilate(src, outputErode, 0,cv::Point(-1, -1), 1, 1, 1);
    cv::blur(outputErode, outputErode, cv::Size( 50, 2 ));
    std::vector<std::vector<cv::Point> > contours;
    Canny(outputErode, outputErode, 230, 255);

    cv::findContours( outputErode, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE );
    std::vector<std::vector<cv::Point> > largestContour;
    for( int i = 0; i < contours.size(); i++ ){
        cv::Rect r = cv::boundingRect(contours[i]);

        if(r.width > (dst.cols- 170)) {
            largestContour.clear();
            largestContour.push_back(contours[i]);
            cv::drawContours(src, largestContour, -2, cv::Scalar(255, 0, 0), 3);
        }
    }
    
    
    return src;
}

//
//void mop(Mat& res) {
////    int filterSize = 2;
//   // IplConvKernel *convKernel = cvCreateStructuringElementEx(filterSize, filterSize, (filterSize - 1) / 2, (filterSize - 1) / 2, CV_SHAPE_RECT, NULL);
////
////    CvMat cvMat = res;
////    cvMorphologyEx( &cvMat, &cvMat, NULL, convKernel, CV_MOP_CLOSE, 10 );
//    
//    int erosion_size = 6;
//    cv::Mat element = cv::getStructuringElement(cv::MORPH_CROSS,
//                                                cv::Size(2 * erosion_size + 1, 2 * erosion_size + 1),
//                                                cv::Point(erosion_size, erosion_size) );
//    
//    //! dilates the image (applies the local maximum operator)
//    cv::dilate(cvMat, cvMat, element);
//    
//}


/* 
 * http://felix.abecassis.me/category/opencv/page/2/
 */
Mat calculateAndRotateAngle(Mat& res, Mat &dst) {
    std::vector<cv::Vec4i> lines;
    double angle = 0.;
    
    cv::Size size = res.size();
    
    cv::HoughLinesP(res, lines, 1, CV_PI/180, 100, size.width / 2.f, 5);
    
    Mat disp_lines(size, CV_8UC1, cv::Scalar(0, 0, 0));
    unsigned nb_lines = lines.size();
    for (unsigned i = 0; i < nb_lines; ++i)
    {
        cv::line(disp_lines, cv::Point(lines[i][0], lines[i][1]),
                 cv::Point(lines[i][2], lines[i][3]), cv::Scalar(255, 0 ,0));
        angle += atan2((double)lines[i][3] - lines[i][1],
                       (double)lines[i][2] - lines[i][0]);
    }
    angle /= nb_lines; // mean angle, in radi
    
    rotatev2(res, angle,dst);
    NSLog(@"Angle %f", angle);
    return dst;
}
//http://answers.opencv.org/question/8956/basic-image-enhancing-for-ocr-purproses/

/**
 * Rotate an image
 * http://opencv-code.com/quick-tips/how-to-rotate-image-in-opencv/
 */

void rotatev2(cv::Mat& src, double angle, cv::Mat& dst)
{
    //int len = std::max(src.cols, src.rows);
    
    cv::Point2f pt(src.cols/2., src.rows/2.);
    
    cv::Mat r = cv::getRotationMatrix2D(pt, angle, 1.0);
    
    cv::warpAffine(src, dst, r, cv::Size(src.cols, src.rows));
}

void rotate(cv::Mat& src, double angle, cv::Mat& dst)
{
    cv::Mat img = src;
    
    cv::bitwise_not(img, img);
    
    std::vector<cv::Point> points;
    cv::Mat_<uchar>::iterator it = img.begin<uchar>();
    cv::Mat_<uchar>::iterator end = img.end<uchar>();
    for (; it != end; ++it)
        if (*it)
            points.push_back(it.pos());
    
    cv::RotatedRect box = cv::minAreaRect(cv::Mat(points));
    cv::Mat rot_mat = cv::getRotationMatrix2D(box.center, angle, 1);
    cv::warpAffine(img, dst, rot_mat, img.size(), cv::INTER_CUBIC);
    
    cv::Size box_size = box.size;
    if (box.angle < -45.)
        std::swap(box_size.width, box_size.height);
    cv::getRectSubPix(dst, box_size, box.center, dst);
}




@end
