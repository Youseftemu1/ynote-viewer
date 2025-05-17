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

  let browser = null;
  try {
    const { html = '<h1>Default PDF Content</h1>' } = req.body;

    // Launch headless browser using Vercel-compatible approach
    browser = await puppeteer.launch({
      args: chromium.args,
      executablePath: process.env.CHROME_EXECUTABLE_PATH || await chromium.executablePath(),
      headless: true, // Force headless true
    });

    // Create new page with minimal settings
    const page = await browser.newPage();
    await page.setViewport({ width: 794, height: 1123 }); // A4 size in pixels

    // Use basic content setting
    await page.setContent(html, {
      waitUntil: 'networkidle0',
    });

    // Generate PDF with minimal options
    const pdf = await page.pdf({
      format: 'a4',
      printBackground: true,
    });

    // Close browser before sending response
    if (browser) {
      await browser.close();
      browser = null;
    }

    // Set basic headers and send response
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=note.pdf');
    res.status(200).send(Buffer.from(pdf));

  } catch (error) {
    console.error('PDF generation error:', error);
    
    // Close browser in case of error
    if (browser) {
      try {
        await browser.close();
      } catch (closeError) {
        console.error('Error closing browser:', closeError);
      }
    }
    
    res.status(500).json({ error: 'Failed to generate PDF' });
  }
} 