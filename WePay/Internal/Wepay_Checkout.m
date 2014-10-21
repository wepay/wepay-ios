//
//  Wepay_Checkout.m
//  WePay
//
//  Created by Chaitanya Bagaria on 7/1/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#import "WePay_Checkout.h"

#import "WePay.h"
#import <WPError+internal.h>
#import <WPClient.h>

@interface WePay_Checkout ()

@property (nonatomic, strong) NSString *clientId;
@property (nonatomic, weak) id<WPCheckoutDelegate> externalCheckoutDelegate;

@end

@implementation WePay_Checkout

- (instancetype) initWithConfig:(WPConfig *)config
{
    if (self = [super init]) {
        // set the clientId
        self.clientId = config.clientId;

        // pass the config to the client
        WPClient.config = config;
    }

    return self;
}

- (void) storeSignatureImage:(UIImage *)image
               forCheckoutId:(NSString *)checkoutId
            checkoutDelegate:(id<WPCheckoutDelegate>) checkoutDelegate
{
    self.externalCheckoutDelegate = checkoutDelegate;

    BOOL isImageValid = NO;
    NSString *base64Data = nil;

    // validate image
    if ([self canStoreSignatureImage:image]) {
        base64Data = [self storableStringForImage:image];
        if (base64Data) {
            isImageValid = YES;
        }
    }

    // take action based on validity
    if (isImageValid) {
        // yes, upload
        [self uploadSignatureData:base64Data forCheckoutId:checkoutId image:image];
    } else {
        // no, return error
        [self.externalCheckoutDelegate didFailToStoreSignatureImage:image
                                                      forCheckoutId:checkoutId
                                                          withError:[WPError errorInvalidSignatureImage]];
    }
}


#pragma mark - Signature Storage

const static CGFloat MIN_HEIGHT = 64;
const static CGFloat MIN_WIDTH = 64;
const static CGFloat MAX_HEIGHT = 256;
const static CGFloat MAX_WIDTH = 256;

/**
 *  Validates the type and size of image to make sure it can be stored.
 *
 *  @param image the signature image to be validated.
 *
 *  @return YES if valid, otherwise NO.
 */
- (BOOL) canStoreSignatureImage:(UIImage *)image
{
    // Check image exists
    if (image == nil) {
        return NO;
    }

    // get height and width
    CGFloat h = image.size.height;
    CGFloat w = image.size.width;

    // check trivial height width
    if (h == 0 || w == 0) {
        return NO;
    }

    // if height has to be scaled up, resulting width should be acceptable
    if (h < MIN_HEIGHT && (w * MIN_HEIGHT / h > MAX_WIDTH)) {
        return NO;
    }

    // if width has to be scaled up, resulting height should be acceptable
    if (w < MIN_WIDTH && (h * MIN_WIDTH / w > MAX_HEIGHT)) {
        return NO;
    }

    // if height has to be scaled down, resulting width should be acceptable
    if (h > MAX_HEIGHT && (w * MAX_HEIGHT / h < MIN_WIDTH)) {
        return NO;
    }

    // if width has to be scaled down, resulting height should be acceptable
    if (w > MAX_WIDTH && (h * MAX_WIDTH / w < MIN_HEIGHT)) {
        return NO;
    }

    return YES;
}

/**
 *  Converts the provided image into its base-64 representation.
 *
 *  @param image the image to be converted.
 *
 *  @return the base-64 representation, or nil if there was an error.
 */
