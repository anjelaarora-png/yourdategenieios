import { ChevronLeft, HelpCircle } from "lucide-react";

interface MobileHelpScreenProps {
  onBack: () => void;
}

const MobileHelpScreen = ({ onBack }: MobileHelpScreenProps) => (
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
      <h1 className="text-lg font-semibold">Help & FAQ</h1>
    </header>
    <div className="px-5 py-6">
      <div className="flex flex-col items-center justify-center py-12 text-center">
        <div className="w-16 h-16 rounded-full bg-muted flex items-center justify-center mb-4">
          <HelpCircle className="w-8 h-8 text-muted-foreground" />
        </div>
        <p className="text-muted-foreground text-sm mb-6">
          How-to guides and frequently asked questions will appear here.
        </p>
        <p className="text-xs text-muted-foreground">
          Need support? Contact us at support@yourdategenie.com
        </p>
      </div>
    </div>
  </div>
);

export default MobileHelpScreen;
