// CDLJSONPResponseSerializer.h
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

#import "AFURLResponseSerialization.h"

/** Error domain for CDLJSONPResponseSerializer. */
extern NSString * const CDLJSONPResponseSerializerErrorDomain;

/** A response serializer that parses JSONP using a Javascript context. */
@interface CDLJSONPResponseSerializer
  : AFHTTPResponseSerializer <NSSecureCoding>

/**
 Convenience constructor.

 \param callback The name of the JSONP callback function.

 \return A new instance of CDLJSONPResponseSerializer.
 */
+ (instancetype)serializerWithCallback:(NSString *)callback;

/** The name of the JSONP callback function. */
@property (atomic, copy) NSString *callback;

@end
