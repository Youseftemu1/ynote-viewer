document.addEventListener('DOMContentLoaded', () => {
  const fileInput = document.getElementById('fileInput');
  const uploadBtn = document.getElementById('uploadBtn');
  const generatePdfBtn = document.getElementById('generatePdfBtn');
  const pasteBtn = document.getElementById('pasteBtn');
  const textArea = document.getElementById('textArea');
  const noteViewer = document.getElementById('noteViewer');
  let currentContent = '';

  // Handle file upload button
  uploadBtn.addEventListener('click', () => {
    fileInput.click();
  });

  // Handle file selection
  fileInput.addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    try {
      const content = await readFile(file);
      currentContent = content;
      displayNote(content);
    } catch (error) {
      console.error('Error reading file:', error);
      alert('Error reading file. Please try again.');
    }
  });

  // Handle paste button click
  pasteBtn.addEventListener('click', () => {
    const content = textArea.value.trim();
    if (content) {
      currentContent = content;
      displayNote(content);
    } else {
      alert('Please enter some text first!');
    }
  });

  // Handle PDF generation
  generatePdfBtn.addEventListener('click', async () => {
    if (!currentContent) {
      alert('Please upload a file or paste some text first!');
      return;
    }

    generatePdfBtn.textContent = 'Generating...';
    generatePdfBtn.disabled = true;

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
                <pre>${currentContent}</pre>
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
      generatePdfBtn.textContent = 'Generate PDF';
      generatePdfBtn.disabled = false;
    }
  });

  // Read file content
  function readFile(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => resolve(e.target.result);
      reader.onerror = (e) => reject(e);
      reader.readAsText(file);
    });
  }

  // Display note content
  function displayNote(content) {
    const formattedContent = content
      .replace(/\n/g, '<br>')
      .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');

    noteViewer.innerHTML = `
      <div class="prose max-w-none">
        ${formattedContent}
      </div>
    `;
  }
}); 