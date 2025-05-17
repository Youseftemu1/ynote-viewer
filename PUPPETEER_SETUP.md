# Setting Up Puppeteer PDF Generation with Emoji Support

This guide explains how to set up a proper Puppeteer PDF generation service on Google Cloud Run that supports colored emojis.

## Why Vercel Doesn't Work Well for Puppeteer

Vercel's serverless functions have several limitations that make Puppeteer difficult to use:

1. **Memory constraints**: Limited to ~1024MB, which is tight for Chrome
2. **No persistent /tmp directory**: Needed for Chrome to operate
3. **Limited execution time**: Functions time out after 10 seconds (free tier)
4. **Size limits**: 50MB deployment limit (compressed)
5. **No system dependencies**: Can't install necessary fonts or sandbox support

## Better Option: Google Cloud Run

Google Cloud Run is ideal for running Puppeteer because:

1. **Container-based**: You control the entire environment
2. **Higher memory limits**: Up to 32GB RAM
3. **Longer execution time**: Up to 60 minutes
4. **Persistent storage options**: Can mount volumes
5. **Custom dependencies**: Full control over system packages

## Setup Instructions

### 1. Create a New Project

```bash
mkdir pdf-emoji-service
cd pdf-emoji-service
npm init -y
```

### 2. Install Dependencies

```bash
npm install puppeteer express cors
```

### 3. Create a Dockerfile

```dockerfile
FROM node:16-slim

# Install dependencies for Puppeteer
RUN apt-get update && apt-get install -y \
    fonts-noto-color-emoji \
    fonts-noto-cjk \
    fonts-liberation \
    libx11-xcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxi6 \
    libxtst6 \
    libnss3 \
    libcups2 \
    libxss1 \
    libxrandr2 \
    libasound2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libpangocairo-1.0-0 \
    libgtk-3-0 \
    libgbm1 \
    --no-install-recommends

# Create app directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy app source
COPY . .

# Expose port
EXPOSE 8080

# Start the service
CMD [ "node", "server.js" ]
```

### 4. Create the Server (server.js)

```javascript
const express = require('express');
const puppeteer = require('puppeteer');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 8080;

// Enable JSON body parsing and CORS
app.use(express.json({ limit: '10mb' }));
app.use(cors());

// PDF generation endpoint
app.post('/generate-pdf', async (req, res) => {
  let browser = null;
  
  try {
    const { html = '<h1>Default PDF Content</h1>' } = req.body;
    
    // Launch browser with emoji font support
    browser = await puppeteer.launch({
      args: ['--no-sandbox', '--font-render-hinting=none'],
      headless: true,
    });
    
    const page = await browser.newPage();
    
    // Set viewport (A4 dimensions)
    await page.setViewport({
      width: 794,
      height: 1123,
      deviceScaleFactor: 2,
    });
    
    // Override font settings to use emoji fonts
    await page.evaluateOnNewDocument(() => {
      // Use fonts that support emoji rendering
      document.documentElement.style.fontFamily = 
        "'Noto Color Emoji', 'Segoe UI Emoji', 'Arial', sans-serif";
    });
    
    // Set content with proper timeout
    await page.setContent(html, {
      waitUntil: 'networkidle0',
      timeout: 30000,
    });
    
    // Generate PDF
    const pdf = await page.pdf({
      format: 'a4',
      printBackground: true,
      preferCSSPageSize: true,
      margin: {
        top: '20mm',
        right: '20mm',
        bottom: '20mm',
        left: '20mm'
      }
    });
    
    await browser.close();
    browser = null;
    
    // Send PDF
    res.contentType('application/pdf');
    res.send(pdf);
    
  } catch (error) {
    console.error('PDF generation error:', error);
    
    if (browser) {
      await browser.close();
    }
    
    res.status(500).json({ error: 'Failed to generate PDF' });
  }
});

// Health check endpoint
app.get('/', (req, res) => {
  res.send('PDF Service is running');
});

app.listen(port, () => {
  console.log(`PDF service listening at http://localhost:${port}`);
});
```

### 5. Build and Deploy to Google Cloud Run

```bash
# Build the Docker image
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/pdf-service

# Deploy to Cloud Run
gcloud run deploy pdf-service \
  --image gcr.io/YOUR_PROJECT_ID/pdf-service \
  --platform managed \
  --memory 2Gi \
  --concurrency 10 \
  --allow-unauthenticated
```

### 6. Update Frontend to Use Your Service

Replace the server-side PDF generation in your Next.js app to call this service:

```javascript
const handleServerPdf = async () => {
  if (!noteContent) {
    alert('Please upload a file or paste some text first!');
    return;
  }

  setServerPdfLoading(true);
  try {
    // Create HTML with emoji support
    const htmlContent = `
      <html>
        <head>
          <style>
            body {
              font-family: 'Noto Color Emoji', 'Segoe UI Emoji', Arial, sans-serif;
              line-height: 1.6;
              margin: 40px;
              font-size: 12pt;
            }
            pre {
              white-space: pre-wrap;
              word-wrap: break-word;
              font-family: 'Noto Color Emoji', 'Segoe UI Emoji', Arial, sans-serif;
            }
          </style>
        </head>
        <body>
          <pre>${noteContent}</pre>
        </body>
      </html>
    `;

    // Call your Cloud Run service 
    const response = await fetch('https://pdf-service-xxxxx.a.run.app/generate-pdf', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ html: htmlContent }),
    });

    if (!response.ok) {
      throw new Error('Failed to generate PDF');
    }

    // Handle the PDF response
    const blob = await response.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'note-with-emojis.pdf';
    document.body.appendChild(a);
    a.click();
    
    setTimeout(() => {
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    }, 100);
  } catch (error) {
    console.error('Error generating PDF:', error);
    alert('Failed to generate PDF. Please try again.');
  } finally {
    setServerPdfLoading(false);
  }
};
```

## Testing Emoji Support

You can test emoji support by including various emojis in your text:

```
Here are some emojis: 😀 🎉 🚀 🌈 💯 ⭐ 📊 🔥
```

When rendered through Puppeteer on Google Cloud Run with the proper fonts installed, these should appear as colored, selectable emojis in the generated PDF. 