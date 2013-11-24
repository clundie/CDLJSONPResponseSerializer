// CDLJSONPResponseSerializer.m
//  
// Copyright (c) 2013 Chris Lundie (http://www.lundie.ca/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "CDLJSONPResponseSerializer.h"
#import <JavaScriptCore/JavaScriptCore.h>

NSString * const CDLJSONPResponseSerializerErrorDomain =
  @"ca.lundie.CDLJSONPResponseSerializerErrorDomain";

@implementation CDLJSONPResponseSerializer

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.acceptableContentTypes = [NSSet setWithArray:@[
      @"application/javascript",
      @"application/json",
      @"text/json",
      @"text/javascript",
    ]];
  }
  return self;
}

+ (instancetype)serializerWithCallback:(NSString *)callback
{
  CDLJSONPResponseSerializer *serializer = [[self alloc] init];
  serializer.callback = callback;
  return serializer;
}

#pragma mark - AFURLResponseSerialization protocol

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
  if (![self validateResponse:(NSHTTPURLResponse *)response
                         data:data
                        error:error]) {
    if ([*error code] == NSURLErrorCannotDecodeContentData) {
      return nil;
    }
  }
  __block id json = nil;
  NSString *script =
    [[NSString alloc] initWithData:data encoding:self.stringEncoding];
  if (script) {
    JSContext *context = [[JSContext alloc] init];
    NSString *callback = [self.callback copy];
    context[callback] = ^(id _json) {
      if ([NSJSONSerialization isValidJSONObject:_json]) {
        json = [NSKeyedUnarchiver unarchiveObjectWithData:
                 [NSKeyedArchiver archivedDataWithRootObject:_json]];
      } else {
        json = nil;
      }
    };
    [context evaluateScript:script];
  }
  if (!json) {
    NSMutableDictionary *userInfo = [@{
      NSLocalizedDescriptionKey: @"The JSONP response was invalid",
    } mutableCopy];
    NSURL *URL = [response URL];
    if (URL) {
      userInfo[NSURLErrorFailingURLErrorKey] = URL;
    }
    *error = [NSError errorWithDomain:CDLJSONPResponseSerializerErrorDomain
                                 code:NSURLErrorCannotParseResponse
                             userInfo:userInfo];
  }
  return json;
}

#pragma mark - NSSecureCoding protocol

+ (BOOL)supportsSecureCoding
{
  return YES;
}

#pragma mark - NSCoding protocol

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if (!self) {
    return nil;
  }
  self.callback = [decoder decodeObjectOfClass:[NSString class]
                                        forKey:@"callback"];
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:self.callback forKey:@"callback"];
}

#pragma mark - NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
  __typeof(self) serializer = [[[self class] allocWithZone:zone] init];
  serializer.callback = self.callback;
  return serializer;
}

@end
