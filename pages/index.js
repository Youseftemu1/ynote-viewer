import Head from 'next/head';
import { useEffect, useState, useCallback, useRef } from 'react';
import dynamic from 'next/dynamic';

// Dynamically import jsPDF with no SSR
const JsPDFModule = dynamic(
  () => import('jspdf').then(mod => ({ jsPDF: mod.default })),
  { ssr: false }
);

// Dynamically import html2canvas with no SSR
const Html2CanvasModule = dynamic(
  () => import('html2canvas').then(mod => ({ html2canvas: mod.default })),
  { ssr: false }
);

export default function Home() {
  const [isClient, setIsClient] = useState(false);
  const [noteContent, setNoteContent] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [clientPdfLoading, setClientPdfLoading] = useState(false);
  const [serverPdfLoading, setServerPdfLoading] = useState(false);
  const previewRef = useRef(null);

  const displayNote = useCallback((content) => {
    setNoteContent(content);
    const noteViewer = document.getElementById('noteViewer');
    if (noteViewer) {
      const formattedContent = content
        .replace(/\n/g, '<br>')
        .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');
      noteViewer.innerHTML = `
        <div class="prose max-w-none">
          ${formattedContent}
        </div>
      `;
    }
  }, []);

  const handleFileUpload = useCallback(async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      const content = await readFile(file);
      displayNote(content);
    } catch (error) {
      console.error('Error reading file:', error);
      alert('Error reading file. Please try again.');
    }
  }, [displayNote]);

  const readFile = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => resolve(e.target.result);
      reader.onerror = (e) => reject(e);
      reader.readAsText(file);
    });
  };

  // Client-side PDF generation using jsPDF - Simplified version
  const handleClientPdf = async () => {
    if (!noteContent) {
      alert('Please upload a file or paste some text first!');
      return;
    }

    setClientPdfLoading(true);
    try {
      // Import jsPDF dynamically
      const { jsPDF } = await JsPDFModule;
      
      // Create new PDF document
      const pdf = new jsPDF({
        orientation: 'portrait',
        unit: 'mm',
        format: 'a4'
      });
      
      // Format text (replace tabs with spaces)
      const formattedText = noteContent.replace(/\t/g, '    ');
      
      // Split text into lines to handle pagination
      const lines = pdf.splitTextToSize(formattedText, 170); // 170mm width (with margins)
      
      // Add text to PDF
      pdf.setFont('helvetica');
      pdf.setFontSize(11);
      pdf.text(lines, 20, 20); // 20mm margins
      
      // Save the PDF
      pdf.save('note-client.pdf');
      
    } catch (error) {
      console.error('Error generating client-side PDF:', error);
      alert('Failed to generate PDF on client. Please try again.');
    } finally {
      setClientPdfLoading(false);
    }
  };

  // Server-side PDF generation using Puppeteer
  const handleServerPdf = async () => {
    if (!noteContent) {
      alert('Please upload a file or paste some text first!');
      return;
    }

    setServerPdfLoading(true);
    try {
      // Create simple HTML for the PDF
      const htmlContent = `
        <html>
          <head>
            <style>
              body {
                font-family: Arial, sans-serif;
                line-height: 1.6;
                margin: 40px;
                font-size: 12pt;
              }
              pre {
                white-space: pre-wrap;
                word-wrap: break-word;
                font-family: Arial, sans-serif;
              }
            </style>
          </head>
          <body>
            <pre>${noteContent}</pre>
          </body>
        </html>
      `;

      const response = await fetch('/api/generate-pdf', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ html: htmlContent }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || 'Failed to generate PDF');
      }

      // Get blob directly from response
      const blob = await response.blob();
      
      // Create download link
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'note-server.pdf';
      document.body.appendChild(a);
      a.click();
      
      // Clean up
      setTimeout(() => {
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      }, 100);
    } catch (error) {
      console.error('Error generating server PDF:', error);
      alert(error.message || 'Failed to generate PDF on server. Please try again.');
    } finally {
      setServerPdfLoading(false);
    }
  };

  const handlePastePreview = useCallback(() => {
    const textArea = document.getElementById('textArea');
    const content = textArea.value.trim();
    if (content) {
      displayNote(content);
    } else {
      alert('Please enter some text first!');
    }
  }, [displayNote]);

  const handleTestButton = () => {
    alert('Test button works!');
  };

  useEffect(() => {
    setIsClient(true);
  }, []);

  if (!isClient) {
    return (
      <div>
        <Head>
          <title>YNote Viewer</title>
          <meta name="description" content="View and convert notes to PDF" />
          <link rel="icon" href="/favicon.ico" />
          <link rel="stylesheet" href="/styles.css" />
        </Head>
        <main>
          <p>Loading YNote Viewer...</p>
        </main>
      </div>
    );
  }

  return (
    <div className="bg-gray-100 min-h-screen">
      <Head>
        <title>YNote Viewer</title>
        <meta name="description" content="View and convert notes to PDF" />
        <link rel="icon" href="/favicon.ico" />
        <link rel="stylesheet" href="/styles.css" />
      </Head>

      <nav className="bg-white shadow-lg">
        <div className="max-w-6xl mx-auto px-4">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center">
              <h1 className="text-xl font-bold text-gray-800">YNote Viewer</h1>
            </div>
            <div className="flex items-center space-x-4">
              <button
                onClick={handleTestButton}
                className="bg-yellow-500 hover:bg-yellow-600 text-white px-8 py-3 rounded-lg text-lg font-bold animate-pulse"
              >
                TEST BUTTON
              </button>
              <button
                onClick={() => document.getElementById('fileInput').click()}
                className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg"
              >
                Upload File
              </button>
              <button
                onClick={handleClientPdf}
                className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded-lg"
                disabled={clientPdfLoading}
              >
                {clientPdfLoading ? 'Generating...' : 'Download PDF (Client)'}
              </button>
              <button
                onClick={handleServerPdf}
                className="bg-purple-500 hover:bg-purple-600 text-white px-4 py-2 rounded-lg"
                disabled={serverPdfLoading}
              >
                {serverPdfLoading ? 'Generating...' : 'Download PDF (Server)'}
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-6xl mx-auto px-4 py-8">
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <div className="mb-4">
            <label htmlFor="textArea" className="block text-gray-700 font-medium mb-2">
              Paste or type your text here:
            </label>
            <textarea
              id="textArea"
              className="w-full h-32 p-2 border rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Type or paste your text here..."
            ></textarea>
            <button
              onClick={handlePastePreview}
              className="mt-2 bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg"
            >
              Preview Text
            </button>
          </div>
          <div className="mt-6">
            <h2 className="text-lg font-semibold mb-2">Preview:</h2>
            <div 
              id="noteViewer" 
              ref={previewRef}
              className="min-h-[300px] p-4 border rounded-lg"
            >
              <div className="text-center text-gray-500">
                Your text will appear here
              </div>
            </div>
          </div>
        </div>
      </main>

      <input
        type="file"
        id="fileInput"
        accept=".txt,.md,.doc,.docx"
        className="hidden"
        onChange={handleFileUpload}
      />
    </div>
  );
} 