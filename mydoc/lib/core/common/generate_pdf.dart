import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'hive_storage.dart';

Future<File> generatePdf(String text) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Text(text, style: pw.TextStyle(fontSize: 14));
      },
    ),
  );

  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/consultation_record.pdf');

  await file.writeAsBytes(await pdf.save());
  return file;
}


Future<File> generatePdfFile({
  required String patientName,
  required String transcription,
  required String soapNotes,
  String gender = "N/A",
}) async {
  final pdf = pw.Document();

  // 1. Get Doctor Data from Hive
  final String docName = HiveStorage.getName() ?? "Unknown Doctor";
  final String docSpeciality =
      HiveStorage.getspeciallisation() ?? "General Physician";
  final String currentDate = DateFormat('dd-MMM-yyyy').format(DateTime.now());

  // Define Colors
  final PdfColor primaryColor = PdfColor.fromHex(
    "#1B434D",
  ); // Dark Teal from your image
  final PdfColor grayColor = PdfColors.grey700;

  // Define Text Styles
  final titleStyle = pw.TextStyle(
    fontSize: 24,
    fontWeight: pw.FontWeight.bold,
    color: primaryColor,
  );
  final headerStyle = pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    color: primaryColor,
  );
  final labelStyle = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: primaryColor,
  );
  final valueStyle = pw.TextStyle(fontSize: 10, color: PdfColors.black);
  final bodyStyle = pw.TextStyle(
    fontSize: 10,
    lineSpacing: 2,
    color: PdfColors.black,
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return [
          // --- TITLE ---
          pw.Center(
            child: pw.Text("AI-Powered Medical Report", style: titleStyle),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: primaryColor, thickness: 1),
          pw.SizedBox(height: 10),

          // --- DOCTOR INFO SECTION ---
          pw.Text("Doctor Info", style: headerStyle),
          pw.SizedBox(height: 5),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex("#F5F9FA"), // Light teal background
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text("Doctor Name: ", style: labelStyle),
                        pw.Text(docName, style: valueStyle),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text("Specialisation: ", style: labelStyle),
                        pw.Text(docSpeciality, style: valueStyle),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text("Date: ", style: labelStyle),
                        pw.Text(currentDate, style: valueStyle),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          // --- PATIENT INFO SECTION ---
          pw.Text("Patient Info", style: headerStyle),
          pw.SizedBox(height: 5),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex("#F5F9FA"),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text("Name: ", style: labelStyle),
                    pw.Text(patientName, style: valueStyle),
                  ],
                ),
                // pw.Row(
                //   children: [
                //     pw.Text("Gender: ", style: labelStyle),
                //     pw.Text(gender, style: valueStyle),
                //   ],
                // ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // --- TRANSCRIPTION ---
          pw.Text("Transcription", style: headerStyle),
          pw.SizedBox(height: 5),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              transcription.isEmpty
                  ? "No transcription available."
                  : transcription,
              style: bodyStyle,
            ),
          ),
          pw.SizedBox(height: 20),

          // --- SOAP NOTES ---
          pw.Text("SOAP Notes", style: headerStyle),
          pw.SizedBox(height: 5),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              soapNotes.isEmpty ? "No notes available." : soapNotes,
              style: bodyStyle,
            ),
          ),


        ];
      },
    ),
  );

  // --- SAVE FILE LOGIC ---
  String path;
  if (Platform.isAndroid) {
    path = '/storage/emulated/0/Download';
  } else {
    final dir = await getApplicationDocumentsDirectory();
    path = dir.path;
  }

  final fileName =
      'Report_${patientName.replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final file = File('$path/$fileName');

  await file.writeAsBytes(await pdf.save());
  return file;
}

Future<void> sharePdfByEmail(String text) async {
  final pdfFile = await generatePdf(text);

  await Share.shareXFiles(
    [XFile(pdfFile.path)],
    subject:
        ""
        "Consultation Record",
    text: "Please find the attached consultation record PDF.",
  );
}
