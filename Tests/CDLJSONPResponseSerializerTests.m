// CDLJSONPResponseSerializerTests.m
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

#import <XCTest/XCTest.h>
#import "CDLJSONPResponseSerializer.h"
#import "AFNetworking.h"
#define EXP_SHORTHAND
#import "Expecta.h"

static NSURL *BaseURL();
static NSHTTPURLResponse *SuccessfulResponse(NSString *contentType);
static NSData *JSONPData(id JSONObject, NSString *callback,
                         NSString *prefix, NSString *suffix);

static NSData *JSONPData(id JSONObject, NSString *callback,
                         NSString *prefix, NSString *suffix)
{
  NSData *jsonData;
  if ([NSJSONSerialization isValidJSONObject:JSONObject]) {
    jsonData = [NSJSONSerialization dataWithJSONObject:JSONObject
                                               options:0
                                                 error:NULL];
  } else {
    jsonData =
      [[JSONObject description] dataUsingEncoding:NSUTF8StringEncoding];
  }
  NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                               encoding:NSUTF8StringEncoding];
  NSString *script = [NSString stringWithFormat:@"%3$@%2$@(%1$@);%4$@",
                                                jsonString, callback,
                                                prefix, suffix];
  NSData *responseData = [script dataUsingEncoding:NSUTF8StringEncoding];
  return responseData;
}

static NSHTTPURLResponse *SuccessfulResponse(NSString *contentType)
{
  NSDictionary *headerFields = @{
    @"Content-Type": contentType,
  };
  NSURL *URL = BaseURL();
  NSHTTPURLResponse *response =
    [[NSHTTPURLResponse alloc] initWithURL:URL
                                statusCode:200
                               HTTPVersion:@"1.1"
                              headerFields:headerFields];
  return response;
}

static NSURL *BaseURL()
{
  NSURL *URL = [NSURL URLWithString:@"http://foo.example/"];
  return URL;
}

@interface CDLJSONPResponseSerializerTests : XCTestCase

@property (atomic, copy) NSURL *baseURL;

@end

@implementation CDLJSONPResponseSerializerTests

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testThatJSONPResponseSerializerInitializesCallbackProperty
{
  NSString *callback = @"foo";
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  expect(serializer.callback).to.equal(callback);
}

- (void)testThatJSONPResponseSerializerCopiesCallbackProperty
{
  NSString *callback = @"foo";
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  CDLJSONPResponseSerializer *serializerCopy = [serializer copy];
  expect(serializerCopy.callback).to.equal(callback);
  serializer.callback = @"bar";
  expect(serializerCopy.callback).to.equal(callback);
}

- (void)testThatJSONPResponseSerializerSupportsSecureCoding
{
  expect([CDLJSONPResponseSerializer supportsSecureCoding]).to.beTruthy();
}

- (void)testThatJSONPResponseSerializerCanBeEncodedAndDecoded
{
  NSString *callback = @"foo";
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:serializer];
  CDLJSONPResponseSerializer *serializer2 =
    [NSKeyedUnarchiver unarchiveObjectWithData:archive];
  expect(serializer2.callback).to.equal(callback);
  serializer.callback = @"bar";
  expect(serializer2.callback).to.equal(callback);
}

- (void)testThatJSONPResponseSerializerReturnsDictionaryForValidJSONDictionary
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/javascript");
  NSString *callback = @"foo";
  id json = @{
    @"bert"   : @"ernie",
    @"count"  : @12345,
    @"yesno"  : @YES,
    @"maybe"  : @NO,
    @"cookie" : @[@"monster"],
    @"room"   : @{@"johnny": @"lisa"},
  };
  NSData *responseData = JSONPData(json, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  NSError *error = nil;
  id responseObject = [serializer responseObjectForResponse:response
                                                       data:responseData
                                                      error:&error];
  expect(error).to.beNil();
  expect(responseObject).to.equal(json);
}

- (void)testThatJSONPResponseSerializerReturnsArrayForValidJSONArray
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/javascript");
  NSString *callback = @"foo";
  id json = @[
    @"bert",
    @12345,
    @YES,
    @NO,
    @[@"monster"],
    @{@"johnny": @"lisa"},
  ];
  NSData *responseData = JSONPData(json, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  NSError *error = nil;
  id responseObject = [serializer responseObjectForResponse:response
                                                       data:responseData
                                                      error:&error];
  expect(error).to.beNil();
  expect(responseObject).to.equal(json);
}

