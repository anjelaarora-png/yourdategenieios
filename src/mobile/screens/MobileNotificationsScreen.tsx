import { ChevronLeft, Bell } from "lucide-react";

interface MobileNotificationsScreenProps {
  onBack: () => void;
}

const MobileNotificationsScreen = ({ onBack }: MobileNotificationsScreenProps) => (
  <div className="min-h-screen bg-background pb-24">
    <header className="sticky top-0 z-10 bg-background/95 backdrop-blur border-b px-4 py-3 flex items-center gap-3">
      <button
        type="button"
        onClick={onBack}
        className="p-2 -ml-2 rounded-full hover:bg-muted haptic-button"
        aria-label="Back to profile"
      >
        <ChevronLeft className="w-6 h-6" />
      </button>
      <h1 className="text-lg font-semibold">Notifications</h1>
    </header>
    <div className="px-5 py-6">
      <div className="flex flex-col items-center justify-center py-12 text-center">
        <div className="w-16 h-16 rounded-full bg-muted flex items-center justify-center mb-4">
          <Bell className="w-8 h-8 text-muted-foreground" />
        </div>
        <p className="text-muted-foreground text-sm">
          Manage reminders and date alerts here. More options coming soon.
        </p>
      </div>
    </div>
  </div>
);

export default MobileNotificationsScreen;
