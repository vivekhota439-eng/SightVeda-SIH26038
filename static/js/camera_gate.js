// =============================================================================
// FUNDUS CAMERA & REAL-TIME RED/GREEN QUALITY GATE MODULE
// =============================================================================
let currentStream = null;
let currentVideo = null;
let currentCanvas = null;
let currentCtx = null;
let qualityCheckInterval = null;
let lastQualityState = 'red';

let selectedCameraDeviceId = null;
let isOpticalInverted = false;
let currentZoomScale = 1.0;

// 1. Initialize Camera and Enumerate Connected USB / Optical Devices
async function initLiveCamera() {
    currentVideo = document.getElementById('liveVideo');
    currentCanvas = document.getElementById('qualityCanvas');
    if (!currentVideo || !currentCanvas) return;

    currentCtx = currentCanvas.getContext('2d', { willReadFrequently: true });

    // Populate camera source select dropdown
    await populateCameraDevices();

    // Start video stream with selected or preferred fundus camera
    await startCameraStream(selectedCameraDeviceId);
}

// Enumerate connected USB / Video Input Devices
async function populateCameraDevices() {
    const select = document.getElementById('cameraSourceSelect');
    const badge = document.getElementById('cameraConnectionBadge');
    if (!select) return;

    try {
        // Request initial permission so device labels are available
        if (!currentStream) {
            try {
                const tempStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
                tempStream.getTracks().forEach(t => t.stop());
            } catch(e) {}
        }

        const devices = await navigator.mediaDevices.enumerateDevices();
        const videoDevices = devices.filter(d => d.kind === 'videoinput');

        select.innerHTML = '';
        let fundusCameraFound = false;

        if (videoDevices.length === 0) {
            select.innerHTML = '<option value="">No Camera Devices Detected</option>';
            if (badge) {
                badge.innerText = '🔴 No Camera Detected';
                badge.style.background = '#fee2e2';
                badge.style.color = '#991b1b';
            }
            return;
        }

        videoDevices.forEach((device, index) => {
            const opt = document.createElement('option');
            opt.value = device.deviceId;
            
            const label = device.label || `Camera ${index + 1}`;
            const isFundus = /fundus|retina|remidio|forus|topcon|canon|zeiss|horus|ophthalmic|uvc|usb video/i.test(label);

            if (isFundus) {
                opt.text = `👁️ ${label} (External Fundus Camera USB)`;
                opt.selected = true;
                selectedCameraDeviceId = device.deviceId;
                fundusCameraFound = true;
            } else if (/back|rear|environment/i.test(label)) {
                opt.text = `📷 ${label} (Rear / External Camera)`;
                if (!fundusCameraFound) selectedCameraDeviceId = device.deviceId;
            } else {
                opt.text = `💻 ${label} (Built-in / WebCam)`;
            }

            select.appendChild(opt);
        });

        if (badge) {
            if (fundusCameraFound) {
                badge.innerText = '🟢 USB Fundus Camera Connected';
                badge.style.background = '#dcfce7';
                badge.style.color = '#166534';
                badge.style.border = '1px solid #86efac';
            } else {
                badge.innerText = '🟡 General Camera (Connect USB Fundus Camera)';
                badge.style.background = '#fef3c7';
                badge.style.color = '#92400e';
                badge.style.border = '1px solid #fde68a';
            }
        }
    } catch(err) {
        console.warn("Could not enumerate camera devices:", err);
    }
}

// Start video stream with specified camera device ID
async function startCameraStream(deviceId) {
    stopLiveCamera();

    const constraints = {
        audio: false,
        video: {
            width: { ideal: 1920, min: 1280 },
            height: { ideal: 1080, min: 720 }
        }
    };

    if (deviceId) {
        constraints.video.deviceId = { exact: deviceId };
    } else {
        constraints.video.facingMode = "environment";
    }

    try {
        currentStream = await navigator.mediaDevices.getUserMedia(constraints);
        currentVideo.srcObject = currentStream;
        await currentVideo.play();
        applyOpticalTransforms();
        startRealtimeQualityAnalysis();
    } catch(err) {
        console.warn("Camera streaming error, retrying standard constraints:", err);
        try {
            currentStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
            currentVideo.srcObject = currentStream;
            await currentVideo.play();
            applyOpticalTransforms();
            startRealtimeQualityAnalysis();
        } catch(e) {
            updateQualityBadge('red', '⚠️ Camera Inaccessible. Please Check USB Connection or Upload File.');
        }
    }
}