- (void)testThatJSONPResponseSerializerAcceptsApplicationJavascriptMimeType
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/javascript");
  NSString *callback = @"foo";
  NSError *error = nil;
  NSData *responseData = JSONPData(@{}, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializer];
  [serializer validateResponse:response data:responseData error:&error];
  expect(error).to.beNil();
}

- (void)testThatJSONPResponseSerializerAcceptsApplicationJSONMimeType
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/json");
  NSString *callback = @"foo";
  NSError *error = nil;
  NSData *responseData = JSONPData(@{}, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializer];
  [serializer validateResponse:response data:responseData error:&error];
  expect(error).to.beNil();
}

- (void)testThatJSONPResponseSerializerAcceptsTextJSONMimeType
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"text/json");
  NSString *callback = @"foo";
  NSError *error = nil;
  NSData *responseData = JSONPData(@{}, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializer];
  [serializer validateResponse:response data:responseData error:&error];
  expect(error).to.beNil();
}

- (void)testThatJSONPResponseSerializerAcceptsTextJavascriptMimeType
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"text/javascript");
  NSString *callback = @"foo";
  NSError *error = nil;
  NSData *responseData = JSONPData(@{}, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializer];
  [serializer validateResponse:response data:responseData error:&error];
  expect(error).to.beNil();
}

- (void)testThatJSONPResponseSerializerRejectsUnknownMimeType
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"foo/bar");
  NSString *callback = @"foo";
  NSError *error = nil;
  NSData *responseData = JSONPData(@{}, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializer];
  [serializer validateResponse:response data:responseData error:&error];
  expect(error).notTo.beNil();
  expect([error domain]).to.equal(AFNetworkingErrorDomain);
  expect([error code]).to.equal(NSURLErrorCannotDecodeContentData);
}

- (void)testThatJSONPResponseSerializerReturnsErrorForPlainJSON
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/javascript");
  NSString *callback = @"foo";
  id json = @{
    @"bert"   : @"ernie",
    @"count"  : @12345,
    @"yesno"  : @YES,
    @"maybe"  : @NO,
    @"cookie" : @[@"monster"],
    @"room"   : @{@"johnny": @"lisa"},
  };
  NSData *responseData = [NSJSONSerialization dataWithJSONObject:json
                                                         options:0
                                                           error:NULL];
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  NSError *error = nil;
  id responseObject = [serializer responseObjectForResponse:response
                                                       data:responseData
                                                      error:&error];
  expect(error).notTo.beNil();
  expect([error domain]).to.equal(CDLJSONPResponseSerializerErrorDomain);
  expect([error code]).to.equal(NSURLErrorCannotParseResponse);
  NSDictionary *errorInfo = [error userInfo];
  expect(errorInfo[NSURLErrorFailingURLErrorKey]).to.equal([response URL]);
  expect(errorInfo[NSLocalizedDescriptionKey]).notTo.beNil();
  expect(responseObject).to.beNil();
}

- (void)testThatJSONPResponseSerializerReturnsErrorForJSONPWithWrongCallback
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/javascript");
  NSString *callback = @"foo";
  id json = @{
    @"bert"   : @"ernie",
    @"count"  : @12345,
    @"yesno"  : @YES,
    @"maybe"  : @NO,
    @"cookie" : @[@"monster"],
    @"room"   : @{@"johnny": @"lisa"},
  };
  NSData *responseData = JSONPData(json, callback, @"x", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  NSError *error = nil;
  id responseObject = [serializer responseObjectForResponse:response
                                                       data:responseData
                                                      error:&error];
  expect(error).notTo.beNil();
  expect([error domain]).to.equal(CDLJSONPResponseSerializerErrorDomain);
  expect([error code]).to.equal(NSURLErrorCannotParseResponse);
  NSDictionary *errorInfo = [error userInfo];
  expect(errorInfo[NSURLErrorFailingURLErrorKey]).to.equal([response URL]);
  expect(errorInfo[NSLocalizedDescriptionKey]).notTo.beNil();
  expect(responseObject).to.beNil();
}

- (void)testThatJSONPResponseSerializerReturnsErrorForString
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/javascript");
  NSString *callback = @"foo";
  id json = @"\"bert\"";
  NSData *responseData = JSONPData(json, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  NSError *error = nil;
  id responseObject = [serializer responseObjectForResponse:response
                                                       data:responseData
                                                      error:&error];
  expect(error).notTo.beNil();
  expect([error domain]).to.equal(CDLJSONPResponseSerializerErrorDomain);
  expect([error code]).to.equal(NSURLErrorCannotParseResponse);
  NSDictionary *errorInfo = [error userInfo];
  expect(errorInfo[NSURLErrorFailingURLErrorKey]).to.equal([response URL]);
  expect(errorInfo[NSLocalizedDescriptionKey]).notTo.beNil();
  expect(responseObject).to.beNil();
}

