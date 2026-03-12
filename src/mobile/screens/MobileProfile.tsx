import { useState } from "react";
import { User, Settings, Heart, Bell, Moon, HelpCircle, LogOut, ChevronRight, Shield, Star, CreditCard, Share2 } from "lucide-react";
import { useAuth } from "@/hooks/useAuth";
import { useDatePlans } from "@/hooks/useDatePlans";
import logo from "@/assets/logo.png";

interface MobileProfileProps {
  onNavigate: (screen: string) => void;
}

const MobileProfile = ({ onNavigate }: MobileProfileProps) => {
  const { user, signOut } = useAuth();
  const { plans } = useDatePlans();
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

  const firstName = user?.email?.split("@")[0] || "User";
  const completedDates = plans.filter((p) => p.status === "completed").length;
  const totalDates = plans.length;

  const handleLogout = async () => {
    await signOut();
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="px-5 pt-14 pb-6">
        <div className="flex flex-col items-center">
          {/* Avatar */}
          <div className="w-24 h-24 rounded-full bg-gradient-to-br from-primary/20 to-primary/10 flex items-center justify-center mb-4 border-4 border-background shadow-lg">
            <span className="text-4xl font-bold text-primary">
              {firstName.charAt(0).toUpperCase()}
            </span>
          </div>

          <h1 className="text-[2.5rem] font-bold font-tangerine mb-1 text-primary">
            {firstName.charAt(0).toUpperCase() + firstName.slice(1)}
          </h1>
          <p className="text-muted-foreground text-sm">{user?.email}</p>

          {/* Stats */}
          <div className="flex items-center gap-8 mt-6">
            <div className="text-center">
              <p className="text-2xl font-bold text-primary">{totalDates}</p>
              <p className="text-xs text-muted-foreground">Date Plans</p>
            </div>
            <div className="w-px h-10 bg-border" />
            <div className="text-center">
              <p className="text-2xl font-bold text-green-500">{completedDates}</p>
              <p className="text-xs text-muted-foreground">Completed</p>
            </div>
            <div className="w-px h-10 bg-border" />
            <div className="text-center">
              <p className="text-2xl font-bold text-amber-500">
                {completedDates > 0 ? Math.round((completedDates / Math.max(totalDates, 1)) * 100) : 0}%
              </p>
              <p className="text-xs text-muted-foreground">Success</p>
            </div>
          </div>
        </div>
      </div>

      {/* Menu sections */}
      <div className="px-5 space-y-6">
        {/* Preferences Section */}
        <div>
          <h3 className="section-header">Preferences</h3>
          <div className="ios-list">
            <MenuItem
              icon={<Heart className="w-5 h-5 text-rose-500" />}
              label="Date Preferences"
              description="Your default settings"
              onClick={() => onNavigate("preferences")}
            />
            <MenuItem
              icon={<Bell className="w-5 h-5 text-blue-500" />}
              label="Notifications"
              description="Reminders & alerts"
              onClick={() => onNavigate("notifications")}
            />
            <MenuItem
              icon={<Moon className="w-5 h-5 text-purple-500" />}
              label="Appearance"
              description="Dark mode, themes"
              onClick={() => onNavigate("settings")}
            />
          </div>
        </div>

        {/* Account Section */}
        <div>
          <h3 className="section-header">Account</h3>
          <div className="ios-list">
            <MenuItem
              icon={<CreditCard className="w-5 h-5 text-green-500" />}
              label="Subscription"
              description="Free plan"
              badge="Upgrade"
              onClick={() => onNavigate("settings")}
            />
            <MenuItem
              icon={<Shield className="w-5 h-5 text-amber-500" />}
              label="Privacy & Security"
              onClick={() => onNavigate("settings")}
            />
            <MenuItem
              icon={<User className="w-5 h-5 text-gray-500" />}
              label="Account Settings"
              onClick={() => onNavigate("settings")}
            />
          </div>
        </div>

        {/* Support Section */}
        <div>
          <h3 className="section-header">Support</h3>
          <div className="ios-list">
            <MenuItem
              icon={<Star className="w-5 h-5 text-amber-500" />}
              label="Rate the App"
              onClick={() => onNavigate("help")}
            />
            <MenuItem
              icon={<Share2 className="w-5 h-5 text-blue-500" />}
              label="Share with Friends"
              onClick={() => {
                if (typeof navigator !== "undefined" && navigator.share) {
                  navigator.share({
                    title: "Your Date Genie",
                    text: "Plan magical dates in seconds with Your Date Genie!",
                    url: window.location.origin,
                  }).catch(() => {});
                } else {
                  navigator.clipboard?.writeText(window.location.origin);
                }
              }}
            />
            <MenuItem
              icon={<HelpCircle className="w-5 h-5 text-green-500" />}
              label="Help & FAQ"
              onClick={() => onNavigate("help")}
            />
          </div>
        </div>

        {/* Logout */}
        <button
          onClick={() => setShowLogoutConfirm(true)}
          className="w-full ios-list"
        >
          <div className="ios-list-item text-red-500">
            <div className="flex items-center gap-3">
              <LogOut className="w-5 h-5" />
              <span className="font-medium">Sign Out</span>
            </div>
          </div>
        </button>

        {/* App info */}
        <div className="text-center pt-4 pb-8">
          <img src={logo} alt="Your Date Genie" className="h-8 w-auto mx-auto mb-2 opacity-50" />
          <p className="text-xs text-muted-foreground">Version 1.0.0</p>
        </div>
      </div>

      {/* Logout confirmation sheet */}
      {showLogoutConfirm && (
        <>
          <div className="ios-sheet-backdrop" onClick={() => setShowLogoutConfirm(false)} />
          <div className="ios-sheet text-center">
            <div className="swipe-indicator" />
            <h3 className="text-lg font-semibold mb-2">Sign Out?</h3>
            <p className="text-muted-foreground text-sm mb-6">
              You'll need to sign in again to access your date plans.
            </p>
            <div className="space-y-3">
              <button
                onClick={handleLogout}
                className="ios-button w-full bg-red-500 text-white"
              >
                Sign Out
              </button>
              <button
                onClick={() => setShowLogoutConfirm(false)}
                className="ios-button ios-button-secondary w-full"
              >
                Cancel
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
};

interface MenuItemProps {
  icon: React.ReactNode;
  label: string;
  description?: string;
  badge?: string;
  onClick: () => void;
}

const MenuItem = ({ icon, label, description, badge, onClick }: MenuItemProps) => (
  <button onClick={onClick} className="ios-list-item w-full haptic-button">
    <div className="flex items-center gap-3">
      {icon}
      <div className="text-left">
        <p className="font-medium">{label}</p>
        {description && <p className="text-xs text-muted-foreground">{description}</p>}
      </div>
    </div>
    <div className="flex items-center gap-2">
      {badge && (
        <span className="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full font-medium">
          {badge}
        </span>
      )}
      <ChevronRight className="w-5 h-5 text-muted-foreground" />
    </div>
  </button>
);

export default MobileProfile;
