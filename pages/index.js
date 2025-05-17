import Head from 'next/head';
import { useEffect, useState } from 'react';

export default function Home() {
  const [isClient, setIsClient] = useState(false);
  const [noteContent, setNoteContent] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    setIsClient(true);
    // Initialize event listeners after component mounts
    if (typeof window !== 'undefined') {
      const fileInput = document.getElementById('fileInput');
      const uploadBtn = document.getElementById('uploadBtn');
      const generatePdfBtn = document.getElementById('generatePdfBtn');
      const pasteBtn = document.getElementById('pasteBtn');
      const textArea = document.getElementById('textArea');

      uploadBtn?.addEventListener('click', () => fileInput.click());
      fileInput?.addEventListener('change', handleFileUpload);
      generatePdfBtn?.addEventListener('click', handleGeneratePdf);
      pasteBtn?.addEventListener('click', () => {
        const content = textArea.value.trim();
        if (content) {
          displayNote(content);
        } else {
          alert('Please enter some text first!');
        }
      });
    }
  }, []);

  const handleFileUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      const content = await readFile(file);
      displayNote(content);
    } catch (error) {
      console.error('Error reading file:', error);
      alert('Error reading file. Please try again.');
    }
  };

  const readFile = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => resolve(e.target.result);
      reader.onerror = (e) => reject(e);
      reader.readAsText(file);
    });
  };

  const displayNote = (content) => {
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
  };

  const handleGeneratePdf = async () => {
    if (!noteContent) {
      alert('Please upload a file or paste some text first!');
      return;
    }

    setIsLoading(true);
    try {
      const response = await fetch('/api/generate-pdf', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          html: `
            <html>
              <head>
                <style>
                  body {
                    font-family: Arial, sans-serif;
                    line-height: 1.6;
                    margin: 40px;
                  }
                  pre {
                    white-space: pre-wrap;
                    word-wrap: break-word;
                  }
                </style>
              </head>
              <body>
                <pre>${noteContent}</pre>
              </body>
            </html>
          `
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to generate PDF');
      }

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'note.pdf';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Error generating PDF:', error);
      alert('Failed to generate PDF. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  if (!isClient) {
    return (
      <div>
        <Head>
          <title>YNote Viewer</title>
          <meta name="description" content="View and convert notes to PDF" />
          <link rel="icon" href="/favicon.ico" />
          <link rel="stylesheet" href="/styles.css" />
          <script src="https://cdn.tailwindcss.com"></script>
        </Head>
        <main>
          <p>Loading YNote Viewer...</p>
        </main>
      </div>
    );
  }

  return (
    <div>
      <Head>
        <title>YNote Viewer</title>
        <meta name="description" content="View and convert notes to PDF" />
        <link rel="icon" href="/favicon.ico" />
        <link rel="stylesheet" href="/styles.css" />
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="/viewer.js"></script>
      </Head>
      <div className="bg-gray-100 min-h-screen">
        <nav className="bg-white shadow-lg">
          <div className="max-w-6xl mx-auto px-4">
            <div className="flex justify-between items-center py-4">
              <div className="flex items-center">
                <h1 className="text-xl font-bold text-gray-800">YNote Viewer</h1>
              </div>
              <div className="flex items-center space-x-4">
                <button
                  id="uploadBtn"
                  className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg"
                >
                  Upload File
                </button>
                <button
                  id="generatePdfBtn"
                  className={`bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded-lg ${
                    isLoading ? 'opacity-50 cursor-not-allowed' : ''
                  }`}
                  disabled={isLoading}
                >
                  {isLoading ? 'Generating...' : 'Generate PDF'}
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
                id="pasteBtn"
                className="mt-2 bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg"
              >
                Preview Text
              </button>
            </div>
            <div className="mt-6">
              <h2 className="text-lg font-semibold mb-2">Preview:</h2>
              <div id="noteViewer" className="min-h-[300px] p-4 border rounded-lg">
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
        />
      </div>
    </div>
  );
} 