- (void)testThatJSONPResponseSerializerReturnsErrorForNumber
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/javascript");
  NSString *callback = @"foo";
  id json = @"12345";
  NSData *responseData = JSONPData(json, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  NSError *error = nil;
  id responseObject = [serializer responseObjectForResponse:response
                                                       data:responseData
                                                      error:&error];
  expect(error).notTo.beNil();
  expect([error domain]).to.equal(CDLJSONPResponseSerializerErrorDomain);
  expect([error code]).to.equal(NSURLErrorCannotParseResponse);
  NSDictionary *errorInfo = [error userInfo];
  expect(errorInfo[NSURLErrorFailingURLErrorKey]).to.equal([response URL]);
  expect(errorInfo[NSLocalizedDescriptionKey]).notTo.beNil();
  expect(responseObject).to.beNil();
}

- (void)testThatJSONPResponseSerializerReturnsErrorForTrue
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/javascript");
  NSString *callback = @"foo";
  id json = @"true";
  NSData *responseData = JSONPData(json, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  NSError *error = nil;
  id responseObject = [serializer responseObjectForResponse:response
                                                       data:responseData
                                                      error:&error];
  expect(error).notTo.beNil();
  expect([error domain]).to.equal(CDLJSONPResponseSerializerErrorDomain);
  expect([error code]).to.equal(NSURLErrorCannotParseResponse);
  NSDictionary *errorInfo = [error userInfo];
  expect(errorInfo[NSURLErrorFailingURLErrorKey]).to.equal([response URL]);
  expect(errorInfo[NSLocalizedDescriptionKey]).notTo.beNil();
  expect(responseObject).to.beNil();
}

- (void)testThatJSONPResponseSerializerReturnsErrorForFalse
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/javascript");
  NSString *callback = @"foo";
  id json = @"false";
  NSData *responseData = JSONPData(json, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  NSError *error = nil;
  id responseObject = [serializer responseObjectForResponse:response
                                                       data:responseData
                                                      error:&error];
  expect(error).notTo.beNil();
  expect([error domain]).to.equal(CDLJSONPResponseSerializerErrorDomain);
  expect([error code]).to.equal(NSURLErrorCannotParseResponse);
  NSDictionary *errorInfo = [error userInfo];
  expect(errorInfo[NSURLErrorFailingURLErrorKey]).to.equal([response URL]);
  expect(errorInfo[NSLocalizedDescriptionKey]).notTo.beNil();
  expect(responseObject).to.beNil();
}

- (void)testThatJSONPResponseSerializerReturnsErrorForNull
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/javascript");
  NSString *callback = @"foo";
  id json = @"null";
  NSData *responseData = JSONPData(json, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  NSError *error = nil;
  id responseObject = [serializer responseObjectForResponse:response
                                                       data:responseData
                                                      error:&error];
  expect(error).notTo.beNil();
  expect([error domain]).to.equal(CDLJSONPResponseSerializerErrorDomain);
  expect([error code]).to.equal(NSURLErrorCannotParseResponse);
  NSDictionary *errorInfo = [error userInfo];
  expect(errorInfo[NSURLErrorFailingURLErrorKey]).to.equal([response URL]);
  expect(errorInfo[NSLocalizedDescriptionKey]).notTo.beNil();
  expect(responseObject).to.beNil();
}

- (void)testThatJSONPResponseSerializerReturnsErrorForUndefined
{
  NSHTTPURLResponse *response = SuccessfulResponse(@"application/javascript");
  NSString *callback = @"foo";
  id json = @"undefined";
  NSData *responseData = JSONPData(json, callback, @"", @"");
  CDLJSONPResponseSerializer *serializer =
    [CDLJSONPResponseSerializer serializerWithCallback:callback];
  NSError *error = nil;
  id responseObject = [serializer responseObjectForResponse:response
                                                       data:responseData
                                                      error:&error];
  expect(error).notTo.beNil();
  expect([error domain]).to.equal(CDLJSONPResponseSerializerErrorDomain);
  expect([error code]).to.equal(NSURLErrorCannotParseResponse);
  NSDictionary *errorInfo = [error userInfo];
  expect(errorInfo[NSURLErrorFailingURLErrorKey]).to.equal([response URL]);
  expect(errorInfo[NSLocalizedDescriptionKey]).notTo.beNil();
  expect(responseObject).to.beNil();
}

@end
