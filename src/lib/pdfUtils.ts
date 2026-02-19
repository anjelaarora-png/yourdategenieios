import jsPDF from 'jspdf';
import { DatePlan } from "@/types/datePlan";

// Brand Colors (converted from HSL to RGB)
const COLORS = {
  maroon: { r: 46, g: 15, b: 26 },        // Deep maroon background
  maroonDark: { r: 35, g: 12, b: 20 },    // Darker maroon
  gold: { r: 218, g: 165, b: 32 },        // Gold primary
  goldDark: { r: 176, g: 126, b: 28 },    // Darker gold
  cream: { r: 244, g: 240, b: 232 },      // Cream accent
  creamDark: { r: 226, g: 218, b: 204 },  // Darker cream
  white: { r: 255, g: 255, b: 255 },
  textDark: { r: 46, g: 15, b: 26 },      // Dark text on light
  textLight: { r: 244, g: 240, b: 232 },  // Light text on dark
  mutedText: { r: 120, g: 100, b: 90 },   // Muted text
};

/**
 * Generate and download a beautifully branded PDF of the date plan
 */
export async function generatePDF(plan: DatePlan): Promise<void> {
  const doc = new jsPDF();
  const pageWidth = doc.internal.pageSize.getWidth();
  const pageHeight = doc.internal.pageSize.getHeight();
  const margin = 20;
  const contentWidth = pageWidth - margin * 2;
  let y = 0;

  // Helper to add new page with header
  const addNewPage = () => {
    doc.addPage();
    drawPageBackground();
    y = 30;
  };

  // Helper to check and add new page if needed
  const checkNewPage = (neededHeight: number) => {
    if (y + neededHeight > pageHeight - 35) {
      addNewPage();
    }
  };

  // Draw elegant page background
  const drawPageBackground = () => {
    // Cream background
    doc.setFillColor(COLORS.cream.r, COLORS.cream.g, COLORS.cream.b);
    doc.rect(0, 0, pageWidth, pageHeight, 'F');
    
    // Maroon header bar
    doc.setFillColor(COLORS.maroon.r, COLORS.maroon.g, COLORS.maroon.b);
    doc.rect(0, 0, pageWidth, 12, 'F');
    
    // Gold accent line under header
    doc.setDrawColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
    doc.setLineWidth(1);
    doc.line(0, 12, pageWidth, 12);
    
    // Maroon footer bar
    doc.setFillColor(COLORS.maroon.r, COLORS.maroon.g, COLORS.maroon.b);
    doc.rect(0, pageHeight - 15, pageWidth, 15, 'F');
    
    // Gold accent line above footer
    doc.line(0, pageHeight - 15, pageWidth, pageHeight - 15);
    
    // Footer text
    doc.setFontSize(8);
    doc.setFont('helvetica', 'italic');
    doc.setTextColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
    doc.text('Created with Your Date Genie', pageWidth / 2, pageHeight - 6, { align: 'center' });
  };

  // Draw decorative gold corner flourish
  const drawCornerAccent = (x: number, y: number, size: number, flip: boolean = false) => {
    doc.setDrawColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
    doc.setLineWidth(0.5);
    const dir = flip ? -1 : 1;
    // Simple elegant corner
    doc.line(x, y, x + (size * dir), y);
    doc.line(x, y, x, y + size);
  };

  // ==================== COVER PAGE ====================
  drawPageBackground();
  
  // Large maroon title section
  doc.setFillColor(COLORS.maroon.r, COLORS.maroon.g, COLORS.maroon.b);
  doc.roundedRect(margin - 5, 25, contentWidth + 10, 75, 3, 3, 'F');
  
  // Gold border around title section
  doc.setDrawColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
  doc.setLineWidth(1.5);
  doc.roundedRect(margin - 5, 25, contentWidth + 10, 75, 3, 3, 'S');
  
  // Corner accents
  drawCornerAccent(margin - 2, 28, 8);
  drawCornerAccent(pageWidth - margin + 2, 28, 8, true);
  drawCornerAccent(margin - 2, 97, 8);
  drawCornerAccent(pageWidth - margin + 2, 97, 8, true);
  
  // Title
  y = 50;
  doc.setFontSize(28);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
  const titleLines = doc.splitTextToSize(plan.title, contentWidth - 10);
  doc.text(titleLines, pageWidth / 2, y, { align: 'center' });
  y += titleLines.length * 12;
  
  // Gold divider line
  doc.setDrawColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
  doc.setLineWidth(0.5);
  doc.line(margin + 30, y, pageWidth - margin - 30, y);
  y += 10;
  
  // Tagline
  doc.setFontSize(13);
  doc.setFont('helvetica', 'italic');
  doc.setTextColor(COLORS.cream.r, COLORS.cream.g, COLORS.cream.b);
  const taglineLines = doc.splitTextToSize(plan.tagline, contentWidth - 20);
  doc.text(taglineLines, pageWidth / 2, y, { align: 'center' });
  
  // Info cards section
  y = 120;
  
  // Duration card
  const cardWidth = (contentWidth - 10) / 2;
  doc.setFillColor(COLORS.maroon.r, COLORS.maroon.g, COLORS.maroon.b);
  doc.roundedRect(margin, y, cardWidth, 35, 2, 2, 'F');
  doc.setDrawColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
  doc.setLineWidth(0.5);
  doc.roundedRect(margin, y, cardWidth, 35, 2, 2, 'S');
  
  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
  doc.text('DURATION', margin + cardWidth / 2, y + 12, { align: 'center' });
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(COLORS.cream.r, COLORS.cream.g, COLORS.cream.b);
  doc.text(plan.totalDuration, margin + cardWidth / 2, y + 26, { align: 'center' });
  
  // Cost card
  doc.setFillColor(COLORS.maroon.r, COLORS.maroon.g, COLORS.maroon.b);
  doc.roundedRect(margin + cardWidth + 10, y, cardWidth, 35, 2, 2, 'F');
  doc.setDrawColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
  doc.roundedRect(margin + cardWidth + 10, y, cardWidth, 35, 2, 2, 'S');
  
  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
  doc.text('ESTIMATED COST', margin + cardWidth + 10 + cardWidth / 2, y + 12, { align: 'center' });
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(COLORS.cream.r, COLORS.cream.g, COLORS.cream.b);
  doc.text(plan.estimatedCost, margin + cardWidth + 10 + cardWidth / 2, y + 26, { align: 'center' });
  
  // Stops overview
  y = 175;
  doc.setFontSize(11);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(COLORS.textDark.r, COLORS.textDark.g, COLORS.textDark.b);
  doc.text(`${plan.stops.length} carefully curated experiences await you`, pageWidth / 2, y, { align: 'center' });
  
  // ==================== ITINERARY PAGE(S) ====================
  addNewPage();
  
  // Section header
  const drawSectionHeader = (title: string) => {
    doc.setFillColor(COLORS.maroon.r, COLORS.maroon.g, COLORS.maroon.b);
    doc.roundedRect(margin, y, contentWidth, 18, 2, 2, 'F');
    doc.setDrawColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
    doc.setLineWidth(0.8);
    doc.roundedRect(margin, y, contentWidth, 18, 2, 2, 'S');
    
    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
    doc.text(title, margin + 10, y + 12);
    y += 28;
  };
  
  drawSectionHeader('YOUR ITINERARY');
  
  // Stops
  for (let i = 0; i < plan.stops.length; i++) {
    const stop = plan.stops[i];
    checkNewPage(85);
    
    // Stop card container
    const cardStartY = y;
    
    // Step number circle
    doc.setFillColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
    doc.circle(margin + 8, y + 8, 8, 'F');
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(COLORS.maroon.r, COLORS.maroon.g, COLORS.maroon.b);
    doc.text(String(stop.order), margin + 8, y + 11, { align: 'center' });
    
    // Stop name
    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(COLORS.maroon.r, COLORS.maroon.g, COLORS.maroon.b);
    doc.text(stop.name, margin + 22, y + 10);
    y += 6;
    
    // Time and venue type badge
    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(COLORS.mutedText.r, COLORS.mutedText.g, COLORS.mutedText.b);
    doc.text(`${stop.timeSlot} | ${stop.duration} | ${stop.venueType}${stop.validated ? ' (Verified)' : ''}`, margin + 22, y + 10);
    y += 8;
    
    // Address
    if (stop.address) {
      doc.setFontSize(9);
      doc.setTextColor(COLORS.textDark.r, COLORS.textDark.g, COLORS.textDark.b);
      const addressLines = doc.splitTextToSize(`Location: ${stop.address}`, contentWidth - 25);
      doc.text(addressLines, margin + 22, y + 8);
      y += addressLines.length * 4 + 4;
    }
    
    // Description
    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(COLORS.textDark.r, COLORS.textDark.g, COLORS.textDark.b);
    const descLines = doc.splitTextToSize(stop.description, contentWidth - 25);
    checkNewPage(descLines.length * 5 + 20);
    doc.text(descLines, margin + 22, y + 8);
    y += descLines.length * 5 + 6;
    
    // Why it fits - in a subtle box
    doc.setFillColor(COLORS.creamDark.r, COLORS.creamDark.g, COLORS.creamDark.b);
    const whyLines = doc.splitTextToSize(`Why it fits: ${stop.whyItFits}`, contentWidth - 35);
    const whyBoxHeight = whyLines.length * 4 + 8;
    checkNewPage(whyBoxHeight + 20);
    doc.roundedRect(margin + 20, y + 2, contentWidth - 22, whyBoxHeight, 2, 2, 'F');
    doc.setFontSize(9);
    doc.setFont('helvetica', 'italic');
    doc.setTextColor(COLORS.mutedText.r, COLORS.mutedText.g, COLORS.mutedText.b);
    doc.text(whyLines, margin + 25, y + 8);
    y += whyBoxHeight + 4;
    
    // Romantic tip - gold accent
    doc.setDrawColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
    doc.setLineWidth(2);
    const tipLines = doc.splitTextToSize('Tip: ' + stop.romanticTip, contentWidth - 35);
    checkNewPage(tipLines.length * 4 + 15);
    doc.line(margin + 22, y + 4, margin + 22, y + 4 + tipLines.length * 4 + 4);
    doc.setFontSize(9);
    doc.setFont('helvetica', 'italic');
    doc.setTextColor(COLORS.goldDark.r, COLORS.goldDark.g, COLORS.goldDark.b);
    doc.text(tipLines[0], margin + 28, y + 8);
    if (tipLines.length > 1) {
      for (let j = 1; j < tipLines.length; j++) {
        doc.text(tipLines[j], margin + 28, y + 8 + j * 4);
      }
    }
    y += tipLines.length * 4 + 12;
    
    // Divider between stops (except last)
    if (i < plan.stops.length - 1) {
      doc.setDrawColor(COLORS.creamDark.r, COLORS.creamDark.g, COLORS.creamDark.b);
      doc.setLineWidth(0.5);
      doc.line(margin + 20, y, pageWidth - margin - 20, y);
      y += 10;
    }
  }
  
  // ==================== GENIE'S SECRET TOUCH ====================
  if (plan.genieSecretTouch) {
    checkNewPage(60);
    y += 10;
    
    drawSectionHeader("GENIE'S SECRET TOUCH");
    
    // Special box for secret touch
    doc.setFillColor(COLORS.maroon.r, COLORS.maroon.g, COLORS.maroon.b);
    const secretLines = doc.splitTextToSize(plan.genieSecretTouch.description, contentWidth - 30);
    const secretBoxHeight = secretLines.length * 5 + 30;
    checkNewPage(secretBoxHeight);
    doc.roundedRect(margin, y, contentWidth, secretBoxHeight, 3, 3, 'F');
    doc.setDrawColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
    doc.setLineWidth(1);
    doc.roundedRect(margin, y, contentWidth, secretBoxHeight, 3, 3, 'S');
    
    doc.setFontSize(13);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
    doc.text(plan.genieSecretTouch.title, margin + 15, y + 15);
    
    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(COLORS.cream.r, COLORS.cream.g, COLORS.cream.b);
    doc.text(secretLines, margin + 15, y + 25);
    
    y += secretBoxHeight + 15;
  }
  
  // ==================== PACKING LIST ====================
  if (plan.packingList && plan.packingList.length > 0) {
    checkNewPage(40 + plan.packingList.length * 7);
    
    drawSectionHeader('WHAT TO BRING');
    
    // Packing items in elegant list
    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(COLORS.textDark.r, COLORS.textDark.g, COLORS.textDark.b);
    
    for (const item of plan.packingList) {
      checkNewPage(8);
      // Gold bullet
      doc.setFillColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
      doc.circle(margin + 8, y + 1, 2, 'F');
      doc.text(item, margin + 15, y + 3);
      y += 8;
    }
    y += 10;
  }
  
  // ==================== WEATHER NOTE ====================
  if (plan.weatherNote) {
    checkNewPage(30);
    
    doc.setFillColor(COLORS.creamDark.r, COLORS.creamDark.g, COLORS.creamDark.b);
    const weatherLines = doc.splitTextToSize('Weather: ' + plan.weatherNote, contentWidth - 20);
    const weatherBoxHeight = weatherLines.length * 5 + 12;
    doc.roundedRect(margin, y, contentWidth, weatherBoxHeight, 2, 2, 'F');
    
    doc.setFontSize(10);
    doc.setFont('helvetica', 'italic');
    doc.setTextColor(COLORS.mutedText.r, COLORS.mutedText.g, COLORS.mutedText.b);
    doc.text(weatherLines[0], margin + 10, y + 10);
    if (weatherLines.length > 1) {
      for (let i = 1; i < weatherLines.length; i++) {
        doc.text(weatherLines[i], margin + 10, y + 10 + i * 5);
      }
    }
    y += weatherBoxHeight + 10;
  }
  
  // ==================== CONVERSATION STARTERS (if available) ====================
  if (plan.conversationStarters && plan.conversationStarters.length > 0) {
    checkNewPage(50);
    
    drawSectionHeader('CONVERSATION STARTERS');
    
    for (const starter of plan.conversationStarters) {
      checkNewPage(25);
      
      doc.setFillColor(COLORS.creamDark.r, COLORS.creamDark.g, COLORS.creamDark.b);
      const questionLines = doc.splitTextToSize(starter.question, contentWidth - 30);
      const starterBoxHeight = questionLines.length * 5 + 14;
      doc.roundedRect(margin + 5, y, contentWidth - 10, starterBoxHeight, 2, 2, 'F');
      
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(COLORS.textDark.r, COLORS.textDark.g, COLORS.textDark.b);
      doc.text(questionLines[0], margin + 12, y + 10);
      if (questionLines.length > 1) {
        for (let i = 1; i < questionLines.length; i++) {
          doc.text(questionLines[i], margin + 12, y + 10 + i * 5);
        }
      }
      
      y += starterBoxHeight + 6;
    }
    y += 5;
  }
  
  // ==================== GIFT SUGGESTIONS (if available) ====================
  if (plan.giftSuggestions && plan.giftSuggestions.length > 0) {
    checkNewPage(50);
    
    drawSectionHeader('GIFT IDEAS');
    
    for (const gift of plan.giftSuggestions) {
      checkNewPage(40);
      
      doc.setFillColor(COLORS.creamDark.r, COLORS.creamDark.g, COLORS.creamDark.b);
      const giftDescLines = doc.splitTextToSize(gift.description, contentWidth - 35);
      const giftBoxHeight = giftDescLines.length * 4 + 25;
      doc.roundedRect(margin + 5, y, contentWidth - 10, giftBoxHeight, 2, 2, 'F');
      
      // Gift name
      doc.setFontSize(11);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(COLORS.maroon.r, COLORS.maroon.g, COLORS.maroon.b);
      doc.text(gift.name, margin + 12, y + 10);
      
      // Price range
      doc.setFontSize(9);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(COLORS.gold.r, COLORS.gold.g, COLORS.gold.b);
      doc.text(gift.priceRange, margin + 12, y + 18);
      
      // Description
      doc.setFontSize(9);
      doc.setTextColor(COLORS.textDark.r, COLORS.textDark.g, COLORS.textDark.b);
      doc.text(giftDescLines, margin + 12, y + 26);
      
      y += giftBoxHeight + 6;
    }
  }

  // Save the PDF
  const filename = `date-plan-${plan.title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/-+/g, '-').replace(/^-|-$/g, '')}.pdf`;
  doc.save(filename);
}
