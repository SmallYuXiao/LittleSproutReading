//
//  YouTubeWebView.swift
//  LittleSproutReading
//
//  YouTube Web 页面视图 - 用于浏览和选择视频
//

import SwiftUI
import WebKit

/// WebView 包装器 - 用于在 SwiftUI 中使用 WKWebView
struct YouTubeWebView: UIViewRepresentable {
    @ObservedObject var viewModel: VideoPlayerViewModel
    let onVideoSelected: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = .all
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // 使用搜索语法排除 Shorts：加 -"#shorts" -shorts
        let searchQuery = "english learning -\"#shorts\" -shorts"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery
        if let url = URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 不需要更新
    }
    
    // MARK: - Coordinator (处理 WebView 导航事件)
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: YouTubeWebView
        
        init(_ parent: YouTubeWebView) {
            self.parent = parent
        }
        
        // 拦截导航请求
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            let urlString = url.absoluteString
            print("🌐 [WebView] 导航到: \(urlString)")
            
            // 检测是否是 YouTube 视频链接
            if let videoID = YouTubeURLParser.extractVideoID(from: urlString) {
                print("🎬 [WebView] 检测到视频 ID: \(videoID)")
                
                // 拦截导航，跳转到应用内播放器
                DispatchQueue.main.async {
                    self.parent.onVideoSelected(urlString)
                }
                
                decisionHandler(.cancel)
                return
            }
            
            // 允许其他导航（浏览 YouTube 页面）
            decisionHandler(.allow)
        }
        
        // 页面加载开始
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🌐 [WebView] 开始加载页面")
        }
        
        // 页面加载完成
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ [WebView] 页面加载完成")
            
            // 注入 JavaScript 禁用悬停自动播放
            let disableHoverPlayScript = """
            (function() {
                // 禁用 YouTube 的悬停自动播放功能
                var style = document.createElement('style');
                style.innerHTML = `
                    /* 禁用视频缩略图的悬停播放 */
                    ytd-thumbnail video,
                    ytd-moving-thumbnail-renderer video,
                    ytd-video-preview video {
                        display: none !important;
                        pointer-events: none !important;
                    }
                    
                    /* 禁用悬停时的动画效果 */
                    ytd-thumbnail:hover video {
                        opacity: 0 !important;
                    }
                    
                    /* 确保静态缩略图始终显示 */
                    ytd-thumbnail img {
                        display: block !important;
                        opacity: 1 !important;
                    }
                `;
                document.head.appendChild(style);
                
                // 阻止视频元素加载和播放
                setInterval(function() {
                    var videos = document.querySelectorAll('ytd-thumbnail video, ytd-moving-thumbnail-renderer video');
                    videos.forEach(function(video) {
                        video.pause();
                        video.removeAttribute('src');
                        video.load();
                    });
                }, 500);
                
                console.log('🚫 YouTube 悬停自动播放已禁用');
            })();
            """
            
            webView.evaluateJavaScript(disableHoverPlayScript) { result, error in
                if let error = error {
                    print("❌ [WebView] 注入脚本失败: \(error.localizedDescription)")
                } else {
                    print("✅ [WebView] 已禁用悬停自动播放")
                }
            }
        }
        
        // 页面加载失败
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ [WebView] 页面加载失败: \(error.localizedDescription)")
        }
    }
}

/// YouTube Web 浏览视图（全屏原生风格）
struct YouTubeWebBrowserView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var webView: WKWebView?
    @State private var savedScrollPosition: CGPoint = .zero  // 保存滚动位置
    
    var body: some View {
        // 全屏 WebView，不需要导航栏，更像原生应用
        YouTubeWebViewWithControls(
            viewModel: viewModel,
            canGoBack: $canGoBack,
            canGoForward: $canGoForward,
            isLoading: $isLoading,
            webView: $webView,
            savedScrollPosition: $savedScrollPosition
        )
        .background(Color.black)
        .ignoresSafeArea()  // 忽略安全区域，顶部和底部贴合屏幕，更像原生应用
        .onAppear {
            print("🖥️ [WebView] WebView 视图出现（全屏原生风格）")
            // 重置恢复标志，允许下次返回时再次恢复
            if let wv = webView, let delegate = wv.navigationDelegate as? YouTubeWebViewWithControls.Coordinator {
                delegate.hasRestoredPosition = false
                print("   🔄 已重置 hasRestoredPosition")
            }
        }
        .onDisappear {
            print("🖥️ [WebView] WebView 视图消失，保存滚动位置")
            // 保存滚动位置
            saveScrollPosition()
        }
    }
    
    // MARK: - 保存和恢复滚动位置
    
    private func saveScrollPosition() {
        guard let webView = webView else {
            print("⚠️ [WebView] webView 为 nil，无法保存滚动位置")
            return
        }
        
        webView.evaluateJavaScript("window.scrollY") { [self] result, error in
            if let error = error {
                print("❌ [WebView] 获取滚动位置失败: \(error.localizedDescription)")
                return
            }
            
            if let scrollY = result as? CGFloat {
                DispatchQueue.main.async {
                    self.savedScrollPosition = CGPoint(x: 0, y: scrollY)
                    print("💾 [WebView] 保存滚动位置: Y = \(scrollY)")
                }
            }
        }
    }
}

