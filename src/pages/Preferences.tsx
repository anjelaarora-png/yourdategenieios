import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { PlacesAutocompleteInput } from "@/components/ui/PlacesAutocompleteInput";
import { Skeleton } from "@/components/ui/skeleton";
import { ArrowLeft, Save, MapPin, Car, Zap, Utensils, AlertTriangle, Accessibility, Wind, Lock, Loader2, CheckCircle } from "lucide-react";
import { useAuth } from "@/hooks/useAuth";
import { useUserPreferences } from "@/hooks/useUserPreferences";
import { useToast } from "@/hooks/use-toast";
import OptionCard from "@/components/questionnaire/OptionCard";
import {
  TRANSPORTATION_MODES,
  TRAVEL_RADIUS,
  ENERGY_LEVELS,
  ACTIVITIES,
  CUISINES,
  DIETARY_RESTRICTIONS,
  DRINK_PREFERENCES,
  BUDGET_RANGES,
  COMMON_ALLERGIES,
  HARD_NOS,
  ACCESSIBILITY_OPTIONS,
  SMOKING_PREFERENCES,
  SMOKING_ACTIVITIES,
} from "@/components/questionnaire/types";
import { supabase } from "@/integrations/supabase/client";

interface EditablePreferences {
  default_city: string;
  default_neighborhood: string;
  transportation_mode: string;
  travel_radius: string;
  energy_level: string;
  activity_preferences: string[];
  food_preferences: string[];
  dietary_restrictions: string[];
  drink_preferences: string;
  budget_range: string;
  allergies: string[];
  deal_breakers: string[];
  accessibility_needs: string[];
  smoking_preference: string;
  smoking_activities: string[];
}

