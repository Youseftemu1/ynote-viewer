import Head from 'next/head';
import { useEffect } from 'react';

export default function Home() {
  useEffect(() => {
    // Redirect to the static HTML page
    window.location.href = '/index.html';
  }, []);

  return (
    <div>
      <Head>
        <title>YNote Viewer</title>
        <meta name="description" content="View and convert notes to PDF" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main>
        <p>Loading...</p>
      </main>
    </div>
  );
} 