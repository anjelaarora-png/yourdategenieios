import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { supabase } from "@/integrations/supabase/client";
import type { User, AuthError } from "@supabase/supabase-js";

type AuthContextValue = {
  user: User | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: AuthError | null }>;
  signUp: (email: string, password: string) => Promise<{ error: AuthError | null }>;
  resetPassword: (email: string) => Promise<{ error: AuthError | null }>;
  signOut: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const isMounted = useRef(true);

  useEffect(() => {
    isMounted.current = true;

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!isMounted.current) return;
      setUser(session?.user ?? null);
      setLoading(false);
    });

    void supabase.auth.getSession().then(({ data: { session }, error }) => {
      if (!isMounted.current) return;
      if (error) {
        console.error("[Auth] getSession:", error.message);
      }
      setUser(session?.user ?? null);
      setLoading(false);
    });

    return () => {
      isMounted.current = false;
      subscription.unsubscribe();
    };
  }, []);

  // Re-read session when the tab or PWA regains focus (timers may have been suspended while backgrounded).
  useEffect(() => {
    const syncFromStorage = () => {
      if (document.visibilityState !== "visible") return;
      void supabase.auth.getSession().then(({ data: { session }, error }) => {
        if (!isMounted.current) return;
        if (error) {
          console.error("[Auth] getSession on visible:", error.message);
          return;
        }
        setUser(session?.user ?? null);
      });
    };

    document.addEventListener("visibilitychange", syncFromStorage);
    window.addEventListener("pageshow", syncFromStorage);
    return () => {
      document.removeEventListener("visibilitychange", syncFromStorage);
      window.removeEventListener("pageshow", syncFromStorage);
    };
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      return { error };
    } catch (err) {
      console.error("[Auth] Sign in error:", err);
      return { error: err as AuthError };
    }
  }, []);

  const signUp = useCallback(async (email: string, password: string) => {
    try {
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          emailRedirectTo: `${window.location.origin}/app`,
        },
      });
      return { error };
    } catch (err) {
      console.error("[Auth] Sign up error:", err);
      return { error: err as AuthError };
    }
  }, []);

  const resetPassword = useCallback(async (email: string) => {
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`,
      });
      return { error };
    } catch (err) {
      console.error("[Auth] Reset password error:", err);
      return { error: err as AuthError };
    }
  }, []);

  const signOut = useCallback(async () => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) {
        console.error("[Auth] Sign out error:", error.message);
        throw error;
      }
      if (isMounted.current) {
        setUser(null);
      }
    } catch (err) {
      console.error("[Auth] Unexpected sign out error:", err);
      throw err;
    }
  }, []);

  const value = useMemo(
    () => ({
      user,
      loading,
      signIn,
      signUp,
      resetPassword,
      signOut,
    }),
    [user, loading, signIn, signUp, resetPassword, signOut]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (ctx === undefined) {
    throw new Error("useAuth must be used within AuthProvider");
  }
  return ctx;
}
