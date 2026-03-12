import { ChevronLeft } from "lucide-react";

interface MobileSettingsScreenProps {
  onBack: () => void;
}

const MobileSettingsScreen = ({ onBack }: MobileSettingsScreenProps) => (
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
      <h1 className="text-lg font-semibold">Settings</h1>
    </header>
    <div className="px-5 py-6">
      <p className="text-muted-foreground text-sm mb-6">
        Notifications, appearance, subscription, and privacy options will appear here.
      </p>
      <div className="ios-list">
        <div className="ios-list-item">
          <span className="font-medium">Notifications</span>
          <span className="text-xs text-muted-foreground">Reminders & alerts</span>
        </div>
        <div className="ios-list-item">
          <span className="font-medium">Appearance</span>
          <span className="text-xs text-muted-foreground">Theme</span>
        </div>
        <div className="ios-list-item">
          <span className="font-medium">Subscription</span>
          <span className="text-xs text-muted-foreground">Free plan</span>
        </div>
        <div className="ios-list-item">
          <span className="font-medium">Privacy & Security</span>
          <span className="text-xs text-muted-foreground">Data and security</span>
        </div>
      </div>
    </div>
  </div>
);

export default MobileSettingsScreen;
