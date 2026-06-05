import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../core/theme/app_colors.dart';

class ReceiptDialog extends StatelessWidget {
  final OrderModel order;
  final String choyxonaName;
  final String? tableName;

  const ReceiptDialog({
    super.key,
    required this.order,
    required this.choyxonaName,
    this.tableName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('receipt_preview'.tr(), style: const TextStyle(color: Colors.black)),
      content: SizedBox(
        width: 300,
        height: 400,
        child: PdfPreview(
          build: (format) => _generatePdf(format),
          allowSharing: true,
          allowPrinting: true,
          initialPageFormat: PdfPageFormat.roll80,
          pdfFileName: 'receipt_${order.orderId}.pdf',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('close'.tr()),
        ),
      ],
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'uz', symbol: "so'm", decimalDigits: 0);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    
    // Kirill va lotin alifbolarini qo'llab-quvvatlash uchun font yuklaymiz
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                choyxonaName,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Chek #${order.orderId.substring(0, 8)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                dateFormat.format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 10),
              ),
              if (tableName != null)
                pw.Text(
                  tableName!,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
              
              pw.Divider(),
              
              ...order.items.map((item) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        item.dishName,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      '${item.quantityDisplay} x ${currencyFormat.format(item.price)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                );
              }),
              
              pw.Divider(),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Jami:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    currencyFormat.format(order.totalAmount),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              
              if (order.discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Chegirma:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      '-${currencyFormat.format(order.subtotal * (order.discount / 100))}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                
              if (order.tips > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Xizmat (Tips):', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      currencyFormat.format(order.tips),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),

              pw.SizedBox(height: 16),
              pw.Text(
                'Xaridingiz uchun rahmat!',
                style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
              ),
              pw.Text(
                'Choyxona.uz orqali',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
