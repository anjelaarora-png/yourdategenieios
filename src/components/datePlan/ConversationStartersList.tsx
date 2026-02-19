import { useMemo } from "react";
import { ConversationStarter } from "@/types/datePlan";
import { SavedDatePlan } from "@/hooks/useDatePlans";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { MessageCircle } from "lucide-react";

interface ConversationStartersListProps {
  plans: SavedDatePlan[];
}

// Type guard to validate conversation starter object
const isValidConversationStarter = (obj: unknown): obj is ConversationStarter => {
  if (!obj || typeof obj !== 'object') return false;
  const convo = obj as Record<string, unknown>;
  return (
    typeof convo.question === 'string' && 
    convo.question.trim() !== '' &&
    typeof convo.category === 'string'
  );
};

const ConversationStartersList = ({ plans }: ConversationStartersListProps) => {
  // Memoize the aggregation to prevent recalculation on every render
  const { allConvos, byCategory, categories } = useMemo(() => {
    const convos: { convo: ConversationStarter; planTitle: string }[] = [];
    
    // Safely iterate with defensive guards
    if (Array.isArray(plans)) {
      plans.forEach((plan) => {
        // Guard: ensure plan exists and has valid structure
        if (!plan || typeof plan !== 'object') return;
        
        const planTitle = plan.title || 'Untitled Plan';
        const starters = plan.conversation_starters;
        
        // Guard: ensure conversation_starters is an array
        if (!Array.isArray(starters)) return;
        
        starters.forEach((convo) => {
          // Validate each conversation starter
          if (isValidConversationStarter(convo)) {
            convos.push({ 
              convo: {
                question: convo.question,
                category: convo.category || 'General',
                emoji: convo.emoji || '💬',
              }, 
              planTitle 
            });
          }
        });
      });
    }

    // Group by category with deduplication
    const grouped: Record<string, typeof convos> = {};
    const seenQuestions = new Set<string>();
    
    convos.forEach((item) => {
      // Deduplicate by question text
      const questionKey = item.convo.question.toLowerCase().trim();
      if (seenQuestions.has(questionKey)) return;
      seenQuestions.add(questionKey);
      
      const cat = item.convo.category || "General";
      if (!grouped[cat]) grouped[cat] = [];
      grouped[cat].push(item);
    });

    const sortedCategories = Object.keys(grouped).sort();

    return { 
      allConvos: convos, 
      byCategory: grouped, 
      categories: sortedCategories 
    };
  }, [plans]);

  if (allConvos.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center bg-muted rounded-lg p-8 gap-3 h-[300px]">
        <MessageCircle className="w-12 h-12 text-muted-foreground" />
        <p className="text-muted-foreground text-center">
          No conversation starters yet. When generating date plans, enable "Conversation Starters" to see personalized prompts here!
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <p className="text-sm text-muted-foreground">
        {allConvos.length} conversation starter{allConvos.length !== 1 ? "s" : ""} from your saved plans
      </p>
      
      {categories.map((category) => (
        <div key={category} className="space-y-3">
          <h3 className="font-display text-lg text-foreground">{category}</h3>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {byCategory[category].map((item, i) => (
              <Card key={i} className="border-border hover:shadow-md transition-shadow">
                <CardContent className="pt-4 space-y-2">
                  <div className="flex items-start gap-2">
                    <span className="text-xl shrink-0">{item.convo.emoji}</span>
                    <p className="text-sm font-medium text-foreground leading-snug">
                      {item.convo.question}
                    </p>
                  </div>
                  <div className="flex items-center justify-between pt-2 border-t border-border">
                    <Badge variant="secondary" className="text-xs">
                      {item.convo.category}
                    </Badge>
                    <p className="text-xs text-muted-foreground">
                      {item.planTitle}
                    </p>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
};

export default ConversationStartersList;
