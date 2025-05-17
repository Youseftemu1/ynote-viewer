import 'package:flutter/material.dart';
import 'dart:io';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart' as html2pdf;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;
import 'dart:ui';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emoji PDF Creator',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Emoji PDF Creator (B&W)'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;

  Future<void> _exportEmojiPdf() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Generating PDF with copyable emojis...')),
        );
      }

      // Use the provided API key for emoji-api.com
      String apiKey = '2d4f01ed791366400538e1ca8256678b252408f9';

      // Create a PDF document with proper Unicode handling
      final pdf = pw.Document(
        title: 'Emoji PDF',
        author: 'Flutter App',
        creator: 'PDF Package',
        producer: 'Flutter',
        subject: 'Emoji Collection',
        keywords: 'emoji, unicode, pdf',
        // Ensure proper Unicode support
        compress:
            false, // Disabling compression can help with some Unicode issues
      );

      // Load the Noto Emoji font for better black and white emoji support
      final notoEmojiFont =
          await rootBundle.load('assets/fonts/NotoEmoji-Regular.ttf');
      final emojiFontData = pw.Font.ttf(notoEmojiFont);

      // Fetch emoji data from emoji-api.com
      final List<Map<String, dynamic>> emojiData = [];

      try {
        // Get a selection of different emoji categories for variety
        final categories = [
          'smileys-emotion',
          'animals-nature',
          'food-drink',
          'travel-places',
          'objects'
        ];

        for (final category in categories) {
          try {
            final response = await http.get(
              Uri.parse(
                  'https://emoji-api.com/categories/$category?access_key=$apiKey'),
            );

            if (response.statusCode == 200) {
              final List<dynamic> data = json.decode(response.body);
              // Take just a few emojis from each category to keep PDF size reasonable
              for (int i = 0; i < data.length && i < 3; i++) {
                emojiData.add(Map<String, dynamic>.from(data[i]));
              }
            }
          } catch (e) {
            print('Error fetching $category emojis: $e');
          }
        }
      } catch (e) {
        print('Error fetching emoji data: $e');
      }

      // If API call fails or no API key, use some static emoji data as fallback
      if (emojiData.isEmpty) {
        // Static emoji data as fallback
        emojiData.addAll([
          {
            "slug": "grinning-face",
            "character": "😀",
            "unicodeName": "grinning face",
            "codePoint": "1F600",
            "group": "smileys-emotion"
          },
          {
            "slug": "smiling-face-with-hearts",
            "character": "🥰",
            "unicodeName": "smiling face with hearts",
            "codePoint": "1F970",
            "group": "smileys-emotion"
          },
          {
            "slug": "rocket",
            "character": "🚀",
            "unicodeName": "rocket",
            "codePoint": "1F680",
            "group": "travel-places"
          },
          {
            "slug": "red-apple",
            "character": "🍎",
            "unicodeName": "red apple",
            "codePoint": "1F34E",
            "group": "food-drink"
          },
          {
            "slug": "cat-face",
            "character": "🐱",
            "unicodeName": "cat face",
            "codePoint": "1F431",
            "group": "animals-nature"
          },
          {
            "slug": "rainbow",
            "character": "🌈",
            "unicodeName": "rainbow",
            "codePoint": "1F308",
            "group": "travel-places"
          },
          {
            "slug": "thumbs-up",
            "character": "👍",
            "unicodeName": "thumbs up",
            "codePoint": "1F44D",
            "group": "people-body"
          },
          {
            "slug": "sparkles",
            "character": "✨",
            "unicodeName": "sparkles",
            "codePoint": "2728",
            "group": "activities"
          }
        ]);
      }

      // Group the emojis by category
      final groupedEmojis = <String, List<Map<String, dynamic>>>{};
      for (final emoji in emojiData) {
        final group = emoji['group'] as String;
        if (!groupedEmojis.containsKey(group)) {
          groupedEmojis[group] = [];
        }
        groupedEmojis[group]!.add(emoji);
      }

      // Create a special widget for emoji that displays correctly and copies correctly
      pw.Widget buildCopyableEmoji(String emojiChar, {double size = 16}) {
        return pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            // Invisible text with raw Unicode for copying
            pw.Positioned.fill(
              child: pw.Text(
                emojiChar,
                style: pw.TextStyle(
                  fontSize: size,
                  // Make text fully transparent but still selectable
                  color: pw_pdf.PdfColors.white.flatten(),
                ),
              ),
            ),
            // Visible text with Noto Emoji font
            pw.Text(
              emojiChar,
              style: pw.TextStyle(
                font: emojiFontData,
                fontSize: size,
              ),
            ),
          ],
        );
      }

      // Create a table with better emoji handling
      pw.Widget buildEmojiTable(List<Map<String, dynamic>> emojis) {
        return pw.Table(
          border: pw.TableBorder.all(
            color: pw_pdf.PdfColors.grey300,
            width: 0.5,
          ),
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: pw_pdf.PdfColors.grey200,
              ),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Emoji',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Code',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Name',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
            // Data rows
            ...emojis.map((emoji) {
              final character = emoji['character'] as String;
              final codePoint = emoji['codePoint'] as String;
              return pw.TableRow(
                children: [
                  // Emoji column
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Center(
                      child: buildCopyableEmoji(character, size: 16),
                    ),
                  ),
                  // Code point column
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'U+$codePoint',
                      style: pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  // Name column
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      emoji['unicodeName'] as String,
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        );
      }

      // Add a black and white text-only page with simple layout for maximum copyability
      pdf.addPage(
        pw.Page(
          pageFormat: pw_pdf.PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Center(
                  child: pw.Text(
                    'Copyable Black & White Emoji PDF',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),

                // Instructions
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: pw_pdf.PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'This PDF contains Unicode emoji characters that can be copied and pasted.\n'
                    'The emojis appear in black and white using the Noto Emoji font.\n'
                    'To use: Select and copy the emoji characters, then paste them into apps that support emoji display.',
                    style: pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),

                pw.SizedBox(height: 20),

                // All emojis in one section for easy copying
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: pw_pdf.PdfColors.black),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'All Emojis (copy the entire line):',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Flexible(
                            child: pw.Text(
                              emojiData
                                  .map((e) => e['character'] as String)
                                  .join(' '),
                              style: const pw
                                  .TextStyle(), // Use default style for raw Unicode
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Category headers and emoji tables
                ...groupedEmojis.entries.map((entry) {
                  final categoryName = entry.key;
                  final categoryEmojis = entry.value;

                  // Format category name
                  final formattedCategory = categoryName
                      .split('-')
                      .map((word) => word[0].toUpperCase() + word.substring(1))
                      .join(' ');

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        formattedCategory,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      buildEmojiTable(categoryEmojis),
                      pw.SizedBox(height: 10),
                    ],
                  );
                }).toList(),
              ],
            );
          },
        ),
      );

      // Add a page with individual copyable emoji blocks
      pdf.addPage(
        pw.Page(
          pageFormat: pw_pdf.PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Center(
                  child: pw.Text(
                    'Individual Copyable Emoji Characters',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),

                // Instructions
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: pw_pdf.PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Each box below contains a single emoji character for easy selection and copying.',
                    style: pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),

                pw.SizedBox(height: 15),

                // Grid of individual emoji boxes
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: emojiData.map((emoji) {
                    return pw.Container(
                      width: 80,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                            color: pw_pdf.PdfColors.black, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          // Emoji character
                          buildCopyableEmoji(emoji['character'] as String,
                              size: 24),
                          pw.SizedBox(height: 5),
                          // Raw Unicode text for better copyability
                          pw.Container(
                            decoration: pw.BoxDecoration(
                              color: pw_pdf.PdfColors.grey100,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: pw.Text(
                              emoji['character'] as String,
                              style: const pw
                                  .TextStyle(), // Default style for raw Unicode
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          // Name
                          pw.Text(
                            emoji['unicodeName'] as String,
                            style: pw.TextStyle(fontSize: 6),
                            textAlign: pw.TextAlign.center,
                          ),
                          // Code point
                          pw.Text(
                            'U+${emoji['codePoint']}',
                            style: pw.TextStyle(fontSize: 6),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                pw.SizedBox(height: 20),
              ],
            );
          },
        ),
      );

      // Add a page with text descriptions and emoji characters
      pdf.addPage(
        pw.Page(
          pageFormat: pw_pdf.PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Center(
                  child: pw.Text(
                    'Emoji Characters with Text Descriptions',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Instructions
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: pw_pdf.PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Each line below contains an emoji with its description.\n'
                    'If you cannot see the emoji character, you can identify it by the description.',
                    style: pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),

                pw.SizedBox(height: 20),

                // List of emojis with descriptions
                ...emojiData.map((emoji) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 30,
                            height: 30,
                            alignment: pw.Alignment.center,
                            decoration: pw.BoxDecoration(
                              border:
                                  pw.Border.all(color: pw_pdf.PdfColors.grey),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              emoji['character'] as String,
                              style: pw.TextStyle(
                                  font: emojiFontData, fontSize: 16),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            child: pw.Text(
                              '${emoji['unicodeName']} (U+${emoji['codePoint']})',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          // Text representation of the emoji for copying
                          pw.Container(
                            width: 80,
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 5, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: pw_pdf.PdfColors.grey100,
                              border:
                                  pw.Border.all(color: pw_pdf.PdfColors.grey),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              emoji['character'] as String,
                              style: pw.TextStyle(
                                  font: emojiFontData, fontSize: 16),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )),

                pw.SizedBox(height: 20),

                // Tips
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: pw_pdf.PdfColors.amber100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Tips for Working with Emoji PDFs',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '• If emojis appear as boxes, try selecting and copying them anyway\n'
                        '• Paste copied text into apps that support emoji display (messaging apps, social media, etc.)\n'
                        '• Try different PDF viewers if emojis don\'t display correctly\n'
                        '• You can identify emojis by their Unicode code point (U+XXXX) if they don\'t display',
                        style: pw.TextStyle(
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Add a page with both display and copyable sections
      pdf.addPage(
        pw.Page(
          pageFormat: pw_pdf.PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Emoji PDF: Display vs. Copyable',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),
                // Display section (Noto Emoji font)
                pw.Text('Display (may look correct, but not always copyable):',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: pw_pdf.PdfColors.grey)),
                  child: pw.Text(
                    emojiData.map((e) => e['character'] as String).join(' '),
                    style: pw.TextStyle(font: emojiFontData, fontSize: 24),
                  ),
                ),
                pw.SizedBox(height: 20),
                // Copyable section (no custom font)
                pw.Text(
                    'Copyable Unicode Emoji (may look like boxes, but copy/paste works):',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: pw_pdf.PdfColors.amber)),
                  child: pw.Text(
                    emojiData.map((e) => e['character'] as String).join(' '),
                    style: pw.TextStyle(fontSize: 24), // NO font: parameter!
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                    'Tip: Always copy from the yellow section above for real emoji characters.',
                    style: pw.TextStyle(
                        fontSize: 10, color: pw_pdf.PdfColors.amber800)),
              ],
            );
          },
        ),
      );

      // Add a page with raw Unicode characters for copying
      pdf.addPage(
        pw.Page(
          pageFormat: pw_pdf.PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Title
                pw.Center(
                  child: pw.Text(
                    'Raw Unicode Emoji Characters',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Plain text introduction
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'This page contains raw Unicode emoji characters for copying and pasting.\n'
                    'The text below uses the default font with no styling to maximize compatibility.',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),

                pw.SizedBox(height: 20),

                // Raw unicode for copying - IMPORTANT: No custom font here
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: pw_pdf.PdfColors.black),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Copy these raw Unicode characters:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 15),

                      // Each emoji on its own line
                      ...emojiData.map((emoji) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 8),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                // Name and code
                                pw.Expanded(
                                  child: pw.Text(
                                    '${emoji['unicodeName']} (U+${emoji['codePoint']})',
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                                // Plain emoji character for copying (no custom font)
                                pw.Container(
                                  width: 60,
                                  padding: const pw.EdgeInsets.all(4),
                                  decoration: pw.BoxDecoration(
                                    color: pw_pdf.PdfColors.grey100,
                                    border: pw.Border.all(
                                        color: pw_pdf.PdfColors.black),
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Center(
                                    child: pw.Text(
                                      emoji['character'] as String,
                                      style: const pw
                                          .TextStyle(), // Default style for raw Unicode
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Add a demo page: image with selectable/copyable hidden text
      final ByteData emojiBytes =
          await rootBundle.load('assets/fonts/seguiemj.ttf');
      final Uint8List emojiImage = emojiBytes.buffer.asUint8List(
          0, 256); // Just a placeholder, replace with a real image if you want

      pdf.addPage(
        pw.Page(
          pageFormat: pw_pdf.PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Demo: Selectable Image that Copies Text',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text(
                    'Select the image below and copy. It will copy the word "hello".'),
                pw.SizedBox(height: 20),
                pw.Stack(
                  alignment: pw.Alignment.center,
                  children: [
                    // Show an emoji as an image (for demo, use a big emoji character)
                    pw.Text('😀',
                        style: pw.TextStyle(fontSize: 80, font: emojiFontData)),
                    // Overlay fully transparent text
                    pw.Positioned(
                      left: 0,
                      top: 0,
                      child: pw.Container(
                        width: 80,
                        height: 80,
                        alignment: pw.Alignment.center,
                        color: pw_pdf.PdfColors.white, // white background
                        child: pw.Text(
                          'hello',
                          style: pw.TextStyle(
                            fontSize: 80,
                            color: pw_pdf.PdfColors.white, // white text
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                    'Try selecting the emoji above and copying. It should copy the word "hello".'),
              ],
            );
          },
        ),
      );

      // Let user choose save location or default to Downloads
      String? outputPath;
      try {
        String? selectedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save your emoji PDF',
          fileName: 'emoji_black_white.pdf',
        );
        if (selectedPath != null) {
          outputPath = selectedPath;
        }
      } catch (e) {
        // ignore, fallback to Downloads
      }

      if (outputPath == null) {
        Directory? downloadsDir;
        try {
          downloadsDir = await getDownloadsDirectory();
        } catch (e) {
          downloadsDir = await getTemporaryDirectory();
        }
        outputPath = '${downloadsDir?.path ?? '.'}/emoji_black_white.pdf';
      }

      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF with B&W emojis saved to $outputPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating PDF: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> convertHtmlToPdfWithDocRaptor(BuildContext context) async {
    final html = '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <title>Emoji PDF</title>
        <style>
          @import url('https://fonts.googleapis.com/css2?family=Noto+Color+Emoji');
          body {
            font-family: 'Noto Color Emoji', 'Segoe UI Emoji', 'Apple Color Emoji', sans-serif;
            font-size: 32px;
          }
        </style>
      </head>
      <body>
        <h1>Here are some emojis:</h1>
        <p>😀 🥰 🚀 🍎 🐱 🌈 👍 ✨</p>
      </body>
    </html>
    ''';

    final url = Uri.parse('https://docraptor.com/docs');
    final apiKey = 'L7zGjCCzI2m8vd7lKL9L'; // Updated API key for test mode

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/pdf',
          'Authorization': 'Basic ' + base64Encode(utf8.encode('$apiKey:')),
        },
        body: jsonEncode({
          'user_credentials': apiKey,
          'doc': {
            'document_content': html,
            'name': 'emojis_raptor.pdf',
            'document_type': 'pdf',
            'test': true, // Ensure test mode is enabled
          }
        }),
      );

      if (response.statusCode == 200) {
        final downloadsDir = await getDownloadsDirectory();
        final filePath = '${downloadsDir?.path ?? '.'}/emojis_raptor.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Automatically add white squares and a text page to the DocRaptor PDF
        final outputPath =
            '${downloadsDir?.path ?? '.'}/emojis_raptor_with_squares.pdf';
        await addWhiteSquaresAndTextPageToDocRaptorPdf(filePath, outputPath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'PDF with white squares and text page saved to $outputPath')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'DocRaptor error: ${response.statusCode} ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DocRaptor error: $e')),
        );
      }
    }
  }

  Future<void> extractTextAndCreateNewPdf(
      String inputPdfPath, String outputPdfPath) async {
    // Load the existing PDF using Syncfusion
    final List<int> bytes = await File(inputPdfPath).readAsBytes();
    final sf_pdf.PdfDocument document = sf_pdf.PdfDocument(inputBytes: bytes);

    // Extract all text from the document
    String allText = sf_pdf.PdfTextExtractor(document).extractText();

    // Create a new PDF with the extracted text using the pdf package
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Text(allText),
      ),
    );

    // Save the new PDF
    final file = File(outputPdfPath);
    await file.writeAsBytes(await pdf.save());

    document.dispose();
  }

  Future<void> addWhiteSquaresAndTextPageToDocRaptorPdf(
      String inputPdfPath, String outputPdfPath) async {
    // Load the existing PDF
    final List<int> bytes = await File(inputPdfPath).readAsBytes();
    final sf_pdf.PdfDocument document = sf_pdf.PdfDocument(inputBytes: bytes);

    // Define the size and position of the white square
    const double squareSize = 50; // 50x50 points
    const double margin = 20; // Distance from the edge

    for (int i = 0; i < document.pages.count; i++) {
      final page = document.pages[i];
      final pageWidth = page.getClientSize().width;
      final pageHeight = page.getClientSize().height;

      // Draw white square at the top center
      page.graphics.drawRectangle(
        brush: sf_pdf.PdfBrushes.white,
        bounds: Rect.fromLTRB(
          (pageWidth - squareSize) / 2,
          margin,
          (pageWidth - squareSize) / 2 + squareSize,
          margin + squareSize,
        ),
      );

      // Draw white square at the bottom center
      page.graphics.drawRectangle(
        brush: sf_pdf.PdfBrushes.white,
        bounds: Rect.fromLTRB(
          (pageWidth - squareSize) / 2,
          pageHeight - margin - squareSize,
          (pageWidth - squareSize) / 2 + squareSize,
          pageHeight - margin,
        ),
      );
    }

    // Always add a new page (even if text extraction fails)
    String allText = sf_pdf.PdfTextExtractor(document).extractText();
    if (allText.trim().isEmpty) {
      allText =
          'This is a second page added after download. (No text extracted)';
    }
    final newPage = document.pages.add();
    newPage.graphics.drawString(
      allText,
      sf_pdf.PdfStandardFont(sf_pdf.PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(
          0, 0, newPage.getClientSize().width, newPage.getClientSize().height),
    );

    // Save the modified PDF
    final List<int> newBytes = document.saveSync();
    await File(outputPdfPath).writeAsBytes(newBytes);
    document.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Create a PDF with black & white copyable emojis',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text(
              'This app creates a PDF where emojis appear as black & white characters\n'
              'that can be copied and pasted into other applications.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _exportEmojiPdf,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              label:
                  Text(_isLoading ? 'Creating PDF...' : 'Create B&W Emoji PDF'),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Examples: '),
                Text('😀 🥰 🚀 🍎 🐱 🌈 👍 ✨', style: TextStyle(fontSize: 20)),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Raptor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => convertHtmlToPdfWithDocRaptor(context),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Extract & Copy Raptor PDF Text'),
              onPressed: () async {
                // Example usage: assumes the DocRaptor PDF is in Downloads
                final downloadsDir = await getDownloadsDirectory();
                final inputPath =
                    '${downloadsDir?.path ?? '.'}/emojis_raptor.pdf';
                final outputPath =
                    '${downloadsDir?.path ?? '.'}/emojis_raptor_text_only.pdf';
                await extractTextAndCreateNewPdf(inputPath, outputPath);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Extracted text PDF saved to $outputPath')),
                  );
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.crop_square),
              label: const Text('Add White Squares to Raptor PDF'),
              onPressed: () async {
                final downloadsDir = await getDownloadsDirectory();
                final inputPath =
                    '${downloadsDir?.path ?? '.'}/emojis_raptor.pdf';
                final outputPath =
                    '${downloadsDir?.path ?? '.'}/emojis_raptor_with_squares.pdf';
                await addWhiteSquaresAndTextPageToDocRaptorPdf(
                    inputPath, outputPath);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'PDF with white squares and text page saved to $outputPath')),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Generate PDF with Puppeteer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => generatePdfWithPuppeteer(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> generatePdfWithPuppeteer(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final html = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Generated PDF</title>
          <style>
            body {
              font-family: Arial, sans-serif;
              margin: 40px;
              line-height: 1.6;
            }
            .emoji {
              font-size: 24px;
            }
            .container {
              max-width: 800px;
              margin: 0 auto;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>PDF Generated with Puppeteer</h1>
            <p>This PDF was generated using Vercel Serverless Functions and Puppeteer.</p>
            <div class="emoji">
              😀 🥰 🚀 🍎 🐱 🌈 👍 ✨
            </div>
            <p>Generated on: ${DateTime.now()}</p>
          </div>
        </body>
      </html>
      ''';

      final response = await http.post(
        Uri.parse('https://your-vercel-project.vercel.app/api/generatePDF'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'html': html}),
      );

      if (response.statusCode == 200) {
        // Save the PDF
        final downloadsDir = await getDownloadsDirectory();
        final outputPath =
            '${downloadsDir?.path ?? '.'}/puppeteer_generated.pdf';

        await File(outputPath).writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF saved to $outputPath')),
          );
        }
      } else {
        throw Exception('Failed to generate PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
