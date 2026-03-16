import { useNavigate } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { useAdminStats, UserPreferenceSummary } from '@/hooks/useAdminStats';
import { useAuth } from '@/hooks/useAuth';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { Tooltip, TooltipContent, TooltipTrigger, TooltipProvider } from '@/components/ui/tooltip';
import { Users, Calendar, TrendingUp, ArrowLeft, Shield, Eye, Download, MapPin, Utensils, Car, Zap, Gift, AlertCircle } from 'lucide-react';
import { UserStat } from '@/hooks/useAdminStats';
import { format } from 'date-fns';
import { SignupTrendChart } from '@/components/admin/SignupTrendChart';
import { UserDetailsDialog } from '@/components/admin/UserDetailsDialog';

const exportUsersToCSV = (users: UserStat[], preferences: Record<string, UserPreferenceSummary>) => {
  const headers = [
    'Display Name', 'Email', 'Role', 'Signup Date/Time', 'Total Date Plans', 'Last Plan Date',
    'Location', 'City', 'Neighborhood', 'Budget', 'Energy Level', 
    'Food Preferences', 'Drink Preferences', 'Dietary Restrictions', 'Allergies',
    'Deal Breakers', 'Transportation', 'Travel Radius', 'Activities', 
    'Accessibility Needs', 'Smoking Preference',
    'Gift Recipient', 'Gift Interests', 'Gift Budget', 'Gift Occasion'
  ];
  const rows = users.map(user => {
    const prefs = preferences[user.user_id];
    return [
      user.display_name || 'Anonymous',
      user.email || '',
      user.role,
      format(new Date(user.signup_date), 'yyyy-MM-dd HH:mm'),
      user.total_date_plans.toString(),
      user.last_plan_date ? format(new Date(user.last_plan_date), 'yyyy-MM-dd') : '',
      prefs?.preferred_location || '',
      prefs?.default_city || '',
      prefs?.default_neighborhood || '',
      prefs?.budget_range || '',
      prefs?.energy_level || '',
      prefs?.food_preferences?.join('; ') || '',
      (Array.isArray(prefs?.drink_preferences) ? prefs.drink_preferences.join('; ') : prefs?.drink_preferences) || '',
      prefs?.dietary_restrictions?.join('; ') || '',
      prefs?.allergies?.join('; ') || '',
      prefs?.deal_breakers?.join('; ') || '',
      prefs?.transportation_mode || '',
      prefs?.travel_radius || '',
      prefs?.activity_preferences?.join('; ') || '',
      prefs?.accessibility_needs?.join('; ') || '',
      prefs?.smoking_preference || '',
      prefs?.gift_recipient || '',
      prefs?.gift_interests?.join('; ') || '',
      prefs?.gift_budget || '',
      prefs?.gift_occasion || ''
    ];
  });
  
  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.map(cell => `"${cell.replace(/"/g, '""')}"`).join(','))
  ].join('\n');
  
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `users-export-${format(new Date(), 'yyyy-MM-dd')}.csv`;
  link.click();
};

