#import "TestHatenaBookmark.h"
#import "SimpleHttpClient.h"

@implementation TestHatenaBookmark

//----------------------------------------------------------------------------//
#pragma mark -- Internal --
//----------------------------------------------------------------------------//

- (NSString *)getInputStreamWithPrompt:(NSString *)prompt
{
    NSFileHandle *output = [NSFileHandle fileHandleWithStandardOutput];
    NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];

    [output writeData:[NSData
        dataWithBytes:[prompt UTF8String]
               length:[prompt length]
    ]];

    NSMutableData *line = [NSMutableData dataWithData:[input availableData]];
    char *p = [line mutableBytes];
    p[[line length] - 1] = (char)NULL;

    return [NSString stringWithUTF8String:[line bytes]];
}

- (void)sendHttpRequest
{
    NSString *username = [self
        getInputStreamWithPrompt:@"Input Hatena Username:"
    ];
    NSString *password = [self
        getInputStreamWithPrompt:@"Input Hatena Password:"
    ];

    [_isAllLoaded setObject:@"NO" forKey:@"feed"];

    SimpleHttpClient *client = [[SimpleHttpClient alloc] initWithDelegate:self];
    [client autorelease];

    [client
        setCredentialForHost:@"b.hatena.ne.jp"
                    username:username
                    password:password
    ];

    [client
               get:@"http://b.hatena.ne.jp/atom"
        parameters:nil
           context:@"feed"
    ];
}

- (void)waitHttpResponse
{
    BOOL is_running;
    do {
        is_running = [[NSRunLoop currentRunLoop]
            runMode:NSDefaultRunLoopMode
            beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]
        ];
    } while (is_running && !is_loaded);
}

//----------------------------------------------------------------------------//
#pragma mark -- SimpleHttpClientOperation delegate --
//----------------------------------------------------------------------------//

- (void)simpleHttpClientOperation:(SimpleHttpClientOperation *)operation
didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSInteger status = [response statusCode];
    NSLog(@"status = %d", status);
    [_response setObject:response forKey:operation.context];
} 

- (void)simpleHttpClientOperation:(SimpleHttpClientOperation *)operation
    didReceiveData:(NSData *)data
{
    NSLog(@"data = %@", [NSString stringWithUTF8String:[data bytes]]);
    if (![_data objectForKey:operation.context]) {
        [_data setObject:[NSMutableData data] forKey:operation.context];
    }
    [[_data objectForKey:operation.context] appendData:data];
} 

- (void)simpleHttpClientOperation:(SimpleHttpClientOperation *)operation
  didFailWithError:(NSError *)error
{
    NSLog(@"error = %@", error);
    [_error setObject:error forKey:operation.context];
} 

//----------------------------------------------------------------------------//
#pragma mark -- SimpleHttpClient delegate --
//----------------------------------------------------------------------------//

- (void)simpleHttpClient:(SimpleHttpClient *)client
      didFinishOperation:(SimpleHttpClientOperation *)operation
{
    [_isAllLoaded setObject:@"YES" forKey:operation.context];

    NSEnumerator *isAllLoadedEnum = [_isAllLoaded keyEnumerator];
    NSString *context;
    while (context = [isAllLoadedEnum nextObject]) {
        if ([[_isAllLoaded objectForKey:context] isEqualToString:@"NO"]) {
            return;
        }
    }

    is_loaded = YES;
}

//----------------------------------------------------------------------------//
#pragma mark -- Initialize --
//----------------------------------------------------------------------------//

- (id)init
{
    if (![super init]) {
        return nil;
    }

    is_loaded   = NO;

    _isAllLoaded = [NSMutableDictionary dictionary];
    _response    = [NSMutableDictionary dictionary];
    _data        = [NSMutableDictionary dictionary];
    _error       = [NSMutableDictionary dictionary];

    return self;
}

- (void)dealloc
{
    _isAllLoaded = nil;
    _response    = nil;
    _data        = nil;
    _error       = nil;

    [super dealloc];
}

//----------------------------------------------------------------------------//
#pragma mark -- APIs --
//----------------------------------------------------------------------------//

- (void)runTest
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"start TestSimpleHttpClientWSSE\n");
    @try {
        [self sendHttpRequest];
        [self waitHttpResponse];

//        NSAssert1(0 < length, @"%d byte.", length);
    }
    @catch (NSException *ex) {
        NSLog(@"Name  : %@\n", [ex name]);
        NSLog(@"Reason: %@\n", [ex reason]);
    }
    NSLog(@"end TestSimpleHttpClientWSSE\n");

    [pool release];
}

@end
