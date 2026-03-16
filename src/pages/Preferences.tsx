import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { PlacesAutocompleteInput } from "@/components/ui/PlacesAutocompleteInput";
import { Skeleton } from "@/components/ui/skeleton";
import { ArrowLeft, Save, MapPin, Car, Zap, Utensils, AlertTriangle, Accessibility, Wind, Lock, Loader2, CheckCircle, ChevronDown, Users } from "lucide-react";
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
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible";
import { supabase } from "@/integrations/supabase/client";

const GENDER_OPTIONS = [
  { value: "male", label: "Male", emoji: "👨" },
  { value: "female", label: "Female", emoji: "👩" },
  { value: "non-binary", label: "Non-binary", emoji: "🧑" },
  { value: "prefer-not-to-say", label: "Prefer not to say", emoji: "🙂" },
] as const;

interface EditablePreferences {
  gender: string;
  partner_gender: string;
  default_city: string;
  default_neighborhood: string;
  transportation_mode: string;
  travel_radius: string;
  energy_level: string;
  activity_preferences: string[];
  food_preferences: string[];
  dietary_restrictions: string[];
  drink_preferences: string[];
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
    gender: "",
    partner_gender: "",
    default_city: "",
    default_neighborhood: "",
    transportation_mode: "",
    travel_radius: "",
    energy_level: "",
    activity_preferences: [],
    food_preferences: [],
    dietary_restrictions: [],
    drink_preferences: [],
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
        gender: preferences.gender || "",
        partner_gender: preferences.partner_gender || "",
        default_city: preferences.default_city || "",
        default_neighborhood: preferences.default_neighborhood || "",
        transportation_mode: preferences.transportation_mode || "",
        travel_radius: preferences.travel_radius || "",
        energy_level: preferences.energy_level || "",
        activity_preferences: preferences.activity_preferences || [],
        food_preferences: preferences.food_preferences || [],
        dietary_restrictions: preferences.dietary_restrictions || [],
        drink_preferences: Array.isArray(preferences.drink_preferences)
          ? preferences.drink_preferences
          : preferences.drink_preferences
            ? [preferences.drink_preferences]
            : [],
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
    if (!user) return;

