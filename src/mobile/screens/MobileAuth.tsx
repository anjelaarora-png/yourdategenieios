import { useState } from "react";
import { Eye, EyeOff, Mail, Lock, ArrowLeft, Sparkles, CheckCircle, PartyPopper } from "lucide-react";
import { useAuth } from "@/hooks/useAuth";
import logo from "@/assets/logo.png";

interface MobileAuthProps {
  onSuccess: () => void;
}

type AuthMode = "welcome" | "login" | "signup" | "forgot" | "verify-email";

const MobileAuth = ({ onSuccess }: MobileAuthProps) => {
  const [mode, setMode] = useState<AuthMode>("welcome");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [resetSent, setResetSent] = useState(false);

  const { signIn, signUp, resetPassword } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      if (mode === "signup") {
        if (password !== confirmPassword) {
          setError("Passwords don't match");
          setLoading(false);
          return;
        }
        if (password.length < 6) {
          setError("Password must be at least 6 characters");
          setLoading(false);
          return;
        }
        const { error } = await signUp(email, password);
        if (error) throw error;
        setMode("verify-email");
      } else if (mode === "login") {
        const { error } = await signIn(email, password);
        if (error) throw error;
        onSuccess();
      } else if (mode === "forgot") {
        const { error } = await resetPassword(email);
        if (error) throw error;
        setResetSent(true);
      }
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : "An error occurred";
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  // Email verification sent screen
  if (mode === "verify-email") {
    return (
      <div className="min-h-screen flex flex-col bg-gradient-to-b from-green-500/10 via-background to-background px-6">
        <div className="pt-14">
          <button
            onClick={() => setMode("welcome")}
            className="flex items-center gap-1 text-primary haptic-button py-2"
          >
            <ArrowLeft className="w-5 h-5" />
            Back
          </button>
        </div>

        <div className="flex-1 flex flex-col items-center justify-center">
          {/* Success animation */}
          <div className="relative mb-8">
            <div className="w-24 h-24 rounded-full bg-green-500/20 flex items-center justify-center">
              <CheckCircle className="w-12 h-12 text-green-500" />
            </div>
            <div className="absolute -top-2 -right-2 w-10 h-10 rounded-full bg-amber-500/20 flex items-center justify-center">
              <PartyPopper className="w-5 h-5 text-amber-500" />
            </div>
          </div>

          <h2 className="text-2xl font-bold text-center mb-3">Check Your Inbox!</h2>
          
          <div className="bg-card border border-border rounded-2xl p-4 mb-6 max-w-xs">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                <Mail className="w-5 h-5 text-primary" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Email sent to</p>
                <p className="font-medium text-sm truncate">{email}</p>
              </div>
            </div>
          </div>

          <p className="text-muted-foreground text-center max-w-xs mb-6">
            We've sent you a confirmation link. Click it to activate your account and start planning amazing dates!
          </p>

          <div className="w-full max-w-xs space-y-3">
            <div className="flex items-center gap-3 text-sm text-muted-foreground">
              <div className="w-6 h-6 rounded-full bg-muted flex items-center justify-center text-xs font-bold">1</div>
              <span>Open the email from Your Date Genie</span>
            </div>
            <div className="flex items-center gap-3 text-sm text-muted-foreground">
              <div className="w-6 h-6 rounded-full bg-muted flex items-center justify-center text-xs font-bold">2</div>
              <span>Click "Confirm your email"</span>
            </div>
            <div className="flex items-center gap-3 text-sm text-muted-foreground">
              <div className="w-6 h-6 rounded-full bg-muted flex items-center justify-center text-xs font-bold">3</div>
              <span>Come back and sign in!</span>
            </div>
          </div>
        </div>

        <div className="pb-12 space-y-3">
          <button
            onClick={() => setMode("login")}
            className="ios-button ios-button-primary w-full"
          >
            I've Confirmed - Sign In
          </button>
          <p className="text-center text-xs text-muted-foreground">
            Didn't receive the email? Check your spam folder or{" "}
            <button onClick={() => setMode("signup")} className="text-primary">
              try again
            </button>
          </p>
        </div>
      </div>
    );
  }

  // Welcome screen
  if (mode === "welcome") {
    return (
      <div className="min-h-screen flex flex-col bg-background px-6">
        {/* Hero section */}
        <div className="flex-1 flex flex-col items-center justify-center">
          <img src={logo} alt="Your Date Genie" className="h-20 w-auto mb-6" />
          <h1 className="large-title text-center mb-3">
            Your Perfect Date<br />Awaits
          </h1>
          <p className="text-muted-foreground text-center text-lg max-w-xs">
            AI-powered date planning that understands your style
          </p>
        </div>

        {/* Action buttons */}
        <div className="pb-12 space-y-3">
          <button
            onClick={() => setMode("signup")}
            className="ios-button ios-button-primary w-full flex items-center justify-center gap-2"
          >
            <Sparkles className="w-5 h-5" />
            Create Account
          </button>
          <button
            onClick={() => setMode("login")}
            className="ios-button ios-button-secondary w-full"
          >
            Sign In
          </button>
        </div>
      </div>
    );
  }

  // Forgot password success
  if (mode === "forgot" && resetSent) {
    return (
      <div className="min-h-screen flex flex-col bg-background px-6">
        <div className="pt-4">
          <button
            onClick={() => { setMode("login"); setResetSent(false); }}
            className="flex items-center gap-1 text-primary haptic-button py-2"
          >
            <ArrowLeft className="w-5 h-5" />
            Back to Sign In
          </button>
        </div>

        <div className="flex-1 flex flex-col items-center justify-center">
          <div className="w-20 h-20 rounded-full bg-green-500/10 flex items-center justify-center mb-6">
            <Mail className="w-10 h-10 text-green-500" />
          </div>
          <h2 className="text-2xl font-bold text-center mb-3">Check Your Email</h2>
          <p className="text-muted-foreground text-center max-w-xs">
            We sent a password reset link to <span className="font-medium text-foreground">{email}</span>
          </p>
        </div>
      </div>
    );
  }

  // Login / Signup / Forgot form
  return (
    <div className="min-h-screen flex flex-col bg-background">
      {/* Header */}
      <div className="px-6 pt-4">
        <button
          onClick={() => setMode("welcome")}
          className="flex items-center gap-1 text-primary haptic-button py-2"
        >
          <ArrowLeft className="w-5 h-5" />
          Back
        </button>
      </div>

      {/* Form content */}
      <div className="flex-1 px-6 pt-8">
        <h1 className="text-3xl font-bold mb-2">
          {mode === "login" && "Welcome Back"}
          {mode === "signup" && "Create Account"}
          {mode === "forgot" && "Reset Password"}
        </h1>
        <p className="text-muted-foreground mb-8">
          {mode === "login" && "Sign in to continue planning amazing dates"}
          {mode === "signup" && "Start your journey to perfect dates"}
          {mode === "forgot" && "Enter your email to receive a reset link"}
        </p>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Email input */}
          <div className="relative">
            <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Email address"
              className="ios-input pl-12"
              required
              autoComplete="email"
            />
          </div>

          {/* Password input */}
          {mode !== "forgot" && (
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
              <input
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Password"
                className="ios-input pl-12 pr-12"
                required
                autoComplete={mode === "login" ? "current-password" : "new-password"}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-muted-foreground haptic-button"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          )}

          {/* Confirm password for signup */}
          {mode === "signup" && (
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
              <input
                type={showPassword ? "text" : "password"}
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Confirm password"
                className="ios-input pl-12"
                required
                autoComplete="new-password"
              />
            </div>
          )}

          {/* Error message */}
          {error && (
            <div className="bg-destructive/10 text-destructive px-4 py-3 rounded-lg text-sm">
              {error}
            </div>
          )}

          {/* Forgot password link */}
          {mode === "login" && (
            <button
              type="button"
              onClick={() => setMode("forgot")}
              className="text-primary text-sm font-medium"
            >
              Forgot password?
            </button>
          )}

          {/* Submit button */}
          <button
            type="submit"
            disabled={loading}
            className="ios-button ios-button-primary w-full mt-6 disabled:opacity-50"
          >
            {loading ? (
              <span className="flex items-center justify-center gap-2">
                <div className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                {mode === "login" && "Signing In..."}
                {mode === "signup" && "Creating Account..."}
                {mode === "forgot" && "Sending..."}
              </span>
            ) : (
              <>
                {mode === "login" && "Sign In"}
                {mode === "signup" && "Create Account"}
                {mode === "forgot" && "Send Reset Link"}
              </>
            )}
          </button>
        </form>

        {/* Toggle between login and signup */}
        {(mode === "login" || mode === "signup") && (
          <p className="text-center text-muted-foreground mt-8">
            {mode === "login" ? "Don't have an account? " : "Already have an account? "}
            <button
              onClick={() => setMode(mode === "login" ? "signup" : "login")}
              className="text-primary font-medium"
            >
              {mode === "login" ? "Sign Up" : "Sign In"}
            </button>
          </p>
        )}
      </div>
    </div>
  );
};

export default MobileAuth;
