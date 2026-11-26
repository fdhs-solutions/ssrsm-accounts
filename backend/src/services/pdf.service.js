import PDFDocument from 'pdfkit';
import { DailyStockEntryModel } from '../models/index.js';
import { ProductService } from './product.service.js';
import { fmtNum, fmtNumZero, fmtDate } from '../utils/formatters.js';

const COLORS = {
  primary: '#1F4E79',
  headerBg: '#EEF2F8',
  subHeaderBg: '#F6F8FB',
  highlightBg: '#FFF3DC',
  border: '#1F4E79',
  text: '#14243A',
  subText: '#5F6F82',
};

const START_X = 30;
const TOTAL_WIDTH = 841.89 - 60;
const H1_HEIGHT = 20;
const H2_HEIGHT = 16;
const ROW_HEIGHT = 18;
const MAX_Y = 540;

const COLS = [
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
  { id: 'note', name: 'Note', width: TOTAL_WIDTH - (34 + 56 + 54 + 50 + 50 + 54 + 66 + 48 + 48 + 48 + 46 + 46 + 75) },
];

function drawTableHeader(doc, startY) {
  let currentY = startY;
  const colStartIdx = 7;
  const colEndIdx = 12;

  let colStartX = START_X;
  for (let i = 0; i < colStartIdx; i++) colStartX += COLS[i].width;

  let colWidthTotal = 0;
  for (let i = colStartIdx; i <= colEndIdx; i++) colWidthTotal += COLS[i].width;

  doc.rect(START_X, currentY, TOTAL_WIDTH, H1_HEIGHT).fill(COLORS.headerBg);
  doc.rect(START_X, currentY, TOTAL_WIDTH, H1_HEIGHT).lineWidth(1).stroke(COLORS.border);

  let curX = START_X;
  for (let i = 0; i < COLS.length; i++) {
    if (i < colStartIdx || i > colEndIdx) {
      doc.moveTo(curX, currentY).lineTo(curX, currentY + H1_HEIGHT + H2_HEIGHT).stroke(COLORS.border);
    }
    curX += COLS[i].width;
  }
  doc.moveTo(START_X + TOTAL_WIDTH, currentY).lineTo(START_X + TOTAL_WIDTH, currentY + H1_HEIGHT + H2_HEIGHT).stroke(COLORS.border);

  curX = START_X;
  for (let i = 0; i < COLS.length; i++) {
    if (i < colStartIdx || i > colEndIdx) {
      doc.font('Helvetica-Bold').fontSize(7.5).fillColor(COLORS.text)
        .text(COLS[i].name, curX + 2, currentY + 3, {
          width: COLS[i].width - 4,
          align: 'center',
          lineGap: -1,
        });
    }
    curX += COLS[i].width;
  }

  doc.font('Helvetica-Bold').fontSize(8.5).fillColor(COLORS.text)
    .text('C O L L E C T I O N', colStartX, currentY + 5, {
      width: colWidthTotal,
      align: 'center',
    });

  currentY += H1_HEIGHT;
  doc.rect(colStartX, currentY, colWidthTotal, H2_HEIGHT).fill(COLORS.subHeaderBg);
  doc.rect(START_X, currentY, TOTAL_WIDTH, H2_HEIGHT).lineWidth(0.8).stroke(COLORS.border);

  curX = colStartX;
  for (let i = colStartIdx; i <= colEndIdx; i++) {
    doc.moveTo(curX, currentY).lineTo(curX, currentY + H2_HEIGHT).stroke(COLORS.border);
    doc.font('Helvetica-Bold').fontSize(7.5).fillColor(COLORS.text)
      .text(COLS[i].name, curX + 2, currentY + 4, {
        width: COLS[i].width - 4,
        align: 'center',
      });
    curX += COLS[i].width;
  }

  return currentY + H2_HEIGHT;
}

