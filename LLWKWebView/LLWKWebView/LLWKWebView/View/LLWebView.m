//
//  LLWebView.m
//  JavaScript
//
//  Created by L² on 2018/6/3.
//
/** APP版本号 */
#define LLWebViewAppVersion [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
#import "LLWebView.h"
// runtime 设置 objc_msgSend Calls = NO;
#import "objc/runtime.h"
#import "LLHtmlModel.h"
// WKWebView 内存不释放的问题解决
@interface WeakWebViewScriptMessageTestDelegate : NSObject<WKScriptMessageHandler>

//WKScriptMessageHandler 这个协议类专门用来处理JavaScript调用原生OC的方法
@property (nonatomic, weak) id<WKScriptMessageHandler> scriptTestDelegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptTestDelegate;

@end
@implementation WeakWebViewScriptMessageTestDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate {
    self = [super init];
    if (self) {
        _scriptTestDelegate = scriptDelegate;
    }
    return self;
}

#pragma mark - WKScriptMessageHandler
//遵循WKScriptMessageHandler协议，必须实现如下方法，然后把方法向外传递
//通过接收JS传出消息的name进行捕捉的回调方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    if ([self.scriptTestDelegate respondsToSelector:@selector(userContentController:didReceiveScriptMessage:)]) {
        [self.scriptTestDelegate userContentController:userContentController didReceiveScriptMessage:message];
    }
}

@end

@interface LLWebView()<WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler,UIImagePickerControllerDelegate>
/** WKWebView*/
@property(strong,nonatomic)WKWebView *webView;
/** 滚动条*/
@property (strong ,nonatomic) UIProgressView *progress;

/** 弹窗使用的ViewController*/
@property (nonatomic, strong) UIViewController *showAlertViewController;

/** 设置UserAgent*/
@property (nonatomic, strong) NSString *userAgent;

@end
@implementation LLWebView

-(UIProgressView *)progress{ // 滚动条
    if (_progress==nil) {
        _progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        _progress.trackTintColor = [UIColor clearColor]; // 背景条
        _progress.progressTintColor = [UIColor redColor]; // 进度条
        _progress.frame = CGRectMake(0, 0, self.bounds.size.width, 1.5);
    }
    return _progress;
}
/** 进度条颜色 默认红色*/
-(void)setProgressTintColor:(UIColor *)progressTintColor{
    _progressTintColor = progressTintColor;
    
    _progress.progressTintColor = progressTintColor; // 进度条
}

/** 进度条背景 默认透明*/
-(void)setTrackTintColor:(UIColor *)trackTintColor{
    _trackTintColor = trackTintColor;
    
    _progress.trackTintColor = trackTintColor; // 背景条
}

