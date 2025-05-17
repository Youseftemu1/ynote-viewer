import 'package:aspose_words_cloud/aspose_words_cloud.dart';
import 'dart:io';
import 'dart:typed_data';

Future<void> main() async {
  // 1. Configure Aspose.Words Cloud
  var configuration = Configuration('YOUR_CLIENT_ID', 'YOUR_CLIENT_SECRET');
  var wordsApi = WordsApi(configuration);

  // 2. Upload your DOCX file to Aspose Cloud
  var localFileContent = await File('emojis.docx').readAsBytes();
  var uploadRequest =
      UploadFileRequest(ByteData.view(localFileContent.buffer), 'emojis.docx');
  await wordsApi.uploadFile(uploadRequest);

  // 3. Convert DOCX to PDF in the cloud
  var saveOptionsData = PdfSaveOptionsData()..fileName = 'emojis.pdf';
  var saveAsRequest = SaveAsRequest('emojis.docx', saveOptionsData);
  await wordsApi.saveAs(saveAsRequest);

  // 4. Download the resulting PDF
  var downloadResponse =
      await wordsApi.downloadFile(DownloadFileRequest('emojis.pdf'));
  await File('emojis_from_cloud.pdf')
      .writeAsBytes(downloadResponse.buffer.asUint8List());

  print('PDF with emojis saved as emojis_from_cloud.pdf');
}
