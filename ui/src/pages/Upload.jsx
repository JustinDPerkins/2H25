// src/pages/Upload.jsx
import React, { useEffect, useRef, useState } from 'react';
import {
  Box,
  Typography,
  Button,
  Tooltip,
  Slider,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Stack,
  Switch,
  FormControlLabel
} from '@mui/material';
import {
  CloudUpload as UploadIcon,
  Download as DownloadIcon,
  Opacity as OpacityIcon,
  ZoomOutMap as ZoomIcon,
  Image as ImageIcon,
  RestartAlt as ResetIcon,
  Send as SendIcon
} from '@mui/icons-material';
import { DESIGN_TOKENS } from '../theme';

function Upload() {
  const canvasRef = useRef(null);
  const baseImageRef = useRef(new Image());
  const watermarkImageRef = useRef(new Image());
  const [productSrc, setProductSrc] = useState('/images/paper_products.png');
  const [watermarkSrc, setWatermarkSrc] = useState(null);
  const [watermarkText, setWatermarkText] = useState('');
  const [watermarkType, setWatermarkType] = useState('image'); // 'image' or 'text'
  const [opacity, setOpacity] = useState(0.5);
  const [scale, setScale] = useState(0.3);
  const [position, setPosition] = useState({ x: 0.5, y: 0.5 });
  const [isDragging, setIsDragging] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  const [scanResult, setScanResult] = useState(null);
  const [scanProtectionEnabled, setScanProtectionEnabled] = useState(true);

  const productOptions = [
    { label: 'Paper Stack', src: '/images/paper_products.png' },
    { label: 'Paper Products (Alt)', src: '/images/paper_products_1.png' },
    { label: 'Paper Hero', src: '/images/paper-hero.jpg' },
    { label: 'Files', src: '/images/files.png' }
  ];

  const draw = () => {
    const canvas = canvasRef.current;
    const base = baseImageRef.current;
    const wm = watermarkImageRef.current;
    if (!canvas || !base.complete) return;

    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;

    ctx.clearRect(0, 0, width, height);
    ctx.drawImage(base, 0, 0, width, height);

    if (watermarkType === 'image' && wm && watermarkSrc && wm.complete) {
      const wmAspect = wm.naturalHeight / wm.naturalWidth;
      const targetWidth = Math.max(16, Math.min(width, width * scale));
      const targetHeight = targetWidth * wmAspect;
      const cx = position.x * width;
      const cy = position.y * height;
      const x = cx - targetWidth / 2;
      const y = cy - targetHeight / 2;

      ctx.save();
      ctx.globalAlpha = opacity;
      ctx.drawImage(wm, x, y, targetWidth, targetHeight);
      ctx.restore();
    } else if (watermarkType === 'text' && watermarkText) {
      const cx = position.x * width;
      const cy = position.y * height;
      
      ctx.save();
      ctx.globalAlpha = opacity;
      ctx.fillStyle = 'white';
      ctx.strokeStyle = 'black';
      ctx.lineWidth = 2;
      ctx.font = `${Math.max(12, width * scale * 0.05)}px Arial`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      
      // Draw text with stroke for better visibility
      ctx.strokeText(watermarkText, cx, cy);
      ctx.fillText(watermarkText, cx, cy);
      ctx.restore();
    }
  };

  useEffect(() => {
    const base = baseImageRef.current;
    base.crossOrigin = 'anonymous';
    base.onload = draw;
    base.src = productSrc;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [productSrc]);

  useEffect(() => {
    const wm = watermarkImageRef.current;
    if (watermarkSrc) {
      wm.crossOrigin = 'anonymous';
      wm.onload = draw;
      wm.src = watermarkSrc;
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [watermarkSrc]);

  useEffect(() => {
    draw();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [opacity, scale, position, watermarkType, watermarkText]);

  const onCanvasPointer = (e) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width;
    const y = (e.clientY - rect.top) / rect.height;
    setPosition({ x: Math.max(0, Math.min(1, x)), y: Math.max(0, Math.min(1, y)) });
  };

  const handleMouseDown = (e) => {
    setIsDragging(true);
    onCanvasPointer(e);
  };
  const handleMouseMove = (e) => {
    if (!isDragging) return;
    onCanvasPointer(e);
  };
  const handleMouseUp = () => setIsDragging(false);
  const handleMouseLeave = () => setIsDragging(false);

  const handleWatermarkChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    
    const fileExtension = file.name.split('.').pop().toLowerCase();
    
    if (fileExtension === 'txt') {
      setWatermarkType('text');
      setWatermarkSrc(null);
      
      const reader = new FileReader();
      reader.onload = (event) => {
        const text = event.target.result;
        setWatermarkText(text.trim());
      };
      reader.readAsText(file);
    } else {
      setWatermarkType('image');
      setWatermarkText('');
      const url = URL.createObjectURL(file);
      setWatermarkSrc(url);
    }
  };

  const handleDownload = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const link = document.createElement('a');
    link.download = 'boring-paper-watermarked.png';
    link.href = canvas.toDataURL('image/png');
    link.click();
  };

  const handleSubmit = async () => {
    setSubmitError(null);
    setSubmitSuccess(false);
    setScanResult(null);
    const canvas = canvasRef.current;
    if (!canvas) return;
    setSubmitting(true);
    try {
      const blob = await new Promise((resolve) => canvas.toBlob(resolve, 'image/png'));
      const formData = new FormData();
      const filename = 'boring-paper-watermarked.png';
      formData.append('file', blob, filename);
      formData.append('scanProtection', scanProtectionEnabled.toString());
      const res = await fetch('/api/sdk/upload', { method: 'POST', body: formData });
      if (!res.ok) throw new Error('Upload failed');
      const json = await res.json();
      setScanResult(json);
      setSubmitSuccess(true);
    } catch (e) {
      setSubmitError(e.message || 'Upload failed');
    } finally {
      setSubmitting(false);
    }
  };

  const resetAll = () => {
    setOpacity(0.5);
    setScale(0.3);
    setPosition({ x: 0.5, y: 0.5 });
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'stretch',
        justifyContent: 'stretch',
        background: 'linear-gradient(135deg, #2a2a2a 0%, #1a1a1a 100%)',
        py: DESIGN_TOKENS.spacing.xl
      }}
    >
      <Box sx={{ width: '100%', height: '100%', px: DESIGN_TOKENS.spacing.lg }}>
            <Box sx={{ textAlign: 'center', mb: DESIGN_TOKENS.spacing.lg }}>
              <ImageIcon
                sx={{
                  fontSize: 60,
                  color: 'rgba(255,255,255,0.7)',
                  mb: DESIGN_TOKENS.spacing.md
                }}
              />
              <Typography
                variant="h4"
                sx={{
                  fontWeight: DESIGN_TOKENS.typography.fontWeights.bold,
                  mb: DESIGN_TOKENS.spacing.sm,
                  color: 'rgba(255,255,255,0.9)'
                }}
              >
                Add Your Watermark
              </Typography>
              <Typography variant="subtitle1" sx={{ opacity: 0.7, color: 'rgba(255,255,255,0.7)' }}>
                Customize Boring Paper Co. products with your brand watermark
              </Typography>
            </Box>

            <Stack direction={{ xs: 'column', md: 'row' }} spacing={DESIGN_TOKENS.spacing.lg} sx={{ height: 'calc(100vh - 220px)', minHeight: 0 }}>
              <Box sx={{ flex: 1 }}>
                <Box
                  sx={{
                    border: '2px dashed rgba(255,255,255,0.3)',
                    borderRadius: DESIGN_TOKENS.borderRadius.md,
                    p: DESIGN_TOKENS.spacing.lg,
                    textAlign: 'center',
                    background: 'rgba(0,0,0,0.2)',
                    mb: DESIGN_TOKENS.spacing.md
                  }}
                >
                  <input hidden id="watermark-upload" type="file" accept="image/*,.txt" onChange={handleWatermarkChange} />
                  <label htmlFor="watermark-upload">
                    <Button
                      component="span"
                      variant="contained"
                      startIcon={<UploadIcon />}
                      sx={{
                        background: 'rgba(255,255,255,0.1)',
                        color: 'white',
                        '&:hover': { background: 'rgba(255,255,255,0.2)' }
                      }}
                    >
                      Upload Watermark
                    </Button>
                  </label>
                  <Typography variant="body2" sx={{ mt: DESIGN_TOKENS.spacing.sm, color: 'rgba(255,255,255,0.6)' }}>
                    PNG with transparency or .txt files supported
                  </Typography>
                </Box>

                <FormControl fullWidth size="small" sx={{ mb: DESIGN_TOKENS.spacing.md }}>
                  <InputLabel id="product-select-label">Product Mockup</InputLabel>
                  <Select
                    labelId="product-select-label"
                    label="Product Mockup"
                    value={productSrc}
                    onChange={(e) => setProductSrc(e.target.value)}
                    sx={{ color: 'white' }}
                  >
                    {productOptions.map((opt) => (
                      <MenuItem key={opt.src} value={opt.src}>
                        {opt.label}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>

                <FormControlLabel
                  control={
                    <Switch
                      checked={scanProtectionEnabled}
                      onChange={(e) => setScanProtectionEnabled(e.target.checked)}
                      sx={{
                        '& .MuiSwitch-switchBase.Mui-checked': {
                          color: '#4caf50',
                        },
                        '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': {
                          backgroundColor: '#4caf50',
                        },
                      }}
                    />
                  }
                  label={
                    <Typography sx={{ color: 'rgba(255,255,255,0.8)' }}>
                      Security Scan Protection
                    </Typography>
                  }
                  sx={{ mb: DESIGN_TOKENS.spacing.md }}
                />

                <Stack spacing={DESIGN_TOKENS.spacing.md}>
                  <Stack direction="row" spacing={2} alignItems="center">
                    <ZoomIcon sx={{ color: 'rgba(255,255,255,0.7)' }} />
                    <Slider
                      value={scale}
                      min={0.1}
                      max={0.9}
                      step={0.01}
                      onChange={(_, v) => setScale(v)}
                      sx={{ color: 'white' }}
                    />
                    <Typography sx={{ color: 'rgba(255,255,255,0.7)', minWidth: 48 }}>
                      {(scale * 100).toFixed(0)}%
                    </Typography>
                  </Stack>
                  <Stack direction="row" spacing={2} alignItems="center">
                    <OpacityIcon sx={{ color: 'rgba(255,255,255,0.7)' }} />
                    <Slider
                      value={opacity}
                      min={0}
                      max={1}
                      step={0.01}
                      onChange={(_, v) => setOpacity(v)}
                      sx={{ color: 'white' }}
                    />
                    <Typography sx={{ color: 'rgba(255,255,255,0.7)', minWidth: 48 }}>
                      {(opacity * 100).toFixed(0)}%
                    </Typography>
                  </Stack>

                  <Stack direction="row" spacing={2}>
                    <Tooltip title="Reset">
                      <Button onClick={resetAll} startIcon={<ResetIcon />} variant="outlined" sx={{ color: 'white', borderColor: 'rgba(255,255,255,0.3)' }}>
                        Reset
                      </Button>
                    </Tooltip>
                    <Tooltip title="Download Preview">
                      <Button onClick={handleDownload} startIcon={<DownloadIcon />} variant="contained" sx={{ background: 'rgba(255,255,255,0.15)', color: 'white' }}>
                        Download
                      </Button>
                    </Tooltip>
                    <Tooltip title="Submit to Server">
                      <Button onClick={handleSubmit} startIcon={<SendIcon />} disabled={submitting} variant="contained" sx={{ background: 'rgba(0,128,255,0.3)', color: 'white' }}>
                        {submitting ? 'Submitting…' : 'Submit'}
                      </Button>
                    </Tooltip>
                  </Stack>
                </Stack>
              </Box>

              <Box sx={{ flex: 2, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
                <Box
                  sx={{
                    position: 'relative',
                    border: '1px solid rgba(255,255,255,0.15)',
                    borderRadius: DESIGN_TOKENS.borderRadius.md,
                    background: 'rgba(0,0,0,0.2)',
                    overflow: 'hidden',
                    flex: 1,
                    minHeight: 0
                  }}
                >
                  <canvas
                    ref={canvasRef}
                    width={1000}
                    height={650}
                    style={{ width: '100%', height: '100%', display: 'block', cursor: 'move', aspectRatio: '1000 / 650' }}
                    onMouseDown={handleMouseDown}
                    onMouseMove={handleMouseMove}
                    onMouseUp={handleMouseUp}
                    onMouseLeave={handleMouseLeave}
                  />
                  {!watermarkSrc && !watermarkText && (
                    <Box
                      sx={{
                        position: 'absolute',
                        inset: 0,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: 'rgba(255,255,255,0.6)'
                      }}
                    >
                      <Typography>Upload a watermark image or text file to begin</Typography>
                    </Box>
                  )}
                </Box>
                <Typography variant="caption" sx={{ display: 'block', mt: DESIGN_TOKENS.spacing.sm, color: 'rgba(255,255,255,0.6)' }}>
                  Tip: Click and drag on the preview to position your watermark
                </Typography>

                {submitError && (
                  <Typography variant="body2" sx={{ mt: DESIGN_TOKENS.spacing.sm, color: '#ff8080' }}>
                    {submitError}
                  </Typography>
                )}
                {submitSuccess && (
                  <Typography variant="body2" sx={{ mt: DESIGN_TOKENS.spacing.sm, color: '#80ff80' }}>
                    Uploaded successfully
                  </Typography>
                )}

                {scanResult && (
                  <Box sx={{ mt: DESIGN_TOKENS.spacing.md, background: 'rgba(0,0,0,0.2)', p: DESIGN_TOKENS.spacing.md, borderRadius: DESIGN_TOKENS.borderRadius.md, flex: '0 0 24vh', overflowY: 'auto' }}>
                    <Typography variant="subtitle2" sx={{ color: 'rgba(255,255,255,0.85)', mb: DESIGN_TOKENS.spacing.sm }}>
                      Security Scan Result
                    </Typography>
                    <pre style={{ margin: 0, whiteSpace: 'pre-wrap', wordBreak: 'break-word', color: 'rgba(255,255,255,0.8)' }}>
                      {JSON.stringify(scanResult, null, 2)}
                    </pre>
                  </Box>
                )}
              </Box>
            </Stack>
      </Box>
    </Box>
  );
}

export default Upload;