/** 初始化网页控件*/
-(void)initWithWKWebView{
    // 设置UserAgent
    [self setWebUserAgent];
    
    //创建网页配置对象
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    // 创建设置对象
    WKPreferences *preference = [[WKPreferences alloc]init];
    //最小字体大小 当将javaScriptEnabled属性设置为NO时，可以看到明显的效果
    preference.minimumFontSize = 0;
    //设置是否支持javaScript 默认是支持的
    preference.javaScriptEnabled = YES;
    // 在iOS上默认为NO，表示是否允许不经过用户交互由javaScript自动打开窗口
    preference.javaScriptCanOpenWindowsAutomatically = YES;
    config.preferences = preference;
    // 是使用h5的视频播放器在线播放, 还是使用原生播放器全屏播放
    config.allowsInlineMediaPlayback = YES;
    //设置视频是否需要用户手动播放  设置为NO则会允许自动播放
    if (@available(iOS 9.0, *)) {
        config.requiresUserActionForMediaPlayback = YES;
    } else {
        // Fallback on earlier versions
    }
    //设置是否允许画中画技术 在特定设备上有效
    if (@available(iOS 9.0, *)) {
        config.allowsPictureInPictureMediaPlayback = YES;
    } else {
        // Fallback on earlier versions
    }
    //设置请求的User-Agent信息中应用程序名称 iOS9后可用
    if (@available(iOS 9.0, *)) {
        config.applicationNameForUserAgent = @"ChinaDailyForiPad";
    } else {
        // Fallback on earlier versions
        NSLog(@"============iOS 8.0==================");
    }
    
    // -------------WKScriptMessageHandler------------------
    //自定义的WKScriptMessageHandler 是为了解决内存不释放的问题
    WeakWebViewScriptMessageTestDelegate *weakScriptMessageDelegate = [[WeakWebViewScriptMessageTestDelegate alloc] initWithDelegate:self];
    //这个类主要用来做native与JavaScript的交互管理
    WKUserContentController * wkUController = [[WKUserContentController alloc] init];
    //注册一个name为'某个名字'的js方法 设置处理接收JS方法的对象
    //        [wkUController addScriptMessageHandler:weakScriptMessageDelegate  name:@"接收某个方法名"];
    config.userContentController = wkUController;
    
    //以下代码适配文本大小
    NSString *jSString = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
    //用于进行JavaScript注入
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jSString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [config.userContentController addUserScript:wkUScript];
    
    _webView = [[WKWebView alloc] initWithFrame:self.bounds];
    _webView.navigationDelegate = self; // 导航代理
    _webView.UIDelegate = self; // UI代理
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO; // 背景完全透明
    // 是否允许手势左滑返回上一级, 类似导航控制的左滑返回
    _webView.allowsBackForwardNavigationGestures = NO;
    
    // 可返回的页面列表, 存储已打开过的网页
    WKBackForwardList * backForwardList = [_webView backForwardList];
    //        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.chinadaily.com.cn"]];
    //        [request addValue:[self readCurrentCookieWithDomain:@"http://www.chinadaily.com.cn"] forHTTPHeaderField:@"Cookie"];
    //        [_webView loadRequest:request];
    
    [self addSubview:self.webView]; // 网页
    [self addSubview:self.progress]; // 滚动条
}

+(instancetype)initWithFrame:(CGRect)frame showAlertViewController:(UIViewController *)showAlertViewController userAgent:(NSString *)userAgent {
    
    // 初始化
    LLWebView *webView = [[LLWebView alloc] initWithFrame:frame];
    webView.showAlertViewController = showAlertViewController;
    webView.backgroundColor = [UIColor clearColor];
    
    // 默认监听一个传值方法
    if ([webView.alertMethodName isEqualToString:@"(null)"] || !webView.alertMethodName || [webView.alertMethodName length] == 0) {
        webView.alertMethodName = @"setResponseObj";
    }
    
    // 设置userAgent
    webView.userAgent = userAgent;
    
    // 初始化网页控件
    [webView initWithWKWebView];
    
    // 初始化WKWebView 添加监听方法
    [webView.webView addObserver:webView forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    [webView.webView addObserver:webView forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    
    // 监听网页播放视频的通知
    [[NSNotificationCenter defaultCenter] addObserver:webView selector:@selector(windowVisible:) name:UIWindowDidBecomeVisibleNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:webView selector:@selector(windowHidden:) name:UIWindowDidBecomeHiddenNotification object:nil];
    
    return webView;
}

#pragma mark 网页播放了视频 -- 通知
- (void)windowVisible:(NSNotification *)notify{
    if ([self.delegate respondsToSelector:@selector(LLWebViewWindowVideo:notify:)]) {
        [self.delegate LLWebViewWindowVideo:YES notify:notify];
    }
}

#pragma mark 网页关闭了视频 -- 通知
- (void)windowHidden:(NSNotification *)notify{
    if ([self.delegate respondsToSelector:@selector(LLWebViewWindowVideo:notify:)]) {
        [self.delegate LLWebViewWindowVideo:NO notify:notify];
    }
}

#pragma mark - <************************** 代理 **************************>
/// 开始加载
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
//    NSLog(@"开始加载");
//    NSLog(@"url:%@",webView.URL.absoluteString);
    if (self.delegate&&[self.delegate respondsToSelector:@selector(LLWebViewDidStart:)]) {
        [self.delegate LLWebViewDidStart:webView];
    }
}
/// 获取到网页内容
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
//    NSLog(@"获取到内容");
}
/// 加载完成
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    
    [self getCookie];
    
