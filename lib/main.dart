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
            
            // إنشاء الرندر
            this.renderer = new THREE.WebGLRenderer({ antialias: true });
            this.renderer.setSize(window.innerWidth, window.innerHeight);
            this.renderer.setPixelRatio(window.devicePixelRatio);
            this.renderer.setClearColor(0x000000);
            
            // إضافة الكانفاس للعارض
            viewerArea.appendChild(this.renderer.domElement);
            
            // إضافة الأحداث
            this.addEventListeners();
            
            // بدء الرسم
            this.animate();
            
            console.log('360 Viewer initialized successfully');
            return true;
          },
          
          loadVideo: function(videoUrl) {
            console.log('Loading video:', videoUrl);
            
            const welcomeScreen = document.getElementById('welcome-screen');
            const viewerArea = document.getElementById('viewer-area');
            
            if (welcomeScreen) welcomeScreen.style.display = 'none';
            if (viewerArea) viewerArea.style.display = 'block';
            
            // إنشاء عنصر الفيديو
            this.video = document.createElement('video');
            this.video.src = videoUrl;
            this.video.loop = true;
            this.video.muted = false;
            this.video.volume = 0.7;
            this.video.crossOrigin = 'anonymous';
            this.video.autoplay = true;
            
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
            // إنشاء texture من الفيديو
            this.videoTexture = new THREE.VideoTexture(this.video);
            this.videoTexture.minFilter = THREE.LinearFilter;
            this.videoTexture.magFilter = THREE.LinearFilter;
            
            // إنشاء الكرة
            const geometry = new THREE.SphereGeometry(500, 60, 40);
            geometry.scale(-1, 1, 1);
            
            const material = new THREE.MeshBasicMaterial({ 
              map: this.videoTexture,
              side: THREE.DoubleSide
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
            
            controls.appendChild(playBtn);
            controls.appendChild(muteBtn);
            controls.appendChild(fullscreenBtn);
            
            document.body.appendChild(controls);
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
          
          animate: function() {
            const self = this;
            requestAnimationFrame(function() {
              self.animate();
            });
            
            this.update();
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
