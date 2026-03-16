import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { format, subDays, eachDayOfInterval } from 'date-fns';

export interface UserStat {
  user_id: string;
  display_name: string | null;
  avatar_url: string | null;
  signup_date: string;
  last_updated: string;
  role: string;
  email: string | null;
  total_date_plans: number;
  last_plan_date: string | null;
}

export interface UserPreferenceSummary {
  preferred_location: string | null;
  default_city: string | null;
  default_neighborhood: string | null;
  budget_range: string | null;
  energy_level: string | null;
  food_preferences: string[] | null;
  drink_preferences: string[] | null;
  dietary_restrictions: string[] | null;
  allergies: string[] | null;
  deal_breakers: string[] | null;
  transportation_mode: string | null;
  travel_radius: string | null;
  activity_preferences: string[] | null;
  accessibility_needs: string[] | null;
  smoking_preference: string | null;
  gift_recipient: string | null;
  gift_interests: string[] | null;
  gift_budget: string | null;
  gift_occasion: string | null;
}

interface AdminStats {
  totalUsers: number;
  totalPlans: number;
  usersThisWeek: number;
  plansThisWeek: number;
}

interface SignupTrendData {
  date: string;
  signups: number;
}

export function useAdminStats() {
  const [users, setUsers] = useState<UserStat[]>([]);
  const [stats, setStats] = useState<AdminStats>({
    totalUsers: 0,
    totalPlans: 0,
    usersThisWeek: 0,
    plansThisWeek: 0,
  });
  const [signupTrend, setSignupTrend] = useState<SignupTrendData[]>([]);
  const [userPreferences, setUserPreferences] = useState<Record<string, UserPreferenceSummary>>({});
  const [isAdmin, setIsAdmin] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    checkAdminAndFetch();
  }, []);

  async function checkAdminAndFetch() {
    try {
      setLoading(true);
      
      // Check if current user is admin
      const { data: adminCheck, error: adminError } = await supabase
        .rpc('is_current_user_admin');
      
      if (adminError) throw adminError;
      
      setIsAdmin(adminCheck);
      
      if (!adminCheck) {
        setLoading(false);
        return;
      }

      // Fetch user stats from view
      const { data: userData, error: userError } = await supabase
        .from('user_stats')
        .select('*')
        .order('signup_date', { ascending: false });

      if (userError) throw userError;

      // Calculate stats
      const oneWeekAgo = new Date();
      oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

      const usersThisWeek = (userData || []).filter(
        u => new Date(u.signup_date) >= oneWeekAgo
      ).length;

      // Get total plans count
      const { count: plansCount } = await supabase
        .from('date_plans')
        .select('*', { count: 'exact', head: true });

      // Get plans this week
      const { count: plansThisWeekCount } = await supabase
        .from('date_plans')
        .select('*', { count: 'exact', head: true })
        .gte('created_at', oneWeekAgo.toISOString());

      // Fetch all user preferences
      const { data: prefsData } = await supabase
        .from('user_preferences')
        .select('*');

      // Build preferences map
      const prefsMap: Record<string, UserPreferenceSummary> = {};
      (prefsData || []).forEach(pref => {
        prefsMap[pref.user_id] = {
          preferred_location: pref.preferred_location,
          default_city: pref.default_city,
          default_neighborhood: pref.default_neighborhood,
          budget_range: pref.budget_range,
          energy_level: pref.energy_level,
          food_preferences: pref.food_preferences,
          drink_preferences: pref.drink_preferences,
          dietary_restrictions: pref.dietary_restrictions,
          allergies: pref.allergies,
          deal_breakers: pref.deal_breakers,
          transportation_mode: pref.transportation_mode,
          travel_radius: pref.travel_radius,
          activity_preferences: pref.activity_preferences,
          accessibility_needs: pref.accessibility_needs,
          smoking_preference: pref.smoking_preference,
          gift_recipient: pref.gift_recipient,
          gift_interests: pref.gift_interests,
          gift_budget: pref.gift_budget,
          gift_occasion: pref.gift_occasion,
        };
      });

      // Calculate signup trend (last 30 days)
      const thirtyDaysAgo = subDays(new Date(), 30);
      const allDays = eachDayOfInterval({ start: thirtyDaysAgo, end: new Date() });
      
      const signupsByDate = (userData || []).reduce((acc, user) => {
        const dateKey = format(new Date(user.signup_date), 'yyyy-MM-dd');
        acc[dateKey] = (acc[dateKey] || 0) + 1;
        return acc;
      }, {} as Record<string, number>);

      const trendData: SignupTrendData[] = allDays.map(day => ({
        date: format(day, 'yyyy-MM-dd'),
        signups: signupsByDate[format(day, 'yyyy-MM-dd')] || 0,
      }));

      setUsers(userData || []);
      setSignupTrend(trendData);
      setUserPreferences(prefsMap);
      setStats({
        totalUsers: userData?.length || 0,
        totalPlans: plansCount || 0,
        usersThisWeek,
        plansThisWeek: plansThisWeekCount || 0,
      });
    } catch (err: any) {
      console.error('Admin stats error:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return { users, stats, signupTrend, isAdmin, loading, error, userPreferences, refetch: checkAdminAndFetch };
}
