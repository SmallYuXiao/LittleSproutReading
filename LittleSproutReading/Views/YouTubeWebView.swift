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
        webConfiguration.allowsInlineMediaPlayback = false  // 禁止内嵌播放，强制走详情页
        webConfiguration.mediaTypesRequiringUserActionForPlayback = .all
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // 推荐英语学习内容,使用时长过滤器排除 Shorts
        let searchQuery = "english learning podcast interview TED talk BBC news"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery
        // sp=EgQQARgE 表示只显示 4+ 分钟的视频(完全排除 Shorts)
        if let url = URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)&sp=EgQQARgE") {
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
            
            // 检测是否是 YouTube 视频链接
            if let videoID = YouTubeURLParser.extractVideoID(from: urlString) {
                
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
        }
        
        // 页面加载完成
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            
            // 注入 JavaScript 禁用列表内的任何视频播放
            let disableInlinePlayScript = """
            (function() {
                if (window.lsrInlineBlockInstalled) return;
                window.lsrInlineBlockInstalled = true;
                
                // 全局禁用 video 播放与 src 绑定，防止滚动停下后的自动播放
                (function patchVideo() {
                    if (window.lsrVideoPatched) return;
                    window.lsrVideoPatched = true;
                    const proto = HTMLMediaElement.prototype;
                    
                    // 禁用 play
                    const blockPlay = function() {
                        try { this.pause(); } catch(e) {}
                        return Promise.reject(new DOMException('blocked', 'NotAllowedError'));
                    };
                    proto.play = blockPlay;
                    
                    // 禁用 src setter
                    const srcDesc = Object.getOwnPropertyDescriptor(HTMLMediaElement.prototype, 'src');
                    if (srcDesc && srcDesc.set) {
                        Object.defineProperty(HTMLMediaElement.prototype, 'src', {
                            get: srcDesc.get,
                            set: function(_) {
                                try { this.pause(); this.removeAttribute('src'); this.load(); } catch(e) {}
                            },
                            configurable: true
                        });
                    }
                    
                    // 禁用 load
                    const origLoad = proto.load;
                    proto.load = function() {
                        try { this.pause(); } catch(e) {}
                        return;
                    };
                })();
                
                var style = document.createElement('style');
                style.innerHTML = `
                    ytd-thumbnail video,
                    ytd-moving-thumbnail-renderer video,
                    ytd-video-preview video,
                    ytd-player video,
                    .html5-video-player video {
                        display: none !important;
                        pointer-events: none !important;
                    }
                    ytd-thumbnail img { opacity: 1 !important; }
                    ytd-player, #player, .html5-video-player { pointer-events: none !important; }
                    ytd-app #movie_player { pointer-events: none !important; }
                    ytd-app .html5-video-player { pointer-events: none !important; }
                    ytd-app ytd-player { pointer-events: none !important; }
                `;
                document.head.appendChild(style);
                
                function scrubVideos() {
                    var videos = document.querySelectorAll('video');
                    videos.forEach(function(video) {
                        try { video.pause(); } catch(e) {}
                        video.removeAttribute('src');
                        video.load();
                    });
                }
                
                scrubVideos();
                
                // 滚动/可见性变化时也强制暂停并移除 src，防止滑动停下后自动播放
                ['scroll', 'touchend', 'wheel', 'visibilitychange'].forEach(function(evt) {
                    document.addEventListener(evt, scrubVideos, true);
                });
                
                // 监听 DOM 变化，发现新的视频节点就清理，防止动态加载
                var observer = new MutationObserver(function(mutations) {
                    let foundVideo = false;
                    for (const m of mutations) {
                        if (m.addedNodes && m.addedNodes.length) {
                            foundVideo = true; break;
                        }
                    }
                    if (foundVideo) scrubVideos();
                });
                observer.observe(document.documentElement || document.body, { childList: true, subtree: true });
                
                // 定时兜底
                setInterval(scrubVideos, 500);
            })();
            """
            
            webView.evaluateJavaScript(disableInlinePlayScript) { _, _ in }
        }
        
        // 页面加载失败
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
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
            // 重置恢复标志，允许下次返回时再次恢复
            if let wv = webView, let delegate = wv.navigationDelegate as? YouTubeWebViewWithControls.Coordinator {
                delegate.hasRestoredPosition = false
            }
        }
        .onDisappear {
            // 保存滚动位置
            saveScrollPosition()
        }
    }
    
    // MARK: - 保存和恢复滚动位置
    
    private func saveScrollPosition() {
        guard let webView = webView else {
            return
        }
        
        webView.evaluateJavaScript("window.scrollY") { [self] result, error in
            if let error = error {
                return
            }
            
            if let scrollY = result as? CGFloat {
                DispatchQueue.main.async {
                    self.savedScrollPosition = CGPoint(x: 0, y: scrollY)
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
            // 重新设置 navigationDelegate，确保拦截功能正常
            existingWebView.navigationDelegate = context.coordinator
            return existingWebView
        }
        
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = false  // 禁止内嵌播放
        webConfiguration.mediaTypesRequiringUserActionForPlayback = .all
        
        // 确保可以拦截所有导航请求
        webConfiguration.preferences.javaScriptEnabled = true
        
        // 创建 UserScript - 在页面加载开始时就注入
        let interceptScript = """
        (function() {
            if (window.lsrInterceptorInstalled) return;
            window.lsrInterceptorInstalled = true;
            
            const VIDEO_PATTERNS = [/\\/watch\\?v=/, /youtu\\.be\\//, /\\/shorts\\//, /\\/embed\\//];
            const isVideoUrl = (url) => {
                if (!url) return false;
                try { url = new URL(url, location.origin).href; } catch(e) {}
                return VIDEO_PATTERNS.some(p => p.test(url));
            };
            
            const routeToNative = (url) => {
                setTimeout(() => { window.location.href = url; }, 0);
            };
            
            const handleNavigate = (url, evt) => {
                if (!isVideoUrl(url)) return false;
                if (evt && evt.stopImmediatePropagation) evt.stopImmediatePropagation();
                if (evt && evt.preventDefault) evt.preventDefault();
                routeToNative(url);
                return true;
            };
            
            // 从事件路径中提取视频 URL（兼容无 <a> 的卡片点击）
            const extractUrlFromPath = (path) => {
                for (const el of path) {
                    if (!el) continue;
                    if (el.tagName === 'A' && el.href) return el.href;
                    const vid = el.getAttribute?.('video-id') || el.getAttribute?.('data-video-id');
                    if (vid) return `https://www.youtube.com/watch?v=${vid}`;
                    const thumbLink = el.querySelector?.('a#thumbnail[href]');
                    if (thumbLink?.href) return thumbLink.href;
                    const cmdUrl = el.data?.endpoint?.commandMetadata?.webCommandMetadata?.url;
                    if (cmdUrl) return cmdUrl;
                }
                return null;
            };
            
            // 仅在“点击”而非“滑动”时触发
            let startX = 0, startY = 0, isDragging = false;
            let recentScroll = false;
            const dragThreshold = 10; // px
            const scrollCooldown = 220; // ms
            
            const interceptEvent = (e) => {
                const path = e.composedPath ? e.composedPath() : [];
                const url = extractUrlFromPath(path);
                if (url && handleNavigate(url, e)) return false;
            };
            
            const markRecentScroll = () => {
                recentScroll = true;
                setTimeout(() => { recentScroll = false; }, scrollCooldown);
            };
            
            document.addEventListener('scroll', markRecentScroll, true);
            document.addEventListener('touchmove', markRecentScroll, true);
            document.addEventListener('wheel', markRecentScroll, true);
            
            document.addEventListener('pointerdown', function(e) {
                startX = e.clientX; startY = e.clientY; isDragging = false;
            }, true);
            
            document.addEventListener('pointermove', function(e) {
                if (Math.abs(e.clientX - startX) > dragThreshold ||
                    Math.abs(e.clientY - startY) > dragThreshold) {
                    isDragging = true;
                }
            }, true);
            
            document.addEventListener('pointerup', function(e) {
                if (!isDragging && !recentScroll) interceptEvent(e);
            }, true);
            
            document.addEventListener('pointercancel', function() {
                isDragging = true;
            }, true);
            
            // 兜底：click 事件（不影响拖动，因为 pointermove 已标记 isDragging）
            document.addEventListener('click', function(e) {
                if (!isDragging && !recentScroll) interceptEvent(e);
            }, true);
            
            // 阻断 YouTube 缩略图/播放按钮的默认行为，避免内嵌播放器弹出
            document.addEventListener('click', function(e) {
                const path = e.composedPath ? e.composedPath() : [];
                for (const el of path) {
                    if (!el) continue;
                    if (el.id === 'thumbnail' || el.tagName === 'YTD-THUMBNAIL' || el.classList?.contains('ytd-thumbnail') ||
                        el.tagName === 'YTD-PLAY-BUTTON-RENDERER' || el.classList?.contains('ytd-play-button-renderer')) {
                        e.preventDefault(); e.stopImmediatePropagation(); e.stopPropagation();
                        const url = extractUrlFromPath(path);
                        if (url) handleNavigate(url, e);
                        return false;
                    }
                }
            }, true);
            
            // 拦截 YouTube 的 SPA 导航事件
            window.addEventListener('yt-navigate-start', function(e) {
                const url = e?.detail?.endpoint?.commandMetadata?.webCommandMetadata?.url;
                if (handleNavigate(url, e)) return false;
            }, true);
            
            // 拦截 history 状态变更（YouTube 使用 pushState/replaceState）
            ['pushState', 'replaceState'].forEach(function(name) {
                const original = history[name];
                history[name] = function(state, title, url) {
                    if (url && handleNavigate(url)) return;
                    return original.apply(this, arguments);
                };
            });
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
        
        
        // 保存 WebView 实例
        Self.sharedWebView = webView
        
        // 保存 webView 引用到 Binding
        DispatchQueue.main.async {
            self.webView = webView
        }
        
        
        // 只在第一次创建时加载首页
        if !Self.hasLoadedInitialPage {
            // 默认打开 YouTube Subscriptions (订阅) 页面
            if let url = URL(string: "https://www.youtube.com/feed/subscriptions") {
                let request = URLRequest(url: url)
                webView.load(request)
                Self.hasLoadedInitialPage = true
            }
        } else {
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 确保 navigationDelegate 始终设置正确
        if webView.navigationDelegate !== context.coordinator {
            webView.navigationDelegate = context.coordinator
        }
        
        // 更新导航状态
        DispatchQueue.main.async {
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
        }
        
        // 如果有保存的滚动位置，恢复它
        if savedScrollPosition.y > 0 && !context.coordinator.hasRestoredPosition {
            context.coordinator.hasRestoredPosition = true
            
            
            // 延迟恢复，确保页面已渲染
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                webView.evaluateJavaScript("window.scrollTo(0, \(self.savedScrollPosition.y))") { _, error in
                    if let error = error {
                    } else {
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
            
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            let urlString = url.absoluteString
            
            // 打印所有导航类型，便于调试
            let navType = navigationAction.navigationType
            
            // 检测 YouTube 视频链接
            if let videoID = YouTubeURLParser.extractVideoID(from: urlString) {
                
                // 立即取消导航
                decisionHandler(.cancel)
                
                // 跳转到应用内播放器
                DispatchQueue.main.async {
                    let video = Video(youtubeVideoID: videoID, title: "Loading...")
                    self.parent.viewModel.loadVideo(video, originalURL: urlString)
                }
                
                return
            }
            
            // 允许其他导航（浏览 YouTube 页面）
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
            
            
            // 注入脚本:禁用列表/首页内的任何视频播放(避免首页播放)
            let disableInlinePlayScript = """
            (function() {
                if (window.lsrInlineBlockInstalled) return;
                window.lsrInlineBlockInstalled = true;
                
                // 全局禁用 video 播放与 src 绑定,防止滚动停下后的自动播放
                (function patchVideo() {
                    if (window.lsrVideoPatched) return;
                    window.lsrVideoPatched = true;
                    const proto = HTMLMediaElement.prototype;
                    
                    // 禁用 play
                    const blockPlay = function() {
                        try { this.pause(); } catch(e) {}
                        return Promise.reject(new DOMException('blocked', 'NotAllowedError'));
                    };
                    proto.play = blockPlay;
                    
                    // 禁用 src setter
                    const srcDesc = Object.getOwnPropertyDescriptor(HTMLMediaElement.prototype, 'src');
                    if (srcDesc && srcDesc.set) {
                        Object.defineProperty(HTMLMediaElement.prototype, 'src', {
                            get: srcDesc.get,
                            set: function(_) {
                                try { this.pause(); this.removeAttribute('src'); this.load(); } catch(e) {}
                            },
                            configurable: true
                        });
                    }
                    
                    // 禁用 load
                    const origLoad = proto.load;
                    proto.load = function() {
                        try { this.pause(); } catch(e) {}
                        return;
                    };
                })();
                
                
                var style = document.createElement('style');
                style.innerHTML = `
                    /* 禁用视频自动播放 */
                    ytd-thumbnail video,
                    ytd-moving-thumbnail-renderer video,
                    ytd-video-preview video,
                    ytd-player video,
                    .html5-video-player video {
                        display: none !important;
                        pointer-events: none !important;
                    }
                    ytd-thumbnail img { opacity: 1 !important; }
                    ytd-player, #player, .html5-video-player { pointer-events: none !important; }
                    ytd-app #movie_player { pointer-events: none !important; }
                    ytd-app .html5-video-player { pointer-events: none !important; }
                    ytd-app ytd-player { pointer-events: none !important; }
                    
                    /* 原生应用样式优化 */
                    /* 为顶部内容添加安全区域内边距 */
                    ytd-app {
                        padding-top: env(safe-area-inset-top) !important;
                    }
                    
                    /* 隐藏YouTube原生顶栏(masthead) */
                    #masthead-container,
                    ytd-masthead {
                        display: none !important;
                    }
                    
                    /* 调整主内容区域,填充整个屏幕 */
                    #page-manager,
                    ytd-page-manager {
                        margin-top: 0 !important;
                    }
                    
                    /* 搜索结果页面顶部添加内边距 */
                    ytd-search {
                        padding-top: 12px !important;
                    }
                    
                    /* 优化滚动体验 */
                    html, body {
                        overscroll-behavior: none !important;
                        -webkit-overflow-scrolling: touch !important;
                    }
                `;
                document.head.appendChild(style);
                
                function scrubVideos() {
                    var videos = document.querySelectorAll('video');
                    videos.forEach(function(video) {
                        try { video.pause(); } catch(e) {}
                        video.removeAttribute('src');
                        video.load();
                    });
                }
                
                scrubVideos();
                
                // 滚动/可见性变化时也强制暂停并移除 src,防止滑动停下后自动播放
                ['scroll', 'touchend', 'wheel', 'visibilitychange'].forEach(function(evt) {
                    document.addEventListener(evt, scrubVideos, true);
                });
                
                // 监听 DOM 变化,发现新的视频节点就清理,防止动态加载
                var observer = new MutationObserver(function(mutations) {
                    let foundVideo = false;
                    for (const m of mutations) {
                        if (m.addedNodes && m.addedNodes.length) {
                            foundVideo = true; break;
                        }
                    }
                    if (foundVideo) scrubVideos();
                });
                observer.observe(document.documentElement || document.body, { childList: true, subtree: true });
                
                // 定时兜底
                setInterval(scrubVideos, 500);
            })();
            """
            
            webView.evaluateJavaScript(disableInlinePlayScript) { _, _ in }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}

#Preview {
    YouTubeWebBrowserView(viewModel: VideoPlayerViewModel())
}

