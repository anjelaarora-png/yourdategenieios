import { useEffect, useState, useCallback, useRef } from "react";
import { supabase } from "@/integrations/supabase/client";
import type { User, AuthChangeEvent, AuthError } from "@supabase/supabase-js";

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const initialSessionFetched = useRef(false);
  const isMounted = useRef(true);

  useEffect(() => {
    isMounted.current = true;

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event: AuthChangeEvent, session) => {
        if (isMounted.current && initialSessionFetched.current) {
          setUser(session?.user ?? null);
        }
      }
    );

    const fetchSession = async () => {
      try {
        const { data: { session }, error } = await supabase.auth.getSession();
        if (error) {
          console.error("[useAuth] Error fetching session:", error.message);
        }
        if (isMounted.current) {
          setUser(session?.user ?? null);
          setLoading(false);
          initialSessionFetched.current = true;
        }
      } catch (err) {
        console.error("[useAuth] Unexpected error:", err);
        if (isMounted.current) {
          setUser(null);
          setLoading(false);
          initialSessionFetched.current = true;
        }
      }
    };

    fetchSession();

    return () => {
      isMounted.current = false;
      subscription.unsubscribe();
    };
  }, []);

  const signIn = useCallback(async (email: string, password: string): Promise<{ error: AuthError | null }> => {
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      return { error };
    } catch (err) {
      console.error("[useAuth] Sign in error:", err);
      return { error: err as AuthError };
    }
  }, []);

  const signUp = useCallback(async (email: string, password: string): Promise<{ error: AuthError | null }> => {
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
      console.error("[useAuth] Sign up error:", err);
      return { error: err as AuthError };
    }
  }, []);

  const resetPassword = useCallback(async (email: string): Promise<{ error: AuthError | null }> => {
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`,
      });
      return { error };
    } catch (err) {
      console.error("[useAuth] Reset password error:", err);
      return { error: err as AuthError };
    }
  }, []);

  const signOut = useCallback(async () => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) {
        console.error("[useAuth] Sign out error:", error.message);
        throw error;
      }
      if (isMounted.current) {
        setUser(null);
      }
    } catch (err) {
      console.error("[useAuth] Unexpected sign out error:", err);
      throw err;
    }
  }, []);

  return { user, loading, signIn, signUp, resetPassword, signOut };
}
