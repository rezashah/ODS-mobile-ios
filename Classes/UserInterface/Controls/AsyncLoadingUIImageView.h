/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
// AsyncLoadingUIImageView 
//
// A UIImageView that asynchronous loads an image from a provided HTTP request.
// Does not do any caching itself, so use the ASIHttpRequest designated methods to cache the return result if you want that:
//
// eg.   request.secondsToCache = 86400;
//       request.downloadCache = [ASIDownloadCache sharedCache];
//       [request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
//       [asyncLoadingUIImageView setImageRequest:request];

#import <Foundation/Foundation.h>

@class BaseHTTPRequest;

@interface AsyncLoadingUIImageView : UIImageView

// Uses the provided request to load the image asynchronously.
// Once the data has been retrieved
- (void)setImageWithRequest:(BaseHTTPRequest *)request;

// Note that success and failure blocks are executed on the main thread
- (void)setImageWithRequest:(BaseHTTPRequest *)request
                     succes:(void (^)(UIImage *image))successBlock
                    failure:(void (^)(NSError *error))failureBlock;

@end