/// WebView 包装器（带状态绑定）
struct YouTubeWebViewWithControls: UIViewRepresentable {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var webView: WKWebView?
    @Binding var savedScrollPosition: CGPoint
    
    // 使用静态变量保持 WebView 实例
    private static var sharedWebView: WKWebView?
    private static var hasLoadedInitialPage = false
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // 如果已有实例，直接返回
        if let existingWebView = Self.sharedWebView {
            print("♻️ [WebView] 重用现有 WebView 实例")
            // 重新设置 navigationDelegate，确保拦截功能正常
            existingWebView.navigationDelegate = context.coordinator
            print("   ✅ navigationDelegate 已重新设置")
            return existingWebView
        }
        
        print("🆕 [WebView] 创建新的 WebView 实例")
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = .all
        
        // 确保可以拦截所有导航请求
        webConfiguration.preferences.javaScriptEnabled = true
        
        // 创建 UserScript - 在页面加载开始时就注入
        let interceptScript = """
        (function() {
            console.log('🔧 [Early] YouTube 拦截脚本（早期注入）');
            
            // 等待 DOM 加载完成
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', setupInterceptor);
            } else {
                setupInterceptor();
            }
            
            function setupInterceptor() {
                if (window.ytInterceptorInstalled) {
                    console.log('⚠️ 拦截器已存在');
                    return;
                }
                window.ytInterceptorInstalled = true;
                
                console.log('🎯 设置视频链接拦截器...');
                
                // 拦截所有点击事件
                document.addEventListener('click', function(e) {
                    let target = e.target;
                    let depth = 0;
                    
                    // 向上查找 <a> 标签
                    while (target && target.tagName !== 'A' && depth < 10) {
                        target = target.parentElement;
                        depth++;
                    }
                    
                    if (target && target.href) {
                        let url = target.href;
                        console.log('🔗 [Interceptor] 点击: ' + url);
                        
                        // 检测视频链接
                        if (url.includes('/watch?v=') || 
                            url.includes('youtu.be/') || 
                            url.includes('/shorts/') ||
                            url.includes('/embed/')) {
                            
                            console.log('🎬 [Interceptor] 视频链接！阻止并导航');
                            e.preventDefault();
                            e.stopPropagation();
                            e.stopImmediatePropagation();
                            
                            // 延迟一点点，确保事件完全取消
                            setTimeout(function() {
                                window.location.href = url;
                            }, 10);
                            
                            return false;
                        }
                    }
                }, true); // 捕获阶段
                
                console.log('✅ [Early] 拦截器激活');
            }
        })();
        """
        