export const PdfService = {
  async streamRegisterPdf(res, { productId, productName, startDate, endDate, download }) {
    const product = await ProductService.resolveProduct(productId, { allowAll: true });
    const brandTitle = product?.name || productName || 'Register';

    const entries = await DailyStockEntryModel.findAll({
      productId: product?.id,
      startDate,
      endDate,
    });

    const doc = new PDFDocument({
      size: 'A4',
      layout: 'landscape',
      margins: { top: 30, bottom: 30, left: 30, right: 30 },
      bufferPages: true,
    });

    const filename = `SSRSM_Register_${brandTitle.replace(/\s+/g, '_')}.pdf`;
    const isDownload = download === '1' || download === 'true';
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `${isDownload ? 'attachment' : 'inline'}; filename="${filename}"`);

    doc.pipe(res);

    doc.fillColor(COLORS.primary).fontSize(16).font('Helvetica-Bold')
      .text(`SSRSM Register (${brandTitle})`, { align: 'center' });

    let dateSubtitle = 'All Recorded Entries';
    if (startDate && endDate) {
      dateSubtitle = startDate === endDate
        ? `Date: ${fmtDate(startDate)}`
        : `Period: ${fmtDate(startDate)} to ${fmtDate(endDate)}`;
    } else if (startDate) {
      dateSubtitle = `From: ${fmtDate(startDate)}`;
    } else if (endDate) {
      dateSubtitle = `To: ${fmtDate(endDate)}`;
    }

    doc.fontSize(10).font('Helvetica').fillColor(COLORS.subText).text(dateSubtitle, { align: 'center' });
    doc.moveDown(0.8);

    let currentY = drawTableHeader(doc, doc.y);

    let currentSno = 0;
    let lastDate = null;
    let totOpen = 0, totNew = 0, totSales = 0, totRec = 0, totClose = 0;
    let totCash = 0, totCheque = 0, totRtgs = 0, totAuto = 0, totCredit = 0;
    const countedDates = new Set();

    for (const e of entries) {
      if (currentY + ROW_HEIGHT > MAX_Y) {
        doc.addPage({ size: 'A4', layout: 'landscape', margins: { top: 30, bottom: 30, left: 30, right: 30 } });
        currentY = drawTableHeader(doc, 30);
      }

      const dateStr = (e.entry_date || '').toString().split('T')[0];
      const isSubsequent = dateStr === lastDate;
      let displaySno = '';

      if (!isSubsequent) {
        currentSno += 1;
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

      if (isSubsequent) {
        doc.rect(START_X, currentY, TOTAL_WIDTH, ROW_HEIGHT).fill(COLORS.highlightBg);
      }
      doc.rect(START_X, currentY, TOTAL_WIDTH, ROW_HEIGHT).lineWidth(0.5).stroke(COLORS.border);

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

      let curX = START_X;
      for (let i = 0; i < COLS.length; i++) {
        doc.moveTo(curX, currentY).lineTo(curX, currentY + ROW_HEIGHT).stroke(COLORS.border);
        const val = rowValues[i];
        doc.font('Helvetica').fontSize(7.5).fillColor(COLORS.text)
          .text(val.text, curX + 2, currentY + 4, {
            width: COLS[i].width - 4,
            align: val.align,
            ellipsis: true,
          });
        curX += COLS[i].width;
      }
      doc.moveTo(START_X + TOTAL_WIDTH, currentY).lineTo(START_X + TOTAL_WIDTH, currentY + ROW_HEIGHT).stroke(COLORS.border);
      currentY += ROW_HEIGHT;
    }

    if (currentY + ROW_HEIGHT + 24 > MAX_Y) {
      doc.addPage({ size: 'A4', layout: 'landscape', margins: { top: 30, bottom: 30, left: 30, right: 30 } });
      currentY = drawTableHeader(doc, 30);
    }

    doc.rect(START_X, currentY, TOTAL_WIDTH, ROW_HEIGHT + 2).fill(COLORS.headerBg);
    doc.rect(START_X, currentY, TOTAL_WIDTH, ROW_HEIGHT + 2).lineWidth(1).stroke(COLORS.border);

    const totValues = [
      { text: 'Total', align: 'center' },
      { text: '', align: 'center' },
      { text: fmtNumZero(totOpen), align: 'right' },
      { text: fmtNumZero(totNew), align: 'right' },
      { text: fmtNumZero(totSales), align: 'right' },
      { text: fmtNumZero(totRec), align: 'right' },
      { text: fmtNumZero(totClose), align: 'right' },
      { text: fmtNumZero(totCash), align: 'right' },
      { text: fmtNumZero(totCheque), align: 'right' },
      { text: fmtNumZero(totRtgs), align: 'right' },
      { text: fmtNumZero(totAuto), align: 'right' },
      { text: fmtNumZero(totCredit), align: 'right' },
      { text: '', align: 'left' },
      { text: '', align: 'left' },
    ];

    let curX = START_X;
    for (let i = 0; i < COLS.length; i++) {
      doc.moveTo(curX, currentY).lineTo(curX, currentY + ROW_HEIGHT + 2).stroke(COLORS.border);
      const val = totValues[i];
      if (val.text) {
        doc.font('Helvetica-Bold').fontSize(7.5).fillColor(COLORS.text)
          .text(val.text, curX + 2, currentY + 5, {
            width: COLS[i].width - 4,
            align: val.align,
          });
      }
      curX += COLS[i].width;
    }
    doc.moveTo(START_X + TOTAL_WIDTH, currentY).lineTo(START_X + TOTAL_WIDTH, currentY + ROW_HEIGHT + 2).stroke(COLORS.border);

    const printDate = new Date();
    const pad = (n) => String(n).padStart(2, '0');
    doc.font('Helvetica').fontSize(8).fillColor(COLORS.subText)
      .text(
        `Printed on: ${pad(printDate.getDate())}/${pad(printDate.getMonth() + 1)}/${printDate.getFullYear()} at ${pad(printDate.getHours())}:${pad(printDate.getMinutes())} · Powered by FDHS Solutions`,
        START_X,
        currentY + ROW_HEIGHT + 8,
        { align: 'right', width: TOTAL_WIDTH }
      );

    doc.end();
  },
};
