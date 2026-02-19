import { cn } from "@/lib/utils";

interface OptionCardProps {
  selected: boolean;
  onClick: () => void;
  emoji?: string;
  label: string;
  description?: string;
  compact?: boolean;
}

const OptionCard = ({
  selected,
  onClick,
  emoji,
  label,
  description,
  compact = false,
}: OptionCardProps) => {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "group relative rounded-xl border-2 transition-all duration-200 text-left w-full h-full",
        compact ? "p-2.5 sm:p-3" : "p-3 sm:p-4",
        selected
          ? "border-primary bg-primary/10 shadow-lg shadow-primary/20"
          : "border-border bg-card hover:border-primary/50 hover:bg-primary/5"
      )}
    >
      <div className="flex items-start gap-2 sm:gap-3">
        {emoji && (
          <span className={cn("text-lg sm:text-2xl flex-shrink-0 mt-0.5", compact && "text-base sm:text-xl")}>{emoji}</span>
        )}
        <div className="flex-1 min-w-0">
          <p
            className={cn(
              "font-medium text-xs sm:text-sm leading-tight break-words hyphens-auto",
              selected ? "text-primary" : "text-foreground"
            )}
          >
            {label}
          </p>
          {description && (
            <p className="text-[10px] sm:text-xs text-muted-foreground leading-tight mt-0.5 break-words hyphens-auto line-clamp-2">{description}</p>
          )}
        </div>
        {selected && (
          <div className="w-4 h-4 sm:w-5 sm:h-5 rounded-full gradient-gold flex items-center justify-center flex-shrink-0 mt-0.5">
            <svg
              className="w-2.5 h-2.5 sm:w-3 sm:h-3 text-primary-foreground"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={3}
                d="M5 13l4 4L19 7"
              />
            </svg>
          </div>
        )}
      </div>
    </button>
  );
};

export default OptionCard;