        let userScript = WKUserScript(
            source: interceptScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        
        webConfiguration.userContentController.addUserScript(userScript)
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        print("🌐 [WebView] WebView 初始化完成")
        print("   navigationDelegate 已设置")
        print("   UserScript 已注入（atDocumentStart）")
        
        // 保存 WebView 实例
        Self.sharedWebView = webView
        
        // 保存 webView 引用到 Binding
        DispatchQueue.main.async {
            self.webView = webView
        }
        
        // 只在第一次创建时加载首页
        if !Self.hasLoadedInitialPage {
            let searchQuery = "english news talks interview speech"
            let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery
            
            if let url = URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)") {
                let request = URLRequest(url: url)
                print("🌐 [WebView] 首次加载首页: \(url.absoluteString)")
                print("🔍 搜索关键词: english news talks interview speech")
                webView.load(request)
                Self.hasLoadedInitialPage = true
            }
        } else {
            print("♻️ [WebView] 跳过重复加载，保持当前页面")
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 确保 navigationDelegate 始终设置正确
        if webView.navigationDelegate !== context.coordinator {
            webView.navigationDelegate = context.coordinator
            print("🔄 [WebView] navigationDelegate 已更新")
        }
        
        // 更新导航状态
        DispatchQueue.main.async {
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
        }
        
        // 如果有保存的滚动位置，恢复它
        if savedScrollPosition.y > 0 && !context.coordinator.hasRestoredPosition {
            context.coordinator.hasRestoredPosition = true
            
            print("📍 [WebView] 在 updateUIView 中恢复滚动位置: Y = \(savedScrollPosition.y)")
            
            // 延迟恢复，确保页面已渲染
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                webView.evaluateJavaScript("window.scrollTo(0, \(self.savedScrollPosition.y))") { _, error in
                    if let error = error {
                        print("❌ [WebView] 恢复滚动位置失败: \(error.localizedDescription)")
                    } else {
                        print("✅ [WebView] 滚动位置已恢复")
                        // 恢复后清空，防止重复恢复
                        DispatchQueue.main.async {
                            self.savedScrollPosition = .zero
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: YouTubeWebViewWithControls
        var hasRestoredPosition = false  // 标记是否已恢复位置
        
        init(_ parent: YouTubeWebViewWithControls) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print("⚡️ [Coordinator] decidePolicyFor 被调用")
            
            guard let url = navigationAction.request.url else {
                print("   ⚠️ URL 为 nil，允许导航")
                decisionHandler(.allow)
                return
            }
            
            let urlString = url.absoluteString
            
            // 打印所有导航类型，便于调试
            let navType = navigationAction.navigationType
            print("🌐 [WebView] 导航事件:")
            print("   URL: \(urlString)")
            print("   类型: \(navType.rawValue) (0=链接点击, 1=表单提交, 2=后退/前进, 3=重载, 4=表单重新提交, -1=其他)")
            
            // 检测 YouTube 视频链接
            if let videoID = YouTubeURLParser.extractVideoID(from: urlString) {
                print(String(repeating: "=", count: 60))
                print("🎬 [WebView] 检测到 YouTube 视频！")
                print("📹 视频 ID: \(videoID)")
                print("🔗 原始 URL: \(urlString)")
                print("🚀 拦截导航，跳转到应用内播放器...")
                print(String(repeating: "=", count: 60))
                
                // 立即取消导航
                decisionHandler(.cancel)
                
                // 跳转到应用内播放器
                DispatchQueue.main.async {
                    let video = Video(youtubeVideoID: videoID, title: "Loading...")
                    print("📡 调用 loadVideo() - 将调用后端 API 获取播放地址")
                    self.parent.viewModel.loadVideo(video, originalURL: urlString)
                }
                
                return
            }
            
            // 允许其他导航（浏览 YouTube 页面）
            print("   ✅ 允许导航")
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
            }
            
            print("✅ [WebView] 页面加载完成，准备注入拦截脚本...")
            
            // 首先注入禁用悬停播放的脚本
            let disableHoverPlayScript = """
            (function() {
                // 禁用 YouTube 的悬停自动播放功能
                var style = document.createElement('style');
                style.innerHTML = `
                    /* 禁用视频缩略图的悬停播放 */
                    ytd-thumbnail video,
                    ytd-moving-thumbnail-renderer video,
                    ytd-video-preview video {
                        display: none !important;
                        pointer-events: none !important;
                    }
                    
                    /* 禁用悬停时的动画效果 */
                    ytd-thumbnail:hover video {
                        opacity: 0 !important;
                    }
                    
                    /* 确保静态缩略图始终显示 */
                    ytd-thumbnail img {
                        display: block !important;
                        opacity: 1 !important;
                    }
                `;
                document.head.appendChild(style);
                
                // 阻止视频元素加载和播放
                setInterval(function() {
                    var videos = document.querySelectorAll('ytd-thumbnail video, ytd-moving-thumbnail-renderer video');
                    videos.forEach(function(video) {
                        video.pause();
                        video.removeAttribute('src');
                        video.load();
                    });
                }, 500);
                
                console.log('🚫 YouTube 悬停自动播放已禁用');
            })();
            """
            
            webView.evaluateJavaScript(disableHoverPlayScript) { _, _ in
                print("✅ [WebView] 已禁用悬停自动播放")
            }
            
            // 然后注入 JavaScript 来拦截视频点击
            let interceptScript = """
            (function() {
                console.log('🔧 YouTube 拦截脚本已注入');
                
                // 移除可能存在的旧监听器
                if (window.ytInterceptorInstalled) {
                    console.log('⚠️ 拦截器已存在，跳过');
                    return;
                }
                window.ytInterceptorInstalled = true;
                
                // 拦截所有链接点击（捕获阶段）
                document.addEventListener('click', function(e) {
                    // 查找最近的 <a> 标签
                    let target = e.target;
                    let depth = 0;
                    while (target && target.tagName !== 'A' && depth < 10) {
                        target = target.parentElement;
                        depth++;
                    }
                    
                    if (target && target.href) {
                        let url = target.href;
                        console.log('🔗 点击链接: ' + url);
                        
                        // 检测是否是视频链接
                        if (url.includes('/watch?v=') || 
                            url.includes('youtu.be/') || 
                            url.includes('/shorts/') ||
                            url.includes('/embed/')) {
                            console.log('🎬 检测到视频链接！');
                            console.log('   阻止默认行为并导航...');
                            
                            e.preventDefault();
                            e.stopPropagation();
                            e.stopImmediatePropagation();
                            
                            // 直接导航到该 URL（触发 decidePolicyFor）
                            window.location.href = url;
                            return false;
                        }
                    }
                }, true); // true = 捕获阶段
                
                console.log('✅ 点击拦截器已激活（捕获阶段）');
            })();
            """
            
            webView.evaluateJavaScript(interceptScript) { result, error in
                if let error = error {
                    print("❌ [WebView] JavaScript 注入失败: \(error.localizedDescription)")
                } else {
                    print("✅ [WebView] JavaScript 拦截脚本注入成功")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            print("❌ [WebView] 加载失败: \(error.localizedDescription)")
        }
    }
}

#Preview {
    YouTubeWebBrowserView(viewModel: VideoPlayerViewModel())
}

