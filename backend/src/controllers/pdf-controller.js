import PDFDocument from 'pdfkit';
import { DailyStockEntry, Product } from '../models/index.js';
import { sendError } from '../utils/response.js';

// Helper to format currency numbers in Indian Style (1,00,000)
function fmtNum(val) {
  if (val === null || val === undefined || val === '') return '';
  const num = parseFloat(val);
  if (isNaN(num) || num === 0) return '';
  return num % 1 === 0 ? num.toLocaleString('en-IN') : num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function fmtNumZero(val) {
  if (val === null || val === undefined || val === '') return '0';
  const num = parseFloat(val);
  if (isNaN(num)) return '0';
  return num % 1 === 0 ? num.toLocaleString('en-IN') : num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function fmtDate(iso) {
  if (!iso) return '';
  const clean = iso.toString().split('T')[0];
  const parts = clean.split('-');
  if (parts.length === 3) {
    return `${parts[2]}/${parts[1]}/${parts[0]}`;
  }
  return clean;
}

// GET /api/entries/pdf
export const generateRegisterPdf = async (req, res) => {
  try {
    let { productId, productName, startDate, endDate } = req.query;

    let brandTitle = productName || 'Register';
    let actualProductId = productId;

    if (productId && !/^[0-9a-fA-F-]{36}$/.test(productId)) {
      brandTitle = productId;
      const allProds = await Product.findActive();
      const matched = allProds.find(
        p => p.name.toLowerCase() === productId.toLowerCase()
      );
      if (matched) {
        actualProductId = matched.id;
        brandTitle = matched.name;
      }
    } else if (productId && !productName) {
      const prod = await Product.findById(productId);
      if (prod) brandTitle = prod.name;
    }

    const entries = await DailyStockEntry.findAll({
      productId: actualProductId,
      startDate,
      endDate,
    });

    // Setup A4 Landscape Document
    const doc = new PDFDocument({
      size: 'A4',
      layout: 'landscape',
      margins: { top: 30, bottom: 30, left: 30, right: 30 },
      bufferPages: true,
    });

    const filename = `SSRSM_Register_${brandTitle.replace(/\s+/g, '_')}.pdf`;
    const isDownload = req.query.download === '1' || req.query.download === 'true';
    const disposition = isDownload ? 'attachment' : 'inline';
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `${disposition}; filename="${filename}"`);

    doc.pipe(res);

    // Color Palette
    const cPrimary = '#1F4E79';
    const cHeaderBg = '#EEF2F8';
    const cSubHeaderBg = '#F6F8FB';
    const cHighlightBg = '#FFF3DC';
    const cBorder = '#1F4E79';
    const cText = '#14243A';
    const cSubText = '#5F6F82';

    // Header Title
    doc.fillColor(cPrimary).fontSize(16).font('Helvetica-Bold')
      .text(`SSRSM Register (${brandTitle})`, { align: 'center' });

    let dateSubtitle = '';
    if (startDate && endDate) {
      dateSubtitle = startDate === endDate ? `Date: ${fmtDate(startDate)}` : `Period: ${fmtDate(startDate)} to ${fmtDate(endDate)}`;
    } else if (startDate) {
      dateSubtitle = `From: ${fmtDate(startDate)}`;
    } else if (endDate) {
      dateSubtitle = `To: ${fmtDate(endDate)}`;
    } else {
      dateSubtitle = 'All Recorded Entries';
    }

    doc.fontSize(10).font('Helvetica').fillColor(cSubText)
      .text(dateSubtitle, { align: 'center' });
    doc.moveDown(0.8);

    // Table Coordinates
    // A4 Landscape = 841.89 x 595.28
    const startX = 30;
    const startY = doc.y;
    const totalWidth = 841.89 - 60; // 781.89 pt

    // 14 columns
    const cols = [
      { id: 'sno', name: 'S.No.', width: 34 },
      { id: 'date', name: 'Date', width: 56 },
      { id: 'open', name: 'Opening\nStock', width: 54 },
      { id: 'new', name: 'New\nStock', width: 50 },
      { id: 'sales', name: 'Daily\nSales', width: 50 },
      { id: 'rec', name: 'Stock\nReceived', width: 54 },
      { id: 'close', name: 'Total Closing\nStock', width: 66 },
      { id: 'cash', name: 'Cash', width: 48 },
      { id: 'cheque', name: 'Cheque', width: 48 },
      { id: 'rtgs', name: 'RTGS', width: 48 },
      { id: 'auto', name: 'Auto', width: 46 },
      { id: 'credit', name: 'Credit', width: 46 },
      { id: 'sm', name: 'Sales Man', width: 75 },
      { id: 'note', name: 'Note', width: totalWidth - (34+56+54+50+50+54+66+48+48+48+46+46+75) }, // ~106 pt
    ];

    const h1Height = 20;
    const h2Height = 16;
    const rowHeight = 18;

    let currentY = startY;

    // Draw Top Header 1
    doc.rect(startX, currentY, totalWidth, h1Height).fill(cHeaderBg);
    doc.rect(startX, currentY, totalWidth, h1Height).lineWidth(1).stroke(cBorder);

    // Draw Group Header: Collection (Cols index 7 to 12)
    const colStartIdx = 7;
    const colEndIdx = 12;
    let colStartX = startX;
    for (let i = 0; i < colStartIdx; i++) {
      colStartX += cols[i].width;
    }
    let colWidthTotal = 0;
    for (let i = colStartIdx; i <= colEndIdx; i++) {
      colWidthTotal += cols[i].width;
    }

    // Vertical dividers in Header 1
    let curX = startX;
    for (let i = 0; i < cols.length; i++) {
      if (i < colStartIdx || i > colEndIdx) {
        doc.moveTo(curX, currentY).lineTo(curX, currentY + h1Height + h2Height).stroke(cBorder);
      }
      curX += cols[i].width;
    }
    doc.moveTo(startX + totalWidth, currentY).lineTo(startX + totalWidth, currentY + h1Height + h2Height).stroke(cBorder);

    // Text in Header 1
    curX = startX;
    for (let i = 0; i < cols.length; i++) {
      if (i < colStartIdx || i > colEndIdx) {
        doc.font('Helvetica-Bold').fontSize(7.5).fillColor(cText)
          .text(cols[i].name, curX + 2, currentY + 3, {
            width: cols[i].width - 4,
            align: 'center',
            lineGap: -1,
          });
      }
      curX += cols[i].width;
    }

    // COLLECTION Group Header Text
    doc.font('Helvetica-Bold').fontSize(8.5).fillColor(cText)
      .text('C O L L E C T I O N', colStartX, currentY + 5, {
        width: colWidthTotal,
        align: 'center',
      });

    // Draw Header 2 (Sub-headers for Collection)
    currentY += h1Height;
    doc.rect(colStartX, currentY, colWidthTotal, h2Height).fill(cSubHeaderBg);
    doc.rect(startX, currentY, totalWidth, h2Height).lineWidth(0.8).stroke(cBorder);

    curX = colStartX;
    for (let i = colStartIdx; i <= colEndIdx; i++) {
      doc.moveTo(curX, currentY).lineTo(curX, currentY + h2Height).stroke(cBorder);
      doc.font('Helvetica-Bold').fontSize(7.5).fillColor(cText)
        .text(cols[i].name, curX + 2, currentY + 4, {
          width: cols[i].width - 4,
          align: 'center',
        });
      curX += cols[i].width;
    }

    currentY += h2Height;

    // Table Data Rows
    let currentSno = 0;
    let lastDate = null;

    let totOpen = 0, totNew = 0, totSales = 0, totRec = 0, totClose = 0;
    let totCash = 0, totCheque = 0, totRtgs = 0, totAuto = 0, totCredit = 0;
    const countedDates = new Set();

    entries.forEach((e) => {
      // Check if need new page
      if (currentY + rowHeight > 540) {
        doc.addPage({ size: 'A4', layout: 'landscape', margins: { top: 30, bottom: 30, left: 30, right: 30 } });
        currentY = 30;
      }

      const dateStr = (e.entry_date || '').toString().split('T')[0];
      const isSubsequent = dateStr === lastDate;

      let displaySno = '';
      if (!isSubsequent) {
        currentSno++;
        lastDate = dateStr;
        displaySno = `${currentSno}.`;

        if (!countedDates.has(dateStr)) {
          countedDates.add(dateStr);
          totOpen += parseFloat(e.opening_stock || 0);
          totNew += parseFloat(e.new_stock || 0);
          totSales += parseFloat(e.daily_sales || 0);
          totRec += parseFloat(e.stock_received || 0);
          totClose += parseFloat(e.closing_stock || 0);
        }
      }

      totCash += parseFloat(e.cash_amount || 0);
      totCheque += parseFloat(e.cheque_amount || 0);
      totRtgs += parseFloat(e.rtgs_amount || 0);
      totAuto += parseFloat(e.auto_amount || 0);
      totCredit += parseFloat(e.credit_amount || 0);

      // Row background
      if (isSubsequent) {
        doc.rect(startX, currentY, totalWidth, rowHeight).fill(cHighlightBg);
      }
      doc.rect(startX, currentY, totalWidth, rowHeight).lineWidth(0.5).stroke(cBorder);

      // Column Values
      const rowValues = [
        { text: displaySno, align: 'center' },
        { text: fmtDate(e.entry_date), align: 'center' },
        { text: fmtNumZero(e.opening_stock), align: 'right' },
        { text: fmtNum(e.new_stock), align: 'right' },
        { text: fmtNumZero(e.daily_sales), align: 'right' },
        { text: fmtNum(e.stock_received), align: 'right' },
        { text: fmtNumZero(e.closing_stock), align: 'right' },
        { text: fmtNum(e.cash_amount), align: 'right' },
        { text: fmtNum(e.cheque_amount), align: 'right' },
        { text: fmtNum(e.rtgs_amount), align: 'right' },
        { text: fmtNum(e.auto_amount), align: 'right' },
        { text: fmtNum(e.credit_amount), align: 'right' },
        { text: e.salesman_name || '', align: 'left' },
        { text: e.note || '', align: 'left' },
      ];

      curX = startX;
      for (let i = 0; i < cols.length; i++) {
        // Divider
        doc.moveTo(curX, currentY).lineTo(curX, currentY + rowHeight).stroke(cBorder);
        // Text
        const val = rowValues[i];
        doc.font('Helvetica').fontSize(7.5).fillColor(cText)
          .text(val.text, curX + 2, currentY + 4, {
            width: cols[i].width - 4,
            align: val.align,
            ellipsis: true,
          });
        curX += cols[i].width;
      }
      doc.moveTo(startX + totalWidth, currentY).lineTo(startX + totalWidth, currentY + rowHeight).stroke(cBorder);

      currentY += rowHeight;
    });

    // Totals Row
    doc.rect(startX, currentY, totalWidth, rowHeight + 2).fill(cHeaderBg);
    doc.rect(startX, currentY, totalWidth, rowHeight + 2).lineWidth(1).stroke(cBorder);

    const totValues = [
      { text: 'Total', align: 'center', bold: true },
      { text: '', align: 'center' },
      { text: fmtNumZero(totOpen), align: 'right', bold: true },
      { text: fmtNumZero(totNew), align: 'right', bold: true },
      { text: fmtNumZero(totSales), align: 'right', bold: true },
      { text: fmtNumZero(totRec), align: 'right', bold: true },
      { text: fmtNumZero(totClose), align: 'right', bold: true },
      { text: fmtNumZero(totCash), align: 'right', bold: true },
      { text: fmtNumZero(totCheque), align: 'right', bold: true },
      { text: fmtNumZero(totRtgs), align: 'right', bold: true },
      { text: fmtNumZero(totAuto), align: 'right', bold: true },
      { text: fmtNumZero(totCredit), align: 'right', bold: true },
      { text: '', align: 'left' },
      { text: '', align: 'left' },
    ];

    curX = startX;
    for (let i = 0; i < cols.length; i++) {
      doc.moveTo(curX, currentY).lineTo(curX, currentY + rowHeight + 2).stroke(cBorder);
      const val = totValues[i];
      if (val.text) {
        doc.font('Helvetica-Bold').fontSize(7.5).fillColor(cText)
          .text(val.text, curX + 2, currentY + 5, {
            width: cols[i].width - 4,
            align: val.align,
          });
      }
      curX += cols[i].width;
    }
    doc.moveTo(startX + totalWidth, currentY).lineTo(startX + totalWidth, currentY + rowHeight + 2).stroke(cBorder);

    // Footer info: Printed On date
    const printDate = new Date();
    const day = String(printDate.getDate()).padStart(2, '0');
    const month = String(printDate.getMonth() + 1).padStart(2, '0');
    const year = printDate.getFullYear();
    const hours = String(printDate.getHours()).padStart(2, '0');
    const mins = String(printDate.getMinutes()).padStart(2, '0');

    doc.font('Helvetica').fontSize(8).fillColor(cSubText)
      .text(`Printed on: ${day}/${month}/${year} at ${hours}:${mins} · Powered by FDHS Solutions`, startX, currentY + rowHeight + 8, {
        align: 'right',
        width: totalWidth,
      });

    doc.end();
  } catch (error) {
    console.error('Error generating PDF:', error);
    return sendError(res, error);
  }
};
