import { QuestionnaireData, RELATIONSHIP_STAGES, PARTNER_INTERESTS, GIFT_BUDGETS, CONVERSATION_TOPICS, GIFT_RECIPIENTS, LOVE_LANGUAGES, isSoloDate } from "../types";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import OptionCard from "../OptionCard";
import { Gift, MessageCircle, Heart, Sparkles } from "lucide-react";

interface Step6EnhancersProps {
  data: QuestionnaireData;
  onChange: (updates: Partial<QuestionnaireData>) => void;
}

const Step6Enhancers = ({ data, onChange }: Step6EnhancersProps) => {
  const isSolo = isSoloDate(data.dateType);

  const toggleInterest = (value: string) => {
    const current = data.partnerInterests || [];
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    onChange({ partnerInterests: updated });
  };

  const toggleTopic = (value: string) => {
    const current = data.conversationTopics || [];
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    onChange({ conversationTopics: updated });
  };

  const toggleUserLoveLanguage = (value: string) => {
    const current = data.userLoveLanguages || [];
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    onChange({ userLoveLanguages: updated });
  };

  const togglePartnerLoveLanguage = (value: string) => {
    const current = data.partnerLoveLanguages || [];
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    onChange({ partnerLoveLanguages: updated });
  };

  // Filter gift recipients for solo dates (only "myself" option)
  const filteredGiftRecipients = isSolo 
    ? GIFT_RECIPIENTS.filter(r => r.value === "myself")
    : GIFT_RECIPIENTS;

  return (
    <div className="space-y-6">
      <div className="text-center mb-4">
        <h2 className="font-display text-xl sm:text-2xl mb-2 flex items-center justify-center gap-2">
          {isSolo ? (
            <Sparkles className="w-5 h-5 text-primary" />
          ) : (
            <Heart className="w-5 h-5 text-primary" />
          )}
          {isSolo ? "Enhance Your Solo Experience" : "Deepen Your Connection"}
        </h2>
        <p className="text-sm text-muted-foreground">
          {isSolo 
            ? "Optional extras to make your me-time extra special" 
            : "Optional extras to make your date even more special"
          }
        </p>
      </div>

      {/* Love Languages Section */}
      <div className="space-y-4 p-3 sm:p-4 rounded-lg border border-border bg-card">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
            <Heart className="w-4 h-4 sm:w-5 sm:h-5 text-primary" />
          </div>
          <div>
            <Label className="text-sm sm:text-base font-medium">{isSolo ? "✨ Self-Care Languages" : "💕 Love Languages"}</Label>
            <p className="text-xs sm:text-sm text-muted-foreground">Select all that apply</p>
          </div>
        </div>
        
        <div className={isSolo ? "" : "grid grid-cols-1 md:grid-cols-2 gap-4"}>
          <div>
            <Label className="text-xs text-muted-foreground mb-2 block">
              {isSolo ? "How I like to treat myself" : "My love languages"}
            </Label>
            <div className="space-y-2">
              {LOVE_LANGUAGES.map((lang) => (
                <button
                  key={lang.value}
                  type="button"
                  onClick={() => toggleUserLoveLanguage(lang.value)}
                  className={`w-full flex items-center gap-2 sm:gap-3 px-2 sm:px-3 py-2 rounded-lg border text-xs sm:text-sm transition-all text-left ${
                    data.userLoveLanguages?.includes(lang.value)
                      ? "border-primary bg-primary/10 text-foreground"
                      : "border-border bg-card text-foreground hover:border-primary/50"
                  }`}
                >
                  <span className="text-base sm:text-lg">{lang.emoji}</span>
                  <div className="flex-1 min-w-0">
                    <span className="font-medium block text-xs sm:text-sm">{lang.label}</span>
                    <span className="text-xs opacity-70 hidden sm:block">{lang.desc}</span>
                  </div>
                </button>
              ))}
            </div>
          </div>

          {!isSolo && (
            <div>
              <Label className="text-xs text-muted-foreground mb-2 block">My partner's love languages</Label>
              <div className="space-y-2">
                {LOVE_LANGUAGES.map((lang) => (
                  <button
                    key={lang.value}
                    type="button"
                    onClick={() => togglePartnerLoveLanguage(lang.value)}
                    className={`w-full flex items-center gap-2 sm:gap-3 px-2 sm:px-3 py-2 rounded-lg border text-xs sm:text-sm transition-all text-left ${
                      data.partnerLoveLanguages?.includes(lang.value)
                        ? "border-primary bg-primary/10 text-foreground"
                        : "border-border bg-card text-foreground hover:border-primary/50"
                    }`}
                  >
                    <span className="text-base sm:text-lg">{lang.emoji}</span>
                    <div className="flex-1 min-w-0">
                      <span className="font-medium block text-xs sm:text-sm">{lang.label}</span>
                      <span className="text-xs opacity-70 hidden sm:block">{lang.desc}</span>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Gift Suggestions Toggle */}
      <div className="space-y-4 p-3 sm:p-4 rounded-lg border border-border bg-card">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 sm:gap-3">
            <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
              <Gift className="w-4 h-4 sm:w-5 sm:h-5 text-primary" />
            </div>
            <div>
              <Label htmlFor="gift-toggle" className="text-sm sm:text-base font-medium">
                {isSolo ? "Self-Care Treats" : "Gift Suggestions"}
              </Label>
              <p className="text-xs sm:text-sm text-muted-foreground">
                {isSolo ? "Treat yourself to something special" : "Get personalized gift ideas"}
              </p>
            </div>
          </div>
          <Switch
            id="gift-toggle"
            checked={data.wantGiftSuggestions}
            onCheckedChange={(checked) => {
              onChange({ wantGiftSuggestions: checked });
              // Auto-select "myself" for solo dates
              if (checked && isSolo) {
                onChange({ giftRecipient: "myself" });
              }
            }}
          />
        </div>

        {data.wantGiftSuggestions && (
          <div className="space-y-4 pt-4 border-t border-border">
            {!isSolo && (
              <div>
                <Label className="text-xs sm:text-sm font-medium mb-2 sm:mb-3 block">Who are you shopping for?</Label>
                <div className="grid grid-cols-2 gap-2">
                  {filteredGiftRecipients.map((recipient) => (
                    <OptionCard
                      key={recipient.value}
                      emoji={recipient.emoji}
                      label={recipient.label}
                      description={recipient.desc}
                      selected={data.giftRecipient === recipient.value}
                      onClick={() => onChange({ giftRecipient: recipient.value })}
                    />
                  ))}
                </div>
              </div>
            )}

            <div>
              <Label className="text-xs sm:text-sm font-medium mb-2 sm:mb-3 block">
                {isSolo ? "Your Interests (select all that apply)" : "Their Interests (select all that apply)"}
              </Label>
              <div className="grid grid-cols-3 gap-2">
                {PARTNER_INTERESTS.map((interest) => (
                  <button
                    key={interest.value}
                    type="button"
                    onClick={() => toggleInterest(interest.value)}
                    className={`flex items-center gap-1 sm:gap-2 px-2 py-1.5 sm:py-2 rounded-lg border text-xs sm:text-sm transition-all ${
                      data.partnerInterests?.includes(interest.value)
                        ? "border-primary bg-primary/10 text-foreground"
                        : "border-border bg-card text-foreground hover:border-primary/50"
                    }`}
                  >
                    <span className="text-sm sm:text-base">{interest.emoji}</span>
                    <span className="truncate text-xs sm:text-sm">{interest.label}</span>
                  </button>
                ))}
              </div>
            </div>

            <div>
              <Label className="text-xs sm:text-sm font-medium mb-2 sm:mb-3 block">Gift Budget</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {GIFT_BUDGETS.map((budget) => (
                  <OptionCard
                    key={budget.value}
                    label={budget.label}
                    description={budget.desc}
                    selected={data.giftBudget === budget.value}
                    onClick={() => onChange({ giftBudget: budget.value })}
                  />
                ))}
              </div>
            </div>

            <div>
              <Label htmlFor="gift-notes" className="text-xs sm:text-sm font-medium mb-2 sm:mb-3 block">
                {isSolo ? "Any special notes? (Optional)" : "Any special notes about them? (Optional)"}
              </Label>
              <Textarea
                id="gift-notes"
                placeholder={isSolo 
                  ? "E.g., I've been wanting to try something new, looking for relaxation items..."
                  : "E.g., They love vintage items, recently got into hiking..."
                }
                value={data.giftRecipientNotes || ""}
                onChange={(e) => onChange({ giftRecipientNotes: e.target.value })}
                className="min-h-[60px] sm:min-h-[80px] resize-none text-sm"
              />
            </div>
          </div>
        )}
      </div>

      {/* Conversation/Reflection Prompts Toggle */}
      <div className="space-y-4 p-3 sm:p-4 rounded-lg border border-border bg-card">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 sm:gap-3">
            <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
              <MessageCircle className="w-4 h-4 sm:w-5 sm:h-5 text-primary" />
            </div>
            <div>
              <Label htmlFor="convo-toggle" className="text-sm sm:text-base font-medium">
                {isSolo ? "Self-Reflection Prompts" : "Conversation Starters"}
              </Label>
              <p className="text-xs sm:text-sm text-muted-foreground">
                {isSolo 
                  ? "Thoughtful prompts for self-discovery" 
                  : "Get tailored questions to deepen your connection"
                }
              </p>
            </div>
          </div>
          <Switch
            id="convo-toggle"
            checked={data.wantConversationStarters}
            onCheckedChange={(checked) => onChange({ wantConversationStarters: checked })}
          />
        </div>

        {data.wantConversationStarters && (
          <div className="space-y-4 pt-4 border-t border-border">
            {!isSolo && (
              <div>
                <Label className="text-xs sm:text-sm font-medium mb-2 sm:mb-3 block">Where are you in your relationship?</Label>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {RELATIONSHIP_STAGES.map((stage) => (
                    <OptionCard
                      key={stage.value}
                      emoji={stage.emoji}
                      label={stage.label}
                      description={stage.desc}
                      selected={data.relationshipStage === stage.value}
                      onClick={() => onChange({ relationshipStage: stage.value })}
                    />
                  ))}
                </div>
              </div>
            )}

            <div>
              <Label className="text-xs sm:text-sm font-medium mb-2 sm:mb-3 block">What topics would you like to explore?</Label>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {CONVERSATION_TOPICS.map((topic) => (
                  <button
                    key={topic.value}
                    type="button"
                    onClick={() => toggleTopic(topic.value)}
                    className={`flex flex-col items-center gap-0.5 sm:gap-1 p-2 sm:p-3 rounded-lg border text-xs sm:text-sm transition-all ${
                      data.conversationTopics?.includes(topic.value)
                        ? "border-primary bg-primary/10 text-foreground"
                        : "border-border bg-card text-foreground hover:border-primary/50"
                    }`}
                  >
                    <span className="text-lg sm:text-xl">{topic.emoji}</span>
                    <span className="font-medium text-xs sm:text-sm">{topic.label}</span>
                    <span className="text-xs opacity-70 hidden sm:block">{topic.desc}</span>
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Step6Enhancers;