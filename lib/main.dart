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
            qualityPanel.style.backgroundColor = 'rgba(0,0,0,0.8)';
            qualityPanel.style.color = 'white';
            qualityPanel.style.padding = '10px 15px';
            qualityPanel.style.borderRadius = '10px';
            qualityPanel.style.fontSize = '12px';
            qualityPanel.style.fontFamily = 'monospace';
            qualityPanel.style.zIndex = '3000';
            qualityPanel.style.minWidth = '200px';
            
            const title = document.createElement('div');
            title.textContent = '📊 معلومات الجودة';
            title.style.fontWeight = 'bold';
            title.style.marginBottom = '5px';
            title.style.color = '#2196F3';
            
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
              '🧭 Gyroscope: ' + (this.gyroscopeSupported ? (this.gyroscopeActive ? '✅ مفعل' : '⏸️ متاح') : '❌ غير متاح');
            
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
            vrButton.innerHTML = '🥽 VR Mode';
            vrButton.style.position = 'fixed';
            vrButton.style.bottom = '80px';
            vrButton.style.right = '20px';
            vrButton.style.backgroundColor = 'rgba(0,150,255,0.9)';
            vrButton.style.color = 'white';
            vrButton.style.padding = '12px 20px';
            vrButton.style.borderRadius = '25px';
            vrButton.style.fontSize = '16px';
            vrButton.style.cursor = 'pointer';
            vrButton.style.border = 'none';
            vrButton.style.zIndex = '4000';
            vrButton.style.fontFamily = 'Arial, sans-serif';
            vrButton.style.boxShadow = '0 4px 8px rgba(0,0,0,0.3)';
            
            const self = this;
            vrButton.onclick = function() {
              self.enterVR();
            };
            
            document.body.appendChild(vrButton);
          },
          
          createARButton: function() {
            if (!this.arSupported) return;
            
            const arButton = document.createElement('button');
            arButton.id = 'ar-button';
            arButton.innerHTML = '📱 AR Mode';
            arButton.style.position = 'fixed';
            arButton.style.bottom = '140px';
            arButton.style.right = '20px';
            arButton.style.backgroundColor = 'rgba(255,152,0,0.9)';
            arButton.style.color = 'white';
            arButton.style.padding = '12px 20px';
            arButton.style.borderRadius = '25px';
            arButton.style.fontSize = '16px';
            arButton.style.cursor = 'pointer';
            arButton.style.border = 'none';
            arButton.style.zIndex = '4000';
            arButton.style.fontFamily = 'Arial, sans-serif';
            arButton.style.boxShadow = '0 4px 8px rgba(0,0,0,0.3)';
            
            const self = this;
            arButton.onclick = function() {
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
          },
          
          createGyroscopeButton: function() {
            const gyroButton = document.createElement('button');
            gyroButton.id = 'gyro-button';
            gyroButton.innerHTML = '📱 Gyroscope';
            gyroButton.style.position = 'fixed';
            gyroButton.style.bottom = '20px';
            gyroButton.style.left = '20px';
            gyroButton.style.backgroundColor = 'rgba(76,175,80,0.9)';
            gyroButton.style.color = 'white';
            gyroButton.style.padding = '12px 20px';
            gyroButton.style.borderRadius = '25px';
            gyroButton.style.fontSize = '16px';
            gyroButton.style.cursor = 'pointer';
            gyroButton.style.border = 'none';
            gyroButton.style.zIndex = '4000';
            gyroButton.style.fontFamily = 'Arial, sans-serif';
            gyroButton.style.boxShadow = '0 4px 8px rgba(0,0,0,0.3)';
            
            const self = this;
            gyroButton.onclick = function() {
              self.toggleGyroscope();
              this.textContent = self.gyroscopeActive ? '📱 Gyro ON' : '📱 Gyro OFF';
              this.style.backgroundColor = self.gyroscopeActive ? 'rgba(76,175,80,0.9)' : 'rgba(158,158,158,0.9)';
            };
            
            document.body.appendChild(gyroButton);
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
          
          animate: function() {
            const self = this;
            requestAnimationFrame(function() {
              self.animate();
            });
            
            this.update();
            
            // تحديث الصوت المكاني
            this.updateSpatialAudio();
            
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
