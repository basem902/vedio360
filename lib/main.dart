import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

void main() {
  runApp(const Video360ViewerApp());
}

class Video360ViewerApp extends StatelessWidget {
  const Video360ViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عارض الفيديو 360°',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const Video360ViewerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Video360ViewerPage extends StatefulWidget {
  const Video360ViewerPage({super.key});

  @override
  State<Video360ViewerPage> createState() => _Video360ViewerPageState();
}

class _Video360ViewerPageState extends State<Video360ViewerPage> {
  bool _isLoading = false;
  String? _selectedVideoPath;

  @override
  void initState() {
    super.initState();
    _registerWebViewer();
  }

  void _registerWebViewer() {
    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(
        'web-video-360-viewer',
        (int viewId) => _createWebViewer(),
      );
    }
  }

  html.Element _createWebViewer() {
    final container = html.DivElement();
    container.style.width = '100%';
    container.style.height = '100%';
    container.style.position = 'relative';
    container.style.backgroundColor = '#000000';
    container.style.overflow = 'hidden';
    
    // إنشاء شاشة الترحيب
    final welcomeScreen = html.DivElement();
    welcomeScreen.id = 'welcome-screen';
    welcomeScreen.style.position = 'absolute';
    welcomeScreen.style.top = '50%';
    welcomeScreen.style.left = '50%';
    welcomeScreen.style.transform = 'translate(-50%, -50%)';
    welcomeScreen.style.color = 'white';
    welcomeScreen.style.textAlign = 'center';
    welcomeScreen.style.fontFamily = 'Arial, sans-serif';
    welcomeScreen.style.zIndex = '1000';
    
    final icon = html.DivElement();
    icon.style.fontSize = '64px';
    icon.style.marginBottom = '20px';
    icon.text = '🎬';
    
    final title = html.HeadingElement.h2();
    title.text = 'عارض الفيديو 360°';
    title.style.color = '#2196F3';
    title.style.margin = '0 0 15px 0';
    title.style.fontSize = '28px';
    
    final subtitle1 = html.ParagraphElement();
    subtitle1.text = 'اختر فيديو 360° لبدء المشاهدة';
    subtitle1.style.color = '#cccccc';
    subtitle1.style.margin = '8px 0';
    subtitle1.style.fontSize = '16px';
    
    final subtitle2 = html.ParagraphElement();
    subtitle2.text = '🔊 صوت مفعل • 🖥️ شاشة كاملة • 🎮 تحكم تفاعلي';
    subtitle2.style.color = '#cccccc';
    subtitle2.style.margin = '8px 0';
    subtitle2.style.fontSize = '16px';
    
    welcomeScreen.append(icon);
    welcomeScreen.append(title);
    welcomeScreen.append(subtitle1);
    welcomeScreen.append(subtitle2);
    
    // إنشاء منطقة العرض
    final viewerArea = html.DivElement();
    viewerArea.id = 'viewer-area';
    viewerArea.style.width = '100%';
    viewerArea.style.height = '100%';
    viewerArea.style.position = 'absolute';
    viewerArea.style.top = '0';
    viewerArea.style.left = '0';
    viewerArea.style.display = 'none';
    
    container.append(welcomeScreen);
    container.append(viewerArea);
    
    // تحميل Three.js وإعداد العارض
    _setupViewer(viewerArea);
    
    return container;
  }

  void _setupViewer(html.Element viewerArea) {
    // إضافة Three.js
    final script = html.ScriptElement();
    script.src = 'https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js';
    html.document.head?.append(script);
    
    script.onLoad.listen((_) {
      // إنشاء JavaScript للعارض
      final viewerScript = html.ScriptElement();
      viewerScript.text = '''
        window.Video360Viewer = {
          scene: null,
          camera: null,
          renderer: null,
          video: null,
          videoTexture: null,
          sphere: null,
          isUserInteracting: false,
          lon: 0,
          lat: 0,
          onMouseDownMouseX: 0,
          onMouseDownMouseY: 0,
          onMouseDownLon: 0,
          onMouseDownLat: 0,
          
          init: function() {
            console.log('Initializing 360 Viewer...');
            
            const viewerArea = document.getElementById('viewer-area');
            if (!viewerArea || !window.THREE) {
              console.log('Viewer area or THREE not found');
              return false;
            }
            
            // إنشاء المشهد
            this.scene = new THREE.Scene();
            this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 1, 1100);
            
            // إعداد دعم VR
            this.setupVRSupport();
            
            // إعداد الذكاء الاصطناعي
            this.setupAI();
            
            // إنشاء الرندر مع تحسينات متقدمة للدقة العالية
            const canvas = document.createElement('canvas');
            const context = canvas.getContext('webgl2') || canvas.getContext('webgl');
            const isWebGL2 = !!canvas.getContext('webgl2');
            
            this.renderer = new THREE.WebGLRenderer({ 
              canvas: canvas,
              context: context,
              antialias: true,
              alpha: true,
              powerPreference: 'high-performance',
              stencil: false,
              depth: true,
              logarithmicDepthBuffer: true,
              precision: 'highp', // دقة عالية للحسابات
              preserveDrawingBuffer: false // تحسين الأداء
            });
            
            // تحسين الأداء حسب قوة الجهاز
            const maxTextureSize = this.renderer.capabilities.maxTextureSize;
            const isHighEndDevice = maxTextureSize >= 8192;
            
            this.renderer.setSize(window.innerWidth, window.innerHeight);
            
            // تحسين pixel ratio للدقة العالية
            let pixelRatio;
            if (isHighEndDevice && window.devicePixelRatio > 1) {
              pixelRatio = Math.min(window.devicePixelRatio, 3); // دعم أفضل للشاشات عالية الدقة
            } else {
              pixelRatio = Math.min(window.devicePixelRatio, 2);
            }
            this.renderer.setPixelRatio(pixelRatio);
            this.renderer.setClearColor(0x000000);
            
            // تفعيل تحسينات الرسومات المتقدمة
            this.renderer.shadowMap.enabled = false; // توفير الأداء
            this.renderer.outputColorSpace = THREE.SRGBColorSpace;
            this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
            this.renderer.toneMappingExposure = 1.0;
            
            // تحسينات إضافية للأداء
            this.renderer.info.autoReset = false; // تحسين الذاكرة
            this.renderer.sortObjects = true; // تحسين الرسم
            
            console.log('Renderer initialized:', 
                       isWebGL2 ? 'WebGL2' : 'WebGL1',
                       'Max texture size:', maxTextureSize,
                       'Pixel ratio:', pixelRatio);
            
            // إضافة الكانفاس للعارض
            viewerArea.appendChild(this.renderer.domElement);
            
            // إضافة الأحداث
            this.addEventListeners();
            
            // بدء الرسم
            this.animate();
            
            console.log('360 Viewer initialized successfully');
            
            // رسالة ترحيب للميزات الصوتية الجديدة
            if (this.spatialAudioEnabled) {
              console.log('%c🎵 ميزات الصوت المكاني متاحة!', 'color: #4CAF50; font-size: 14px; font-weight: bold;');
              console.log('استخدم Ctrl+S لفتح إعدادات الصوت');
              console.log('استخدم Ctrl+X لتبديل الصوت المكاني');
            }
            
            // رسالة ترحيب للميزات VR/AR
            if (this.vrSupported || this.arSupported || this.gyroscopeSupported) {
              console.log('%c🥽 ميزات VR/AR متاحة!', 'color: #2196F3; font-size: 14px; font-weight: bold;');
              if (this.vrSupported) console.log('استخدم Ctrl+V لدخول وضع VR');
              if (this.arSupported) console.log('استخدم Ctrl+A لدخول وضع AR');
              if (this.gyroscopeSupported) console.log('استخدم Ctrl+G لتفعيل الجايروسكوب');
            }
            
            // رسالة ترحيب للذكاء الاصطناعي
            if (this.aiEnabled) {
              console.log('%c🤖 ميزات الذكاء الاصطناعي متاحة!', 'color: #FF6B35; font-size: 14px; font-weight: bold;');
              console.log('استخدم Ctrl+I لفتح لوحة التحليل الذكي');
              console.log('التحليل التلقائي: السطوع، الحركة، الصوت، النوع الموسيقي');
            }
            return true;
          },
          
          loadVideo: function(videoUrl) {
            console.log('Loading video:', videoUrl);
            
            const welcomeScreen = document.getElementById('welcome-screen');
            const viewerArea = document.getElementById('viewer-area');
            
            if (welcomeScreen) welcomeScreen.style.display = 'none';
            if (viewerArea) viewerArea.style.display = 'block';
            
            // إنشاء عنصر الفيديو مع دعم Spatial Audio
            this.video = document.createElement('video');
            this.video.src = videoUrl;
            this.video.loop = true;
            this.video.muted = false;
            this.video.volume = 0.7;
            this.video.crossOrigin = 'anonymous';
            this.video.autoplay = true;
            
            // إعداد Spatial Audio
            this.setupSpatialAudio();
            
            const self = this;
            this.video.addEventListener('loadeddata', function() {
              console.log('Video loaded, creating sphere...');
              self.createVideoSphere();
              self.createControls();
              
              self.video.play().then(() => {
                console.log('Video playing');
                // إعداد شريط التقدم
                self.setupProgressBarEvents();
              }).catch(e => {
                console.log('Autoplay prevented');
                self.showPlayButton();
              });
            });
            
            this.video.addEventListener('error', function(e) {
              console.error('Video error:', e);
            });
          },
          
          createVideoSphere: function() {
            // إنشاء texture من الفيديو مع دعم 4K وتحسينات الجودة
            this.videoTexture = new THREE.VideoTexture(this.video);
            
            // تحديد جودة الـ texture حسب دقة الفيديو
            const videoWidth = this.video.videoWidth || 1920;
            const videoHeight = this.video.videoHeight || 1080;
            const is4K = videoWidth >= 3840 || videoHeight >= 2160;
            const is8K = videoWidth >= 7680 || videoHeight >= 4320;
            
            // إعدادات texture محسنة للدقة العالية
            if (is8K) {
              this.videoTexture.minFilter = THREE.LinearFilter;
              this.videoTexture.magFilter = THREE.LinearFilter;
              this.videoTexture.format = THREE.RGBAFormat; // دعم أفضل للـ 8K
            } else if (is4K) {
              this.videoTexture.minFilter = THREE.LinearMipmapLinearFilter;
              this.videoTexture.magFilter = THREE.LinearFilter;
              this.videoTexture.format = THREE.RGBFormat;
              this.videoTexture.generateMipmaps = true; // تحسين للـ 4K
            } else {
              this.videoTexture.minFilter = THREE.LinearFilter;
              this.videoTexture.magFilter = THREE.LinearFilter;
              this.videoTexture.format = THREE.RGBFormat;
              this.videoTexture.generateMipmaps = false;
            }
            
            this.videoTexture.flipY = false; // منع الانقلاب الرأسي
            this.videoTexture.colorSpace = THREE.SRGBColorSpace;
            this.videoTexture.wrapS = THREE.RepeatWrapping;
            this.videoTexture.wrapT = THREE.RepeatWrapping;
            
            // تحسين الأداء للدقة العالية
            this.videoTexture.needsUpdate = true;
            
            console.log('Video resolution detected:', videoWidth + 'x' + videoHeight, 
                       is8K ? '(8K)' : is4K ? '(4K)' : '(HD)');
            
            // إنشاء الكرة بدقة تتناسب مع دقة الفيديو
            let segments, rings;
            if (is8K) {
              segments = 256; // دقة فائقة للـ 8K
              rings = 128;
            } else if (is4K) {
              segments = 192; // دقة عالية للـ 4K
              rings = 96;
            } else {
              segments = 128; // دقة عادية للـ HD
              rings = 64;
            }
            
            const geometry = new THREE.SphereGeometry(500, segments, rings);
            geometry.scale(-1, 1, 1); // انعكاس أفقي للداخل
            
            console.log('Sphere created with segments:', segments, 'rings:', rings);
            
            // تحسين المادة
            const material = new THREE.MeshBasicMaterial({ 
              map: this.videoTexture,
              side: THREE.DoubleSide,
              transparent: false,
              alphaTest: 0,
              depthWrite: true,
              depthTest: true
            });
            
            // إزالة الكرة السابقة إن وجدت
            if (this.sphere) {
              this.scene.remove(this.sphere);
            }
            
            this.sphere = new THREE.Mesh(geometry, material);
            this.scene.add(this.sphere);
            
            console.log('Video sphere created');
          },
          
          createControls: function() {
            const controls = document.createElement('div');
            controls.id = 'video-controls';
            controls.style.position = 'fixed';
            controls.style.bottom = '20px';
            controls.style.left = '50%';
            controls.style.transform = 'translateX(-50%)';
            controls.style.backgroundColor = 'rgba(0,0,0,0.8)';
            controls.style.padding = '10px 20px';
            controls.style.borderRadius = '20px';
            controls.style.display = 'flex';
            controls.style.gap = '10px';
            controls.style.zIndex = '3000';
            
            // إضافة مؤشر الجودة
            this.createQualityIndicator();
            
            // زر التشغيل/الإيقاف
            const playBtn = document.createElement('button');
            playBtn.innerHTML = '⏸️';
            playBtn.style.background = 'none';
            playBtn.style.border = 'none';
            playBtn.style.color = 'white';
            playBtn.style.fontSize = '20px';
            playBtn.style.cursor = 'pointer';
            playBtn.style.padding = '5px';
            
            const self = this;
            playBtn.onclick = function() {
              if (self.video.paused) {
                self.video.play();
                playBtn.innerHTML = '⏸️';
              } else {
                self.video.pause();
                playBtn.innerHTML = '▶️';
              }
            };
            
            // زر الصوت
            const muteBtn = document.createElement('button');
            muteBtn.innerHTML = '🔊';
            muteBtn.style.background = 'none';
            muteBtn.style.border = 'none';
            muteBtn.style.color = 'white';
            muteBtn.style.fontSize = '16px';
            muteBtn.style.cursor = 'pointer';
            muteBtn.style.padding = '5px';
            
            muteBtn.onclick = function() {
              self.video.muted = !self.video.muted;
              muteBtn.innerHTML = self.video.muted ? '🔇' : '🔊';
            };
            
            // زر الشاشة الكاملة
            const fullscreenBtn = document.createElement('button');
            fullscreenBtn.innerHTML = '⛶';
            fullscreenBtn.style.background = 'none';
            fullscreenBtn.style.border = 'none';
            fullscreenBtn.style.color = 'white';
            fullscreenBtn.style.fontSize = '18px';
            fullscreenBtn.style.cursor = 'pointer';
            fullscreenBtn.style.padding = '5px';
            
            fullscreenBtn.onclick = function() {
              if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen();
              } else {
                document.exitFullscreen();
              }
            };
            
            // زر جودة العرض
            const qualityBtn = document.createElement('button');
            qualityBtn.innerHTML = '🎯';
            qualityBtn.title = 'تبديل جودة العرض';
            qualityBtn.style.background = 'none';
            qualityBtn.style.border = 'none';
            qualityBtn.style.color = 'white';
            qualityBtn.style.fontSize = '16px';
            qualityBtn.style.cursor = 'pointer';
            qualityBtn.style.padding = '5px';
            
            let qualityMode = 'high'; // high, medium, low
            qualityBtn.onclick = function() {
              if (qualityMode === 'high') {
                qualityMode = 'medium';
                self.setQualityMode('medium');
                qualityBtn.innerHTML = '🎯';
                qualityBtn.title = 'جودة متوسطة';
              } else if (qualityMode === 'medium') {
                qualityMode = 'low';
                self.setQualityMode('low');
                qualityBtn.innerHTML = '⚡';
                qualityBtn.title = 'جودة منخفضة - أداء سريع';
              } else {
                qualityMode = 'high';
                self.setQualityMode('high');
                qualityBtn.innerHTML = '💎';
                qualityBtn.title = 'جودة عالية';
              }
            };
            
            // زر تصحيح الاتجاه
            const flipBtn = document.createElement('button');
            flipBtn.innerHTML = '🔄';
            flipBtn.title = 'تصحيح اتجاه الفيديو';
            flipBtn.style.background = 'none';
            flipBtn.style.border = 'none';
            flipBtn.style.color = 'white';
            flipBtn.style.fontSize = '16px';
            flipBtn.style.cursor = 'pointer';
            flipBtn.style.padding = '5px';
            
            let flipState = 0; // 0: عادي, 1: انقلاب أفقي, 2: انقلاب رأسي, 3: انقلاب كامل
            flipBtn.onclick = function() {
              flipState = (flipState + 1) % 4;
              self.flipVideo(flipState);
              
              const titles = [
                'اتجاه عادي',
                'انقلاب أفقي',
                'انقلاب رأسي', 
                'انقلاب كامل'
              ];
              flipBtn.title = titles[flipState];
            };
            
            controls.appendChild(playBtn);
            controls.appendChild(muteBtn);
            controls.appendChild(qualityBtn);
            controls.appendChild(flipBtn);
            controls.appendChild(fullscreenBtn);
            
            document.body.appendChild(controls);
          },
          
          createQualityIndicator: function() {
            const qualityPanel = document.createElement('div');
            qualityPanel.id = 'quality-panel';
            qualityPanel.style.position = 'fixed';
            qualityPanel.style.top = '20px';
            qualityPanel.style.right = '20px';
            qualityPanel.style.backgroundColor = 'rgba(0,0,0,0.9)';
            qualityPanel.style.color = 'white';
            qualityPanel.style.padding = '15px 20px';
            qualityPanel.style.borderRadius = '15px';
            qualityPanel.style.fontSize = '13px';
            qualityPanel.style.fontFamily = 'Arial, sans-serif';
            qualityPanel.style.zIndex = '3000';
            qualityPanel.style.minWidth = '280px';
            qualityPanel.style.backdropFilter = 'blur(15px)';
            qualityPanel.style.border = '1px solid rgba(255,255,255,0.2)';
            qualityPanel.style.boxShadow = '0 10px 30px rgba(0,0,0,0.4)';
            qualityPanel.style.transition = 'all 0.3s ease';
            
            const title = document.createElement('div');
            title.innerHTML = '📊 معلومات الجودة <button onclick="window.Video360Viewer.toggleQualityPanel()" style="float: right; background: rgba(255,255,255,0.2); border: none; color: white; padding: 2px 8px; border-radius: 5px; cursor: pointer; font-size: 10px;">إخفاء</button>';
            title.style.fontWeight = 'bold';
            title.style.marginBottom = '10px';
            title.style.color = '#2196F3';
            title.style.display = 'flex';
            title.style.justifyContent = 'space-between';
            title.style.alignItems = 'center';
            
            const info = document.createElement('div');
            info.id = 'quality-info';
            
            qualityPanel.appendChild(title);
            qualityPanel.appendChild(info);
            document.body.appendChild(qualityPanel);
            
            // تحديث المعلومات كل ثانية
            const self = this;
            setInterval(function() {
              self.updateQualityInfo();
            }, 1000);
          },
          
          updateQualityInfo: function() {
            const infoDiv = document.getElementById('quality-info');
            if (!infoDiv || !this.video || !this.renderer) return;
            
            const pixelRatio = this.renderer.getPixelRatio();
            const size = this.renderer.getSize(new THREE.Vector2());
            const videoWidth = this.video.videoWidth || 0;
            const videoHeight = this.video.videoHeight || 0;
            const fps = this.video.getVideoPlaybackQuality ? 
                      this.video.getVideoPlaybackQuality().totalVideoFrames : 'N/A';
            
            // تحديد نوع الدقة
            const is8K = videoWidth >= 7680 || videoHeight >= 4320;
            const is4K = videoWidth >= 3840 || videoHeight >= 2160;
            const isHD = videoWidth >= 1920 || videoHeight >= 1080;
            
            let qualityBadge = '';
            if (is8K) qualityBadge = ' 🏆8K';
            else if (is4K) qualityBadge = ' 💎4K';
            else if (isHD) qualityBadge = ' ⭐HD';
            else qualityBadge = ' 📺SD';
            
            // معلومات الأداء
            const memoryInfo = this.renderer.info.memory;
            const renderInfo = this.renderer.info.render;
            
            infoDiv.innerHTML = 
              'الدقة: ' + videoWidth + 'x' + videoHeight + qualityBadge + '<br>' +
              'الشاشة: ' + Math.round(size.x) + 'x' + Math.round(size.y) + '<br>' +
              'Pixel Ratio: ' + pixelRatio.toFixed(1) + '<br>' +
              'الإطارات: ' + (typeof fps === 'number' ? fps : fps) + '<br>' +
              'المعالج: ' + (this.renderer.capabilities.isWebGL2 ? 'WebGL2' : 'WebGL1') + '<br>' +
              'الذاكرة: ' + (memoryInfo.textures || 0) + ' textures<br>' +
              'FPS: ' + Math.round(1000 / (performance.now() - (this.lastFrameTime || performance.now()))) + '<br>' +
              '🎵 صوت مكاني: ' + (this.spatialAudioEnabled && this.spatialAudioActive ? '✅ مفعل' : '❌ معطل') + '<br>' +
              '🥽 VR Support: ' + (this.vrSupported ? '✅ متاح' : '❌ غير متاح') + '<br>' +
              '📱 AR Support: ' + (this.arSupported ? '✅ متاح' : '❌ غير متاح') + '<br>' +
              '🧭 Gyroscope: ' + (this.gyroscopeSupported ? (this.gyroscopeActive ? '✅ مفعل' : '⏸️ متاح') : '❌ غير متاح') + '<br>' +
              '🤖 AI Analysis: ' + (this.aiEnabled ? '✅ مفعل' : '❌ معطل') + '<br>' +
              '🎯 Auto Optimization: ' + (this.autoOptimization ? '✅ مفعل' : '❌ معطل');
            
            this.lastFrameTime = performance.now();
          },
          
          optimizePerformance: function() {
            if (!this.renderer) return;
            
            // تنظيف الذاكرة
            if (this.renderer.info) {
              this.renderer.info.reset();
            }
            
            // تحسين texture للدقة العالية
            if (this.videoTexture && this.video) {
              const videoWidth = this.video.videoWidth || 0;
              const videoHeight = this.video.videoHeight || 0;
              const is4KOrHigher = videoWidth >= 3840 || videoHeight >= 2160;
              
              if (is4KOrHigher && this.frameCount % 300 === 0) {
                // إعادة تحديث texture للفيديوهات عالية الدقة
                this.videoTexture.needsUpdate = true;
              }
            }
            
            // تحسين الكاميرا للأداء الأمثل
            if (this.camera && this.frameCount % 500 === 0) {
              this.camera.updateProjectionMatrix();
            }
            
            console.log('Performance optimization at frame:', this.frameCount);
          },
          
          setupSpatialAudio: function() {
            try {
              // إنشاء Audio Context للصوت المكاني
              this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
              
              // إنشاء مصدر الصوت من الفيديو
              this.audioSource = this.audioContext.createMediaElementSource(this.video);
              
              // إنشاء Panner Node للصوت ثلاثي الأبعاد
              this.pannerNode = this.audioContext.createPanner();
              this.pannerNode.panningModel = 'HRTF'; // Head-Related Transfer Function
              this.pannerNode.distanceModel = 'inverse';
              this.pannerNode.refDistance = 1;
              this.pannerNode.maxDistance = 10000;
              this.pannerNode.rolloffFactor = 1;
              this.pannerNode.coneInnerAngle = 360;
              this.pannerNode.coneOuterAngle = 0;
              this.pannerNode.coneOuterGain = 0;
              
              // إنشاء Gain Node للتحكم في مستوى الصوت
              this.gainNode = this.audioContext.createGain();
              this.gainNode.gain.value = 0.7;
              
              // إنشاء Analyser للتحليل الطيفي
              this.analyserNode = this.audioContext.createAnalyser();
              this.analyserNode.fftSize = 256;
              this.audioDataArray = new Uint8Array(this.analyserNode.frequencyBinCount);
              
              // ربط العقد
              this.audioSource.connect(this.pannerNode);
              this.pannerNode.connect(this.gainNode);
              this.gainNode.connect(this.analyserNode);
              this.analyserNode.connect(this.audioContext.destination);
              
              // تعيين موقع المستمع
              if (this.audioContext.listener.positionX) {
                this.audioContext.listener.positionX.value = 0;
                this.audioContext.listener.positionY.value = 0;
                this.audioContext.listener.positionZ.value = 0;
                this.audioContext.listener.forwardX.value = 0;
                this.audioContext.listener.forwardY.value = 0;
                this.audioContext.listener.forwardZ.value = -1;
                this.audioContext.listener.upX.value = 0;
                this.audioContext.listener.upY.value = 1;
                this.audioContext.listener.upZ.value = 0;
              }
              
              console.log('Spatial Audio initialized successfully');
              this.spatialAudioEnabled = true;
              this.spatialAudioActive = true; // تفعيل الصوت المكاني افتراضياً
              
              // إعداد المعادل والبيئة الصوتية
              this.setupEqualizer();
              this.setAudioEnvironment('room'); // بيئة غرفة افتراضية
              
            } catch (error) {
              console.log('Spatial Audio not supported:', error);
              this.spatialAudioEnabled = false;
            }
          },
          
          setQualityMode: function(mode) {
            if (!this.sphere || !this.renderer) return;
            
            console.log('Switching to quality mode:', mode);
            
            // إعادة إنشاء الكرة بدقة مختلفة
            this.scene.remove(this.sphere);
            
            let segments, rings, pixelRatio;
            
            switch(mode) {
              case 'high':
                segments = 128;
                rings = 64;
                pixelRatio = Math.min(window.devicePixelRatio, 2);
                break;
              case 'medium':
                segments = 64;
                rings = 32;
                pixelRatio = Math.min(window.devicePixelRatio, 1.5);
                break;
              case 'low':
                segments = 32;
                rings = 16;
                pixelRatio = 1;
                break;
            }
            
            // تحديث pixel ratio
            this.renderer.setPixelRatio(pixelRatio);
            
            // إنشاء كرة جديدة مع إصلاح الانقلاب
            const geometry = new THREE.SphereGeometry(500, segments, rings);
            geometry.scale(-1, 1, 1); // الإعداد الافتراضي
            
            const material = new THREE.MeshBasicMaterial({ 
              map: this.videoTexture,
              side: THREE.DoubleSide,
              transparent: false,
              alphaTest: 0,
              depthWrite: true,
              depthTest: true
            });
            
            this.sphere = new THREE.Mesh(geometry, material);
            this.scene.add(this.sphere);
            
            console.log('Quality mode changed to:', mode, 'Segments:', segments, 'Rings:', rings);
          },
          
          flipVideo: function(flipState) {
            if (!this.sphere) return;
            
            console.log('Flipping video to state:', flipState);
            
            // إعادة تعيين التحويلات
            this.sphere.scale.set(1, 1, 1);
            this.sphere.rotation.set(0, 0, 0);
            
            switch(flipState) {
              case 0: // عادي
                this.sphere.scale.set(-1, 1, 1);
                break;
              case 1: // انقلاب أفقي
                this.sphere.scale.set(1, 1, 1);
                break;
              case 2: // انقلاب رأسي
                this.sphere.scale.set(-1, -1, 1);
                break;
              case 3: // انقلاب كامل
                this.sphere.scale.set(1, -1, 1);
                break;
            }
            
            console.log('Video flipped to state:', flipState);
          },
          
          toggleSpatialAudio: function() {
            if (!this.spatialAudioEnabled) {
              console.log('Spatial Audio not available');
              return;
            }
            
            this.spatialAudioActive = !this.spatialAudioActive;
            
            if (this.spatialAudioActive) {
              // تفعيل الصوت المكاني
              if (this.audioContext.state === 'suspended') {
                this.audioContext.resume();
              }
              console.log('Spatial Audio enabled');
            } else {
              // إيقاف الصوت المكاني - العودة للصوت العادي
              if (this.pannerNode && this.pannerNode.positionX) {
                this.pannerNode.positionX.value = 0;
                this.pannerNode.positionY.value = 0;
                this.pannerNode.positionZ.value = 0;
              }
              console.log('Spatial Audio disabled');
            }
          },
          
          // إعدادات صوتية متقدمة
          setAudioEnvironment: function(environment) {
            if (!this.spatialAudioEnabled || !this.audioContext) return;
            
            // إنشاء Convolver للصدى البيئي
            if (!this.convolverNode) {
              this.convolverNode = this.audioContext.createConvolver();
              this.dryGainNode = this.audioContext.createGain();
              this.wetGainNode = this.audioContext.createGain();
              
              // إعادة توصيل العقد
              this.gainNode.disconnect();
              this.gainNode.connect(this.dryGainNode);
              this.gainNode.connect(this.convolverNode);
              this.convolverNode.connect(this.wetGainNode);
              this.dryGainNode.connect(this.analyserNode);
              this.wetGainNode.connect(this.analyserNode);
            }
            
            // تطبيق إعدادات البيئة
            switch(environment) {
              case 'hall': // قاعة كبيرة
                this.dryGainNode.gain.value = 0.6;
                this.wetGainNode.gain.value = 0.4;
                console.log('Audio environment: Concert Hall');
                break;
              case 'room': // غرفة عادية
                this.dryGainNode.gain.value = 0.8;
                this.wetGainNode.gain.value = 0.2;
                console.log('Audio environment: Room');
                break;
              case 'outdoor': // في الهواء الطلق
                this.dryGainNode.gain.value = 1.0;
                this.wetGainNode.gain.value = 0.0;
                console.log('Audio environment: Outdoor');
                break;
              default: // عادي
                this.dryGainNode.gain.value = 1.0;
                this.wetGainNode.gain.value = 0.0;
            }
          },
          
          // معادل الصوت
          setupEqualizer: function() {
            if (!this.spatialAudioEnabled || !this.audioContext) return;
            
            // إنشاء مرشحات التردد
            this.eqFilters = [];
            const frequencies = [60, 170, 350, 1000, 3500, 10000]; // Hz
            
            frequencies.forEach((freq, index) => {
              const filter = this.audioContext.createBiquadFilter();
              filter.type = index === 0 ? 'lowshelf' : 
                           index === frequencies.length - 1 ? 'highshelf' : 'peaking';
              filter.frequency.value = freq;
              filter.Q.value = 1;
              filter.gain.value = 0; // dB
              
              this.eqFilters.push(filter);
            });
            
            // ربط المرشحات
            if (this.eqFilters.length > 0) {
              this.pannerNode.disconnect();
              this.pannerNode.connect(this.eqFilters[0]);
              
              for (let i = 0; i < this.eqFilters.length - 1; i++) {
                this.eqFilters[i].connect(this.eqFilters[i + 1]);
              }
              
              this.eqFilters[this.eqFilters.length - 1].connect(this.gainNode);
              console.log('Audio equalizer initialized');
            }
          },
          
          showPlayButton: function() {
            const playButton = document.createElement('button');
            playButton.innerHTML = '▶️ تشغيل';
            playButton.style.position = 'fixed';
            playButton.style.top = '50%';
            playButton.style.left = '50%';
            playButton.style.transform = 'translate(-50%, -50%)';
            playButton.style.backgroundColor = 'rgba(33,150,243,0.9)';
            playButton.style.color = 'white';
            playButton.style.padding = '15px 30px';
            playButton.style.borderRadius = '25px';
            playButton.style.fontSize = '18px';
            playButton.style.cursor = 'pointer';
            playButton.style.border = 'none';
            playButton.style.zIndex = '4000';
            
            const self = this;
            playButton.onclick = function() {
              self.video.play();
              playButton.remove();
            };
            
            document.body.appendChild(playButton);
          },
          
          showAudioControls: function() {
            if (!this.spatialAudioEnabled) {
              console.log('Spatial Audio not available');
              return;
            }
            
            // إنشاء لوحة التحكم الصوتي
            const audioPanel = document.createElement('div');
            audioPanel.id = 'audio-controls-panel';
            audioPanel.style.position = 'fixed';
            audioPanel.style.top = '10px';
            audioPanel.style.right = '10px';
            audioPanel.style.backgroundColor = 'rgba(0,0,0,0.8)';
            audioPanel.style.color = 'white';
            audioPanel.style.padding = '15px';
            audioPanel.style.borderRadius = '10px';
            audioPanel.style.zIndex = '3000';
            audioPanel.style.minWidth = '200px';
            audioPanel.style.fontFamily = 'Arial, sans-serif';
            
            audioPanel.innerHTML = 
              '<h3 style="margin-top: 0; color: #2196F3;">🎵 التحكم الصوتي</h3>' +
              '<div style="margin: 10px 0;">' +
                '<label>البيئة الصوتية:</label><br>' +
                '<select id="audio-env" style="width: 100%; padding: 5px; margin-top: 5px;">' +
                  '<option value="outdoor">هواء طلق 🌤️</option>' +
                  '<option value="room" selected>غرفة 🏠</option>' +
                  '<option value="hall">قاعة كبيرة 🏛️</option>' +
                '</select>' +
              '</div>' +
              '<div style="margin: 10px 0;">' +
                '<label>الصوت المكاني:</label><br>' +
                '<button id="spatial-toggle" style="width: 100%; padding: 8px; margin-top: 5px; background: #4CAF50; color: white; border: none; border-radius: 5px; cursor: pointer;">تفعيل ✅</button>' +
              '</div>' +
              '<button onclick="document.getElementById(\\'audio-controls-panel\\').remove()" style="width: 100%; padding: 8px; margin-top: 10px; background: #f44336; color: white; border: none; border-radius: 5px; cursor: pointer;">إغلاق</button>';
            
            document.body.appendChild(audioPanel);
            
            // ربط الأحداث
            const envSelect = document.getElementById('audio-env');
            const spatialToggle = document.getElementById('spatial-toggle');
            const self = this;
            
            envSelect.onchange = function() {
              self.setAudioEnvironment(this.value);
            };
            
            spatialToggle.onclick = function() {
              self.toggleSpatialAudio();
              this.textContent = self.spatialAudioActive ? 'تفعيل ✅' : 'إيقاف ❌';
              this.style.backgroundColor = self.spatialAudioActive ? '#4CAF50' : '#f44336';
            };
          },
          
          addEventListeners: function() {
            const canvas = this.renderer.domElement;
            const self = this;
            
            canvas.addEventListener('mousedown', function(event) {
              self.isUserInteracting = true;
              self.onMouseDownMouseX = event.clientX;
              self.onMouseDownMouseY = event.clientY;
              self.onMouseDownLon = self.lon;
              self.onMouseDownLat = self.lat;
            });
            
            canvas.addEventListener('mousemove', function(event) {
              if (self.isUserInteracting) {
                self.lon = (self.onMouseDownMouseX - event.clientX) * 0.1 + self.onMouseDownLon;
                self.lat = (event.clientY - self.onMouseDownMouseY) * 0.1 + self.onMouseDownLat;
              }
            });
            
            canvas.addEventListener('mouseup', function() {
              self.isUserInteracting = false;
            });
            
            canvas.addEventListener('wheel', function(event) {
              const fov = self.camera.fov + event.deltaY * 0.05;
              self.camera.fov = Math.max(10, Math.min(75, fov));
              self.camera.updateProjectionMatrix();
            });
            
            window.addEventListener('resize', function() {
              self.camera.aspect = window.innerWidth / window.innerHeight;
              self.camera.updateProjectionMatrix();
              self.renderer.setSize(window.innerWidth, window.innerHeight);
            });
            
            // اختصارات لوحة المفاتيح للصوت
            window.addEventListener('keydown', function(event) {
              switch(event.key.toLowerCase()) {
                case 's': // فتح إعدادات الصوت
                  if (event.ctrlKey) {
                    event.preventDefault();
                    self.showAudioControls();
                  }
                  break;
                case 'x': // تبديل الصوت المكاني
                  if (event.ctrlKey) {
                    event.preventDefault();
                    self.toggleSpatialAudio();
                  }
                  break;
                case 'v': // تفعيل VR
                  if (event.ctrlKey) {
                    event.preventDefault();
                    self.enterVR();
                  }
                  break;
                case 'g': // تبديل الجايروسكوب
                  if (event.ctrlKey) {
                    event.preventDefault();
                    self.toggleGyroscope();
                  }
                  break;
                case 'a': // تفعيل AR
                  if (event.ctrlKey) {
                    event.preventDefault();
                    self.enterAR();
                  }
                  break;
                case 'i': // فتح لوحة الذكاء الاصطناعي
                  if (event.ctrlKey) {
                    event.preventDefault();
                    self.showAIPanel();
                  }
                  break;
              }
            });
          },
          
          update: function() {
            if (!this.camera) return;
            
            this.lat = Math.max(-85, Math.min(85, this.lat));
            const phi = (90 - this.lat) * Math.PI / 180;
            const theta = this.lon * Math.PI / 180;
            
            const x = 500 * Math.sin(phi) * Math.cos(theta);
            const y = 500 * Math.cos(phi);
            const z = 500 * Math.sin(phi) * Math.sin(theta);
            
            this.camera.lookAt(x, y, z);
          },
          
          updateSpatialAudio: function() {
            if (!this.spatialAudioEnabled || !this.spatialAudioActive || !this.pannerNode || !this.audioContext.listener) return;
            
            try {
              // حساب اتجاه الكاميرا
              const phi = (90 - this.lat) * Math.PI / 180;
              const theta = this.lon * Math.PI / 180;
              
              // حساب موقع مصدر الصوت بناء على اتجاه النظر
              const distance = 5; // مسافة مصدر الصوت
              const sourceX = distance * Math.sin(phi) * Math.cos(theta);
              const sourceY = distance * Math.cos(phi);
              const sourceZ = distance * Math.sin(phi) * Math.sin(theta);
              
              // تحديث موقع مصدر الصوت
              if (this.pannerNode.positionX) {
                this.pannerNode.positionX.value = sourceX;
                this.pannerNode.positionY.value = sourceY;
                this.pannerNode.positionZ.value = sourceZ;
              }
              
              // تحديث اتجاه المستمع (الكاميرا)
              if (this.audioContext.listener.forwardX) {
                const forwardX = Math.sin(phi) * Math.cos(theta);
                const forwardY = Math.cos(phi);
                const forwardZ = Math.sin(phi) * Math.sin(theta);
                
                this.audioContext.listener.forwardX.value = forwardX;
                this.audioContext.listener.forwardY.value = forwardY;
                this.audioContext.listener.forwardZ.value = forwardZ;
              }
              
              // تحليل الصوت للتأثيرات البصرية
              if (this.analyserNode) {
                this.analyserNode.getByteFrequencyData(this.audioDataArray);
                
                // حساب مستوى الصوت العام
                let sum = 0;
                for (let i = 0; i < this.audioDataArray.length; i++) {
                  sum += this.audioDataArray[i];
                }
                const average = sum / this.audioDataArray.length;
                
                // تأثير بصري بسيط على الكرة حسب مستوى الصوت
                if (this.sphere && average > 50) {
                  const scale = 1 + (average / 1000);
                  this.sphere.scale.setScalar(scale);
                }
              }
              
            } catch (error) {
              console.log('Error updating spatial audio:', error);
            }
          },
          
          setupVRSupport: function() {
            try {
              // التحقق من دعم WebXR للـ VR
              if ('xr' in navigator) {
                navigator.xr.isSessionSupported('immersive-vr').then((supported) => {
                  if (supported) {
                    this.vrSupported = true;
                    console.log('VR Support: Available');
                    this.createVRButton();
                  } else {
                    console.log('VR Support: Not available');
                    this.vrSupported = false;
                  }
                }).catch(() => {
                  console.log('VR Support: Error checking');
                  this.vrSupported = false;
                });
                
                // التحقق من دعم AR
                navigator.xr.isSessionSupported('immersive-ar').then((supported) => {
                  if (supported) {
                    this.arSupported = true;
                    console.log('AR Support: Available');
                    this.createARButton();
                  } else {
                    console.log('AR Support: Not available');
                    this.arSupported = false;
                  }
                }).catch(() => {
                  console.log('AR Support: Error checking');
                  this.arSupported = false;
                });
              } else {
                console.log('WebXR not available - no VR/AR support');
                this.vrSupported = false;
                this.arSupported = false;
              }
              
              // التحقق من دعم الجايروسكوب للموبايل
              if (window.DeviceOrientationEvent) {
                this.gyroscopeSupported = true;
                console.log('Gyroscope Support: Available');
                this.setupGyroscope();
              } else {
                this.gyroscopeSupported = false;
                console.log('Gyroscope Support: Not available');
              }
              
            } catch (error) {
              console.log('VR/AR Setup Error:', error);
              this.vrSupported = false;
              this.gyroscopeSupported = false;
            }
          },
          
          createVRButton: function() {
            if (!this.vrSupported) return;
            
            const vrButton = document.createElement('button');
            vrButton.id = 'vr-button';
            vrButton.innerHTML = '🥽<br><span style="font-size: 12px;">VR Mode</span>';
            vrButton.style.position = 'fixed';
            vrButton.style.bottom = '120px';
            vrButton.style.right = '20px';
            vrButton.style.backgroundColor = 'rgba(0,150,255,0.95)';
            vrButton.style.color = 'white';
            vrButton.style.padding = '15px';
            vrButton.style.borderRadius = '50%';
            vrButton.style.fontSize = '20px';
            vrButton.style.cursor = 'pointer';
            vrButton.style.border = '2px solid rgba(255,255,255,0.3)';
            vrButton.style.zIndex = '4000';
            vrButton.style.fontFamily = 'Arial, sans-serif';
            vrButton.style.boxShadow = '0 6px 20px rgba(0,150,255,0.4)';
            vrButton.style.width = '70px';
            vrButton.style.height = '70px';
            vrButton.style.display = 'flex';
            vrButton.style.flexDirection = 'column';
            vrButton.style.alignItems = 'center';
            vrButton.style.justifyContent = 'center';
            vrButton.style.transition = 'all 0.3s ease';
            vrButton.style.backdropFilter = 'blur(10px)';
            
            // تأثيرات التفاعل
            vrButton.onmouseenter = function() {
              this.style.transform = 'scale(1.1)';
              this.style.boxShadow = '0 8px 25px rgba(0,150,255,0.6)';
            };
            vrButton.onmouseleave = function() {
              this.style.transform = 'scale(1)';
              this.style.boxShadow = '0 6px 20px rgba(0,150,255,0.4)';
            };
            
            const self = this;
            vrButton.onclick = function() {
              this.style.transform = 'scale(0.95)';
              setTimeout(() => {
                this.style.transform = 'scale(1.1)';
              }, 100);
              self.enterVR();
            };
            
            document.body.appendChild(vrButton);
          },
          
          createARButton: function() {
            if (!this.arSupported) return;
            
            const arButton = document.createElement('button');
            arButton.id = 'ar-button';
            arButton.innerHTML = '📱<br><span style="font-size: 12px;">AR Mode</span>';
            arButton.style.position = 'fixed';
            arButton.style.bottom = '200px';
            arButton.style.right = '20px';
            arButton.style.backgroundColor = 'rgba(255,152,0,0.95)';
            arButton.style.color = 'white';
            arButton.style.padding = '15px';
            arButton.style.borderRadius = '50%';
            arButton.style.fontSize = '20px';
            arButton.style.cursor = 'pointer';
            arButton.style.border = '2px solid rgba(255,255,255,0.3)';
            arButton.style.zIndex = '4000';
            arButton.style.fontFamily = 'Arial, sans-serif';
            arButton.style.boxShadow = '0 6px 20px rgba(255,152,0,0.4)';
            arButton.style.width = '70px';
            arButton.style.height = '70px';
            arButton.style.display = 'flex';
            arButton.style.flexDirection = 'column';
            arButton.style.alignItems = 'center';
            arButton.style.justifyContent = 'center';
            arButton.style.transition = 'all 0.3s ease';
            arButton.style.backdropFilter = 'blur(10px)';
            
            // تأثيرات التفاعل
            arButton.onmouseenter = function() {
              this.style.transform = 'scale(1.1)';
              this.style.boxShadow = '0 8px 25px rgba(255,152,0,0.6)';
            };
            arButton.onmouseleave = function() {
              this.style.transform = 'scale(1)';
              this.style.boxShadow = '0 6px 20px rgba(255,152,0,0.4)';
            };
            
            const self = this;
            arButton.onclick = function() {
              this.style.transform = 'scale(0.95)';
              setTimeout(() => {
                this.style.transform = 'scale(1.1)';
              }, 100);
              self.enterAR();
            };
            
            document.body.appendChild(arButton);
          },
          
          setupGyroscope: function() {
            if (!this.gyroscopeSupported) return;
            
            const self = this;
            
            // طلب إذن الوصول للجايروسكوب (iOS 13+)
            if (typeof DeviceOrientationEvent.requestPermission === 'function') {
              DeviceOrientationEvent.requestPermission().then(response => {
                if (response === 'granted') {
                  self.enableGyroscope();
                }
              }).catch(console.error);
            } else {
              // للأجهزة الأخرى
              this.enableGyroscope();
            }
          },
          
          enableGyroscope: function() {
            const self = this;
            
            window.addEventListener('deviceorientation', function(event) {
              if (!self.gyroscopeActive) return;
              
              // تحويل قيم الجايروسكوب إلى زوايا الكاميرا
              const alpha = event.alpha || 0; // Z axis
              const beta = event.beta || 0;   // X axis
              const gamma = event.gamma || 0; // Y axis
              
              // تحديث موقع الكاميرا بناء على الجايروسكوب
              self.lon = alpha;
              self.lat = Math.max(-85, Math.min(85, beta - 90));
              
            }, true);
            
            // إنشاء زر تفعيل الجايروسكوب
            this.createGyroscopeButton();
            
            console.log('Gyroscope controls enabled');
            
            // إنشاء لوحة التحكم الرئيسية
            this.createMainControlPanel();
            
            // إنشاء شريط التقدم
            this.createProgressBar();
          },
          
          createMainControlPanel: function() {
            // إنشاء زر القائمة الرئيسية
            const menuButton = document.createElement('button');
            menuButton.id = 'main-menu-button';
            menuButton.innerHTML = '⚙️<br><span style="font-size: 10px;">Menu</span>';
            menuButton.style.position = 'fixed';
            menuButton.style.bottom = '100px';
            menuButton.style.right = '20px';
            menuButton.style.backgroundColor = 'rgba(33,150,243,0.95)';
            menuButton.style.color = 'white';
            menuButton.style.padding = '15px';
            menuButton.style.borderRadius = '50%';
            menuButton.style.fontSize = '18px';
            menuButton.style.cursor = 'pointer';
            menuButton.style.border = '2px solid rgba(255,255,255,0.3)';
            menuButton.style.zIndex = '5000';
            menuButton.style.fontFamily = 'Arial, sans-serif';
            menuButton.style.boxShadow = '0 6px 20px rgba(33,150,243,0.4)';
            menuButton.style.width = '60px';
            menuButton.style.height = '60px';
            menuButton.style.display = 'flex';
            menuButton.style.flexDirection = 'column';
            menuButton.style.alignItems = 'center';
            menuButton.style.justifyContent = 'center';
            menuButton.style.transition = 'all 0.3s ease';
            menuButton.style.backdropFilter = 'blur(10px)';
            
            // تأثيرات التفاعل
            menuButton.onmouseenter = function() {
              this.style.transform = 'scale(1.1)';
              this.style.boxShadow = '0 8px 25px rgba(33,150,243,0.6)';
            };
            menuButton.onmouseleave = function() {
              this.style.transform = 'scale(1)';
              this.style.boxShadow = '0 6px 20px rgba(33,150,243,0.4)';
            };
            
            const self = this;
            let panelVisible = false;
            
            menuButton.onclick = function() {
              this.style.transform = 'scale(0.95)';
              setTimeout(() => {
                this.style.transform = 'scale(1.1)';
              }, 100);
              
              if (panelVisible) {
                self.hideControlPanel();
                panelVisible = false;
                this.innerHTML = '⚙️<br><span style="font-size: 10px;">Menu</span>';
              } else {
                self.showControlPanel();
                panelVisible = true;
                this.innerHTML = '✖️<br><span style="font-size: 10px;">Close</span>';
              }
            };
            
            document.body.appendChild(menuButton);
          },
          
          showControlPanel: function() {
            // إزالة اللوحة السابقة إن وجدت
            const existingPanel = document.getElementById('floating-control-panel');
            if (existingPanel) existingPanel.remove();
            
            // إنشاء لوحة التحكم العائمة
            const controlPanel = document.createElement('div');
            controlPanel.id = 'floating-control-panel';
            controlPanel.style.position = 'fixed';
            controlPanel.style.bottom = '120px';
            controlPanel.style.right = '20px';
            controlPanel.style.backgroundColor = 'rgba(0,0,0,0.9)';
            controlPanel.style.color = 'white';
            controlPanel.style.padding = '20px';
            controlPanel.style.borderRadius = '20px';
            controlPanel.style.zIndex = '4500';
            controlPanel.style.fontFamily = 'Arial, sans-serif';
            controlPanel.style.backdropFilter = 'blur(15px)';
            controlPanel.style.border = '1px solid rgba(255,255,255,0.2)';
            controlPanel.style.boxShadow = '0 10px 30px rgba(0,0,0,0.5)';
            controlPanel.style.minWidth = '280px';
            controlPanel.style.animation = 'slideUp 0.3s ease';
            
            // إضافة CSS للأنيميشن
            if (!document.getElementById('control-panel-styles')) {
              const style = document.createElement('style');
              style.id = 'control-panel-styles';
              style.textContent = `
                @keyframes slideUp {
                  from { transform: translateY(20px); opacity: 0; }
                  to { transform: translateY(0); opacity: 1; }
                }
                @keyframes slideDown {
                  from { transform: translateY(0); opacity: 1; }
                  to { transform: translateY(20px); opacity: 0; }
                }
                .control-button {
                  width: 100%;
                  padding: 12px;
                  margin: 8px 0;
                  border: none;
                  border-radius: 10px;
                  color: white;
                  cursor: pointer;
                  font-size: 14px;
                  transition: all 0.3s ease;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  gap: 10px;
                }
                .control-button:hover {
                  transform: translateY(-2px);
                  box-shadow: 0 5px 15px rgba(0,0,0,0.3);
                }
              `;
              document.head.appendChild(style);
            }
            
            const self = this;
            
            controlPanel.innerHTML = `
              <h3 style="margin: 0 0 15px 0; text-align: center; color: #2196F3; font-size: 18px;">🎮 لوحة التحكم</h3>
              
              <button class="control-button" onclick="window.Video360Viewer.showAudioControls()" 
                      style="background: linear-gradient(45deg, #4CAF50, #45a049);">
                🎵 إعدادات الصوت
              </button>
              
              <button class="control-button" onclick="window.Video360Viewer.showAIPanel()" 
                      style="background: linear-gradient(45deg, #FF6B35, #e55a2b);">
                🤖 الذكاء الاصطناعي
              </button>
              
              <button class="control-button" onclick="window.Video360Viewer.flipVideo((window.Video360Viewer.flipState || 0) + 1)" 
                      style="background: linear-gradient(45deg, #9C27B0, #7B1FA2);">
                🔄 قلب الفيديو
              </button>
              
              <button class="control-button" onclick="window.Video360Viewer.resetView()" 
                      style="background: linear-gradient(45deg, #FF9800, #F57C00);">
                🎯 إعادة تعيين العرض
              </button>
              
              <button class="control-button" onclick="window.Video360Viewer.toggleFullscreen()" 
                      style="background: linear-gradient(45deg, #607D8B, #455A64);">
                ⛶ ملء الشاشة
              </button>
              
              <button class="control-button" onclick="window.Video360Viewer.toggleProgressBar()" 
                      style="background: linear-gradient(45deg, #795548, #5D4037);">
                📊 شريط التقدم
              </button>
              
              <div style="margin-top: 15px; padding-top: 15px; border-top: 1px solid rgba(255,255,255,0.2);">
                <h4 style="margin: 0 0 10px 0; color: #FFC107; font-size: 14px;">⚡ إعدادات سريعة</h4>
                
                <div style="display: flex; gap: 10px; margin-bottom: 10px;">
                  <button class="control-button" onclick="window.Video360Viewer.setQualityMode('high')" 
                          style="background: linear-gradient(45deg, #4CAF50, #45a049); flex: 1; padding: 8px; font-size: 12px;">
                    💎 عالية
                  </button>
                  <button class="control-button" onclick="window.Video360Viewer.setQualityMode('medium')" 
                          style="background: linear-gradient(45deg, #FF9800, #F57C00); flex: 1; padding: 8px; font-size: 12px;">
                    🎯 متوسطة
                  </button>
                  <button class="control-button" onclick="window.Video360Viewer.setQualityMode('low')" 
                          style="background: linear-gradient(45deg, #F44336, #D32F2F); flex: 1; padding: 8px; font-size: 12px;">
                    ⚡ سريعة
                  </button>
                </div>
              </div>
              
              <div style="margin-top: 10px; text-align: center; font-size: 12px; color: #888;">
                اضغط خارج اللوحة للإغلاق
              </div>
            `;
            
            document.body.appendChild(controlPanel);
            
            // إغلاق اللوحة عند الضغط خارجها
            document.addEventListener('click', function(e) {
              if (!controlPanel.contains(e.target) && !document.getElementById('main-menu-button').contains(e.target)) {
                self.hideControlPanel();
                const menuBtn = document.getElementById('main-menu-button');
                if (menuBtn) {
                  menuBtn.innerHTML = '⚙️<br><span style="font-size: 10px;">Menu</span>';
                }
              }
            });
          },
          
          hideControlPanel: function() {
            const controlPanel = document.getElementById('floating-control-panel');
            if (controlPanel) {
              controlPanel.style.animation = 'slideDown 0.3s ease';
              setTimeout(() => {
                controlPanel.remove();
              }, 300);
            }
          },
          
          toggleQualityPanel: function() {
            const qualityPanel = document.getElementById('quality-panel');
            if (!qualityPanel) return;
            
            if (qualityPanel.style.display === 'none') {
              qualityPanel.style.display = 'block';
              qualityPanel.style.animation = 'slideUp 0.3s ease';
            } else {
              qualityPanel.style.animation = 'slideDown 0.3s ease';
              setTimeout(() => {
                qualityPanel.style.display = 'none';
              }, 300);
            }
          },
          
          toggleProgressBar: function() {
            const progressContainer = document.getElementById('progress-container');
            if (!progressContainer) return;
            
            if (progressContainer.style.display === 'none') {
              progressContainer.style.display = 'flex';
              progressContainer.style.animation = 'slideUp 0.3s ease';
              progressContainer.style.transform = 'translateY(0)';
            } else {
              progressContainer.style.animation = 'slideDown 0.3s ease';
              setTimeout(() => {
                progressContainer.style.display = 'none';
              }, 300);
            }
          },
          
          createGyroscopeButton: function() {
            const gyroButton = document.createElement('button');
            gyroButton.id = 'gyro-button';
            gyroButton.innerHTML = '🧭<br><span style="font-size: 12px;">Gyro</span>';
            gyroButton.style.position = 'fixed';
            gyroButton.style.bottom = '100px';
            gyroButton.style.left = '20px';
            gyroButton.style.backgroundColor = 'rgba(76,175,80,0.95)';
            gyroButton.style.color = 'white';
            gyroButton.style.padding = '15px';
            gyroButton.style.borderRadius = '50%';
            gyroButton.style.fontSize = '20px';
            gyroButton.style.cursor = 'pointer';
            gyroButton.style.border = '2px solid rgba(255,255,255,0.3)';
            gyroButton.style.zIndex = '4000';
            gyroButton.style.fontFamily = 'Arial, sans-serif';
            gyroButton.style.boxShadow = '0 6px 20px rgba(76,175,80,0.4)';
            gyroButton.style.width = '70px';
            gyroButton.style.height = '70px';
            gyroButton.style.display = 'flex';
            gyroButton.style.flexDirection = 'column';
            gyroButton.style.alignItems = 'center';
            gyroButton.style.justifyContent = 'center';
            gyroButton.style.transition = 'all 0.3s ease';
            gyroButton.style.backdropFilter = 'blur(10px)';
            
            // تأثيرات التفاعل
            gyroButton.onmouseenter = function() {
              this.style.transform = 'scale(1.1)';
              this.style.boxShadow = '0 8px 25px rgba(76,175,80,0.6)';
            };
            gyroButton.onmouseleave = function() {
              this.style.transform = 'scale(1)';
              this.style.boxShadow = self.gyroscopeActive ? '0 6px 20px rgba(76,175,80,0.4)' : '0 6px 20px rgba(158,158,158,0.4)';
            };
            
            const self = this;
            gyroButton.onclick = function() {
              this.style.transform = 'scale(0.95)';
              setTimeout(() => {
                this.style.transform = 'scale(1.1)';
              }, 100);
              
              self.toggleGyroscope();
              
              // تحديث المظهر
              if (self.gyroscopeActive) {
                this.innerHTML = '🧭<br><span style="font-size: 12px;">ON</span>';
                this.style.backgroundColor = 'rgba(76,175,80,0.95)';
                this.style.boxShadow = '0 6px 20px rgba(76,175,80,0.4)';
              } else {
                this.innerHTML = '🧭<br><span style="font-size: 12px;">OFF</span>';
                this.style.backgroundColor = 'rgba(158,158,158,0.95)';
                this.style.boxShadow = '0 6px 20px rgba(158,158,158,0.4)';
              }
            };
            
            document.body.appendChild(gyroButton);
          },
          
          createProgressBar: function() {
            // إنشاء حاوي شريط التقدم
            const progressContainer = document.createElement('div');
            progressContainer.id = 'progress-container';
            progressContainer.style.position = 'fixed';
            progressContainer.style.bottom = '0';
            progressContainer.style.left = '0';
            progressContainer.style.right = '0';
            progressContainer.style.height = '80px';
            progressContainer.style.backgroundColor = 'rgba(0,0,0,0.85)';
            progressContainer.style.backdropFilter = 'blur(15px)';
            progressContainer.style.zIndex = '2500';
            progressContainer.style.display = 'flex';
            progressContainer.style.alignItems = 'center';
            progressContainer.style.padding = '0 20px';
            progressContainer.style.transition = 'all 0.3s ease';
            progressContainer.style.transform = 'translateY(80px)';
            progressContainer.style.flexDirection = 'column';
            progressContainer.style.justifyContent = 'center';
            
            // إنشاء صف الأزرار
            const buttonRow = document.createElement('div');
            buttonRow.style.display = 'flex';
            buttonRow.style.alignItems = 'center';
            buttonRow.style.justifyContent = 'center';
            buttonRow.style.gap = '15px';
            buttonRow.style.marginBottom = '10px';
            
            // إنشاء صف شريط التقدم
            const progressRow = document.createElement('div');
            progressRow.style.display = 'flex';
            progressRow.style.alignItems = 'center';
            progressRow.style.width = '100%';
            progressRow.style.padding = '0 20px';
            
            // شريط التقدم
            const progressBar = document.createElement('div');
            progressBar.id = 'video-progress-bar';
            progressBar.style.flex = '1';
            progressBar.style.height = '8px';
            progressBar.style.backgroundColor = 'rgba(255,255,255,0.3)';
            progressBar.style.borderRadius = '4px';
            progressBar.style.margin = '0 15px';
            progressBar.style.cursor = 'pointer';
            progressBar.style.position = 'relative';
            progressBar.style.overflow = 'hidden';
            progressBar.style.boxShadow = 'inset 0 1px 3px rgba(0,0,0,0.3)';
            
            // التقدم المملوء
            const progressFill = document.createElement('div');
            progressFill.id = 'progress-fill';
            progressFill.style.height = '100%';
            progressFill.style.backgroundColor = '#2196F3';
            progressFill.style.borderRadius = '4px';
            progressFill.style.width = '0%';
            progressFill.style.transition = 'width 0.1s ease';
            progressFill.style.background = 'linear-gradient(90deg, #2196F3, #21CBF3, #03DAC6)';
            progressFill.style.boxShadow = '0 2px 4px rgba(33,150,243,0.3)';
            
            // مؤشر الوقت الحالي
            const currentTime = document.createElement('span');
            currentTime.id = 'current-time';
            currentTime.textContent = '0:00';
            currentTime.style.color = 'white';
            currentTime.style.fontSize = '14px';
            currentTime.style.fontFamily = 'Arial, sans-serif';
            currentTime.style.minWidth = '40px';
            
            // مؤشر المدة الإجمالية
            const totalTime = document.createElement('span');
            totalTime.id = 'total-time';
            totalTime.textContent = '0:00';
            totalTime.style.color = 'rgba(255,255,255,0.7)';
            totalTime.style.fontSize = '14px';
            totalTime.style.fontFamily = 'Arial, sans-serif';
            totalTime.style.minWidth = '40px';
            
            // أزرار التحكم السريع
            const playPauseBtn = document.createElement('button');
            playPauseBtn.innerHTML = '⏸️';
            playPauseBtn.style.background = 'rgba(33,150,243,0.8)';
            playPauseBtn.style.border = '1px solid rgba(255,255,255,0.3)';
            playPauseBtn.style.color = 'white';
            playPauseBtn.style.padding = '12px 16px';
            playPauseBtn.style.borderRadius = '25px';
            playPauseBtn.style.cursor = 'pointer';
            playPauseBtn.style.fontSize = '18px';
            playPauseBtn.style.transition = 'all 0.3s ease';
            playPauseBtn.style.backdropFilter = 'blur(10px)';
            playPauseBtn.style.boxShadow = '0 4px 12px rgba(33,150,243,0.3)';
            
            const volumeBtn = document.createElement('button');
            volumeBtn.innerHTML = '🔊';
            volumeBtn.style.background = 'rgba(76,175,80,0.8)';
            volumeBtn.style.border = '1px solid rgba(255,255,255,0.3)';
            volumeBtn.style.color = 'white';
            volumeBtn.style.padding = '12px 16px';
            volumeBtn.style.borderRadius = '25px';
            volumeBtn.style.cursor = 'pointer';
            volumeBtn.style.fontSize = '18px';
            volumeBtn.style.transition = 'all 0.3s ease';
            volumeBtn.style.backdropFilter = 'blur(10px)';
            volumeBtn.style.boxShadow = '0 4px 12px rgba(76,175,80,0.3)';
            
            // زر ملء الشاشة
            const fullscreenBtn = document.createElement('button');
            fullscreenBtn.innerHTML = '⛶';
            fullscreenBtn.style.background = 'rgba(255,152,0,0.8)';
            fullscreenBtn.style.border = '1px solid rgba(255,255,255,0.3)';
            fullscreenBtn.style.color = 'white';
            fullscreenBtn.style.padding = '12px 16px';
            fullscreenBtn.style.borderRadius = '25px';
            fullscreenBtn.style.cursor = 'pointer';
            fullscreenBtn.style.fontSize = '18px';
            fullscreenBtn.style.transition = 'all 0.3s ease';
            fullscreenBtn.style.backdropFilter = 'blur(10px)';
            fullscreenBtn.style.boxShadow = '0 4px 12px rgba(255,152,0,0.3)';
            
            // تجميع العناصر
            progressBar.appendChild(progressFill);
            
            // إضافة الأزرار إلى صف الأزرار
            buttonRow.appendChild(playPauseBtn);
            buttonRow.appendChild(volumeBtn);
            buttonRow.appendChild(fullscreenBtn);
            
            // إضافة عناصر شريط التقدم إلى صف التقدم
            progressRow.appendChild(currentTime);
            progressRow.appendChild(progressBar);
            progressRow.appendChild(totalTime);
            
            // إضافة الصفوف إلى الحاوي الرئيسي
            progressContainer.appendChild(buttonRow);
            progressContainer.appendChild(progressRow);
            
            document.body.appendChild(progressContainer);
            
            const self = this;
            
            // إظهار شريط التقدم عند تحريك الماوس
            let hideTimeout;
            document.addEventListener('mousemove', function() {
              progressContainer.style.transform = 'translateY(0)';
              clearTimeout(hideTimeout);
              hideTimeout = setTimeout(() => {
                progressContainer.style.transform = 'translateY(80px)';
              }, 3000);
            });
            
            // تفعيل شريط التقدم عند تحميل الفيديو
            if (this.video) {
              this.setupProgressBarEvents();
            }
            
            // أحداث الأزرار
            playPauseBtn.onclick = function() {
              if (self.video) {
                if (self.video.paused) {
                  self.video.play();
                  this.innerHTML = '⏸️';
                } else {
                  self.video.pause();
                  this.innerHTML = '▶️';
                }
              }
            };
            
            volumeBtn.onclick = function() {
              if (self.video) {
                if (self.video.muted) {
                  self.video.muted = false;
                  this.innerHTML = '🔊';
                } else {
                  self.video.muted = true;
                  this.innerHTML = '🔇';
                }
              }
            };
            
            fullscreenBtn.onclick = function() {
              if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen();
                this.innerHTML = '🔲';
              } else {
                document.exitFullscreen();
                this.innerHTML = '⛶';
              }
            };
            
            // تأثيرات التفاعل
            playPauseBtn.onmouseenter = function() {
              this.style.transform = 'scale(1.1)';
              this.style.boxShadow = '0 6px 20px rgba(33,150,243,0.5)';
            };
            playPauseBtn.onmouseleave = function() {
              this.style.transform = 'scale(1)';
              this.style.boxShadow = '0 4px 12px rgba(33,150,243,0.3)';
            };
            
            volumeBtn.onmouseenter = function() {
              this.style.transform = 'scale(1.1)';
              this.style.boxShadow = '0 6px 20px rgba(76,175,80,0.5)';
            };
            volumeBtn.onmouseleave = function() {
              this.style.transform = 'scale(1)';
              this.style.boxShadow = '0 4px 12px rgba(76,175,80,0.3)';
            };
            
            fullscreenBtn.onmouseenter = function() {
              this.style.transform = 'scale(1.1)';
              this.style.boxShadow = '0 6px 20px rgba(255,152,0,0.5)';
            };
            fullscreenBtn.onmouseleave = function() {
              this.style.transform = 'scale(1)';
              this.style.boxShadow = '0 4px 12px rgba(255,152,0,0.3)';
            };
          },
          
          setupProgressBarEvents: function() {
            if (!this.video) return;
            
            const progressBar = document.getElementById('video-progress-bar');
            const progressFill = document.getElementById('progress-fill');
            const currentTimeSpan = document.getElementById('current-time');
            const totalTimeSpan = document.getElementById('total-time');
            
            if (!progressBar || !progressFill || !currentTimeSpan || !totalTimeSpan) return;
            
            const self = this;
            
            // تحديث شريط التقدم
            this.video.addEventListener('timeupdate', function() {
              const progress = (this.currentTime / this.duration) * 100;
              progressFill.style.width = progress + '%';
              
              currentTimeSpan.textContent = self.formatTime(this.currentTime);
              totalTimeSpan.textContent = self.formatTime(this.duration);
            });
            
            // النقر على شريط التقدم للانتقال
            progressBar.addEventListener('click', function(e) {
              const rect = this.getBoundingClientRect();
              const clickX = e.clientX - rect.left;
              const width = rect.width;
              const percentage = clickX / width;
              
              if (self.video && self.video.duration) {
                self.video.currentTime = percentage * self.video.duration;
              }
            });
          },
          
          formatTime: function(seconds) {
            if (isNaN(seconds)) return '0:00';
            
            const mins = Math.floor(seconds / 60);
            const secs = Math.floor(seconds % 60);
            return mins + ':' + (secs < 10 ? '0' : '') + secs;
          },
          
          toggleGyroscope: function() {
            this.gyroscopeActive = !this.gyroscopeActive;
            console.log('Gyroscope:', this.gyroscopeActive ? 'ON' : 'OFF');
          },
          
          enterVR: function() {
            if (!this.vrSupported) {
              console.log('VR not supported');
              return;
            }
            
            const self = this;
            
            navigator.xr.requestSession('immersive-vr', {
              optionalFeatures: ['local-floor', 'bounded-floor']
            }).then((session) => {
              self.vrSession = session;
              
              // إعداد WebGL للـ VR
              self.renderer.xr.enabled = true;
              self.renderer.xr.setSession(session);
              
              // تحديث حلقة الرسم للـ VR
              self.renderer.setAnimationLoop(function() {
                self.vrAnimate();
              });
              
              session.addEventListener('end', function() {
                self.exitVR();
              });
              
              console.log('VR Mode: Entered');
              
            }).catch((error) => {
              console.log('VR Error:', error);
            });
          },
          
          exitVR: function() {
            if (this.vrSession) {
              this.vrSession.end();
              this.vrSession = null;
            }
            
            this.renderer.xr.enabled = false;
            this.renderer.setAnimationLoop(null);
            
            // العودة للحلقة العادية
            this.animate();
            
            console.log('VR Mode: Exited');
          },
          
          enterAR: function() {
            if (!this.arSupported) {
              console.log('AR not supported');
              return;
            }
            
            const self = this;
            
            navigator.xr.requestSession('immersive-ar', {
              requiredFeatures: ['local-floor'],
              optionalFeatures: ['dom-overlay', 'light-estimation', 'hit-test']
            }).then((session) => {
              self.arSession = session;
              
              // إعداد WebGL للـ AR
              self.renderer.xr.enabled = true;
              self.renderer.xr.setSession(session);
              
              // جعل الخلفية شفافة للـ AR
              self.renderer.setClearColor(0x000000, 0);
              
              // تحديث حلقة الرسم للـ AR
              self.renderer.setAnimationLoop(function() {
                self.arAnimate();
              });
              
              session.addEventListener('end', function() {
                self.exitAR();
              });
              
              console.log('AR Mode: Entered');
              
            }).catch((error) => {
              console.log('AR Error:', error);
            });
          },
          
          exitAR: function() {
            if (this.arSession) {
              this.arSession.end();
              this.arSession = null;
            }
            
            this.renderer.xr.enabled = false;
            this.renderer.setAnimationLoop(null);
            
            // استعادة الخلفية العادية
            this.renderer.setClearColor(0x000000, 1);
            
            // العودة للحلقة العادية
            this.animate();
            
            console.log('AR Mode: Exited');
          },
          
          arAnimate: function() {
            // حلقة الرسم الخاصة بالـ AR
            this.update();
            this.updateSpatialAudio();
            this.updateQualityInfo();
            
            if (this.frameCount % 100 === 0) {
              this.optimizePerformance();
            }
            
            if (this.renderer && this.scene && this.camera) {
              this.renderer.render(this.scene, this.camera);
            }
          },
          
          vrAnimate: function() {
            // حلقة الرسم الخاصة بالـ VR
            this.update();
            this.updateSpatialAudio();
            this.updateQualityInfo();
            
            if (this.frameCount % 100 === 0) {
              this.optimizePerformance();
            }
            
            if (this.renderer && this.scene && this.camera) {
              this.renderer.render(this.scene, this.camera);
            }
          },
          
          setupAI: function() {
            try {
              console.log('Initializing AI features...');
              
              // إعداد تحليل الفيديو الذكي
              this.aiEnabled = true;
              this.sceneAnalysis = {
                brightness: 0,
                contrast: 0,
                dominantColors: [],
                motionLevel: 0,
                audioLevel: 0
              };
              
              // إعداد التحسين التلقائي
              this.autoOptimization = true;
              this.adaptiveQuality = true;
              
              // إعداد التنبؤ بالحركة
              this.motionPrediction = {
                enabled: true,
                history: [],
                predicted: { lon: 0, lat: 0 }
              };
              
              // إعداد التحليل الصوتي الذكي
              this.audioAI = {
                enabled: true,
                beatDetection: false,
                frequencyAnalysis: [],
                musicGenre: 'unknown'
              };
              
              console.log('AI features initialized successfully');
              
            } catch (error) {
              console.log('AI initialization error:', error);
              this.aiEnabled = false;
            }
          },
          
          analyzeScene: function() {
            if (!this.aiEnabled || !this.video || !this.renderer) return;
            
            try {
              // تحليل السطوع والتباين
              const canvas = this.renderer.domElement;
              const ctx = canvas.getContext('2d');
              if (ctx) {
                const imageData = ctx.getImageData(0, 0, 100, 100);
                const data = imageData.data;
                
                let brightness = 0;
                let contrast = 0;
                
                for (let i = 0; i < data.length; i += 4) {
                  const r = data[i];
                  const g = data[i + 1];
                  const b = data[i + 2];
                  brightness += (r + g + b) / 3;
                }
                
                brightness = brightness / (data.length / 4);
                this.sceneAnalysis.brightness = brightness / 255;
                
                // تحليل مستوى الحركة
                this.analyzeMotion();
                
                // تحليل الصوت
                this.analyzeAudio();
                
                // تطبيق التحسينات التلقائية
                this.applyAIOptimizations();
              }
              
            } catch (error) {
              console.log('Scene analysis error:', error);
            }
          },
          
          analyzeMotion: function() {
            if (!this.motionPrediction.enabled) return;
            
            // تسجيل تاريخ الحركة
            const currentPosition = { lon: this.lon, lat: this.lat, time: Date.now() };
            this.motionPrediction.history.push(currentPosition);
            
            // الاحتفاظ بآخر 10 نقاط فقط
            if (this.motionPrediction.history.length > 10) {
              this.motionPrediction.history.shift();
            }
            
            // حساب مستوى الحركة
            if (this.motionPrediction.history.length >= 2) {
              const recent = this.motionPrediction.history.slice(-2);
              const deltaLon = Math.abs(recent[1].lon - recent[0].lon);
              const deltaLat = Math.abs(recent[1].lat - recent[0].lat);
              this.sceneAnalysis.motionLevel = deltaLon + deltaLat;
              
              // التنبؤ بالحركة القادمة
              this.predictNextMove();
            }
          },
          
          predictNextMove: function() {
            if (this.motionPrediction.history.length < 3) return;
            
            const history = this.motionPrediction.history;
            const recent = history.slice(-3);
            
            // حساب الاتجاه والسرعة
            let avgDeltaLon = 0;
            let avgDeltaLat = 0;
            
            for (let i = 1; i < recent.length; i++) {
              avgDeltaLon += recent[i].lon - recent[i-1].lon;
              avgDeltaLat += recent[i].lat - recent[i-1].lat;
            }
            
            avgDeltaLon /= (recent.length - 1);
            avgDeltaLat /= (recent.length - 1);
            
            // التنبؤ بالموقع القادم
            this.motionPrediction.predicted = {
              lon: this.lon + avgDeltaLon * 2,
              lat: this.lat + avgDeltaLat * 2
            };
          },
          
          analyzeAudio: function() {
            if (!this.audioAI.enabled || !this.analyserNode) return;
            
            try {
              // تحليل التردد
              this.analyserNode.getByteFrequencyData(this.audioDataArray);
              
              // حساب مستوى الصوت العام
              let totalLevel = 0;
              for (let i = 0; i < this.audioDataArray.length; i++) {
                totalLevel += this.audioDataArray[i];
              }
              this.sceneAnalysis.audioLevel = totalLevel / this.audioDataArray.length;
              
              // تحليل الترددات للكشف عن النوع الموسيقي
              this.analyzeFrequencies();
              
              // كشف الإيقاع
              this.detectBeat();
              
            } catch (error) {
              console.log('Audio analysis error:', error);
            }
          },
          
          analyzeFrequencies: function() {
            const frequencies = this.audioDataArray;
            const bass = frequencies.slice(0, 10).reduce((a, b) => a + b, 0) / 10;
            const mid = frequencies.slice(10, 50).reduce((a, b) => a + b, 0) / 40;
            const treble = frequencies.slice(50, 128).reduce((a, b) => a + b, 0) / 78;
            
            this.audioAI.frequencyAnalysis = { bass, mid, treble };
            
            // تخمين النوع الموسيقي بناء على التوزيع الترددي
            if (bass > mid && bass > treble) {
              this.audioAI.musicGenre = 'electronic';
            } else if (mid > bass && mid > treble) {
              this.audioAI.musicGenre = 'vocal';
            } else if (treble > bass && treble > mid) {
              this.audioAI.musicGenre = 'classical';
            } else {
              this.audioAI.musicGenre = 'mixed';
            }
          },
          
          detectBeat: function() {
            const currentLevel = this.sceneAnalysis.audioLevel;
            
            if (!this.lastAudioLevel) {
              this.lastAudioLevel = currentLevel;
              return;
            }
            
            // كشف الذروة الصوتية (Beat)
            if (currentLevel > this.lastAudioLevel * 1.3 && currentLevel > 50) {
              this.audioAI.beatDetection = true;
              
              // تأثير بصري مع الإيقاع
              if (this.sphere) {
                const intensity = currentLevel / 255;
                this.sphere.material.emissive.setRGB(intensity * 0.2, intensity * 0.1, intensity * 0.3);
                
                // العودة للطبيعي تدريجياً
                setTimeout(() => {
                  if (this.sphere) {
                    this.sphere.material.emissive.setRGB(0, 0, 0);
                  }
                }, 100);
              }
            } else {
              this.audioAI.beatDetection = false;
            }
            
            this.lastAudioLevel = currentLevel;
          },
          
          applyAIOptimizations: function() {
            if (!this.autoOptimization) return;
            
            try {
              // تحسين الجودة بناء على مستوى الحركة
              if (this.sceneAnalysis.motionLevel > 50) {
                // حركة سريعة - خفض الجودة للأداء
                this.setQualityMode('medium');
              } else if (this.sceneAnalysis.motionLevel < 10) {
                // حركة قليلة - رفع الجودة
                this.setQualityMode('high');
              }
              
              // تحسين الصوت بناء على النوع الموسيقي
              this.optimizeAudioForGenre();
              
              // تحسين الإضاءة بناء على السطوع
              this.optimizeLighting();
              
            } catch (error) {
              console.log('AI optimization error:', error);
            }
          },
          
          optimizeAudioForGenre: function() {
            if (!this.eqFilters || !this.audioAI.enabled) return;
            
            // تحسين المعادل بناء على النوع الموسيقي
            switch(this.audioAI.musicGenre) {
              case 'electronic':
                // تعزيز الباس والترددات العالية
                if (this.eqFilters[0]) this.eqFilters[0].gain.value = 3; // Bass
                if (this.eqFilters[5]) this.eqFilters[5].gain.value = 2; // Treble
                break;
              case 'vocal':
                // تعزيز الترددات المتوسطة
                if (this.eqFilters[2]) this.eqFilters[2].gain.value = 2;
                if (this.eqFilters[3]) this.eqFilters[3].gain.value = 2;
                break;
              case 'classical':
                // توازن طبيعي مع تعزيز خفيف للترددات العالية
                if (this.eqFilters[4]) this.eqFilters[4].gain.value = 1;
                if (this.eqFilters[5]) this.eqFilters[5].gain.value = 1;
                break;
            }
          },
          
          optimizeLighting: function() {
            if (!this.renderer) return;
            
            // تحسين الإضاءة بناء على سطوع المشهد
            if (this.sceneAnalysis.brightness < 0.3) {
              // مشهد مظلم - زيادة السطوع
              this.renderer.toneMappingExposure = 1.5;
            } else if (this.sceneAnalysis.brightness > 0.7) {
              // مشهد مشرق - تقليل السطوع
              this.renderer.toneMappingExposure = 0.8;
            } else {
              // سطوع طبيعي
              this.renderer.toneMappingExposure = 1.0;
            }
          },
          
          showAIPanel: function() {
            if (!this.aiEnabled) {
              console.log('AI features not available');
              return;
            }
            
            // إنشاء لوحة الذكاء الاصطناعي
            const aiPanel = document.createElement('div');
            aiPanel.id = 'ai-panel';
            aiPanel.style.position = 'fixed';
            aiPanel.style.top = '10px';
            aiPanel.style.left = '10px';
            aiPanel.style.backgroundColor = 'rgba(0,0,0,0.8)';
            aiPanel.style.color = 'white';
            aiPanel.style.padding = '15px';
            aiPanel.style.borderRadius = '10px';
            aiPanel.style.zIndex = '3000';
            aiPanel.style.minWidth = '250px';
            aiPanel.style.fontFamily = 'Arial, sans-serif';
            aiPanel.style.fontSize = '12px';
            
            const self = this;
            
            function updateAIPanel() {
              if (!document.getElementById('ai-panel')) return;
              
              aiPanel.innerHTML = 
                '<h3 style="margin-top: 0; color: #FF6B35;">🤖 الذكاء الاصطناعي</h3>' +
                '<div>📊 السطوع: ' + (self.sceneAnalysis.brightness * 100).toFixed(1) + '%</div>' +
                '<div>🏃 مستوى الحركة: ' + self.sceneAnalysis.motionLevel.toFixed(1) + '</div>' +
                '<div>🔊 مستوى الصوت: ' + self.sceneAnalysis.audioLevel.toFixed(1) + '</div>' +
                '<div>🎵 النوع الموسيقي: ' + self.audioAI.musicGenre + '</div>' +
                '<div>💓 كشف الإيقاع: ' + (self.audioAI.beatDetection ? '✅' : '❌') + '</div>' +
                '<div>🎯 التنبؤ: lon=' + self.motionPrediction.predicted.lon.toFixed(1) + ', lat=' + self.motionPrediction.predicted.lat.toFixed(1) + '</div>' +
                '<div style="margin-top: 10px;">' +
                  '<button onclick="window.Video360Viewer.toggleAutoOptimization()" style="width: 100%; padding: 5px; margin: 2px 0; background: ' + (self.autoOptimization ? '#4CAF50' : '#f44336') + '; color: white; border: none; border-radius: 3px; cursor: pointer;">تحسين تلقائي: ' + (self.autoOptimization ? 'ON' : 'OFF') + '</button>' +
                  '<button onclick="window.Video360Viewer.toggleMotionPrediction()" style="width: 100%; padding: 5px; margin: 2px 0; background: ' + (self.motionPrediction.enabled ? '#4CAF50' : '#f44336') + '; color: white; border: none; border-radius: 3px; cursor: pointer;">تنبؤ الحركة: ' + (self.motionPrediction.enabled ? 'ON' : 'OFF') + '</button>' +
                '</div>' +
                '<button onclick="document.getElementById(\\'ai-panel\\').remove()" style="width: 100%; padding: 8px; margin-top: 10px; background: #f44336; color: white; border: none; border-radius: 5px; cursor: pointer;">إغلاق</button>';
            }
            
            updateAIPanel();
            document.body.appendChild(aiPanel);
            
            // تحديث اللوحة كل ثانية
            const updateInterval = setInterval(() => {
              if (document.getElementById('ai-panel')) {
                updateAIPanel();
              } else {
                clearInterval(updateInterval);
              }
            }, 1000);
          },
          
          toggleAutoOptimization: function() {
            this.autoOptimization = !this.autoOptimization;
            console.log('Auto Optimization:', this.autoOptimization ? 'ON' : 'OFF');
          },
          
          toggleMotionPrediction: function() {
            this.motionPrediction.enabled = !this.motionPrediction.enabled;
            console.log('Motion Prediction:', this.motionPrediction.enabled ? 'ON' : 'OFF');
          },
          
          animate: function() {
            const self = this;
            requestAnimationFrame(function() {
              self.animate();
            });
            
            this.update();
            
            // تحديث الصوت المكاني
            this.updateSpatialAudio();
            
            // تحليل المشهد بالذكاء الاصطناعي
            if (this.frameCount % 30 === 0) { // كل 30 إطار
              this.analyzeScene();
            }
            
            // تحسين الأداء - تنظيف الذاكرة كل 100 إطار
            if (!this.frameCount) this.frameCount = 0;
            this.frameCount++;
            
            if (this.frameCount % 100 === 0) {
              this.optimizePerformance();
            }
            if (this.renderer && this.scene && this.camera) {
              this.renderer.render(this.scene, this.camera);
            }
          }
        };
        
        // تهيئة العارض
        setTimeout(function() {
          window.Video360Viewer.init();
        }, 100);
      ''';
      
      html.document.head?.append(viewerScript);
    });
  }

  Future<void> _pickVideo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        setState(() {
          _selectedVideoPath = url;
        });

        // تحميل الفيديو
        final script = html.ScriptElement();
        script.text = 'if(window.Video360Viewer) { window.Video360Viewer.loadVideo("$url"); }';
        html.document.head?.append(script);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الفيديو: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'عارض الفيديو 360°',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.video_library, color: Colors.white),
            onPressed: _isLoading ? null : _pickVideo,
            tooltip: 'اختر فيديو 360°',
          ),
        ],
      ),
      body: kIsWeb
          ? const HtmlElementView(viewType: 'web-video-360-viewer')
          : const Center(
              child: Text(
                'هذا التطبيق يعمل على الويب فقط حالياً',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