//    NSLog(@"加载完成");
    if (self.delegate&&[self.delegate respondsToSelector:@selector(LLWebViewDidFinish:)]) {
        [self.delegate LLWebViewDidFinish:webView];
    }
}
// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation{
    [self.progress setProgress:0.0f animated:NO];
//    NSLog(@"加载失败");
    if (self.delegate&&[self.delegate respondsToSelector:@selector(LLWebViewDidFail:)]) {
        [self.delegate LLWebViewDidFail:webView];
    }
}

//提交发生错误时调用
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self.progress setProgress:0.0f animated:NO];
}
// 接收到服务器跳转请求即服务重定向时之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"接收到服务器跳转请求即服务重定向时之后调用");
}


#pragma mark - <************************** kvo监听 **************************>
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    // 监听标题
    if ([keyPath isEqualToString:@"title"]){
        if (object == self.webView){
            if (self.delegate&&[self.delegate respondsToSelector:@selector(LLWebViewDidGetTitle:)]) {
                [self.delegate LLWebViewDidGetTitle:self.webView.title];
            }
        }else{
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    
    // 监听进度
    else if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if (object == self.webView) {
//            NSLog(@"监听进度-%f",self.webView.estimatedProgress);
            self.progress.progress = self.webView.estimatedProgress;
            if (_webView.estimatedProgress >= 1.0f) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.progress.progress = 0;
                });
            }
        }
        else{
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - /** 加载网页*/
-(void)loadUrlString:(NSString *)urlString{
    // 是否加载的是本地html
    NSURL *URL;
    if ([urlString hasPrefix:@"http"]) {
        // 网络
        URL = [NSURL URLWithString:urlString];
    }else{
        urlString = [[NSBundle mainBundle] pathForResource:urlString ofType:nil];
        // 本地
        URL = [NSURL fileURLWithPath:urlString];
    }
    // 加载网页
    [self.webView loadRequest:[NSURLRequest requestWithURL:URL]];
}

#pragma mark 解决第一次进入的cookie丢失问题
- (NSString *)readCurrentCookieWithDomain:(NSString *)domainStr{
    NSHTTPCookieStorage*cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSMutableString * cookieString = [[NSMutableString alloc]init];
    for (NSHTTPCookie*cookie in [cookieJar cookies]) {
        [cookieString appendFormat:@"%@=%@;",cookie.name,cookie.value];
    }
    NSLog(@"%@",[cookieJar cookies]);
    //删除最后一个“;”
    if ([cookieString hasSuffix:@";"]) {
        [cookieString deleteCharactersInRange:NSMakeRange(cookieString.length - 1, 1)];
    }
    
    return cookieString;
}

#pragma mark 弹窗使用的控制器
-(void)setShowAlertViewController:(UIViewController *)showAlertViewController{
    _showAlertViewController = showAlertViewController;
}

#pragma mark 添加监听的方法名
-(void)setMethodName:(NSString *)methodName{
    _methodName = methodName;
    
    // 注册一个name为methodName内容的js方法 设置处理接收JS方法的对象
    [_webView.configuration.userContentController addScriptMessageHandler:self name:methodName];
}

#pragma mark 通过添加监听方法,进行的响应
/** 监听方法*/
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
//    NSString *name = message.name;
//    NSString *body = message.body;
//    NSLog(@"139行:\nname:%@\nbody:%@",name,body);
    if ([self.delegate respondsToSelector:@selector(LLWebViewUserContentController:didReceiveScriptMessage:)]) {
        [self.delegate LLWebViewUserContentController:userContentController didReceiveScriptMessage:message];
    }
}

