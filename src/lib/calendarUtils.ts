import { DatePlan } from "@/types/datePlan";

/**
 * Generate a Google Calendar URL for the date plan
 */
export function generateGoogleCalendarUrl(plan: DatePlan, scheduledDate?: string, startTime?: string): string {
  const title = encodeURIComponent(plan.title);
  const description = encodeURIComponent(formatPlanDescription(plan));
  
  // Calculate start and end times
  const { startDateTime, endDateTime } = calculateEventTimes(plan, scheduledDate, startTime);
  
  // Get location from first stop
  const firstStop = plan.stops?.[0];
  const location = firstStop?.address 
    ? encodeURIComponent(firstStop.address)
    : firstStop?.name 
      ? encodeURIComponent(firstStop.name)
      : '';
  
  return `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${title}&dates=${startDateTime}/${endDateTime}&details=${description}&location=${location}`;
}

/**
 * Generate an iCal (.ics) file content for Apple Calendar
 */
export function generateICSContent(plan: DatePlan, scheduledDate?: string, startTime?: string): string {
  const { startDateTime, endDateTime } = calculateEventTimes(plan, scheduledDate, startTime);
  
  const firstStop = plan.stops?.[0];
  const location = firstStop?.address || firstStop?.name || '';
  const description = formatPlanDescription(plan).replace(/\n/g, '\\n');
  
  const icsContent = `BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Your Date Genie//Date Plan//EN
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VEVENT
DTSTART:${startDateTime}
DTEND:${endDateTime}
DTSTAMP:${formatICSDate(new Date())}
UID:${generateUID()}
SUMMARY:${plan.title}
DESCRIPTION:${description}
LOCATION:${location}
STATUS:CONFIRMED
BEGIN:VALARM
ACTION:DISPLAY
DESCRIPTION:Date reminder
TRIGGER:-PT1H
END:VALARM
END:VEVENT
END:VCALENDAR`;

  return icsContent;
}

/**
 * Download ICS file
 */
export function downloadICSFile(plan: DatePlan, scheduledDate?: string, startTime?: string): void {
  const icsContent = generateICSContent(plan, scheduledDate, startTime);
  const blob = new Blob([icsContent], { type: 'text/calendar;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `date-plan-${plan.title.toLowerCase().replace(/\s+/g, '-')}.ics`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

/**
 * Calculate event start and end times
 */
function calculateEventTimes(plan: DatePlan, scheduledDate?: string, startTime?: string): { startDateTime: string; endDateTime: string } {
  // Default to tomorrow if no date provided
  let startDate = new Date();
  startDate.setDate(startDate.getDate() + 1);
  
  if (scheduledDate) {
    startDate = new Date(scheduledDate);
  }
  
  // Set start time (default to 6:00 PM)
  if (startTime) {
    const [hours, minutes] = startTime.split(':').map(Number);
    startDate.setHours(hours, minutes, 0, 0);
  } else {
    startDate.setHours(18, 0, 0, 0);
  }
  
  // Calculate end time based on total duration
  const durationMatch = plan.totalDuration?.match(/(\d+)/);
  const durationHours = durationMatch ? parseInt(durationMatch[1]) : 4;
  
  const endDate = new Date(startDate);
  endDate.setHours(endDate.getHours() + durationHours);
  
  return {
    startDateTime: formatGoogleDate(startDate),
    endDateTime: formatGoogleDate(endDate),
  };
}

/**
 * Format date for Google Calendar (YYYYMMDDTHHmmssZ)
 */
function formatGoogleDate(date: Date): string {
  return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
}

/**
 * Format date for ICS file
 */
function formatICSDate(date: Date): string {
  return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
}

/**
 * Generate a unique ID for the calendar event
 */
function generateUID(): string {
  return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}@yourdategenie.com`;
}

/**
 * Format plan description for calendar
 */
function formatPlanDescription(plan: DatePlan): string {
  let description = `${plan.tagline}\n\n`;
  description += `Duration: ${plan.totalDuration}\n`;
  description += `Estimated Cost: ${plan.estimatedCost}\n\n`;
  description += `--- ITINERARY ---\n\n`;
  
  (plan.stops ?? []).forEach((stop) => {
    description += `${stop.order}. ${stop.emoji} ${stop.name}\n`;
    description += `   Time: ${stop.timeSlot} (${stop.duration})\n`;
    if (stop.address) {
      description += `   📍 ${stop.address}\n`;
    }
    description += `\n`;
  });
  
  if (plan.genieSecretTouch) {
    description += `\n--- GENIE'S SECRET TOUCH ---\n`;
    description += `${plan.genieSecretTouch.emoji} ${plan.genieSecretTouch.title}\n`;
    description += `${plan.genieSecretTouch.description}\n`;
  }
  
  if (plan.packingList?.length > 0) {
    description += `\n--- WHAT TO BRING ---\n`;
    plan.packingList.forEach((item) => {
      description += `• ${item}\n`;
    });
  }
  
  description += `\nCreated with Your Date Genie ✨`;
  
  return description;
}