function stopLiveCamera() {
    if (qualityCheckInterval) {
        clearInterval(qualityCheckInterval);
        qualityCheckInterval = null;
    }
    if (currentStream) {
        currentStream.getTracks().forEach(track => track.stop());
        currentStream = null;
    }
}

function switchCameraSource(deviceId) {
    selectedCameraDeviceId = deviceId;
    startCameraStream(deviceId);
}

// 2. Optical Controls for Ophthalmic Lenses (Inversion & Zoom)
function toggleOpticalInversion() {
    isOpticalInverted = !isOpticalInverted;
    const btn = document.getElementById('btnFlipOptical');
    if (btn) {
        btn.classList.toggle('active', isOpticalInverted);
        btn.style.background = isOpticalInverted ? '#0284c7' : '#ffffff';
        btn.style.color = isOpticalInverted ? '#ffffff' : '#1e293b';
    }
    applyOpticalTransforms();
}

function setZoom(scale) {
    currentZoomScale = scale;
    applyOpticalTransforms();
}

function applyOpticalTransforms() {
    if (!currentVideo) return;
    let transformStr = `scale(${currentZoomScale})`;
    if (isOpticalInverted) {
        // Invert 180 degrees (as seen in indirect ophthalmoscopy)
        transformStr += " rotate(180deg)";
    }
    currentVideo.style.transform = transformStr;
}

// 3. SSC Exam Form Style Real-Time Mathematical Quality Gate
function startRealtimeQualityAnalysis() {
    const box = document.getElementById('cameraBox');
    const captureBtn = document.getElementById('btnCapture');

    qualityCheckInterval = setInterval(() => {
        if (!currentVideo || currentVideo.readyState !== 4) return;

        currentCanvas.width = 320;
        currentCanvas.height = 240;
        currentCtx.drawImage(currentVideo, 0, 0, currentCanvas.width, currentCanvas.height);

        const imgData = currentCtx.getImageData(0, 0, currentCanvas.width, currentCanvas.height);
        const data = imgData.data;

        // 1. Average Brightness / Exposure (Luminance)
        let totalBrightness = 0;
        let count = data.length / 4;
        for (let i = 0; i < data.length; i += 4) {
            totalBrightness += (0.299 * data[i] + 0.587 * data[i+1] + 0.114 * data[i+2]);
        }
        const avgBrightness = totalBrightness / count;

        // 2. High-Frequency Focus / Sharpness (Laplacian approximation in center reticle)
        let focusScore = 0;
        const w = currentCanvas.width;
        const startX = Math.floor(w * 0.25);
        const endX = Math.floor(w * 0.75);
        const startY = Math.floor(currentCanvas.height * 0.25);
        const endY = Math.floor(currentCanvas.height * 0.75);

        for (let y = startY; y < endY; y += 2) {
            for (let x = startX; x < endX; x += 2) {
                const idx = (y * w + x) * 4;
                const rightIdx = (y * w + (x + 2)) * 4;
                const downIdx = ((y + 2) * w + x) * 4;
                
                const lum = 0.299 * data[idx] + 0.587 * data[idx+1] + 0.114 * data[idx+2];
                const lumR = 0.299 * data[rightIdx] + 0.587 * data[rightIdx+1] + 0.114 * data[rightIdx+2];
                const lumD = 0.299 * data[downIdx] + 0.587 * data[downIdx+1] + 0.114 * data[downIdx+2];

                focusScore += Math.abs(lum - lumR) + Math.abs(lum - lumD);
            }
        }
        const normalizedFocus = focusScore / ((endX - startX) * (endY - startY) / 4);

        // Quality Gate Evaluation
        if (avgBrightness >= 48 && avgBrightness <= 215 && normalizedFocus >= 12.5) {
            if (lastQualityState !== 'green') {
                updateQualityBadge('green', '🟢 परफेक्ट फोकस एवं रोशनी (Clear Fundus - Ready to Capture)');
                box.className = 'camera-viewfinder-box status-green';
                if (captureBtn) captureBtn.disabled = false;
                lastQualityState = 'green';
            }
        } else if (avgBrightness < 38) {
            if (lastQualityState !== 'red_dark') {
                updateQualityBadge('red', '🔴 रोशनी कम है (Too Dark) - फ्लैश / लाइट चालू करें');
                box.className = 'camera-viewfinder-box status-red';
                lastQualityState = 'red_dark';
            }
        } else if (avgBrightness > 225) {
            if (lastQualityState !== 'red_glare') {
                updateQualityBadge('red', '🔴 अत्यधिक चमक / कॉर्नियल रिफ्लेक्शन (Corneal Glare)');
                box.className = 'camera-viewfinder-box status-red';
                lastQualityState = 'red_glare';
            }
        } else {
            if (lastQualityState !== 'yellow') {
                updateQualityBadge('yellow', '🟡 स्थिर रखें / पुतली केंद्र में लाएं (Centering Retina)...');
                box.className = 'camera-viewfinder-box status-yellow';
                lastQualityState = 'yellow';
            }
        }
    }, 120);
}