#pragma mark HTML 调用Alter时 原生响应的方法(弹窗) -- WKUIDelegate
/**
    1.在JS端调用alert函数时，会触发此代理方法。
    2.JS端调用alert时所传的数据可以通过message,打印message信息读取出JS端给你的信息。
    3.在原生得到结果后，需要回调给JS，通过completionHandler 回调给JS
    4.completionHandler 回调的参数和返回值都是空
 
 JSON 格式:
    {"title":"确定要删除吗?",
    "message":"内容",
    "buttonCount":[
        {"title":"取消","buttonStyle":"2"},
        {"title":"确定","buttonStyle":"1"}],
        "functionType":"isCart"}
 */
-(void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(nonnull void (^)(void))completionHandler{
//    NSLog(@"在JS端调用alert函数时:%s\n%@----%@", __FUNCTION__,message,LLWebViewAppVersion);
    // 初始化弹窗视图
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    if (message.length > 0) {
        // 弹框发来的数据有值
        NSDictionary *h5ResponseObj = [LLWebView dictionaryWithJsonString:message];
        // 如果字典存在,并且 有按钮这个key
        if (h5ResponseObj && [[h5ResponseObj allKeys] containsObject:@"buttonCount"]) {
            // 转换成弹窗模型
            LLHtmlModel *model = [LLHtmlModel initWithModel:h5ResponseObj];
            // 根据json 弹窗
            [self showAlert:model alert:alert alertBlock:^(BOOL handler, NSString *result) {
                completionHandler();
            }];
        }else{
            // 没生成字典
            alert.title = @"提示";
            alert.message = message;
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                completionHandler();
            }]];
        }
    }else{
        // 弹框发来的数据没有值
        alert.title = @"提示";
        alert.message = message;
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completionHandler();
        }]];
    }
    
    [self.showAlertViewController presentViewController:alert animated:YES completion:NULL];
}

#pragma mark JS端调用confirm函数时，会触发此方法(提交表单)
// 通过message可以拿到JS端所传的数据
// 在iOS端显示原生alert得到YES/NO后
// 通过completionHandler回调给JS端
/**
 JSON 格式:
    {"title":"确定要删除吗?",
    "message":"内容",
    "buttonCount":[
        {"title":"取消","buttonStyle":"2"},
        {"title":"确定","buttonStyle":"1"}],
    "functionType":"isCart"}
 */