export default function Admin() {
  const navigate = useNavigate();
  const { user, loading: authLoading } = useAuth();
  const { users, stats, signupTrend, isAdmin, loading, error, userPreferences } = useAdminStats();
  const [selectedUser, setSelectedUser] = useState<{ id: string; name: string } | null>(null);

  useEffect(() => {
    if (!authLoading && !user) {
      navigate('/login');
    }
  }, [user, authLoading, navigate]);

  if (authLoading || loading) {
    return (
      <div className="min-h-screen bg-background p-8">
        <div className="max-w-7xl mx-auto space-y-6">
          <Skeleton className="h-10 w-64" />
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            {[1, 2, 3, 4].map(i => (
              <Skeleton key={i} className="h-32" />
            ))}
          </div>
          <Skeleton className="h-96" />
        </div>
      </div>
    );
  }

  if (isAdmin === false) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <Card className="max-w-md">
          <CardContent className="pt-6 text-center">
            <Shield className="h-16 w-16 mx-auto text-muted-foreground mb-4" />
            <h2 className="text-xl font-semibold mb-2">Access Denied</h2>
            <p className="text-muted-foreground mb-4">
              You don't have permission to access the admin dashboard.
            </p>
            <Button onClick={() => navigate('/dashboard')}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Dashboard
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <Card className="max-w-md">
          <CardContent className="pt-6 text-center">
            <p className="text-destructive mb-4">Error: {error}</p>
            <Button onClick={() => navigate('/dashboard')}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Dashboard
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-7xl mx-auto p-6 space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold">Admin Dashboard</h1>
            <p className="text-muted-foreground">Monitor users and activity</p>
          </div>
          <Button variant="outline" onClick={() => navigate('/dashboard')}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to App
          </Button>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">Total Users</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalUsers}</div>
              <p className="text-xs text-muted-foreground">
                +{stats.usersThisWeek} this week
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">Total Date Plans</CardTitle>
              <Calendar className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalPlans}</div>
              <p className="text-xs text-muted-foreground">
                +{stats.plansThisWeek} this week
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">Avg Plans/User</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {stats.totalUsers > 0 
                  ? (stats.totalPlans / stats.totalUsers).toFixed(1) 
                  : '0'}
              </div>
              <p className="text-xs text-muted-foreground">engagement metric</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">New This Week</CardTitle>
              <TrendingUp className="h-4 w-4 text-green-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">
                +{stats.usersThisWeek}
              </div>
              <p className="text-xs text-muted-foreground">new signups</p>
            </CardContent>
          </Card>
        </div>

        {/* Signup Trend Chart */}
        <SignupTrendChart data={signupTrend} />

        {/* Users Table */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>All Users</CardTitle>
            <Button variant="outline" size="sm" onClick={() => exportUsersToCSV(users, userPreferences)}>
              <Download className="h-4 w-4 mr-2" />
              Export CSV
            </Button>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Role</TableHead>
                  <TableHead>Signed Up</TableHead>
                  <TableHead>Date Plans</TableHead>
                  <TableHead>Preferences</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center text-muted-foreground">
                      No users yet
                    </TableCell>
                  </TableRow>
                ) : (
                  users.map((user) => (
                    <TableRow key={user.user_id}>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          {user.avatar_url ? (
                            <img 
                              src={user.avatar_url} 
                              alt="" 
                              className="h-8 w-8 rounded-full object-cover"
                            />
                          ) : (
                            <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center">
                              <span className="text-xs font-medium">
                                {(user.display_name || 'U')[0].toUpperCase()}
                              </span>
                            </div>
                          )}
                          <span className="font-medium">
                            {user.display_name || 'Anonymous'}
                          </span>
                        </div>
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {user.email || '—'}
                      </TableCell>
                      <TableCell>
                        <Badge variant={user.role === 'admin' ? 'default' : 'secondary'}>
                          {user.role}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <div>
                          {format(new Date(user.signup_date), 'MMM d, yyyy')}
                          <span className="block text-xs text-muted-foreground">
                            {format(new Date(user.signup_date), 'h:mm a')}
                          </span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className="font-medium">{user.total_date_plans}</span>
                        {user.last_plan_date && (
                          <span className="block text-xs text-muted-foreground">
                            Last: {format(new Date(user.last_plan_date), 'MMM d')}
                          </span>
                        )}
                      </TableCell>
                      <TableCell>
                        {userPreferences[user.user_id] ? (
                          <TooltipProvider>
                            <Tooltip>
                              <TooltipTrigger asChild>
                                <div className="flex items-center gap-1.5 cursor-help">
                                  <MapPin className="h-3 w-3 text-primary" />
                                  <span className="text-xs font-medium truncate max-w-[140px]">
                                    {userPreferences[user.user_id].preferred_location || 
                                     userPreferences[user.user_id].default_city || 
                                     'Preferences set'}
                                  </span>
                                </div>
                              </TooltipTrigger>
                              <TooltipContent side="left" className="max-w-sm p-3">
                                <div className="space-y-2 text-xs">
                                  {/* Location */}
                                  <div className="border-b pb-2">
                                    <p className="font-semibold flex items-center gap-1 mb-1">
                                      <MapPin className="h-3 w-3" /> Location
                                    </p>
                                    {userPreferences[user.user_id].preferred_location && (
                                      <p>📍 {userPreferences[user.user_id].preferred_location}</p>
                                    )}
                                    {userPreferences[user.user_id].default_city && (
                                      <p>🏙️ City: {userPreferences[user.user_id].default_city}</p>
                                    )}
                                    {userPreferences[user.user_id].default_neighborhood && (
                                      <p>🏘️ Neighborhood: {userPreferences[user.user_id].default_neighborhood}</p>
                                    )}
                                    {userPreferences[user.user_id].travel_radius && (
                                      <p>📏 Radius: {userPreferences[user.user_id].travel_radius}</p>
                                    )}
                                    {userPreferences[user.user_id].transportation_mode && (
                                      <p>🚗 Transport: {userPreferences[user.user_id].transportation_mode}</p>
                                    )}
                                  </div>
                                  
                                  {/* Preferences */}
                                  <div className="border-b pb-2">
                                    <p className="font-semibold flex items-center gap-1 mb-1">
                                      <Zap className="h-3 w-3" /> Preferences
                                    </p>
                                    {userPreferences[user.user_id].budget_range && (
                                      <p>💰 Budget: {userPreferences[user.user_id].budget_range}</p>
                                    )}
                                    {userPreferences[user.user_id].energy_level && (
                                      <p>⚡ Energy: {userPreferences[user.user_id].energy_level}</p>
                                    )}
                                    {userPreferences[user.user_id].activity_preferences?.length ? (
                                      <p>🎯 Activities: {userPreferences[user.user_id].activity_preferences?.join(', ')}</p>
                                    ) : null}
                                  </div>
                                  
                                  {/* Food & Drink */}
                                  <div className="border-b pb-2">
                                    <p className="font-semibold flex items-center gap-1 mb-1">
                                      <Utensils className="h-3 w-3" /> Food & Drink
                                    </p>
                                    {userPreferences[user.user_id].food_preferences?.length ? (
                                      <p>🍽️ Food: {userPreferences[user.user_id].food_preferences?.join(', ')}</p>
                                    ) : null}
                                    {(userPreferences[user.user_id].drink_preferences?.length ?? 0) > 0 && (
                                      <p>🍷 Drinks: {userPreferences[user.user_id].drink_preferences?.join(', ')}</p>
                                    )}
                                    {userPreferences[user.user_id].dietary_restrictions?.length ? (
                                      <p>🥗 Dietary: {userPreferences[user.user_id].dietary_restrictions?.join(', ')}</p>
                                    ) : null}
                                    {userPreferences[user.user_id].allergies?.length ? (
                                      <p>⚠️ Allergies: {userPreferences[user.user_id].allergies?.join(', ')}</p>
                                    ) : null}
                                  </div>
                                  
                                  {/* Deal Breakers & Accessibility */}
                                  {(userPreferences[user.user_id].deal_breakers?.length || 
                                    userPreferences[user.user_id].accessibility_needs?.length ||
                                    userPreferences[user.user_id].smoking_preference) && (
                                    <div className="border-b pb-2">
                                      <p className="font-semibold flex items-center gap-1 mb-1">
                                        <AlertCircle className="h-3 w-3" /> Restrictions
                                      </p>
                                      {userPreferences[user.user_id].deal_breakers?.length ? (
                                        <p>🚫 Deal breakers: {userPreferences[user.user_id].deal_breakers?.join(', ')}</p>
                                      ) : null}
                                      {userPreferences[user.user_id].accessibility_needs?.length ? (
                                        <p>♿ Accessibility: {userPreferences[user.user_id].accessibility_needs?.join(', ')}</p>
                                      ) : null}
                                      {userPreferences[user.user_id].smoking_preference && (
                                        <p>🚬 Smoking: {userPreferences[user.user_id].smoking_preference}</p>
                                      )}
                                    </div>
                                  )}
                                  
                                  {/* Gift Preferences */}
                                  {(userPreferences[user.user_id].gift_recipient || 
                                    userPreferences[user.user_id].gift_interests?.length) && (
                                    <div>
                                      <p className="font-semibold flex items-center gap-1 mb-1">
                                        <Gift className="h-3 w-3" /> Gift Info
                                      </p>
                                      {userPreferences[user.user_id].gift_recipient && (
                                        <p>👤 Recipient: {userPreferences[user.user_id].gift_recipient}</p>
                                      )}
                                      {userPreferences[user.user_id].gift_interests?.length ? (
                                        <p>🎁 Interests: {userPreferences[user.user_id].gift_interests?.join(', ')}</p>
                                      ) : null}
                                      {userPreferences[user.user_id].gift_budget && (
                                        <p>💵 Budget: {userPreferences[user.user_id].gift_budget}</p>
                                      )}
                                      {userPreferences[user.user_id].gift_occasion && (
                                        <p>🎉 Occasion: {userPreferences[user.user_id].gift_occasion}</p>
                                      )}
                                    </div>
                                  )}
                                </div>
                              </TooltipContent>
                            </Tooltip>
                          </TooltipProvider>
                        ) : (
                          <span className="text-xs text-muted-foreground">No preferences</span>
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setSelectedUser({ id: user.user_id, name: user.display_name || 'User' })}
                        >
                          <Eye className="h-4 w-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      <UserDetailsDialog
        open={!!selectedUser}
        onOpenChange={(open) => !open && setSelectedUser(null)}
        userId={selectedUser?.id || null}
        userName={selectedUser?.name || ''}
      />
    </div>
  );
}
