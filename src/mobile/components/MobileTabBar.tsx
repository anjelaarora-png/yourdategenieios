import { Home, History, Plus, Music, User } from "lucide-react";
import { TabId } from "../MobileApp";

interface MobileTabBarProps {
  activeTab: TabId;
  onTabChange: (tab: TabId) => void;
}

const tabs: { id: TabId; icon: typeof Home; label: string }[] = [
  { id: "home", icon: Home, label: "Home" },
  { id: "history", icon: History, label: "History" },
  { id: "create", icon: Plus, label: "Create" },
  { id: "music", icon: Music, label: "Playlists" },
  { id: "profile", icon: User, label: "Profile" },
];

const MobileTabBar = ({ activeTab, onTabChange }: MobileTabBarProps) => {
  return (
    <nav className="mobile-tab-bar">
      {tabs.map((tab) => {
        const Icon = tab.icon;
        const isCreate = tab.id === "create";
        const isActive = activeTab === tab.id;

        if (isCreate) {
          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className="tab-create haptic-button"
              aria-label="Create new date plan"
            >
              <div className="tab-create-button">
                <Plus className="w-7 h-7 text-primary-foreground" strokeWidth={2.5} />
              </div>
            </button>
          );
        }

        return (
          <button
            key={tab.id}
            onClick={() => onTabChange(tab.id)}
            className={`tab-item haptic-button ${isActive ? "active" : ""}`}
            aria-label={tab.label}
          >
            <Icon className="tab-icon" strokeWidth={isActive ? 2.5 : 2} />
            <span className="tab-label">{tab.label}</span>
          </button>
        );
      })}
    </nav>
  );
};

export default MobileTabBar;