function updateQualityBadge(color, text) {
    const badge = document.getElementById('qualityBadge');
    const dot = document.getElementById('qualityDot');
    if (!badge || !dot) return;

    badge.childNodes[badge.childNodes.length - 1].nodeValue = " " + text;
    if (color === 'green') {
        dot.style.background = '#22c55e';
    } else if (color === 'yellow') {
        dot.style.background = '#f59e0b';
    } else {
        dot.style.background = '#ef4444';
    }
}

// Snap high-resolution photo from fundus camera stream
function capturePhoto() {
    if (!currentVideo) return;

    const snapCanvas = document.createElement('canvas');
    snapCanvas.width = currentVideo.videoWidth || 1280;
    snapCanvas.height = currentVideo.videoHeight || 720;
    const snapCtx = snapCanvas.getContext('2d');

    // Apply optical transforms if enabled
    if (isOpticalInverted) {
        snapCtx.translate(snapCanvas.width, snapCanvas.height);
        snapCtx.rotate(Math.PI);
    }
    if (currentZoomScale > 1.0) {
        const cropW = snapCanvas.width / currentZoomScale;
        const cropH = snapCanvas.height / currentZoomScale;
        const cropX = (snapCanvas.width - cropW) / 2;
        const cropY = (snapCanvas.height - cropH) / 2;
        snapCtx.drawImage(currentVideo, cropX, cropY, cropW, cropH, 0, 0, snapCanvas.width, snapCanvas.height);
    } else {
        snapCtx.drawImage(currentVideo, 0, 0, snapCanvas.width, snapCanvas.height);
    }

    const dataUrl = snapCanvas.toDataURL('image/png');
    document.getElementById('capturedImageData').value = dataUrl;

    document.getElementById('cameraSection').style.display = 'none';
    document.getElementById('snapPreviewSection').style.display = 'block';
    document.getElementById('snapPreviewImg').src = dataUrl;

    stopLiveCamera();
}

function retakePhoto() {
    document.getElementById('capturedImageData').value = '';
    document.getElementById('snapPreviewSection').style.display = 'none';
    document.getElementById('cameraSection').style.display = 'block';
    initLiveCamera();
}

// Auto-sync / Auto-detect photo from Tabletop Fundus Camera folder
async function autoDetectFundusCamera() {
    const statusMsg = document.getElementById('autoSyncStatusMsg');
    if (statusMsg) statusMsg.innerText = "⏳ Checking Fundus Camera Export Folder...";

    try {
        const res = await fetch('/api/fundus-camera/sync');
        const data = await res.json();
        if (data.status === 'success' && data.image_data) {
            document.getElementById('capturedImageData').value = data.image_data;
            document.getElementById('cameraSection').style.display = 'none';
            document.getElementById('snapPreviewSection').style.display = 'block';
            document.getElementById('snapPreviewImg').src = data.image_data;
            if (statusMsg) statusMsg.innerHTML = `<span style="color: #16a34a; font-weight: bold;">✅ Camera Image Detected: ${data.filename}</span>`;
            stopLiveCamera();
        } else {
            if (statusMsg) statusMsg.innerHTML = `<span style="color: #d97706;">⚠️ ${data.message || 'No new fundus image detected in camera folder.'}</span>`;
        }
    } catch(err) {
        if (statusMsg) statusMsg.innerHTML = `<span style="color: #dc2626;">❌ Sync Error: ${err.message}</span>`;
    }
}