-(void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    
    // 初始化弹窗视图
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    if (message.length > 0) {
        // 弹框发来的数据有值
        NSDictionary *h5ResponseObj = [LLWebView dictionaryWithJsonString:message];
        // 如果字典存在,并且 有按钮这个key
        if (h5ResponseObj && [[h5ResponseObj allKeys] containsObject:@"buttonCount"]) {
            // 转换成弹窗模型
            LLHtmlModel *model = [LLHtmlModel initWithModel:h5ResponseObj];
            // 根据json 弹窗
            [self showAlert:model alert:alert alertBlock:^(BOOL handler, NSString *result) {
                completionHandler(handler);
            }];
            
        }else{
            // 没生成字典
            alert.title = @"提示";
            alert.message = message;
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                completionHandler(YES);
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                completionHandler(YES);
            }]];
        }
    }else{
        // 弹框发来的数据没有值
        alert.title = @"提示";
        alert.message = message;
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completionHandler(YES);
        }]];
    }
    [self.showAlertViewController presentViewController:alert animated:YES completion:NULL];
}
#pragma mark JS端调用prompt函数时(输入框)
// JS端调用prompt函数时，会触发此方法
// 要求输入一段文本
// 在原生输入得到文本内容后，通过completionHandler回调给JS
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    NSLog(@"-%@\n-%@",prompt,defaultText);
    // 初始化弹窗视图
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    if (prompt.length > 0) {
        // 弹框发来的数据有值
        NSDictionary *h5ResponseObj = [LLWebView dictionaryWithJsonString:prompt];
        // 如果字典存在,并且 有按钮这个key
        if (h5ResponseObj && [[h5ResponseObj allKeys] containsObject:@"buttonCount"]) {
            // 转换成弹窗模型
            LLHtmlModel *model = [LLHtmlModel initWithModel:h5ResponseObj];
            // 根据json 弹窗
            [self showAlert:model alert:alert alertBlock:^(BOOL handler, NSString *result) {
                completionHandler(result);
            }];
        }else{
            // 没生成字典
            alert.title = @"提示";
            alert.message = prompt;
            // --------------------字体颜色--------------------------------
            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"请输入";
                textField.textColor = [UIColor blackColor];
            }];
            // --------------------取消--------------------------------
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                completionHandler(@"");
            }]];
            
            // --------------------确定---------------------------------
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                completionHandler([[alert.textFields lastObject] text]);
                [self runJavaScriptSetResponseJSONFunctionType:prompt methodName:@"" buttonTitle:@"" message:[[alert.textFields lastObject] text]];
            }]];
        }
    }else{
        // 弹框发来的数据没有值
        alert.title = @"提示";
        alert.message = prompt;
        // --------------------字体颜色--------------------------------
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"请输入";
            textField.textColor = [UIColor blackColor];
        }];
        // --------------------取消--------------------------------
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            completionHandler(@"");
        }]];
        
        // --------------------确定---------------------------------
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completionHandler([[alert.textFields lastObject] text]);
            [self runJavaScriptSetResponseJSONFunctionType:prompt methodName:@"" buttonTitle:@"" message:[[alert.textFields lastObject] text]];
        }]];
    }
    [self.showAlertViewController presentViewController:alert animated:YES completion:NULL];
}

/** 根据JSON格式 弹窗*/
-(void)showAlert:(LLHtmlModel *)model alert:(UIAlertController *)alert alertBlock:(void(^)(BOOL handler,NSString * result))alertBlock{
    // 标题 内容
    alert.title = model.title;
    alert.message = model.message;
    
    if ([model.placeholder length] > 0) {
        // 输入框类型
        // 输入文字的颜色
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = model.placeholder;
            textField.textColor = [UIColor blackColor];
        }];
    }
    
    for (NSDictionary *buttonDict in model.buttonCount) {
        // 按钮标题
        NSString *buttonTitle = buttonDict[@"title"];
        // 按钮类型
        NSInteger buttonStyle = [buttonDict[@"buttonStyle"] integerValue];
        
        // 弹窗类型
        [alert addAction:[UIAlertAction actionWithTitle:buttonTitle style:buttonStyle handler:^(UIAlertAction * _Nonnull action) {
            if (buttonStyle == 0) {
                // 确定
                alertBlock(YES, [[alert.textFields lastObject] text]);
                /**
                 回传方法
                 functionType : 传过来的标识
                 methodName : 特殊情况下,调用h5的方法
                 buttonTitle : 按钮标题
                 message : 回传信息,比如输入框中的内容
                 */
                [self runJavaScriptSetResponseJSONFunctionType:model.functionType methodName:@"" buttonTitle:buttonTitle message:[[alert.textFields lastObject] text]];
            }else{
                // 取消
                alertBlock(NO, @"");
            }
        }]];
    }
}

#pragma mark 页面是弹出窗口 _blank 处理
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}


#pragma mark alert & confirm 接收自定义参数弹窗,回传方法
-(void)runJavaScriptSetResponseJSONFunctionType:(NSString *)functionType methodName:(NSString *)methodName buttonTitle:(NSString *)buttonTitle message:(NSString *)message{
    if ([message isEqualToString:@"(null)"] || !message) {
        message = @"";
    }

    NSDictionary *h5Dict = @{
                             @"equipment" : @"iOS", // 传入来源
                             @"functionType" : functionType,// 传过来的标识
                             @"version" : LLWebViewAppVersion, // 版本号
                             @"selected": buttonTitle, // 按钮名字
                             @"methodName" : methodName, // 传入一个调用HTML的方法名,便于接收判断进入其他方法
                             @"message" : message // 回传信息,比如输入框中的内容
                             };
    [self evaluateJSMethod:self.alertMethodName JavaScriptDict:h5Dict completionHandler:nil];
}


