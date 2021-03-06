#import "TestSimpleHttpClientOperation.h"
#import "SimpleHttpClientOperation.h"

@implementation TestSimpleHttpClientOperation

//----------------------------------------------------------------------------//
#pragma mark -- Internal --
//----------------------------------------------------------------------------//

- (void)sendHttpRequest
{
    NSURLRequest *request = [NSURLRequest 
        requestWithURL:[NSURL
            URLWithString:@"http://www.google.com/"
        ]
        cachePolicy:NSURLRequestUseProtocolCachePolicy
        timeoutInterval:60.0
    ];

    SimpleHttpClientOperation *operation = [
        [SimpleHttpClientOperation alloc]
        initWithRequest:request
                 filter:nil
                context:nil
               delegate:self
    ];
    [operation autorelease];

    [operation
        addObserver:self
         forKeyPath:@"isFinished"
            options:NSKeyValueObservingOptionNew
            context:nil
    ];

    [_queue addOperation:operation];
}

//----------------------------------------------------------------------------//
#pragma mark -- Initialize --
//----------------------------------------------------------------------------//

- (id)init
{
    if (![super init]) {
        return nil;
    }

    _queue      = [[NSOperationQueue alloc] init];
    _response   = nil;
    _data       = [[NSMutableData alloc] init];
    _error      = nil;

    return self;
}

- (void)dealloc
{
    [_queue cancelAllOperations], [_queue release], _queue = nil;
    [_response release], _response = nil;
    [_data release], _data = nil;
    [_error release], _error = nil;

    [super dealloc];
}

//----------------------------------------------------------------------------//
#pragma mark -- Observe --
//----------------------------------------------------------------------------//

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    [object removeObserver:self forKeyPath:keyPath];
    [self setFinish];
}

//----------------------------------------------------------------------------//
#pragma mark -- SimpleHttpClientOperation delegate --
//----------------------------------------------------------------------------//

- (void)simpleHttpClientOperation:(SimpleHttpClientOperation *)operation
didReceiveResponse:(NSHTTPURLResponse *)response
{
    [_response release];
    _response = [response retain];
} 

- (void)simpleHttpClientOperation:(SimpleHttpClientOperation *)operation
    didReceiveData:(NSData *)data
{
    [_data appendData:data];
} 

- (void)simpleHttpClientOperation:(SimpleHttpClientOperation *)operation
  didFailWithError:(NSError *)error
{
    [_error release];
    _error = [error retain];
} 

//----------------------------------------------------------------------------//
#pragma mark -- APIs --
//----------------------------------------------------------------------------//

- (void)test
{
    [self sendHttpRequest];
    [self waitFinish];

    NSInteger status = [_response statusCode];
    NSAssert1(200 == status, @"status is %d.", status);

    NSInteger length = [_data length];
    NSAssert1(0 < length, @"%d byte.", length);

    NSLog(@"%d byte was received.\n", length);
}

@end
