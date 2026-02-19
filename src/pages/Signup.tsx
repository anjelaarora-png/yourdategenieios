import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ArrowLeft, Loader2, Star, Check, MapPin, Clock, Utensils, Wine, Music, Sparkles } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import logo from "@/assets/logo.png";
import { z } from "zod";

const signupSchema = z.object({
  firstName: z.string().trim().min(1, "First name is required").max(50, "First name too long"),
  lastName: z.string().trim().min(1, "Last name is required").max(50, "Last name too long"),
  email: z.string().trim().email("Invalid email address").max(255, "Email too long"),
  password: z.string().min(6, "Password must be at least 6 characters"),
});

// Sample date plan for preview
const samplePlan = {
  title: "Sunset & Sips",
  tagline: "A golden hour adventure",
  stops: [
    { icon: Wine, name: "Rooftop Wine Bar", time: "6:00 PM" },
    { icon: Utensils, name: "Farm-to-Table Dinner", time: "7:30 PM" },
    { icon: Music, name: "Live Jazz Lounge", time: "9:30 PM" },
  ],
};

// Testimonials for the signup page
const testimonials = [
  {
    name: "Sarah & Michael",
    quote: "Best investment in our relationship. Period.",
    rating: 5,
  },
  {
    name: "Jessica & David", 
    quote: "The Genie found spots we never knew existed!",
    rating: 5,
  },
];

// Features for the signup page
const features = [
  "Personalized multi-stop date plans",
  "Real venues with verified details",
  "Dietary restrictions always respected",
  "Conversation starters included",
  "Share plans with your partner",
];

