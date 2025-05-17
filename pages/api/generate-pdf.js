import chromium from '@sparticuz/chromium';
import puppeteer from 'puppeteer-core';

export const config = {
  api: {
    bodyParser: {
      sizeLimit: '10mb',
    },
    responseLimit: '10mb',
  },
};

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ message: 'Method not allowed' });
  }

  try {
    const { html = '<h1>Default PDF Content</h1>' } = req.body;

    // Launch headless browser with specific Chrome version
    const browser = await puppeteer.launch({
      args: [
        ...chromium.args,
        '--hide-scrollbars',
        '--disable-web-security',
        '--no-sandbox',
        '--disable-setuid-sandbox',
      ],
      defaultViewport: chromium.defaultViewport,
      executablePath: await chromium.executablePath(),
      headless: chromium.headless,
      ignoreHTTPSErrors: true,
    });

    // Create new page with specific viewport
    const page = await browser.newPage();
    await page.setViewport({
      width: 1024,
      height: 768,
      deviceScaleFactor: 1,
    });
    
    // Set content with proper timeout
    await page.setContent(html, {
      waitUntil: ['domcontentloaded', 'networkidle0'],
      timeout: 30000,
    });

    // Generate PDF with specific settings
    const pdf = await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: {
        top: '20px',
        right: '20px',
        bottom: '20px',
        left: '20px'
      },
      preferCSSPageSize: true,
      timeout: 30000,
    });

    // Make sure to close the browser
    await browser.close();

    // Send response with proper headers
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=note.pdf');
    res.setHeader('Content-Length', pdf.length);
    res.status(200).send(pdf);

  } catch (error) {
    console.error('PDF generation error:', error);
    // Close browser if it exists in error case
    if (error.message) {
      console.error('Error details:', error.message);
    }
    res.status(500).json({ 
      error: 'Failed to generate PDF',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
} 