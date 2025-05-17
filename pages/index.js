import Head from 'next/head';
import { useEffect, useState } from 'react';

export default function Home() {
  const [isClient, setIsClient] = useState(false);

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
      </Head>
      <div className="bg-gray-100">
        <nav className="bg-white shadow-lg">
          <div className="max-w-6xl mx-auto px-4">
            <div className="flex justify-between items-center py-4">
              <div className="flex items-center">
                <h1 className="text-xl font-bold text-gray-800">YNote Viewer</h1>
              </div>
              <div className="flex items-center space-x-4">
                <button id="uploadBtn" className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg">
                  Upload Note
                </button>
                <button id="generatePdfBtn" className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded-lg">
                  Generate PDF
                </button>
              </div>
            </div>
          </div>
        </nav>

        <main className="max-w-6xl mx-auto px-4 py-8">
          <div className="bg-white rounded-lg shadow-md p-6">
            <div id="noteViewer" className="min-h-[500px]">
              <div className="text-center text-gray-500">
                Select a note to view
              </div>
            </div>
          </div>
        </main>

        <input type="file" id="fileInput" accept=".txt,.md,.doc,.docx" className="hidden" />
      </div>
      <script src="/app.js"></script>
    </div>
  );
} 