const Signup = () => {
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();

  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault();

    if (password !== confirmPassword) {
      toast({
        title: "Passwords don't match",
        description: "Please make sure your passwords match.",
        variant: "destructive",
      });
      return;
    }

    const validation = signupSchema.safeParse({
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      password,
    });

    if (!validation.success) {
      const firstError = validation.error.errors[0];
      toast({
        title: "Validation error",
        description: firstError.message,
        variant: "destructive",
      });
      return;
    }

    setLoading(true);

    try {
      const displayName = `${firstName.trim()} ${lastName.trim()}`;
      const trimmedEmail = email.trim();
      const trimmedFirstName = firstName.trim();
      
      const { data, error } = await supabase.auth.signUp({
        email: trimmedEmail,
        password,
        options: {
          emailRedirectTo: window.location.origin,
          data: {
            display_name: displayName,
            first_name: trimmedFirstName,
            last_name: lastName.trim(),
          },
        },
      });

      if (error) throw error;

      // Send welcome email (fire and forget - don't block signup)
      if (data.session) {
        supabase.functions.invoke('send-welcome-email', {
          body: {
            email: trimmedEmail,
            display_name: displayName,
            first_name: trimmedFirstName,
          },
        }).catch(err => console.error('Welcome email error:', err));
        
        // Also notify admin of new signup
        supabase.functions.invoke('notify-new-signup', {
          body: {
            user_id: data.user?.id,
            email: trimmedEmail,
            display_name: displayName,
            created_at: new Date().toISOString(),
          },
        }).catch(err => console.error('Admin notification error:', err));
      }

      toast({
        title: "Account created!",
        description: `Welcome to Your Date Genie, ${firstName}! Check your email for a welcome message.`,
      });
      navigate("/dashboard");
    } catch (error: any) {
      toast({
        title: "Sign up failed",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex">
      {/* Left side - Preview & Social Proof */}
      <div className="hidden lg:flex lg:w-1/2 xl:w-3/5 bg-secondary/30 relative overflow-hidden">
        {/* Background effects */}
        <div className="absolute top-1/4 left-1/4 w-[400px] h-[400px] bg-primary/10 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 right-1/4 w-[300px] h-[300px] bg-primary/5 rounded-full blur-3xl" />
        
        <div className="relative z-10 flex flex-col justify-center p-12 xl:p-16 w-full">
          {/* Headline */}
          <div className="mb-12">
            <h2 className="font-display text-4xl xl:text-5xl text-foreground mb-4">
              Your perfect date,<br />
              <span className="text-gradient-gold">planned in 60 seconds</span>
            </h2>
            <p className="text-muted-foreground text-lg max-w-md">
              Join 500+ couples who stopped stressing and started connecting.
            </p>
          </div>

          {/* Date Plan Preview Card */}
          <div className="bg-card border border-border rounded-xl p-6 mb-8 max-w-md shadow-xl">
            <div className="flex items-center gap-2 mb-4">
              <Sparkles className="w-5 h-5 text-primary" />
              <span className="text-sm text-primary font-medium">Sample Date Plan</span>
            </div>
            <h3 className="font-display text-2xl text-foreground mb-1">{samplePlan.title}</h3>
            <p className="text-muted-foreground text-sm mb-6">{samplePlan.tagline}</p>
            
            <div className="space-y-4">
              {samplePlan.stops.map((stop, index) => (
                <div key={stop.name} className="flex items-center gap-4">
                  <div className="relative">
                    <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                      <stop.icon className="w-5 h-5 text-primary" />
                    </div>
                    {index < samplePlan.stops.length - 1 && (
                      <div className="absolute top-10 left-1/2 -translate-x-1/2 w-0.5 h-4 bg-border" />
                    )}
                  </div>
                  <div className="flex-1">
                    <p className="text-foreground font-medium">{stop.name}</p>
                    <p className="text-muted-foreground text-sm">{stop.time}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Testimonials */}
          <div className="space-y-4 max-w-md">
            {testimonials.map((testimonial) => (
              <div key={testimonial.name} className="flex items-start gap-4 bg-card/50 rounded-lg p-4 border border-border/50">
                <div className="flex gap-0.5">
                  {Array.from({ length: testimonial.rating }).map((_, i) => (
                    <Star key={i} className="w-4 h-4 fill-primary text-primary" />
                  ))}
                </div>
                <div>
                  <p className="text-foreground italic">"{testimonial.quote}"</p>
                  <p className="text-muted-foreground text-sm mt-1">— {testimonial.name}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Right side - Signup Form */}
      <div className="w-full lg:w-1/2 xl:w-2/5 flex items-center justify-center p-6 relative">
        {/* Background glow for mobile */}
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[400px] h-[400px] bg-primary/10 rounded-full blur-3xl lg:hidden" />

        <div className="relative w-full max-w-md">
          {/* Back link */}
          <Link to="/" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors mb-8">
            <ArrowLeft className="w-4 h-4" />
            Back to home
          </Link>

          {/* Card */}
          <div className="bg-card border border-border rounded-xl p-8">
            {/* Logo */}
            <div className="flex justify-center mb-6">
              <img src={logo} alt="Your Date Genie" className="h-20 w-auto" />
            </div>

            <h1 className="font-display text-3xl mb-2 text-foreground text-center">
              Create your account
            </h1>
            <p className="text-muted-foreground mb-6 text-center">
              Start planning unforgettable dates
            </p>

            {/* Features list - mobile only */}
            <div className="lg:hidden mb-6 space-y-2">
              {features.slice(0, 3).map((feature) => (
                <div key={feature} className="flex items-center gap-2 text-sm">
                  <Check className="w-4 h-4 text-primary flex-shrink-0" />
                  <span className="text-muted-foreground">{feature}</span>
                </div>
              ))}
            </div>

            <form onSubmit={handleSignup} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="firstName" className="text-foreground">First Name</Label>
                  <Input
                    id="firstName"
                    type="text"
                    placeholder="John"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    required
                    maxLength={50}
                    className="bg-input border-border text-foreground placeholder:text-muted-foreground"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lastName" className="text-foreground">Last Name</Label>
                  <Input
                    id="lastName"
                    type="text"
                    placeholder="Doe"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    required
                    maxLength={50}
                    className="bg-input border-border text-foreground placeholder:text-muted-foreground"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="email" className="text-foreground">Email</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  maxLength={255}
                  className="bg-input border-border text-foreground placeholder:text-muted-foreground"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="password" className="text-foreground">Password</Label>
                <Input
                  id="password"
                  type="password"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="bg-input border-border text-foreground placeholder:text-muted-foreground"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="confirmPassword" className="text-foreground">Confirm Password</Label>
                <Input
                  id="confirmPassword"
                  type="password"
                  placeholder="••••••••"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                  className="bg-input border-border text-foreground placeholder:text-muted-foreground"
                />
              </div>

              <Button 
                type="submit" 
                className="w-full gradient-gold text-primary-foreground font-bold py-6 text-lg hover:opacity-90 glow-gold"
                disabled={loading}
              >
                {loading ? (
                  <>
                    <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                    Creating account...
                  </>
                ) : (
                  "Start Planning Dates →"
                )}
              </Button>
            </form>

            <p className="text-center text-sm text-muted-foreground mt-6">
              Already have an account?{" "}
              <Link to="/login" className="text-primary hover:underline font-medium">
                Sign in
              </Link>
            </p>
          </div>

          {/* Trust badges */}
          <div className="mt-6 flex items-center justify-center gap-6 text-muted-foreground text-sm">
            <div className="flex items-center gap-1">
              <Check className="w-4 h-4 text-primary" />
              <span>Free to start</span>
            </div>
            <div className="flex items-center gap-1">
              <Check className="w-4 h-4 text-primary" />
              <span>No credit card</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Signup;
