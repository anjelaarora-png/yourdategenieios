import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { supabase } from '@/integrations/supabase/client';
import { Calendar, MapPin, Heart, Camera, Settings, Clock } from 'lucide-react';
import { format } from 'date-fns';

interface UserDetailsDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  userId: string | null;
  userName: string;
}

interface DatePlan {
  id: string;
  title: string;
  tagline: string | null;
  status: string;
  created_at: string;
  date_scheduled: string | null;
  estimated_cost: string | null;
  total_duration: string | null;
  weather_note: string | null;
  packing_list: string[] | null;
  stops: unknown;
  conversation_starters: unknown;
  gift_suggestions: unknown;
}

interface Memory {
  id: string;
  image_url: string;
  caption: string | null;
  taken_at: string;
  is_public: boolean;
}

interface Preferences {
  preferred_location: string | null;
  budget_range: string | null;
  energy_level: string | null;
  food_preferences: string[] | null;
  deal_breakers: string[] | null;
  created_at: string;
  updated_at: string;
}

export function UserDetailsDialog({ open, onOpenChange, userId, userName }: UserDetailsDialogProps) {
  const [datePlans, setDatePlans] = useState<DatePlan[]>([]);
  const [memories, setMemories] = useState<Memory[]>([]);
  const [preferences, setPreferences] = useState<Preferences | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (open && userId) {
      fetchUserData();
    }
  }, [open, userId]);

  async function fetchUserData() {
    if (!userId) return;
    
    setLoading(true);
    try {
      // Fetch date plans - get ALL plans regardless of status
      const { data: plans } = await supabase
        .from('date_plans')
        .select('id, title, tagline, status, created_at, date_scheduled, estimated_cost, total_duration, weather_note, packing_list, stops, conversation_starters, gift_suggestions')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      // Fetch memories
      const { data: mems } = await supabase
        .from('date_memories')
        .select('id, image_url, caption, taken_at, is_public')
        .eq('user_id', userId)
        .order('taken_at', { ascending: false });

      // Fetch preferences with timestamps
      const { data: prefs } = await supabase
        .from('user_preferences')
        .select('preferred_location, budget_range, energy_level, food_preferences, deal_breakers, created_at, updated_at')
        .eq('user_id', userId)
        .maybeSingle();

      setDatePlans(plans || []);
      setMemories(mems || []);
      setPreferences(prefs);
    } catch (err) {
      console.error('Error fetching user data:', err);
    } finally {
      setLoading(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl max-h-[85vh]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <span>{userName}</span>
            <Badge variant="outline" className="ml-2">{datePlans.length} plans</Badge>
          </DialogTitle>
        </DialogHeader>

        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="w-8 h-8 rounded-lg bg-primary/20 animate-pulse" />
          </div>
        ) : (
          <Tabs defaultValue="plans" className="w-full">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="plans" className="gap-2">
                <Calendar className="w-4 h-4" />
                Date Plans ({datePlans.length})
              </TabsTrigger>
              <TabsTrigger value="memories" className="gap-2">
                <Camera className="w-4 h-4" />
                Memories ({memories.length})
              </TabsTrigger>
              <TabsTrigger value="preferences" className="gap-2">
                <Settings className="w-4 h-4" />
                Preferences
              </TabsTrigger>
            </TabsList>

            <ScrollArea className="h-[500px] mt-4">
              <TabsContent value="plans" className="space-y-3 m-0">
                {datePlans.length === 0 ? (
                  <p className="text-center text-muted-foreground py-8">No date plans yet</p>
                ) : (
                  datePlans.map((plan) => (
                    <Card key={plan.id} className="border-l-4 border-l-primary/50">
                      <CardHeader className="pb-2">
                        <div className="flex items-start justify-between">
                          <div>
                            <CardTitle className="text-base">{plan.title}</CardTitle>
                            {plan.tagline && (
                              <p className="text-sm text-muted-foreground">{plan.tagline}</p>
                            )}
                          </div>
                          <Badge variant={plan.status === 'completed' ? 'default' : plan.status === 'saved' ? 'secondary' : 'outline'}>
                            {plan.status}
                          </Badge>
                        </div>
                      </CardHeader>
                      <CardContent className="pt-0 space-y-3">
                        <div className="flex flex-wrap gap-4 text-sm text-muted-foreground">
                          <span className="flex items-center gap-1">
                            <Clock className="w-3 h-3" />
                            {format(new Date(plan.created_at), 'MMM d, yyyy h:mm a')}
                          </span>
                          {plan.date_scheduled && (
                            <span className="flex items-center gap-1">
                              <Calendar className="w-3 h-3" />
                              Scheduled {format(new Date(plan.date_scheduled), 'MMM d, yyyy')}
                            </span>
                          )}
                          {plan.estimated_cost && (
                            <span>💰 {plan.estimated_cost}</span>
                          )}
                          {plan.total_duration && (
                            <span>⏱️ {plan.total_duration}</span>
                          )}
                        </div>
                        
                        {/* Stops details */}
                        {Array.isArray(plan.stops) && plan.stops.length > 0 && (
                          <div className="bg-muted/50 rounded-lg p-3">
                            <p className="text-xs font-medium mb-2 flex items-center gap-1">
                              <MapPin className="w-3 h-3" /> {plan.stops.length} Stops
                            </p>
                            <div className="space-y-1">
                              {(plan.stops as Array<{name?: string; venue?: string; time?: string}>).map((stop, idx) => (
                                <p key={idx} className="text-xs text-muted-foreground">
                                  {idx + 1}. {stop.name || stop.venue || 'Unknown'} {stop.time && `(${stop.time})`}
                                </p>
                              ))}
                            </div>
                          </div>
                        )}

                        {/* Weather note */}
                        {plan.weather_note && (
                          <p className="text-xs text-muted-foreground">🌤️ {plan.weather_note}</p>
                        )}

                        {/* Packing list */}
                        {plan.packing_list && plan.packing_list.length > 0 && (
                          <div className="flex flex-wrap gap-1">
                            {plan.packing_list.map((item, i) => (
                              <Badge key={i} variant="outline" className="text-xs">🎒 {item}</Badge>
                            ))}
                          </div>
                        )}
                      </CardContent>
                    </Card>
                  ))
                )}
              </TabsContent>

              <TabsContent value="memories" className="m-0">
                {memories.length === 0 ? (
                  <p className="text-center text-muted-foreground py-8">No memories uploaded</p>
                ) : (
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                    {memories.map((memory) => (
                      <div key={memory.id} className="relative group">
                        <img
                          src={memory.image_url}
                          alt={memory.caption || 'Memory'}
                          className="w-full aspect-square object-cover rounded-lg"
                        />
                        <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg flex flex-col justify-end p-2">
                          <p className="text-white text-xs line-clamp-2">{memory.caption || 'No caption'}</p>
                          <p className="text-white/70 text-xs mt-1">
                            {format(new Date(memory.taken_at), 'MMM d, yyyy')}
                          </p>
                          {memory.is_public && (
                            <Badge variant="secondary" className="absolute top-2 right-2 text-xs">
                              Public
                            </Badge>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </TabsContent>

              <TabsContent value="preferences" className="m-0">
                {!preferences ? (
                  <p className="text-center text-muted-foreground py-8">No preferences set</p>
                ) : (
                  <div className="space-y-4">
                    <Card>
                      <CardHeader className="pb-2">
                        <div className="flex items-center justify-between">
                          <CardTitle className="text-sm">User Preferences</CardTitle>
                          <div className="text-xs text-muted-foreground">
                            Set: {format(new Date(preferences.created_at), 'MMM d, yyyy h:mm a')}
                          </div>
                        </div>
                        {preferences.updated_at !== preferences.created_at && (
                          <p className="text-xs text-muted-foreground">
                            Updated: {format(new Date(preferences.updated_at), 'MMM d, yyyy h:mm a')}
                          </p>
                        )}
                      </CardHeader>
                      <CardContent className="pt-2 space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <p className="text-sm font-medium text-muted-foreground">Preferred Location</p>
                            <p className="flex items-center gap-2">
                              <MapPin className="w-4 h-4 text-primary" />
                              {preferences.preferred_location || <span className="text-muted-foreground italic">Not set</span>}
                            </p>
                          </div>

                          <div>
                            <p className="text-sm font-medium text-muted-foreground">Budget Range</p>
                            <p>💰 {preferences.budget_range || <span className="text-muted-foreground italic">Not set</span>}</p>
                          </div>

                          <div>
                            <p className="text-sm font-medium text-muted-foreground">Energy Level</p>
                            <p>⚡ {preferences.energy_level || <span className="text-muted-foreground italic">Not set</span>}</p>
                          </div>
                        </div>

                        <div>
                          <p className="text-sm font-medium text-muted-foreground mb-2">Food Preferences</p>
                          <div className="flex flex-wrap gap-2">
                            {preferences.food_preferences && preferences.food_preferences.length > 0 ? (
                              preferences.food_preferences.map((pref, i) => (
                                <Badge key={i} variant="secondary">{pref}</Badge>
                              ))
                            ) : (
                              <span className="text-muted-foreground italic text-sm">None set</span>
                            )}
                          </div>
                        </div>

                        <div>
                          <p className="text-sm font-medium text-muted-foreground mb-2">Deal Breakers</p>
                          <div className="flex flex-wrap gap-2">
                            {preferences.deal_breakers && preferences.deal_breakers.length > 0 ? (
                              preferences.deal_breakers.map((db, i) => (
                                <Badge key={i} variant="destructive">{db}</Badge>
                              ))
                            ) : (
                              <span className="text-muted-foreground italic text-sm">None set</span>
                            )}
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  </div>
                )}
              </TabsContent>
            </ScrollArea>
          </Tabs>
        )}
      </DialogContent>
    </Dialog>
  );
}