    setSaving(true);
    try {
      const payload = {
        gender: edited.gender || null,
        partner_gender: edited.partner_gender || null,
        default_city: edited.default_city || null,
        default_neighborhood: edited.default_neighborhood || null,
        preferred_location: `${edited.default_city}${edited.default_neighborhood ? `, ${edited.default_neighborhood}` : ""}`,
        transportation_mode: edited.transportation_mode || null,
        travel_radius: edited.travel_radius || null,
        energy_level: edited.energy_level || null,
        activity_preferences: edited.activity_preferences,
        food_preferences: edited.food_preferences,
        dietary_restrictions: edited.dietary_restrictions.filter(d => d !== "none"),
        drink_preferences: edited.drink_preferences?.length ? edited.drink_preferences : null,
        budget_range: edited.budget_range || null,
        allergies: edited.allergies.filter(a => a !== "none"),
        deal_breakers: edited.deal_breakers,
        accessibility_needs: edited.accessibility_needs.filter(a => a !== "none"),
        smoking_preference: edited.smoking_preference || null,
        smoking_activities: edited.smoking_activities.filter(s => s !== "none"),
      };

      if (preferences) {
        const { error } = await supabase
          .from("user_preferences")
          .update(payload)
          .eq("id", preferences.id);
        if (error) throw error;
      } else {
        const { error } = await supabase
          .from("user_preferences")
          .insert({ user_id: user.id, ...payload })
          .select()
          .single();
        if (error) throw error;
      }

      toast({ title: "Preferences saved." });
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

  const [openSections, setOpenSections] = useState<Record<string, boolean>>({
    gender: true,
    location: true,
    transport: false,
    energy: false,
    food: false,
    avoid: false,
    accessibility: false,
    smoke: false,
    password: false,
  });
  const toggleSection = (key: string) => setOpenSections((p) => ({ ...p, [key]: !p[key] }));

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-4xl mx-auto p-6 space-y-3">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <Button variant="ghost" size="icon" onClick={() => navigate("/dashboard")}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div>
              <h1 className="text-xl font-bold">My Preferences</h1>
              <p className="text-muted-foreground text-xs">Edit below and save. Stored on your account only.</p>
            </div>
          </div>
          <Button onClick={handleSave} disabled={saving} size="sm" className="gradient-gold text-primary-foreground shrink-0">
            <Save className="w-4 h-4 mr-1" />
            {saving ? "Saving..." : "Save"}
          </Button>
        </div>

        {/* You & partner (gender) */}
        <Collapsible open={openSections.gender} onOpenChange={() => toggleSection("gender")}>
          <Card>
            <CollapsibleTrigger className="w-full">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 py-3">
                <CardTitle className="flex items-center gap-2 text-base">
                  <Users className="w-4 h-4 text-primary" />
                  You & partner
                </CardTitle>
                <ChevronDown className={`h-4 w-4 transition-transform ${openSections.gender ? "rotate-180" : ""}`} />
              </CardHeader>
            </CollapsibleTrigger>
            <CollapsibleContent>
          <CardContent className="space-y-3 pt-0">
            <div>
              <Label className="text-sm text-muted-foreground mb-2 block">Your gender</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {GENDER_OPTIONS.map((opt) => (
                  <OptionCard
                    key={opt.value}
                    selected={edited.gender === opt.value}
                    onClick={() => setEdited((prev) => ({ ...prev, gender: opt.value }))}
                    emoji={opt.emoji}
                    label={opt.label}
                    compact
                  />
                ))}
              </div>
            </div>
            <div>
              <Label className="text-sm text-muted-foreground mb-2 block">Partner&apos;s gender</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {GENDER_OPTIONS.map((opt) => (
                  <OptionCard
                    key={opt.value}
                    selected={edited.partner_gender === opt.value}
                    onClick={() => setEdited((prev) => ({ ...prev, partner_gender: opt.value }))}
                    emoji={opt.emoji}
                    label={opt.label}
                    compact
                  />
                ))}
              </div>
            </div>
          </CardContent>
            </CollapsibleContent>
          </Card>
        </Collapsible>

        {/* Location */}
        <Collapsible open={openSections.location} onOpenChange={() => toggleSection("location")}>
          <Card>
            <CollapsibleTrigger className="w-full">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 py-3">
                <CardTitle className="flex items-center gap-2 text-base">
                  <MapPin className="w-4 h-4 text-primary" />
                  Location
                </CardTitle>
                <ChevronDown className={`h-4 w-4 transition-transform ${openSections.location ? "rotate-180" : ""}`} />
              </CardHeader>
            </CollapsibleTrigger>
            <CollapsibleContent>
          <CardContent className="space-y-3 pt-0">
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
            </CollapsibleContent>
          </Card>
        </Collapsible>

        <Collapsible open={openSections.transport} onOpenChange={() => toggleSection("transport")}>
          <Card>
            <CollapsibleTrigger className="w-full">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 py-3">
                <CardTitle className="flex items-center gap-2 text-base">
                  <Car className="w-4 h-4 text-primary" />
                  Transportation
                </CardTitle>
                <ChevronDown className={`h-4 w-4 transition-transform ${openSections.transport ? "rotate-180" : ""}`} />
              </CardHeader>
            </CollapsibleTrigger>
            <CollapsibleContent>
          <CardContent className="space-y-3 pt-0">
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
            </CollapsibleContent>
          </Card>
        </Collapsible>

        <Collapsible open={openSections.energy} onOpenChange={() => toggleSection("energy")}>
          <Card>
            <CollapsibleTrigger className="w-full">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 py-3">
                <CardTitle className="flex items-center gap-2 text-base">
                  <Zap className="w-4 h-4 text-primary" />
                  Energy & Activities
                </CardTitle>
                <ChevronDown className={`h-4 w-4 transition-transform ${openSections.energy ? "rotate-180" : ""}`} />
              </CardHeader>
            </CollapsibleTrigger>
            <CollapsibleContent>
          <CardContent className="space-y-3 pt-0">
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
            </CollapsibleContent>
          </Card>
        </Collapsible>

        <Collapsible open={openSections.food} onOpenChange={() => toggleSection("food")}>
          <Card>
            <CollapsibleTrigger className="w-full">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 py-3">
                <CardTitle className="flex items-center gap-2 text-base">
                  <Utensils className="w-4 h-4 text-primary" />
                  Food & Drinks
                </CardTitle>
                <ChevronDown className={`h-4 w-4 transition-transform ${openSections.food ? "rotate-180" : ""}`} />
              </CardHeader>
            </CollapsibleTrigger>
            <CollapsibleContent>
          <CardContent className="space-y-3 pt-0">
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
              <Label className="text-sm text-muted-foreground mb-3 block">Preferred beverages (pick any)</Label>
              <div className="grid grid-cols-2 sm:grid-cols-5 gap-2">
                {DRINK_PREFERENCES.map(drink => (
                  <OptionCard
                    key={drink.value}
                    selected={edited.drink_preferences.includes(drink.value)}
                    onClick={() => toggleArrayValue("drink_preferences", drink.value)}
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
            </CollapsibleContent>
          </Card>
        </Collapsible>

        <Collapsible open={openSections.avoid} onOpenChange={() => toggleSection("avoid")}>
          <Card>
            <CollapsibleTrigger className="w-full">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 py-3">
                <CardTitle className="flex items-center gap-2 text-base">
                  <AlertTriangle className="w-4 h-4 text-primary" />
                  Avoid
                </CardTitle>
                <ChevronDown className={`h-4 w-4 transition-transform ${openSections.avoid ? "rotate-180" : ""}`} />
              </CardHeader>
            </CollapsibleTrigger>
            <CollapsibleContent>
          <CardContent className="space-y-3 pt-0">
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
            </CollapsibleContent>
          </Card>
        </Collapsible>

        <Collapsible open={openSections.accessibility} onOpenChange={() => toggleSection("accessibility")}>
          <Card>
            <CollapsibleTrigger className="w-full">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 py-3">
                <CardTitle className="flex items-center gap-2 text-base">
                  <Accessibility className="w-4 h-4 text-primary" />
                  Accessibility
                </CardTitle>
                <ChevronDown className={`h-4 w-4 transition-transform ${openSections.accessibility ? "rotate-180" : ""}`} />
              </CardHeader>
            </CollapsibleTrigger>
            <CollapsibleContent>
          <CardContent className="pt-0">
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
            </CollapsibleContent>
          </Card>
        </Collapsible>

        <Collapsible open={openSections.smoke} onOpenChange={() => toggleSection("smoke")}>
          <Card>
            <CollapsibleTrigger className="w-full">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 py-3">
                <CardTitle className="flex items-center gap-2 text-base">
                  <Wind className="w-4 h-4 text-primary" />
                  Smoke & Vibe
                </CardTitle>
                <ChevronDown className={`h-4 w-4 transition-transform ${openSections.smoke ? "rotate-180" : ""}`} />
              </CardHeader>
            </CollapsibleTrigger>
            <CollapsibleContent>
          <CardContent className="space-y-3 pt-0">
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
            </CollapsibleContent>
          </Card>
        </Collapsible>

        <Collapsible open={openSections.password} onOpenChange={() => toggleSection("password")}>
          <Card>
            <CollapsibleTrigger className="w-full">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 py-3">
                <CardTitle className="flex items-center gap-2 text-base">
                  <Lock className="w-4 h-4 text-primary" />
                  Password
                </CardTitle>
                <ChevronDown className={`h-4 w-4 transition-transform ${openSections.password ? "rotate-180" : ""}`} />
              </CardHeader>
            </CollapsibleTrigger>
            <CollapsibleContent>
          <CardContent className="space-y-3 pt-0">
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
            </CollapsibleContent>
          </Card>
        </Collapsible>

        <div className="flex justify-end py-4">
          <Button onClick={handleSave} disabled={saving} size="sm" className="gradient-gold text-primary-foreground">
            <Save className="w-4 h-4 mr-1" />
            {saving ? "Saving..." : "Save preferences"}
          </Button>
        </div>
      </div>
    </div>
  );
};

export default Preferences;
