import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { lazy, Suspense } from "react";
import Index from "./pages/Index";
import { AuthProvider } from "@/hooks/useAuth";
import { UserPreferencesProvider } from "@/hooks/useUserPreferences";

// Lazy-load all non-landing routes so the marketing bundle stays lean.
const Login = lazy(() => import("./pages/Login"));
const Signup = lazy(() => import("./pages/Signup"));
const ForgotPassword = lazy(() => import("./pages/ForgotPassword"));
const ResetPassword = lazy(() => import("./pages/ResetPassword"));
const Dashboard = lazy(() => import("./pages/Dashboard"));
const Preferences = lazy(() => import("./pages/Preferences"));
const Admin = lazy(() => import("./pages/Admin"));
const Mobile = lazy(() => import("./pages/Mobile"));
const PrivacyPolicy = lazy(() => import("./pages/PrivacyPolicy"));
const Terms = lazy(() => import("./pages/Terms"));
const NotFound = lazy(() => import("./pages/NotFound"));
const Waitlist = lazy(() => import("./pages/Waitlist"));
const ForBusiness = lazy(() => import("./pages/ForBusiness"));
const BusinessLogin = lazy(() => import("./pages/BusinessLogin"));
const BusinessPartnerPortal = lazy(() => import("./pages/BusinessPartnerPortal"));

// Optimized QueryClient configuration for reliability and iOS WebView stability
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      // Prevent duplicate requests within 2 seconds
      staleTime: 2000,
      // Cache data for 5 minutes
      gcTime: 5 * 60 * 1000,
      // Retry failed requests with exponential backoff
      retry: (failureCount, error) => {
        // Don't retry on 4xx errors (client errors)
        if (error && typeof error === 'object' && 'status' in error) {
          const status = (error as { status: number }).status;
          if (status >= 400 && status < 500) return false;
        }
        return failureCount < 2;
      },
      retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 10000),
      // Prevent refetching on window focus (important for iOS WebView)
      refetchOnWindowFocus: false,
      // Prevent refetching on reconnect to avoid duplicate calls
      refetchOnReconnect: false,
    },
    mutations: {
      // Retry mutations once on failure
      retry: 1,
      retryDelay: 1000,
    },
  },
});

const App = () => (
  <QueryClientProvider client={queryClient}>
    <AuthProvider>
    <UserPreferencesProvider>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Suspense fallback={null}>
          <Routes>
            <Route path="/" element={<Index />} />
            <Route path="/login" element={<Login />} />
            <Route path="/signup" element={<Signup />} />
            <Route path="/forgot-password" element={<ForgotPassword />} />
            <Route path="/reset-password" element={<ResetPassword />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/preferences" element={<Preferences />} />
            <Route path="/admin" element={<Admin />} />
            <Route path="/app" element={<Mobile />} />
            <Route path="/privacy-policy" element={<PrivacyPolicy />} />
            <Route path="/privacy" element={<PrivacyPolicy />} />
            <Route path="/terms" element={<Terms />} />
            <Route path="/waitlist" element={<Waitlist />} />
            <Route path="/for-business" element={<ForBusiness />} />
            <Route path="/for-business/login" element={<BusinessLogin />} />
            <Route path="/for-business/apply" element={<BusinessPartnerPortal />} />
            {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </Suspense>
      </BrowserRouter>
    </TooltipProvider>
    </UserPreferencesProvider>
    </AuthProvider>
  </QueryClientProvider>
);

export default App;