- (NSString *) storableStringForImage:(UIImage *)image
{
    //scale image if necessary
    UIImage *scaledImage = [self scaledSignatureImageCopy:image];

    // encode to base64
    NSString *base64 = [UIImagePNGRepresentation(scaledImage) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

    return base64;
}

/**
 *  Copies the provided image and scales it to fit the spec, if needed.
 *
 *  @param image the image to be scaled.
 *
 *  @return the copied and scaled image, or nil if there was an error.
 */
- (UIImage *) scaledSignatureImageCopy:(UIImage *)image
{
    // default scale
    CGFloat scale = 1.0;

    // get height and width
    CGFloat h = image.size.height;
    CGFloat w = image.size.width;

    // scaling up
    if (h < MIN_HEIGHT || w < MIN_WIDTH) {
        scale = MAX(MIN_HEIGHT / h, MIN_WIDTH / w);
    }

    // scaling down
    if (h > MAX_HEIGHT || w > MAX_WIDTH) {
        scale = MIN(MAX_HEIGHT / h, MAX_WIDTH / w);
    }

    CGSize newSize = CGSizeMake(w * scale, h * scale);
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = nil;
    BOOL shouldReleaseImageRef = NO;

    if (image.CGImage) {
        imageRef = image.CGImage;
    } else if (image.CIImage) {
        CIContext *context = [CIContext contextWithOptions:nil];
        imageRef = [context createCGImage:image.CIImage fromRect:[image.CIImage extent]];
        shouldReleaseImageRef = YES;
    }

    CGBitmapInfo bitmapinfo = [self normalizeBitmapInfo:CGImageGetBitmapInfo(imageRef)];

    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newSize.width,
                                                newSize.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                CGImageGetColorSpace(imageRef),
                                                bitmapinfo);

    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);

    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, newRect, imageRef);

    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];

    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    if (shouldReleaseImageRef) {
        CGImageRelease(imageRef);
    }

    return newImage;
}

/**
 *  Fixes a problem caused by BitmapInfo constants being deprecated in iOS 8.0
 *
 *  @param oldBitmapInfo original bitmap info
 *
 *  @return corrected bitap info
 */
- (CGBitmapInfo)normalizeBitmapInfo:(CGBitmapInfo)oldBitmapInfo {
    //extract the alpha info by resetting everything else
    CGImageAlphaInfo alphaInfo = oldBitmapInfo & kCGBitmapAlphaInfoMask;

    //Since iOS8 it's not allowed anymore to create contexts with unmultiplied Alpha info
    if (alphaInfo == kCGImageAlphaLast) {
        alphaInfo = kCGImageAlphaPremultipliedLast;
    }
    if (alphaInfo == kCGImageAlphaFirst) {
        alphaInfo = kCGImageAlphaPremultipliedFirst;
    }

    //reset the bits
    CGBitmapInfo newBitmapInfo = oldBitmapInfo & ~kCGBitmapAlphaInfoMask;

    //set the bits to the new alphaInfo
    newBitmapInfo |= alphaInfo;

    return newBitmapInfo;
}

/**
 *  Uploads the provided signature image data on WePay's servers
 *
 *  @param base64Data the signature image base-64 data
 *  @param checkoutId the checkout id to associate with the signature
 *  @param image      the original image provided by the app
 */
- (void) uploadSignatureData:(NSString *)base64Data
               forCheckoutId:(NSString *)checkoutId
                       image:(UIImage *) image
{
    NSMutableDictionary * requestParams = [@{} mutableCopy];
    [requestParams setObject:self.clientId forKey:@"client_id"];
    [requestParams setObject:checkoutId forKey:@"checkout_id"];
    [requestParams setObject:base64Data forKey:@"base64_img_data"];

    [WPClient checkoutSignatureCreate:requestParams
                         successBlock:^(NSDictionary * returnData) {
                             NSString *signatureUrl = [returnData objectForKey:@"signature_url"];

                             // inform external success
                             [self informExternalSignatureSuccess:signatureUrl forCheckoutId:checkoutId];
                         }
                         errorHandler:^(NSError * error) {
                             // inform external failure
                             [self informExternalSignatureFailure:error forCheckoutId:checkoutId image:image];
                         }
     ];
}

#pragma mark - inform external signature delegate

- (void) informExternalSignatureSuccess:(NSString *)signatureUrl forCheckoutId:(NSString *) checkoutId
{
    // If the external delegate is listening for success, send it
    if (self.externalCheckoutDelegate && [self.externalCheckoutDelegate respondsToSelector:@selector(didStoreSignature:forCheckoutId:)]) {
        [self.externalCheckoutDelegate didStoreSignature:signatureUrl forCheckoutId:checkoutId];
    }
}

- (void) informExternalSignatureFailure:(NSError *)error forCheckoutId:(NSString *) checkoutId image:(UIImage *)image
{
    // If the external delegate is listening for error, send it
    if (self.externalCheckoutDelegate && [self.externalCheckoutDelegate respondsToSelector:@selector(didFailToStoreSignatureImage:forCheckoutId:withError:)]) {
        [self.externalCheckoutDelegate didFailToStoreSignatureImage:image forCheckoutId:checkoutId withError:error];
    }
}

@end