#pragma mark API是根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    NSString * urlStr = navigationAction.request.URL.absoluteString;
    NSLog(@"发送跳转请求：%@",urlStr);
    
    //自己定义的协议头
    NSString *htmlHeadString = @"baidu://";
    
    // 判断请求头是否是 https://www.baidu.com 如果是就不在请求加载跳转
    if([urlStr hasPrefix:htmlHeadString]){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"你想前往我的百度主页?" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }])];
        [alertController addAction:([UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL * url = [NSURL URLWithString:[urlStr stringByReplacingOccurrencesOfString:@"baidu://callName_?" withString:@""]];
            [[UIApplication sharedApplication] openURL:url];
            
        }])];
        [self.showAlertViewController presentViewController:alertController animated:YES completion:nil];
        
        decisionHandler(WKNavigationActionPolicyCancel);
    }else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark API是根据客户端受到的服务器响应头以及response相关信息来决定是否可以跳转
-(void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    
    NSString * urlStr = navigationResponse.response.URL.absoluteString;
    NSLog(@"当前跳转地址：%@",urlStr);
    //  允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
    //  不允许跳转
//    decisionHandler(WKNavigationResponsePolicyCancel);
}

#pragma mark 需要响应身份验证时调用 同样在block中需要传入用户身份凭证
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    
    //用户身份信息
    NSURLCredential * newCred = [[NSURLCredential alloc] initWithUser:@"user123" password:@"123" persistence:NSURLCredentialPersistenceNone];
    //为 challenge 的发送方提供 credential
    [challenge.sender useCredential:newCred forAuthenticationChallenge:challenge];
    completionHandler(NSURLSessionAuthChallengeUseCredential,newCred);
}

//进程被终止时调用
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    
}