const Preferences = () => {
  const navigate = useNavigate();
  const { user, loading: authLoading } = useAuth();
  const { preferences, loading: prefsLoading, refetch } = useUserPreferences();
  const { toast } = useToast();
  const [saving, setSaving] = useState(false);
  const [edited, setEdited] = useState<EditablePreferences>({
    default_city: "",
    default_neighborhood: "",
    transportation_mode: "",
    travel_radius: "",
    energy_level: "",
    activity_preferences: [],
    food_preferences: [],
    dietary_restrictions: [],
    drink_preferences: "",
    budget_range: "",
    allergies: [],
    deal_breakers: [],
    accessibility_needs: [],
    smoking_preference: "",
    smoking_activities: [],
  });
  
  // Password change state
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmNewPassword, setConfirmNewPassword] = useState("");
  const [changingPassword, setChangingPassword] = useState(false);
  const [passwordChanged, setPasswordChanged] = useState(false);

  const handleChangePassword = async () => {
    if (newPassword !== confirmNewPassword) {
      toast({
        title: "Passwords don't match",
        description: "Please make sure your new passwords match.",
        variant: "destructive",
      });
      return;
    }

    if (newPassword.length < 6) {
      toast({
        title: "Password too short",
        description: "Password must be at least 6 characters.",
        variant: "destructive",
      });
      return;
    }

    setChangingPassword(true);

    try {
      const { error } = await supabase.auth.updateUser({
        password: newPassword,
      });

      if (error) throw error;

      setPasswordChanged(true);
      setCurrentPassword("");
      setNewPassword("");
      setConfirmNewPassword("");
      
      toast({
        title: "Password updated! ✨",
        description: "Your password has been changed successfully.",
      });

      // Reset the success state after 3 seconds
      setTimeout(() => setPasswordChanged(false), 3000);
    } catch (error: any) {
      toast({
        title: "Failed to change password",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setChangingPassword(false);
    }
  };

  useEffect(() => {
    if (!authLoading && !user) {
      navigate("/login");
    }
  }, [user, authLoading, navigate]);

  useEffect(() => {
    if (preferences) {
      setEdited({
        default_city: preferences.default_city || "",
        default_neighborhood: preferences.default_neighborhood || "",
        transportation_mode: preferences.transportation_mode || "",
        travel_radius: preferences.travel_radius || "",
        energy_level: preferences.energy_level || "",
        activity_preferences: preferences.activity_preferences || [],
        food_preferences: preferences.food_preferences || [],
        dietary_restrictions: preferences.dietary_restrictions || [],
        drink_preferences: preferences.drink_preferences || "",
        budget_range: preferences.budget_range || "",
        allergies: preferences.allergies || [],
        deal_breakers: preferences.deal_breakers || [],
        accessibility_needs: preferences.accessibility_needs || [],
        smoking_preference: preferences.smoking_preference || "",
        smoking_activities: preferences.smoking_activities || [],
      });
    }
  }, [preferences]);

  const toggleArrayValue = (field: keyof EditablePreferences, value: string, isExclusive?: boolean) => {
    setEdited(prev => {
      const current = prev[field] as string[];
      if (isExclusive && value === "none") {
        return { ...prev, [field]: ["none"] };
      }
      const filtered = current.filter(v => v !== "none");
      const updated = filtered.includes(value)
        ? filtered.filter(v => v !== value)
        : [...filtered, value];
      return { ...prev, [field]: updated };
    });
  };

  const handleSave = async () => {
    if (!user || !preferences) return;
    
    setSaving(true);
    try {
      const { error } = await supabase
        .from("user_preferences")
        .update({
          default_city: edited.default_city || null,
          default_neighborhood: edited.default_neighborhood || null,
          preferred_location: `${edited.default_city}${edited.default_neighborhood ? `, ${edited.default_neighborhood}` : ""}`,
          transportation_mode: edited.transportation_mode || null,
          travel_radius: edited.travel_radius || null,
          energy_level: edited.energy_level || null,
          activity_preferences: edited.activity_preferences,
          food_preferences: edited.food_preferences,
          dietary_restrictions: edited.dietary_restrictions.filter(d => d !== "none"),
          drink_preferences: edited.drink_preferences || null,
          budget_range: edited.budget_range || null,
          allergies: edited.allergies.filter(a => a !== "none"),
          deal_breakers: edited.deal_breakers,
          accessibility_needs: edited.accessibility_needs.filter(a => a !== "none"),
          smoking_preference: edited.smoking_preference || null,
          smoking_activities: edited.smoking_activities.filter(s => s !== "none"),
        })
        .eq("id", preferences.id);

      if (error) throw error;

      toast({
        title: "Preferences saved! ✨",
        description: "Your preferences will be used for future date plans.",
      });
      refetch();
    } catch (error) {
      console.error("Error saving preferences:", error);
      toast({
        title: "Couldn't save",
        description: "Something went wrong. Please try again.",
        variant: "destructive",
      });
    } finally {
      setSaving(false);
    }
  };

  if (authLoading || prefsLoading) {
    return (
      <div className="min-h-screen bg-background p-6">
        <div className="max-w-4xl mx-auto space-y-6">
          <Skeleton className="h-10 w-48" />
          <div className="grid gap-6">
            {[1, 2, 3].map(i => (
              <Skeleton key={i} className="h-48" />
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (!preferences) {
    return (
      <div className="min-h-screen bg-background p-6">
        <div className="max-w-4xl mx-auto">
          <Button variant="ghost" onClick={() => navigate("/dashboard")} className="mb-6">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Dashboard
          </Button>
          <Card>
            <CardContent className="pt-6 text-center">
              <p className="text-muted-foreground mb-4">
                No preferences saved yet. Create a date plan first to save your preferences!
              </p>
              <Button onClick={() => navigate("/dashboard")}>
                Go to Dashboard
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-4xl mx-auto p-6 space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button variant="ghost" size="icon" onClick={() => navigate("/dashboard")}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div>
              <h1 className="text-2xl font-bold">My Preferences</h1>
              <p className="text-muted-foreground text-sm">
                These will pre-fill your questionnaire
              </p>
            </div>
          </div>
          <Button onClick={handleSave} disabled={saving} className="gradient-gold text-primary-foreground">
            <Save className="w-4 h-4 mr-2" />
            {saving ? "Saving..." : "Save Changes"}
          </Button>
        </div>

        {/* Location */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <MapPin className="w-5 h-5 text-primary" />
              Default Location
            </CardTitle>
            <CardDescription>Your go-to date location</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>City</Label>
                <PlacesAutocompleteInput
                  value={edited.default_city}
                  onChange={(v) => setEdited(prev => ({ ...prev, default_city: v }))}
                  placeholder="e.g., New York"
                  mode="city"
                />
              </div>
              <div className="space-y-2">
                <Label>Neighborhood (optional)</Label>
                <PlacesAutocompleteInput
                  value={edited.default_neighborhood}
                  onChange={(v) => setEdited(prev => ({ ...prev, default_neighborhood: v }))}
                  placeholder="e.g., Brooklyn"
                  mode="city"
                />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Transportation */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <Car className="w-5 h-5 text-primary" />
              Transportation
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">How do you get around?</Label>
              <div className="grid grid-cols-2 sm:grid-cols-5 gap-2">
                {TRANSPORTATION_MODES.map(mode => (
                  <OptionCard
                    key={mode.value}
                    selected={edited.transportation_mode === mode.value}
                    onClick={() => setEdited(prev => ({ ...prev, transportation_mode: mode.value }))}
                    emoji={mode.emoji}
                    label={mode.label}
                    compact
                  />
                ))}
              </div>
            </div>
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">Travel radius</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {TRAVEL_RADIUS.map(radius => (
                  <OptionCard
                    key={radius.value}
                    selected={edited.travel_radius === radius.value}
                    onClick={() => setEdited(prev => ({ ...prev, travel_radius: radius.value }))}
                    emoji={radius.emoji}
                    label={radius.label}
                    description={radius.distance}
                    compact
                  />
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Energy & Activities */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <Zap className="w-5 h-5 text-primary" />
              Energy & Activities
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">Preferred energy level</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {ENERGY_LEVELS.map(level => (
                  <OptionCard
                    key={level.value}
                    selected={edited.energy_level === level.value}
                    onClick={() => setEdited(prev => ({ ...prev, energy_level: level.value }))}
                    emoji={level.emoji}
                    label={level.label}
                    compact
                  />
                ))}
              </div>
            </div>
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">Favorite activities</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {ACTIVITIES.map(activity => (
                  <OptionCard
                    key={activity.value}
                    selected={edited.activity_preferences.includes(activity.value)}
                    onClick={() => toggleArrayValue("activity_preferences", activity.value)}
                    emoji={activity.emoji}
                    label={activity.label}
                    compact
                  />
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Food & Drinks */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <Utensils className="w-5 h-5 text-primary" />
              Food & Drinks
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">Favorite cuisines</Label>
              <div className="grid grid-cols-2 sm:grid-cols-5 gap-2">
                {CUISINES.map(cuisine => (
                  <OptionCard
                    key={cuisine.value}
                    selected={edited.food_preferences.includes(cuisine.value)}
                    onClick={() => toggleArrayValue("food_preferences", cuisine.value)}
                    emoji={cuisine.emoji}
                    label={cuisine.label}
                    compact
                  />
                ))}
              </div>
            </div>
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">Dietary restrictions</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {DIETARY_RESTRICTIONS.map(diet => (
                  <OptionCard
                    key={diet.value}
                    selected={edited.dietary_restrictions.includes(diet.value)}
                    onClick={() => toggleArrayValue("dietary_restrictions", diet.value, diet.value === "none")}
                    emoji={diet.emoji}
                    label={diet.label}
                    compact
                  />
                ))}
              </div>
            </div>
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">Drink of choice</Label>
              <div className="grid grid-cols-2 sm:grid-cols-5 gap-2">
                {DRINK_PREFERENCES.map(drink => (
                  <OptionCard
                    key={drink.value}
                    selected={edited.drink_preferences === drink.value}
                    onClick={() => setEdited(prev => ({ ...prev, drink_preferences: drink.value }))}
                    emoji={drink.emoji}
                    label={drink.label}
                    compact
                  />
                ))}
              </div>
            </div>
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">Budget range</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {BUDGET_RANGES.map(budget => (
                  <OptionCard
                    key={budget.value}
                    selected={edited.budget_range === budget.value}
                    onClick={() => setEdited(prev => ({ ...prev, budget_range: budget.value }))}
                    label={budget.label}
                    description={budget.desc}
                  />
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Deal Breakers */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <AlertTriangle className="w-5 h-5 text-primary" />
              Avoid These
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">Food allergies</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {COMMON_ALLERGIES.map(allergy => (
                  <OptionCard
                    key={allergy.value}
                    selected={edited.allergies.includes(allergy.value)}
                    onClick={() => toggleArrayValue("allergies", allergy.value, allergy.value === "none")}
                    emoji={allergy.emoji}
                    label={allergy.label}
                    compact
                  />
                ))}
              </div>
            </div>
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">Hard no's</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {HARD_NOS.map(item => (
                  <OptionCard
                    key={item.value}
                    selected={edited.deal_breakers.includes(item.value)}
                    onClick={() => toggleArrayValue("deal_breakers", item.value)}
                    emoji={item.emoji}
                    label={item.label}
                    compact
                  />
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Accessibility */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <Accessibility className="w-5 h-5 text-primary" />
              Accessibility Needs
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
              {ACCESSIBILITY_OPTIONS.map(option => (
                <OptionCard
                  key={option.value}
                  selected={edited.accessibility_needs.includes(option.value)}
                  onClick={() => toggleArrayValue("accessibility_needs", option.value, option.value === "none")}
                  emoji={option.emoji}
                  label={option.label}
                  description={option.desc}
                  compact
                />
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Smoke & Vibe */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <Wind className="w-5 h-5 text-primary" />
              Smoke & Vibe
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">Venue atmosphere</Label>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
                {SMOKING_PREFERENCES.map(option => (
                  <OptionCard
                    key={option.value}
                    selected={edited.smoking_preference === option.value}
                    onClick={() => setEdited(prev => ({ ...prev, smoking_preference: option.value }))}
                    emoji={option.emoji}
                    label={option.label}
                    description={option.desc}
                    compact
                  />
                ))}
              </div>
            </div>
            <div>
              <Label className="text-sm text-muted-foreground mb-3 block">Interested in these experiences?</Label>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {SMOKING_ACTIVITIES.map(option => (
                  <OptionCard
                    key={option.value}
                    selected={edited.smoking_activities.includes(option.value)}
                    onClick={() => toggleArrayValue("smoking_activities", option.value, option.value === "none")}
                    emoji={option.emoji}
                    label={option.label}
                    description={option.desc}
                    compact
                  />
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Change Password */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <Lock className="w-5 h-5 text-primary" />
              Change Password
            </CardTitle>
            <CardDescription>Update your account password</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {passwordChanged ? (
              <div className="flex items-center gap-3 p-4 bg-primary/10 rounded-lg">
                <CheckCircle className="w-5 h-5 text-primary" />
                <span className="text-sm text-foreground">Password changed successfully!</span>
              </div>
            ) : (
              <>
                <div className="space-y-2">
                  <Label htmlFor="newPassword">New Password</Label>
                  <Input
                    id="newPassword"
                    type="password"
                    placeholder="••••••••"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    className="bg-input border-border"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="confirmNewPassword">Confirm New Password</Label>
                  <Input
                    id="confirmNewPassword"
                    type="password"
                    placeholder="••••••••"
                    value={confirmNewPassword}
                    onChange={(e) => setConfirmNewPassword(e.target.value)}
                    className="bg-input border-border"
                  />
                </div>
                <Button 
                  onClick={handleChangePassword} 
                  disabled={changingPassword || !newPassword || !confirmNewPassword}
                  variant="outline"
                  className="w-full sm:w-auto"
                >
                  {changingPassword ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      Updating...
                    </>
                  ) : (
                    <>
                      <Lock className="w-4 h-4 mr-2" />
                      Change Password
                    </>
                  )}
                </Button>
              </>
            )}
          </CardContent>
        </Card>

        {/* Bottom Save Button */}
        <div className="flex justify-end pb-8">
          <Button onClick={handleSave} disabled={saving} size="lg" className="gradient-gold text-primary-foreground">
            <Save className="w-4 h-4 mr-2" />
            {saving ? "Saving..." : "Save All Changes"}
          </Button>
        </div>
      </div>
    </div>
  );
};

export default Preferences;