#pragma mark 设置UserAgent
- (void)setWebUserAgent {
    //当然还有另一种方式可以全局设置
    if ([self.userAgent length] > 0) {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        NSString *userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        NSString*newUserAgent;
        newUserAgent = [userAgent stringByAppendingString:@"/"];
        newUserAgent = [newUserAgent stringByAppendingString:self.userAgent];
        NSDictionary*dictionary = [NSDictionary dictionaryWithObjectsAndKeys:newUserAgent,@"UserAgent",nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark 通过监听getJSON_iOS方法,动态返回json 给html
-(void)getHTMLJSONWithDict:(NSDictionary *)dict{
    /** JSON 格式
        {"className":"LLParams",
         "method":{
                "methodName":"getParams",
                "setMethodName":"setResponseObj"
        }}
     */
    // 创建对象(写到这里已经可以进行随机页面跳转了)
    id instance = [self getClass:dict[@"className"]];
    // 下面是调用方法－－－－－－－－－－－－
    // iOS 方法名
    NSString *methodName = dict[@"method"][@"methodName"];
    // HTML 方法名
    NSString *setMethodName = dict[@"method"][@"setMethodName"];
    // 根据名字获取方法
    SEL sel = NSSelectorFromString(methodName);
    // 返回值
    id params;
    // 如果有这个方法
    if ([instance respondsToSelector:sel]) {
        params = [instance performSelector:sel];
    }else{
        params = @{};
    }
    // 传个json 给html 通过方法名
    [self evaluateJSMethod:setMethodName JavaScriptDict:params completionHandler:nil];
}

#pragma mark 通过监听JumpManagerTool方法,动态创建传值跳转
- (void)jumpWithDict:(NSDictionary *)dict navController:(UINavigationController *)navController{
    /** JSON 格式
     {"className":"CViewController",
     "method":{
     "methodName":"refresh",
     "methodType":"void",
     "methodParameter":""
     },
     "properties":
     {
     "msgId":"1223030330",
     "msgType":"3"
     }}
     */
    
    //类名(对象名)
    // 创建对象(写到这里已经可以进行随机页面跳转了)
    id instance = [self getClass:dict[@"className"]];
    
    //下面是调用方法－－－－－－－－－－－－
    //    NSArray *methodArr = [NSArray arrayWithArray:dict[@"method"]];
    NSString *methodName = dict[@"method"][@"methodName"];// 方法名
    NSString *methodParameter = dict[@"method"][@"methodParameter"];// 方法参数
    NSString *methodType = dict[@"method"][@"methodType"];// 方法类型
    // 根据名字获取方法
    SEL sel = NSSelectorFromString(methodName);
    // 如果有这个方法
    if ([instance respondsToSelector:sel]) {
        if ([methodType isEqualToString:@"void"]) {
            // 无参数 无返回值
            [instance performSelector:sel];
        }else if ([methodType isEqualToString:@"parameter"]){
            // 有参数 无返回值
            [instance performSelector:sel withObject:methodParameter];
        }else if ([methodType isEqualToString:@"returnValue"]){
            // 有参数 有返回值
            id param = [instance performSelector:sel withObject:methodParameter];
            //假设为NSString *类型
            NSString *str = (NSString *)param;
        }else{
            NSLog(@"其他方法-----%@",methodName);
        }
    }else{
        NSLog(@"未发现的方法名 ---- %@",methodName);
    }
    
    //下面是传值－－－－－－－－－－－－－－
    [dict[@"properties"] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([self checkIsExistPropertyWithInstance:instance verifyPropertyName:key]) {
            //kvc给属性赋值
            NSLog(@"%@,%@",obj,key);
            [instance setValue:obj forKey:key];
        }else {
            NSLog(@"未发现 --- key=%@的属性",key);
        }
    }];
    [navController pushViewController:instance animated:YES];
}

// 根据字符串,返回一个实体类
-(id)getClass:(NSString *)name{
    //类名(对象名)
    NSString *class = name;
    const char *className = [class cStringUsingEncoding:NSASCIIStringEncoding];
    Class newClass = objc_getClass(className);
    if (!newClass) {
        //创建一个类
        Class superClass = [NSObject class];
        newClass = objc_allocateClassPair(superClass, className, 0);
        //注册你创建的这个类
        objc_registerClassPair(newClass);
    }
    
    // 创建对象(写到这里已经可以进行随机页面跳转了)
    return [[newClass alloc] init];
}

#pragma mark 判断某个类中 是否含有某个属性
-(BOOL)checkIsExistPropertyWithInstance:(id)instance verifyPropertyName:(NSString *)verifyPropertyName{
    unsigned int outCount, i;
    // 获取对象里的属性列表
    objc_property_t * properties = class_copyPropertyList([instance
                                                           class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property =properties[i];
        //  属性名转成字符串
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        // 判断该属性是否存在
        if ([propertyName isEqualToString:verifyPropertyName]) {
            free(properties);
            return YES;
        }
    }
    free(properties);
    
    // 再遍历父类中的属性
    Class superClass = class_getSuperclass([instance class]);
    
    //通过下面的方法获取属性列表
    unsigned int outCount2;
    objc_property_t *properties2 = class_copyPropertyList(superClass, &outCount2);
    
    for (int i = 0 ; i < outCount2; i++) {
        objc_property_t property2 = properties2[i];
        //  属性名转成字符串
        NSString *propertyName2 = [[NSString alloc] initWithCString:property_getName(property2) encoding:NSUTF8StringEncoding];
        // 判断该属性是否存在
        if ([propertyName2 isEqualToString:verifyPropertyName]) {
            free(properties2);
            return YES;
        }
    }
    free(properties2); //释放数组
    return NO;
}

#pragma mark 调用js方法,发送参数
-(void)evaluateJSMethod:(NSString *)method JavaScript:(NSString *)javaScript{
    if ([method length] > 0) {
        // setResponseObj('值')
        NSString *js = [NSString stringWithFormat:@"%@('%@')",method,javaScript];
        [self.webView evaluateJavaScript:js completionHandler:nil];
    }
}

#pragma mark 调用js方法,发送参数,JSON 格式
-(void)evaluateJSMethod:(NSString *)method JavaScriptDict:(NSDictionary *)dict  completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler{
    if ([method length] > 0) {
        NSString *js;
        if (dict) {
            // 将字典转成JSON 格式
            js = [NSString stringWithFormat:@"%@('%@')",method,[LLWebView convertToJsonData:dict]];
        }else{
            js = [NSString stringWithFormat:@"%@('%@')",method,@""];
        }
        
        [self.webView evaluateJavaScript:js completionHandler:completionHandler];
    }
}

#pragma mark 调用js方法,发送参数,拼接完整字符串
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler{
    [self.webView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}

#pragma mark 解决 页面内跳转（a标签等）还是取不到cookie的问题
- (void)getCookie{
    
    //取出cookie
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    //js函数
    NSString *JSFuncString =
    @"function setCookie(name,value,expires)\
    {\
    var oDate=new Date();\
    oDate.setDate(oDate.getDate()+expires);\
    document.cookie=name+'='+value+';expires='+oDate+';path=/'\
    }\
    function getCookie(name)\
    {\
    var arr = document.cookie.match(new RegExp('(^| )'+name+'=([^;]*)(;|$)'));\
    if(arr != null) return unescape(arr[2]); return null;\
    }\
    function delCookie(name)\
    {\
    var exp = new Date();\
    exp.setTime(exp.getTime() - 1);\
    var cval=getCookie(name);\
    if(cval!=null) document.cookie= name + '='+cval+';expires='+exp.toGMTString();\
    }";
    
    //拼凑js字符串
    NSMutableString *JSCookieString = JSFuncString.mutableCopy;
    for (NSHTTPCookie *cookie in cookieStorage.cookies) {
        NSString *excuteJSString = [NSString stringWithFormat:@"setCookie('%@', '%@', 1);", cookie.name, cookie.value];
        [JSCookieString appendString:excuteJSString];
    }
    //执行js
    [_webView evaluateJavaScript:JSCookieString completionHandler:nil];
    
}


#pragma mark - <************************** dealloc **************************>
-(void)dealloc{
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView.configuration.userContentController removeAllUserScripts]; // 移除所有
}

#pragma mark 返回上一页面
-(BOOL)goBack{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
        return YES;
    }else{
        return NO;
    }
}

#pragma mark 刷新页面
-(void)reload{
    [self.webView reload];
}


#pragma mark JSON->Dict
// 字典转字符串
+(NSString *)convertToJsonData:(NSDictionary *)dict{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    if (!jsonData) {
        NSLog(@"%@",error);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0,jsonString.length};
    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    return mutStr;
}
// 字典转json字符串方法
+(NSDictionary*)dictionaryWithJsonString:(NSString*)jsonString{
    NSData *JSONData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingMutableLeaves error:nil];
    return responseJSON;
}

#pragma mark 转换工具 (拼接中文URL)
/**
 *  中文 转 Encode
 */
+ (NSString *)URLEncodedString:(NSString *)String{
    NSString *unencodedString = String;
    NSString *encodedString = (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                     kCFAllocatorDefault, (CFStringRef)unencodedString,
                                                                                                     NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                     kCFStringEncodingUTF8));
    return encodedString;
}

/**
 *  Encode 转 中文
 */
+ (NSString *)URLDecodedString:(NSString *)String{
    NSString *encodedString = String;
    NSString *decodedString = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding
    (NULL,(__bridge CFStringRef)encodedString,CFSTR(""),
     CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    
    return decodedString;
}
@end
